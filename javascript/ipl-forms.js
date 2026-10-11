/*
 * GitHub issue forms — IPL has no backend, so contribution and contact forms open a prefilled issue
 * on GitHub (spec 001: honest actions). Without JavaScript the form still submits as GET to the issue page.
 *
 * Markup contract:
 *   <form data-ipl-issue-form data-repo="InternetPublicLibrary/pt-BR" data-title-prefix="Sugestão de recurso: "
 *         action="https://github.com/InternetPublicLibrary/pt-BR/issues/new" method="get">
 *     <input data-issue-title …>                 value appended to the title prefix
 *     <input data-issue-field="Categoria" …>     each becomes "**Categoria:** value" in the body
 *     <input type="hidden" name="title"><input type="hidden" name="body">
 *   </form>
 */
(function () {
  'use strict';

  function value(field) {
    if (field.type === 'checkbox') return field.checked ? '✓' : '';
    if (field.tagName === 'SELECT') {
      var option = field.options[field.selectedIndex];
      return option && option.value !== '' ? option.text.trim() : '';
    }
    return field.value.trim();
  }

  function setup(form) {
    form.addEventListener('submit', function () {
      var titleField = form.querySelector('[data-issue-title]');
      var title = (form.getAttribute('data-title-prefix') || '') + (titleField ? value(titleField) : '');
      var lines = [];
      Array.prototype.forEach.call(form.querySelectorAll('[data-issue-field]'), function (field) {
        var text = value(field);
        if (text) lines.push('**' + field.getAttribute('data-issue-field') + ':** ' + text);
      });
      lines.push('', '_' + location.href + '_');
      // Query the hidden inputs explicitly: form.elements.title may resolve to a field with id="title".
      form.querySelector('input[type="hidden"][name="title"]').value = title.trim();
      form.querySelector('input[type="hidden"][name="body"]').value = lines.join('\n');
    });
  }

  function init() {
    Array.prototype.forEach.call(document.querySelectorAll('[data-ipl-issue-form]'), setup);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
