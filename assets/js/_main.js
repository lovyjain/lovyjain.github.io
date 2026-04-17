document.addEventListener('DOMContentLoaded', function() {
  var toggles = document.querySelectorAll('.menu-toggle');
  toggles.forEach(function(toggle) {
    toggle.addEventListener('click', function() {
      var menu = document.querySelector('.menu');
      if (menu) {
        menu.classList.toggle('open');
      }
    });
  });
});
