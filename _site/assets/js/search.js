(function () {
  const cfgEl = document.getElementById('search-config');
  if (!cfgEl) return;
  const cfg = JSON.parse(cfgEl.textContent || '{}');
  if (!cfg.engine) return;

  const log = (...a) => cfg.debug && console.log('[search]', ...a);
  const $ = (id) => document.getElementById(id);
  const input = $('search-input');
  const out = $('search-results');
  if (!input || !out) return;

  const escapeHTML = (s) => (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const termsFrom = (q) => (q || '').toLowerCase().trim().split(/\s+/).filter(Boolean);
  const markTerms = (text, terms) => {
    let html = escapeHTML(text || '');
    for (const t of terms) {
      if (!t) continue;
      const re = new RegExp(`(${t.replace(/[.*+?^${}()|[\\]\\\\]/g,'\\$&')})`,'gi');
      html = html.replace(re, '<mark>$1</mark>');
    }
    return html;
  };
  const pathCap = (url) => {
    // Return the first directory in the URL /<THIS>/ with the first letter capitalized
    try {
      const u = new URL(url, window.location.origin);
      const parts = u.pathname.split('/').filter(Boolean);
      if (parts.length === 0) return '/';
      return parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
    } catch (e) {
      return '';
    }
  };
  const snippet = (text, terms, radius = 80) => {
    if (!text) return '';
    const lower = text.toLowerCase();
    let first = -1;
    for (const t of terms) {
      const i = lower.indexOf(t);
      if (i !== -1 && (first === -1 || i < first)) first = i;
    }
    const start = Math.max(0, first === -1 ? 0 : first - radius);
    const end = Math.min(text.length, first === -1 ? radius * 2 : first + radius);
    const sliced = text.slice(start, end);
    return (start > 0 ? '…' : '') + markTerms(sliced, terms) + (end < text.length ? '…' : '');
  };
  const render = (rows, query) => {
    const terms = termsFrom(query);
    out.innerHTML = rows.map(r => {
      const pathCapValue = pathCap(r.url);
      return `<li>
       <a href="${r.url}">${escapeHTML(r.title)}${pathCapValue ? ` (in ${pathCapValue})` : ''}</a>
       ${r.content ? `<div class="snippet">${snippet(r.content, terms)}</div>` : ''}
       </li>`;
    }).join('');
  };

  let docs = null, byId = null;
  async function ensureDocs() {
    if (docs) return;
    const res = await fetch(cfg.searchJson, { credentials: 'same-origin' });
    docs = await res.json();
    byId = new Map(docs.map(d => [String(d.id), d]));
    log('docs', docs.length);
  }

  let searchFn = null;

  async function boot() {
    try {
      if (cfg.engine === 'minisearch') await initMiniSearch();
      else if (cfg.engine === 'lunr') await initLunr();
      else if (cfg.engine === 'elasticlunr') await initElastic();
      else throw new Error('Unknown engine: ' + cfg.engine);

      let pending = null;
      input.addEventListener('input', () => {
        const q = input.value.trim();
        if (pending) cancelAnimationFrame(pending);
        pending = requestAnimationFrame(() => {
          const rows = q ? searchFn(q) : [];
          render(rows, q);
        });
      });
    } catch (e) {
    }
  }

  async function initMiniSearch() {
    if (!window.MiniSearch) throw new Error('MiniSearch not loaded');
    await ensureDocs();
    const o = cfg.options || {};
    const mini = new window.MiniSearch({
      fields: ['title','content'],
      storeFields: ['title','url','content','date'],
      searchOptions: {
        boost: { title: o.title_boost || 3 },
        prefix: !!o.prefix,
        fuzzy: (typeof o.fuzzy === 'number') ? o.fuzzy : 0.2
      }
    });
    mini.addAll(docs);
    searchFn = (q) => mini.search(q).map(h => {
      const d = mini.documentStore.getDoc(h.id);
      return { title: d.title, url: d.url, content: d.content };
    });
  }

  async function initLunr() {
    if (!window.lunr) throw new Error('Lunr not loaded');
    await ensureDocs();

    const safeDocs = docs.map(d => ({
      id: String(d.id),
      title: d.title || '',
      content: d.content || '',
      url: d.url
    }));

    const o = cfg.options || {};
    console.time('[search] lunr build');
    const idx = window.lunr(function () {
      this.ref('id');
      this.field('title', { boost: o.title_boost || 3 });
      this.field('content');
      this.metadataWhitelist = ['position'];
      safeDocs.forEach(d => this.add(d), this);
    });
    console.timeEnd('[search] lunr build');

    const byIdLocal = new Map(safeDocs.map(d => [d.id, d]));

    // Prefix + light fuzzy query builder
    const qopts = {
      minLen: 2,                            // ignore very short inputs
      trailingWildcard: true,               // enable prefix match
      fuzzyEdits: 1,                        // edit distance for len>=4 tokens
      fields: ['title','content']
    };

    function queryWithPrefixAndFuzzy(qstr) {
      const tokens = window.lunr.tokenizer(qstr).map(t => t.toString()).filter(Boolean);
      if (tokens.length === 0) return [];
      return idx.query(q => {
        tokens.forEach((term, i) => {
          // prefix match
          q.term(term, {
            fields: qopts.fields,
            wildcard: qopts.trailingWildcard ? window.lunr.Query.wildcard.TRAILING : 0,
            presence: window.lunr.Query.presence.OPTIONAL,
            boost: i === 0 ? 2 : 1
          });
          // light fuzziness for longer terms
          if (term.length >= 4 && qopts.fuzzyEdits) {
            q.term(term, {
              fields: qopts.fields,
              editDistance: qopts.fuzzyEdits,
              presence: window.lunr.Query.presence.OPTIONAL
            });
          }
        });
      });
    }

    searchFn = (qstr) => {
      if (!qstr || qstr.length < qopts.minLen) return [];
      const results = queryWithPrefixAndFuzzy(qstr);
      return results.map(r => {
        const d = byIdLocal.get(String(r.ref));
        return d ? { title: d.title, url: d.url, content: d.content } : null;
      }).filter(Boolean);
    };
  }


  async function initElastic() {
    if (!window.elasticlunr) throw new Error('elasticlunr not loaded');
    await ensureDocs();
    const idx = window.elasticlunr(function () {
      this.setRef('id');
      this.addField('title');
      this.addField('content');
    });
    docs.forEach(d => idx.addDoc(d));
    const o = cfg.options || {};
    searchFn = (q) => idx.search(q, { bool: o.bool || 'AND', expand: (o.expand !== false) })
      .map(r => {
        const d = byId.get(String(r.ref));
        return { title: d.title, url: d.url, content: d.content };
      });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
