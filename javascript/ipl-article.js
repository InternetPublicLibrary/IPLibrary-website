/* Progressive article contents: native fragment links, no scrolling overrides. */
(() => {
  const article = document.querySelector('[data-ipl-article]');
  if (!article) return;
  // Discussion tabs disclose panels; keep their expanded state in sync with selection.
  article.querySelectorAll('button[role="tab"][aria-controls]').forEach((tab) => {
    const reflectPanel = () => tab.setAttribute('aria-expanded', String(tab.getAttribute('aria-selected') === 'true'));
    reflectPanel();
    new MutationObserver(reflectPanel).observe(tab, { attributes: true, attributeFilter: ['aria-selected'] });
  });
  const headings = [...article.querySelectorAll('.ipl-prose h2')];
  const usedIds = new Set([...document.querySelectorAll('[id]')].map((element) => element.id));
  headings.forEach((heading, index) => {
    if (heading.id) return;
    let id = `article-section-${index + 1}`;
    while (usedIds.has(id)) id += '-heading';
    heading.id = id;
    usedIds.add(id);
  });
  document.querySelectorAll('[data-article-contents]').forEach((list) => {
    const items = headings.map((heading) => {
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = `#${heading.id}`;
      link.className = 'text-blue-600 hover:underline';
      link.textContent = heading.textContent;
      item.append(link);
      return item;
    });
    const discussion = document.getElementById('discussion');
    if (discussion && !headings.some((heading) => discussion.contains(heading))) {
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = '#discussion';
      link.className = 'text-blue-600 hover:underline';
      link.textContent = document.documentElement.lang === 'pt-BR' ? 'Discussão' : 'Discussion';
      item.append(link);
      const relatedIndex = headings.findIndex((heading) => heading.id === 'related');
      items.splice(relatedIndex < 0 ? items.length : relatedIndex, 0, item);
    }
    if (items.length) list.replaceChildren(...items);
  });
})();
