// Applies the saved light/dark choice before the page paints (classic script, so it runs before the modules).
(function () {
  try {
    var saved = localStorage.getItem('theme');
    if (saved === 'light' || saved === 'dark') document.documentElement.setAttribute('data-theme', saved);
  } catch (e) { /* storage unavailable: follow the system setting */ }
}());
