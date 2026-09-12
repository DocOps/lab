// Scrollspy functionality for document layout
(function() {
  'use strict';

  if (!window.themeConfig || !window.themeConfig.scrollspy) return;

  let toc;
  let headings;
  let tocLinks;

  function init() {
      generateTOC();
      initScrollspy();
  }

  function generateTOC() {
      toc = document.getElementById('toc');
      if (!toc) return;

      // Only select H2-H4 headings, completely ignore H1
      const headings = document.querySelectorAll('.document-content h2, .document-content h3, .document-content h4');
      if (headings.length === 0) return;

      // Store headings for scrollspy (this is used by updateActiveLink)
      window.scrollspyHeadings = headings;

      // Clear existing TOC content
      toc.innerHTML = '';

      const tocList = document.createElement('ul');
      let currentLevel = 2; // Start with h2 as base level
      let stack = [tocList];

      headings.forEach((heading, index) => {
          // Ensure heading has an ID for linking
          if (!heading.id) {
              heading.id = 'heading-' + index;
          }

          const level = parseInt(heading.tagName.charAt(1));
          const text = heading.textContent;

          // Adjust stack based on heading level
          while (currentLevel < level && stack.length > 0) {
              const subList = document.createElement('ul');
              const lastItem = stack[stack.length - 1].lastElementChild;
              if (lastItem) {
                  lastItem.appendChild(subList);
              }
              stack.push(subList);
              currentLevel++;
          }

          while (currentLevel > level && stack.length > 1) {
              stack.pop();
              currentLevel--;
          }

          // Create TOC item
          const listItem = document.createElement('li');
          const link = document.createElement('a');
          link.href = '#' + heading.id;
          link.textContent = text;
          link.className = 'toc-link';
          
          listItem.appendChild(link);
          stack[stack.length - 1].appendChild(listItem);

          currentLevel = level;
      });

      toc.appendChild(tocList);
      tocLinks = toc.querySelectorAll('.toc-link');
  }

  function initScrollspy() {
      if (!tocLinks || tocLinks.length === 0) return;

      let ticking = false;

      function updateActiveLink() {
          const scrollPos = window.scrollY + 100; // Offset for better UX
          let activeHeading = null;

          // Use the headings we stored during TOC generation
          const headingsToCheck = window.scrollspyHeadings || [];

          // Find the currently visible heading
          for (let i = headingsToCheck.length - 1; i >= 0; i--) {
              if (headingsToCheck[i].offsetTop <= scrollPos) {
                  activeHeading = headingsToCheck[i];
                  break;
              }
          }

          // Update active link
          tocLinks.forEach(link => link.classList.remove('active'));
          
          if (activeHeading) {
              const activeLink = toc.querySelector(`a[href="#${activeHeading.id}"]`);
              if (activeLink) {
                  activeLink.classList.add('active');
              }
          }

          ticking = false;
      }

      function requestTick() {
      if (!ticking) {
          requestAnimationFrame(updateActiveLink);
          ticking = true;
      }
      }

      window.addEventListener('scroll', requestTick);
      updateActiveLink(); // Initial call
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
  } else {
      init();
  }

})();
