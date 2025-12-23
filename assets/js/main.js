// Main JavaScript for the DocOps Lab site
// Handles theme functionality, smooth scrolling, and interactive features

// Wait for theme config to be available
function getConfig() {
  return window.themeConfig || {};
}

// Initialize all theme functionality
function init() {
  const config = getConfig();

  removeInlineThemeStyles();
  initDarkMode();
  initSmoothScrolling();
  initProjectCardClicks();
  initCodeBlockLabels();
  initSidebarEnhancements();
  initAdmonitionIconPinning();
  initFootnotesMover();
  initTopBanner();
  initLibraryComponentPopovers();
  initDocsTabs();
  initTokenSwapper();

  if (config.parallax) {
    initParallax();
  }
}

function removeInlineThemeStyles() {
  const inlineStyles = document.querySelectorAll('head style');
  inlineStyles.forEach(style => {
    if (style.textContent.includes('background-color:#f7faea!important') || 
        style.textContent.includes('background-color:#1a202c!important')) {
      style.remove();
    }
  });
}

// Project card click handlers
function initProjectCardClicks() {
  // Wait a bit for all elements to be fully rendered
  setTimeout(() => {
    // Handle project cards with data-href attribute
    const projectCards = document.querySelectorAll('.project-card[data-href]');

    if (projectCards.length > 0) {
      projectCards.forEach((card) => {
        const href = card.getAttribute('data-href');

        if (href) {
          card.addEventListener('click', (e) => {
            // Don't navigate if clicking on a link inside the card
            if (e.target.closest('a')) {
              return;
            }

            window.location.href = href;
          });

          card.style.cursor = 'pointer';
          card.setAttribute('title', `Click to view: ${href}`);
        }
      });
    }

    // Handle any other clickable project elements
    const clickableProjects = document.querySelectorAll('[data-project-link]');

    clickableProjects.forEach(element => {
      const href = element.getAttribute('data-project-link');
      if (href) {
        element.addEventListener('click', (e) => {
          if (e.target.closest('a')) return;
          window.location.href = href;
        });
        element.style.cursor = 'pointer';
      }
    });
  }, 100); // Small delay to ensure DOM is fully rendered
}

// Dark mode functionality
function initDarkMode() {
  const config = getConfig();
  if (!config.darkMode) return;

  const toggleButton = createDarkModeToggle();
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
  const savedTheme = localStorage.getItem('theme');

  // Check if theme was already set by immediate script
  const alreadyDark = document.documentElement.classList.contains('dark-mode');

  // Determine initial theme:
  // 1. Use what's already set if immediate script set it
  // 2. Use saved preference if it exists  
  // 3. Use OS/browser preference if available
  // 4. Default to dark mode as fallback
  let initialTheme;
  if (alreadyDark) {
    initialTheme = 'dark';
  } else if (savedTheme) {
    initialTheme = savedTheme;
  } else if (prefersDark.matches) {
    initialTheme = 'dark';
  } else if (window.matchMedia('(prefers-color-scheme: light)').matches) {
    initialTheme = 'light';
  } else {
    // No OS preference detected or OS preference unknown - default to dark
    initialTheme = 'dark';
  }

  // Set the initial theme (this will also sync the toggle button icon)
  setTheme(initialTheme);

  // Ensure icon is updated after Lucide loads
  setTimeout(() => {
    setTheme(initialTheme);
  }, 300);

  // Listen for system theme changes
  prefersDark.addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      setTheme(e.matches ? 'dark' : 'light');
    }
  });

  // Toggle button click handler
  toggleButton.addEventListener('click', () => {
    const currentTheme = document.body.classList.contains('dark-mode') ? 'dark' : 'light';
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
  });
}

function createDarkModeToggle() {
  const toggle = document.createElement('button');
  toggle.className = 'dark-mode-toggle';
  toggle.innerHTML = '<i data-lucide="moon"></i>';
  toggle.setAttribute('aria-label', 'Toggle dark mode');
  document.body.appendChild(toggle);
  return toggle;
}

function setTheme(theme) {
  const html = document.documentElement;
  const body = document.body;
  const toggleButton = document.querySelector('.dark-mode-toggle');

  // Toggle HLJS themes
  const hljsLight = document.getElementById('hljs-theme-light');
  const hljsDark = document.getElementById('hljs-theme-dark');

  if (theme === 'dark') {
    html.classList.add('dark-mode');
    html.classList.remove('force-light-mode');
    body.classList.add('dark-mode');
    body.classList.remove('force-light-mode');

    if (hljsDark && hljsLight) {
      hljsDark.disabled = false;
      hljsLight.disabled = true;
    }

    if (toggleButton) {
      // Replace with sun icon
      toggleButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="m12 2 0 2"/><path d="m12 20 0 2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="m2 12 2 0"/><path d="m20 12 2 0"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>';
    }
  } else {
    html.classList.remove('dark-mode');
    html.classList.add('force-light-mode');
    body.classList.remove('dark-mode');
    body.classList.add('force-light-mode');

    if (hljsDark && hljsLight) {
      hljsDark.disabled = true;
      hljsLight.disabled = false;
    }

    if (toggleButton) {
      // Replace with moon icon
      toggleButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>';
    }
  }
}

// Smooth scrolling for anchor links with banner offset
function initSmoothScrolling() {
  // Handle direct navigation to anchors (URL hash on page load)
  if (window.location.hash) {
    // Wait for page to fully load before adjusting scroll position
    setTimeout(() => {
      scrollToAnchorWithOffset(window.location.hash);
    }, 100);
  }

  // Handle anchor link clicks
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const hash = this.getAttribute('href');
      scrollToAnchorWithOffset(hash);
      
      // Update URL hash without triggering scroll
      if (history.pushState) {
        history.pushState(null, null, hash);
      } else {
        window.location.hash = hash;
      }
    });
  });

  // Handle browser back/forward with hash changes
  window.addEventListener('hashchange', function() {
    if (window.location.hash) {
      scrollToAnchorWithOffset(window.location.hash);
    }
  });
}

// Scroll to anchor with offset to account for fixed banner
function scrollToAnchorWithOffset(hash) {
  const target = document.querySelector(hash);
  if (!target) return;
  
  // Calculate offset based on banner height
  const banner = document.getElementById('top-banner');
  let offset = 20; // Default offset in pixels
  
  if (banner && !banner.classList.contains('banner-hidden')) {
    offset = banner.offsetHeight + 20; // Banner height plus some padding
  }
  
  // Get target position
  const targetPosition = target.offsetTop - offset;
  
  // Smooth scroll to position
  window.scrollTo({
    top: targetPosition,
    behavior: 'smooth'
  });
}

// Basic parallax effect for hero sections
function initParallax() {
  const heroSection = document.querySelector('.hero-section');
  if (!heroSection) return;

  let ticking = false;

  function updateParallax() {
    const scrolled = window.pageYOffset;
    const rate = scrolled * -0.5;
    heroSection.style.transform = `translateY(${rate}px)`;
    ticking = false;
  }

  // Attach scroll event for parallax
  window.addEventListener('scroll', function () {
    if (!ticking) {
      window.requestAnimationFrame(updateParallax);
      ticking = true;
    }
  });
}

// Add labels to upper-right corner of code blocks with collision detection
function initCodeBlockLabels() {
  const codeBlocks = document.querySelectorAll('code[data-lang]');

  codeBlocks.forEach(block => {
    const lang = block.getAttribute('data-lang');
    const preBlock = block.closest('pre');
    if (!preBlock) return;

    // Check if we already added labels to this pre block
    if (preBlock.querySelector('.code-lang-label')) return;

    // Create copy button
    const copyBtn = document.createElement('button');
    copyBtn.className = 'code-copy-btn';
    copyBtn.setAttribute('data-lang', lang);

    // Add SVG icon
    copyBtn.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
      </svg>
    `;

    // Add copy functionality
    copyBtn.addEventListener('click', () => {
      const code = block.textContent || block.innerText || '';
      navigator.clipboard.writeText(code).catch(() => {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = code;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
      });
    });

    // Create language label
    const label = document.createElement('span');
    label.className = 'code-lang-label';
    label.setAttribute('data-lang', lang);

    // Replace twig with LIQUID
    if (lang === 'twig') {
      label.textContent = 'LIQUID';
    } else {
      label.textContent = lang.toUpperCase();
    }

    // Check first line length to avoid collision with labels
    const textContent = block.textContent || block.innerText || '';
    const firstLine = textContent.split('\n')[0] || '';

    // If first line is longer than 60 characters, add spacing class
    if (firstLine.length > 140) {
      preBlock.classList.add('long-first-line');
    }

    // Add both buttons to the parent pre block
    preBlock.style.position = 'relative';
    preBlock.appendChild(copyBtn);
    preBlock.appendChild(label);

    // Position copy button to the left of the language label after both are added
    requestAnimationFrame(() => {
      const labelRect = label.getBoundingClientRect();
      const preRect = preBlock.getBoundingClientRect();
      const labelWidth = labelRect.width;

      // Position copy button with 0.5rem gap to the left of the language label
      const gap = 8; // 0.5rem = 8px (assuming 16px base font size)
      const copyBtnRight = labelWidth + gap;
      copyBtn.style.right = `${copyBtnRight}px`;
    });
  });
}


// Sidebar enhancements: collapse/expand and stash functionality
function initSidebarEnhancements() {
  const sidebarBlocks = document.querySelectorAll('.sidebarblock');

  // Do nothing if no sidebar blocks found
  if (sidebarBlocks.length === 0) return;

  // Don't create till until needed

  sidebarBlocks.forEach(function (block) {
    setupSidebarBlock(block);
  });
}

function ensureSidebarTill() {
  let till = document.querySelector('#sidebar-till');
  if (!till) {
    till = document.createElement('div');
    till.id = 'sidebar-till';
    till.innerHTML = '<h3>Stashed Sidebars</h3>';

    // Try to insert before footer, otherwise before closing body tag
    const footer = document.querySelector('footer');
    if (footer) {
      footer.parentNode.insertBefore(till, footer);
    } else {
      document.body.appendChild(till);
    }
  }
  return till;
}

function setupSidebarBlock(block) {
  // Add an ID to the sidebar block if it doesn't have one
  if (!block.id) {
    const title = block.querySelector('.title');
    if (title) {
      const slug = title.textContent.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
      const random = Math.floor(Math.random() * 1000000);
      block.id = slug + '-' + random;
    } else {
      const random = Math.floor(Math.random() * 1000000);
      block.id = 'sidebarblock-' + random;
    }
  }

  const blockTitle = block.querySelector('.title')?.textContent || 'Untitled Sidebar';
  const contentDiv = block.querySelector('.content');
  if (!contentDiv) return;

  const contentChildren = Array.from(contentDiv.children);
  if (contentChildren.length <= 1) return; // Need at least 2 elements to have collapse functionality

  // Find all the divs that do not contain the class .title
  const contentBlocks = contentChildren.filter(child => !child.classList.contains('title'));

  if (contentBlocks.length < 2) return; // Need at least 2 blocks to have collapse functionality

  // Keep the title and first block visible, hide the rest
  const hiddenContentBlocks = contentBlocks.slice(1);

  // Only proceed if there are blocks to hide
  if (hiddenContentBlocks.length === 0) {
    console.log('No additional blocks to hide in sidebar:', blockTitle);
    return;
  }

  // Create wrapper for hidden content - move only the additional blocks
  const hideWrapper = document.createElement('div');
  hideWrapper.className = 'sidebar-hidden-content hide';
  hiddenContentBlocks.forEach(function (cBlock) {
    hideWrapper.appendChild(cBlock);
  });

  // Create "Continue reading" link
  const continueReading = document.createElement('div');
  continueReading.className = 'sidebar-continue-reading';
  continueReading.innerHTML = `
    <a href="#" class="continue-reading-link">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="m6 9 6 6 6-6"/>
      </svg>
      Continue reading this sidebar...
    </a>
  `;

  // Create bottom collapse button (will be hidden initially)
  const bottomCollapseBtn = document.createElement('div');
  bottomCollapseBtn.className = 'sidebar-bottom-collapse';
  bottomCollapseBtn.innerHTML = `
    <button class="sidebar-toggle-btn bottom-toggle">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="m18 15-6-6-6 6"/>
      </svg>
    </button>
  `;

  // Add the bottom collapse button to the hidden wrapper (so it shows when expanded)
  hideWrapper.appendChild(bottomCollapseBtn);

  // Append the wrapper and continue reading link after the first block
  contentDiv.appendChild(hideWrapper);
  contentDiv.appendChild(continueReading);

  // Create button container
  const buttonContainer = document.createElement('div');
  buttonContainer.className = 'sidebar-controls';

  // Create expand/collapse toggle button
  const toggleButton = document.createElement('button');
  toggleButton.className = 'sidebar-toggle-btn';
  toggleButton.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="m6 9 6 6 6-6"/>
    </svg>
  `;
  toggleButton.title = 'Expand sidebar';

  // Create stash button
  const stashButton = document.createElement('button');
  stashButton.className = 'sidebar-stash-btn';
  stashButton.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M12 2v14"/>
      <path d="m5 9 7 7 7-7"/>
      <path d="M2 21h20"/>
    </svg>
  `;
  stashButton.title = 'Stash to bottom';

  buttonContainer.appendChild(toggleButton);
  buttonContainer.appendChild(stashButton);
  block.appendChild(buttonContainer);

  // Toggle expand/collapse functionality
  function toggleSidebar(expand) {
    if (expand) {
      // Expand
      hideWrapper.classList.remove('hide');
      block.classList.add('expanded');
      continueReading.style.display = 'none';
      toggleButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="m18 15-6-6-6 6"/>
        </svg>
      `;
      toggleButton.title = 'Collapse sidebar';
    } else {
      // Collapse
      hideWrapper.classList.add('hide');
      block.classList.remove('expanded');
      continueReading.style.display = 'block';
      toggleButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="m6 9 6 6 6-6"/>
        </svg>
      `;
      toggleButton.title = 'Expand sidebar';
    }
  }

  toggleButton.addEventListener('click', function () {
    const isCollapsed = hideWrapper.classList.contains('hide');
    toggleSidebar(isCollapsed);
  });

  // Continue reading link functionality
  const continueLink = continueReading.querySelector('.continue-reading-link');
  continueLink.addEventListener('click', function (e) {
    e.preventDefault();
    toggleSidebar(true);
  });

  // Bottom collapse button functionality
  const bottomToggleBtn = bottomCollapseBtn.querySelector('.bottom-toggle');
  bottomToggleBtn.addEventListener('click', function () {
    toggleSidebar(false);
  });

  // Stash functionality
  stashButton.addEventListener('click', function () {
    // Create till only when first sidebar is stashed
    const till = ensureSidebarTill();

    // Store original parent and position for restoration
    const originalParent = block.parentNode;
    const originalNextSibling = block.nextSibling;

    // Create placeholder div in original location
    const movedDiv = document.createElement('div');
    movedDiv.className = 'sidebar-moved';
    movedDiv.setAttribute('data-block', block.id);
    movedDiv.innerHTML = `
      <div class="sidebar-moved-notice">
        <span>📌 Sidebar "${blockTitle}" moved to bottom</span>
        <a href="#${block.id}" class="sidebar-goto-link">Go to →</a>
        <button class="sidebar-undo-btn" data-block="${block.id}">Undo</button>
      </div>
    `;

    // Insert placeholder in original location
    originalParent.insertBefore(movedDiv, block);

    // Expand the sidebar when moving to till
    if (hideWrapper.classList.contains('hide')) {
      toggleSidebar(true);
    }

    // Change stash button to return functionality
    stashButton.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 22v-14"/>
        <path d="m19 15-7-7-7 7"/>
        <path d="M2 3h20"/>
      </svg>
    `;
    stashButton.title = 'Return to original position';

    // Move to till with smooth transition
    block.style.transition = 'all 0.3s ease';
    till.appendChild(block);

    // Undo functionality for placeholder
    const undoButton = movedDiv.querySelector('.sidebar-undo-btn');
    undoButton.addEventListener('click', function (e) {
      e.preventDefault();
      // Move sidebar back to original position
      movedDiv.parentNode.insertBefore(block, movedDiv);
      movedDiv.remove();

      // Reset stash button to original state
      stashButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 2v14"/>
          <path d="m5 9 7 7 7-7"/>
          <path d="M2 21h20"/>
        </svg>
      `;
      stashButton.title = 'Stash to bottom';

      // Restore original stash handler
      stashButton.removeEventListener('click', newStashHandler);
      stashButton.addEventListener('click', originalStashHandler);
    });

    // Store reference to original handler for restoration
    const originalStashHandler = arguments.callee;

    // Update stash button functionality to return (when clicked from till)
    const newStashHandler = function () {
      // Move back to original position and remove placeholder
      movedDiv.parentNode.insertBefore(block, movedDiv);
      movedDiv.remove();

      // Reset stash button to original state
      stashButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 2v14"/>
          <path d="m5 9 7 7 7-7"/>
          <path d="M2 21h20"/>
        </svg>
      `;
      stashButton.title = 'Stash to bottom';

      // Remove the return handler and restore original stash handler
      stashButton.removeEventListener('click', newStashHandler);
      stashButton.addEventListener('click', originalStashHandler);
    };

    // Replace the event listener
    stashButton.removeEventListener('click', arguments.callee);
    stashButton.addEventListener('click', newStashHandler);
  });
}

// If the page contains sidebarblocks with titles, APPEND them to the TOC
// Check for .sidebarblock > .content > .title
// Insert titles with link to .sidebarblock's #id into #id
// - inside uL.sectlevel1
// - after the last LI
// - As <li>Sidebars<ul class="sectlevel2"><li><a href="#sidebar-id">Sidebar Title</a></li></ul></li>
function addSidebarsToToc() {
  const toc = document.getElementById('toc');
  if (!toc) return;

  const sidebarBlocks = document.querySelectorAll('.sidebarblock');
  if (sidebarBlocks.length === 0) return;

  // Create Sidebars section
  const sidebarsLi = document.createElement('li');
  sidebarsLi.className = 'toc-sidebars';
  sidebarsLi.innerHTML = '<span>Sidebars</span>';

  const sidebarsUl = document.createElement('ul');
  sidebarsUl.className = 'sectlevel2';

  sidebarBlocks.forEach(block => {
    const titleElement = block.querySelector('.title');
    if (!titleElement) return;

    const sidebarId = block.id;
    const sidebarTitle = titleElement.textContent || 'Untitled Sidebar';

    const sidebarLi = document.createElement('li');
    const sidebarLink = document.createElement('a');
    sidebarLink.href = `#${sidebarId}`;
    sidebarLink.textContent = sidebarTitle;

    sidebarLi.appendChild(sidebarLink);
    sidebarsUl.appendChild(sidebarLi);
  });

  sidebarsLi.appendChild(sidebarsUl);

  // Append to TOC
  const tocUl = toc.querySelector('ul.sectlevel1');
  if (tocUl) {
    tocUl.appendChild(sidebarsLi);
  }
  
}

// Pin admonition icons to top when icon cell is tall
function initAdmonitionIconPinning() {
  const iconCells = document.querySelectorAll('.admonitionblock td.icon');

  iconCells.forEach(cell => {
    if (cell.offsetHeight > 200) {
      cell.style.verticalAlign = 'top';
      cell.style.paddingTop = '3rem';
    }
  });
}

// IF the document contains div#footnotes-placeholder, move the div#footnotes and its contents to replace div#footnotes-placeholder
function initFootnotesMover() {
  const placeholder = document.querySelector('#footnotes-placeholder');
  if (!placeholder) return;

  const footnotes = document.querySelector('#footnotes');
  if (!footnotes) return;

  // Move the footnotes content to the placeholder
  placeholder.replaceWith(footnotes);

  // Replace #footnotes hr element with h2.title with contents Footnotes
  const hr = footnotes.querySelector('hr');
  if (hr) {
    const title = document.createElement('div');
    title.className = 'title';
    title.textContent = 'Footnotes';
    hr.replaceWith(title);
  }
}

// Top banner functionality
function initTopBanner() {
  const banner = document.getElementById('top-banner');
  const toggle = document.getElementById('banner-toggle');
  const mobileNav = document.getElementById('banner-mobile-nav');
  
  if (!banner) return;
  
  // Banner hiding disabled - banner stays visible at all times
  // window.addEventListener('scroll', function() {
  //   const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  //   const footer = document.querySelector('footer');
  //   
  //   if (footer) {
  //     const footerTop = footer.offsetTop;
  //     const windowBottom = scrollTop + window.innerHeight;
  //     
  //     // Hide banner when footer comes into view
  //     if (windowBottom >= footerTop) {
  //       banner.classList.add('banner-hidden');
  //     } else {
  //       // Keep banner visible until footer reaches viewport
  //       banner.classList.remove('banner-hidden');
  //     }
  //   }
  // });
  
  // Mobile menu toggle
  if (toggle && mobileNav) {
    toggle.addEventListener('click', function() {
      const isOpen = mobileNav.classList.contains('nav-open');
      
      if (isOpen) {
        mobileNav.classList.remove('nav-open');
        toggle.setAttribute('aria-expanded', 'false');
      } else {
        mobileNav.classList.add('nav-open');
        toggle.setAttribute('aria-expanded', 'true');
      }
    });
    
    // Close mobile nav when clicking outside
    document.addEventListener('click', function(event) {
      if (!banner.contains(event.target)) {
        mobileNav.classList.remove('nav-open');
        toggle.setAttribute('aria-expanded', 'false');
      }
    });
  }
}

// Initialize library component popovers
function initLibraryComponentPopovers() {
  const libraryItems = document.querySelectorAll('.project-libraries .library-item');
  
  libraryItems.forEach(item => {
    const descriptionElement = item.querySelector('.library-component-description');
    if (!descriptionElement) return;
    
    // Check if there's actual content in the description
    const descriptionContent = descriptionElement.innerHTML.trim();
    // Be more lenient - check for empty or whitespace-only content, but allow basic HTML
    if (!descriptionContent || descriptionContent === '' || descriptionContent === '<p></p>') {
      console.log('Library item skipped - no content:', item.textContent?.trim());
      return;
    }
    
    console.log('Library item with popover found:', item.textContent?.trim(), 'Content length:', descriptionContent.length);
    
    // Mark this item as having a popover
    item.classList.add('has-popover');
    
    // Create popover element
    const popover = document.createElement('div');
    popover.className = 'library-popover';
    popover.innerHTML = descriptionContent;
    popover.style.display = 'none';
    
    // Add popover to body for absolute positioning
    document.body.appendChild(popover);
    
    // Store reference to popover on the item (using a data attribute to avoid conflicts)
    item.dataset.popoverId = 'popover-' + Math.random().toString(36).substr(2, 9);
    popover.id = item.dataset.popoverId;
    
    // Click handler to toggle popover
    item.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      
      // Hide any other open popovers and remove their open class
      const openItems = document.querySelectorAll('.library-item.popover-open');
      openItems.forEach(openItem => {
        if (openItem !== item) {
          const otherPopover = document.getElementById(openItem.dataset.popoverId);
          if (otherPopover) {
            otherPopover.style.display = 'none';
          }
          openItem.classList.remove('popover-open');
        }
      });
      
      // Toggle this popover
      if (popover.style.display === 'none') {
        showPopover(item, popover);
        item.classList.add('popover-open');
      } else {
        popover.style.display = 'none';
        item.classList.remove('popover-open');
      }
    });
  });
  
  // Click outside to close popover
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.library-popover') && !e.target.closest('.has-popover')) {
      const openItems = document.querySelectorAll('.library-item.popover-open');
      openItems.forEach(item => {
        const popover = document.getElementById(item.dataset.popoverId);
        if (popover) {
          popover.style.display = 'none';
        }
        item.classList.remove('popover-open');
      });
    }
  });
  
  // Close popover on escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const openItems = document.querySelectorAll('.library-item.popover-open');
      openItems.forEach(item => {
        const popover = document.getElementById(item.dataset.popoverId);
        if (popover) {
          popover.style.display = 'none';
        }
        item.classList.remove('popover-open');
      });
    }
  });
}

// Show popover with proper positioning
function showPopover(triggerElement, popover) {
  popover.style.display = 'block';
  
  // Get trigger element position
  const triggerRect = triggerElement.getBoundingClientRect();
  const popoverRect = popover.getBoundingClientRect();
  
  // Calculate position (below the trigger by default)
  let top = triggerRect.bottom + window.scrollY + 8;
  let left = triggerRect.left + window.scrollX;
  
  // Adjust if popover would go off the right edge of screen
  if (left + popoverRect.width > window.innerWidth) {
    left = window.innerWidth - popoverRect.width - 16;
  }
  
  // Adjust if popover would go off the left edge of screen
  if (left < 16) {
    left = 16;
  }
  
  // If there's not enough space below, show above the trigger
  if (top + popoverRect.height > window.innerHeight + window.scrollY) {
    top = triggerRect.top + window.scrollY - popoverRect.height - 8;
  }
  
  // Apply position
  popover.style.position = 'absolute';
  popover.style.top = `${top}px`;
  popover.style.left = `${left}px`;
}

// Docs tabs functionality
function initDocsTabs() {
  const tabContainer = document.querySelector('.docs-tabs');
  if (!tabContainer) return;

  const tabs = tabContainer.querySelectorAll('.docs-tab');
  const panels = document.querySelectorAll('.docs-panel');

  function switchTab(targetTab, targetPanel) {
    // Reset all tabs and panels
    tabs.forEach(tab => {
      tab.setAttribute('aria-selected', 'false');
    });
    panels.forEach(panel => {
      panel.classList.remove('active');
    });

    // Activate target tab and panel
    targetTab.setAttribute('aria-selected', 'true');
    targetPanel.classList.add('active');

    // Store the active tab in session storage
    sessionStorage.setItem('activeDocsTab', targetTab.id);
  }

  // Add click handlers to tabs
  tabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      e.preventDefault();
      const targetPanelId = tab.getAttribute('aria-controls');
      const targetPanel = document.getElementById(targetPanelId);
      if (targetPanel) {
        switchTab(tab, targetPanel);
      }
    });
  });

  // Restore previously active tab from session storage
  const savedTab = sessionStorage.getItem('activeDocsTab');
  if (savedTab) {
    const tabToRestore = document.getElementById(savedTab);
    if (tabToRestore) {
      const targetPanelId = tabToRestore.getAttribute('aria-controls');
      const targetPanel = document.getElementById(targetPanelId);
      if (targetPanel) {
        switchTab(tabToRestore, targetPanel);
      }
    }
  }
}

// Token Swapper functionality
function initTokenSwapper() {
  if (!window.pageTokens) return;

  const contentArea = document.querySelector('.document-body');
  if (!contentArea) return;

  window.pageTokens.forEach(token => {
    token = token.trim();
    const inputId = `token_${token}`;
    const input = document.getElementById(inputId);
    if (!input) return;

    const placeholder = `<$tok.${token}>`;
    const value = input.value;

    // Helper to replace text in a node
    function replaceInNode(node) {
      if (node.nodeType === 3) { // Text node
        if (node.nodeValue.includes(placeholder)) {
          const span = document.createElement('span');
          span.className = 'token-value';
          span.dataset.token = token;
          span.textContent = value;
          
          const parts = node.nodeValue.split(placeholder);
          const fragment = document.createDocumentFragment();
          
          parts.forEach((part, index) => {
            if (part) {
              fragment.appendChild(document.createTextNode(part));
            }
            if (index < parts.length - 1) {
              const s = span.cloneNode(true);
              fragment.appendChild(s);
            }
          });
          
          node.parentNode.replaceChild(fragment, node);
        }
      } else if (node.nodeType === 1) { // Element node
        // Skip script and style tags, and the form itself
        if (node.tagName !== 'SCRIPT' && node.tagName !== 'STYLE' && !node.classList.contains('token-swap-form')) {
           // Convert childNodes to array to handle live collection
           Array.from(node.childNodes).forEach(replaceInNode);
        }
      }
    }

    replaceInNode(contentArea);

    // Add event listener
    input.addEventListener('input', (e) => {
      const newValue = e.target.value;
      const spans = document.querySelectorAll(`.token-value[data-token="${token}"]`);
      spans.forEach(span => {
        span.textContent = newValue;
      });
    });
  });
}

// Ensure init runs after DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
