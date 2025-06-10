document.addEventListener('DOMContentLoaded', function() {
  // Mobile menu toggle
  const menuToggle = document.getElementById('menu-toggle');
  if (menuToggle) {
    menuToggle.addEventListener('click', function() {
      const mobileMenu = document.getElementById('mobile-menu');
      mobileMenu.classList.toggle('hidden');
    });
  }

  // Category sidebar toggle
  const categoryHeaders = document.querySelectorAll('.category-header');
  categoryHeaders.forEach(header => {
    header.addEventListener('click', function() {
      const categoryItem = this.closest('.category-item');
      const subcategoryList = categoryItem.querySelector('.subcategory-list');
      const icon = this.querySelector('i');
      
      if (subcategoryList) {
        subcategoryList.classList.toggle('hidden');
        icon.classList.toggle('transform');
        icon.classList.toggle('rotate-180');
      }
    });
  });
  
  // Search functionality for category sidebar
  const searchInput = document.getElementById('category-search');
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const searchValue = this.value.toLowerCase();
      const categoryItems = document.querySelectorAll('.category-item');
      
      categoryItems.forEach(item => {
        const categoryName = item.querySelector('.category-header span').textContent.toLowerCase();
        const subcategoryItems = item.querySelectorAll('.subcategory-item');
        
        let matchFound = categoryName.includes(searchValue);
        
        // Also check subcategories
        subcategoryItems.forEach(subItem => {
          const subcategoryName = subItem.querySelector('a').textContent.toLowerCase();
          if (subcategoryName.includes(searchValue)) {
            matchFound = true;
            subItem.style.display = 'block';
          } else {
            subItem.style.display = searchValue ? 'none' : 'block';
          }
        });
        
        item.style.display = matchFound ? 'block' : 'none';
        
        // Show subcategories if there's a search query
        if (matchFound && searchValue && item.querySelector('.subcategory-list')) {
          item.querySelector('.subcategory-list').classList.remove('hidden');
        }
      });
    });
  }
}); 