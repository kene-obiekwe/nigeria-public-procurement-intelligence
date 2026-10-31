// Old dashboard links pointed at the site root (/#suppliers, /#competition?method=…). The dashboard now lives at
// dashboard.html, so a dashboard page hash on the landing page forwards there with the same hash, before the page
// paints (classic script in <head>). The list is the page IDs of js/text.js PAGES; check_web_data.py checks they agree.
(function () {
  var PAGES = ['overview', 'suppliers', 'competition', 'budget', 'timing', 'entities', 'implementation', 'data-quality'];
  function forward() {
    var id = location.hash.replace(/^#/, '').split('?')[0];
    if (PAGES.indexOf(id) !== -1) location.replace('dashboard.html' + location.hash);
  }
  forward();
  window.addEventListener('hashchange', forward);
}());
