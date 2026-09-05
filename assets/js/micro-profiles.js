// Micro profile expansion functionality
// This handles click-to-expand for all micro profiles across the site

document.addEventListener('DOMContentLoaded', function() {
  // Initialize micro profile expansion functionality
  function initMicroProfiles() {
    document.querySelectorAll('.project-micro').forEach(function(microProfile) {
      // Remove any existing listeners to prevent duplicates
      microProfile.removeEventListener('click', handleMicroProfileClick);
      
      // Add click listener
      microProfile.addEventListener('click', handleMicroProfileClick);
    });
  }
  
  function handleMicroProfileClick(e) {
    // Don't expand if clicking on a link
    if (e.target.closest('a')) return;
    
    // Toggle expanded state
    this.classList.toggle('expanded');
  }
  
  // Initialize on page load
  initMicroProfiles();
  
  // Re-initialize if content is dynamically loaded
  // This is useful for SPA-style navigation or AJAX content
  if (window.MutationObserver) {
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.addedNodes.length > 0) {
          // Check if any added nodes contain micro profiles
          const addedNodes = Array.from(mutation.addedNodes);
          const hasMicroProfiles = addedNodes.some(node => 
            node.nodeType === 1 && (
              node.classList && node.classList.contains('project-micro') ||
              node.querySelector && node.querySelector('.project-micro')
            )
          );
          
          if (hasMicroProfiles) {
            initMicroProfiles();
          }
        }
      });
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
});
