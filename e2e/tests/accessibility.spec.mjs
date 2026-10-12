// @ts-check
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Representative page of every layout, in both languages.
const PAGES = [
  ['home', '/en-US/'],
  ['home pt-BR', '/pt-BR/'],
  ['categories', '/en-US/categories/'],
  ['category', '/en-US/academics/'],
  ['subcategory', '/en-US/academics/computer-science-theory/'],
  ['section', '/en-US/academics/computer-science-theory/cryptography-theory/'],
  ['wiki', '/en-US/academics/computer-science-theory/cryptography-theory/wiki/'],
  ['search', '/en-US/search/'],
  ['learning paths', '/en-US/learning-paths/'],
  ['learning path pt-BR', '/pt-BR/learning-paths/frontend/'],
  ['not found', '/this-page-does-not-exist/'],
];

const BLOCKING = ['serious', 'critical'];

for (const scheme of ['light', 'dark']) for (const [name, path] of PAGES) {
  test(`${name} (${scheme}) has no serious or critical WCAG 2.2 AA violations`, async ({ page }, testInfo) => {
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto(path);
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();

    await testInfo.attach('axe-results', {
      body: JSON.stringify(results.violations, null, 2),
      contentType: 'application/json',
    });

    const blocking = results.violations
      .filter((violation) => BLOCKING.includes(violation.impact ?? ''))
      .map((violation) => `${violation.impact} ${violation.id} (${violation.nodes.length}x): ${violation.help}`);
    expect(blocking).toEqual([]);
  });
}
