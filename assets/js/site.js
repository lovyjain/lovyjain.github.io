(() => {
  const button = document.querySelector('.menu-toggle');
  const menu = document.querySelector('.menu');
  if (button && menu) {
    button.addEventListener('click', () => {
      const expanded = button.getAttribute('aria-expanded') === 'true';
      button.setAttribute('aria-expanded', String(!expanded));
      menu.classList.toggle('open');
    });
  }

  const year = document.getElementById('year');
  if (year) year.textContent = new Date().getFullYear();
})();
