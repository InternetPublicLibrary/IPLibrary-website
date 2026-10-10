/*
 * Appearance control (System / Light / Dark) — spec 001 AC8.
 * The inline snippet in head.html applies a stored choice before first paint; this file wires the control.
 *
 * Markup contract (rendered by the shell, slice S2):
 *   <div data-ipl-appearance>
 *     <button type="button" aria-haspopup="menu" aria-expanded="false" aria-controls="ipl-appearance-menu"
 *             data-ipl-appearance-toggle>…<span class="ipl-visually-hidden">Appearance</span></button>
 *     <ul id="ipl-appearance-menu" role="menu" hidden>
 *       <li role="none"><button type="button" role="menuitemradio" aria-checked="false" data-theme-value="system">System</button></li>
 *       <li role="none"><button type="button" role="menuitemradio" aria-checked="false" data-theme-value="light">Light</button></li>
 *       <li role="none"><button type="button" role="menuitemradio" aria-checked="false" data-theme-value="dark">Dark</button></li>
 *     </ul>
 *   </div>
 *
 * Fires `ipl:themechange` on document with detail { choice, theme } so embeds (discussion) can follow.
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'ipl-theme';
  var CHOICES = ['system', 'light', 'dark'];
  var systemDark = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function readChoice() {
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      return CHOICES.indexOf(stored) > -1 ? stored : 'system';
    } catch (error) {
      return 'system';
    }
  }

  function effectiveTheme(choice) {
    if (choice === 'light' || choice === 'dark') return choice;
    return systemDark && systemDark.matches ? 'dark' : 'light';
  }

  function apply(choice) {
    var root = document.documentElement;
    if (choice === 'system') root.removeAttribute('data-theme');
    else root.setAttribute('data-theme', choice);
    try {
      if (choice === 'system') localStorage.removeItem(STORAGE_KEY);
      else localStorage.setItem(STORAGE_KEY, choice);
    } catch (error) { /* storage unavailable: the choice lasts for this page only */ }
    document.dispatchEvent(new CustomEvent('ipl:themechange', {
      detail: { choice: choice, theme: effectiveTheme(choice) },
    }));
  }

  function setup(control) {
    var toggle = control.querySelector('[data-ipl-appearance-toggle]');
    var menu = document.getElementById(toggle && toggle.getAttribute('aria-controls'));
    if (!toggle || !menu) return;
    var items = Array.prototype.slice.call(menu.querySelectorAll('[role="menuitemradio"]'));

    function sync(choice) {
      items.forEach(function (item) {
        item.setAttribute('aria-checked', String(item.getAttribute('data-theme-value') === choice));
      });
    }

    function open(focusIndex) {
      menu.hidden = false;
      toggle.setAttribute('aria-expanded', 'true');
      var checked = items.findIndex(function (item) { return item.getAttribute('aria-checked') === 'true'; });
      var index = typeof focusIndex === 'number' ? focusIndex : Math.max(checked, 0);
      items[(index + items.length) % items.length].focus();
    }

    function close(returnFocus) {
      menu.hidden = true;
      toggle.setAttribute('aria-expanded', 'false');
      if (returnFocus) toggle.focus();
    }

    toggle.addEventListener('click', function () {
      if (menu.hidden) open(); else close(false);
    });

    toggle.addEventListener('keydown', function (event) {
      if (event.key === 'ArrowDown') { event.preventDefault(); open(); }
      if (event.key === 'ArrowUp') { event.preventDefault(); open(items.length - 1); }
    });

    menu.addEventListener('keydown', function (event) {
      var index = items.indexOf(document.activeElement);
      if (event.key === 'ArrowDown') { event.preventDefault(); items[(index + 1) % items.length].focus(); }
      else if (event.key === 'ArrowUp') { event.preventDefault(); items[(index - 1 + items.length) % items.length].focus(); }
      else if (event.key === 'Home') { event.preventDefault(); items[0].focus(); }
      else if (event.key === 'End') { event.preventDefault(); items[items.length - 1].focus(); }
      else if (event.key === 'Escape') { event.preventDefault(); close(true); }
      else if (event.key === 'Tab') { close(false); }
    });

    items.forEach(function (item) {
      item.addEventListener('click', function () {
        var choice = item.getAttribute('data-theme-value');
        apply(choice);
        sync(choice);
        close(true);
      });
    });

    document.addEventListener('click', function (event) {
      if (!menu.hidden && !control.contains(event.target)) close(false);
    });

    sync(readChoice());
  }

  function init() {
    Array.prototype.forEach.call(document.querySelectorAll('[data-ipl-appearance]'), setup);
    if (systemDark && systemDark.addEventListener) {
      systemDark.addEventListener('change', function () {
        if (readChoice() === 'system') {
          document.dispatchEvent(new CustomEvent('ipl:themechange', {
            detail: { choice: 'system', theme: effectiveTheme('system') },
          }));
        }
      });
    }
  }

  window.IPLTheme = { current: function () { return effectiveTheme(readChoice()); } };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
