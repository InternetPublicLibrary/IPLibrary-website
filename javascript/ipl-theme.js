/*
 * Dark mode toggle — spec 001 AC8. Light is the default; dark applies only by explicit choice.
 * The inline snippet in head.html applies a stored choice before first paint; this file wires the toggle.
 *
 * Markup contract: <button type="button" data-ipl-theme-toggle aria-pressed="false">Dark mode</button>
 * The label stays fixed; aria-pressed carries the on/off state (WAI-ARIA toggle button pattern).
 * Fires `ipl:themechange` on document with detail { theme } so embeds (discussion) can follow.
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'ipl-theme';

  function current() {
    return document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
  }

  function apply(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (error) { /* storage unavailable: the choice lasts for this page only */ }
    document.dispatchEvent(new CustomEvent('ipl:themechange', { detail: { theme: theme } }));
  }

  function sync(toggles) {
    var dark = current() === 'dark';
    toggles.forEach(function (toggle) { toggle.setAttribute('aria-pressed', String(dark)); });
  }

  function init() {
    var toggles = Array.prototype.slice.call(document.querySelectorAll('[data-ipl-theme-toggle]'));
    toggles.forEach(function (toggle) {
      toggle.addEventListener('click', function () {
        apply(current() === 'dark' ? 'light' : 'dark');
        sync(toggles);
      });
    });
    sync(toggles);
  }

  window.IPLTheme = { current: current };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
