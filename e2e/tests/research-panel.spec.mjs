// @ts-check
// Research panel: organized tabs, on-demand loading, safe rendering of third-party data.
import { test, expect } from '@playwright/test';

const PAGE = '/pt-BR/academicos/teoria-da-computacao/';

async function openPapers(page) {
  await page.goto(PAGE);
  const panel = page.locator('[data-research-panel]');
  await panel.scrollIntoViewIfNeeded();
  await page.getByRole('tab', { name: 'Artigos' }).click();
  return panel;
}

test('queries use the menu title, and English sources get the English title', async ({ page }) => {
  await page.goto(PAGE);
  const panel = page.locator('[data-research-panel]');
  await expect(panel).toHaveAttribute('data-query', 'Teoria da Computação');
  await expect(panel).toHaveAttribute('data-query-en', 'Computer Science Theory');
  await expect(page).toHaveTitle(/^Teoria da Computação/);
});

test('tabs follow the WAI-ARIA keyboard pattern', async ({ page }) => {
  await page.goto(PAGE);
  const first = page.getByRole('tab', { name: 'Visão geral' });
  await first.focus();
  await page.keyboard.press('ArrowRight');
  const papers = page.getByRole('tab', { name: 'Artigos' });
  await expect(papers).toBeFocused();
  await expect(papers).toHaveAttribute('aria-selected', 'true');
  await expect(page.locator('#research-panel-papers')).toBeVisible();
  await expect(page.locator('#research-panel-overview')).toBeHidden();
});

test('a source is only requested when its tab is opened', async ({ page }) => {
  const requested = [];
  page.on('request', (request) => {
    if (request.url().includes('api.openalex.org')) requested.push(request.url());
  });
  await page.goto(PAGE);
  await page.locator('[data-research-panel]').scrollIntoViewIfNeeded();
  await page.waitForTimeout(500);
  expect(requested).toEqual([]);
  await page.getByRole('tab', { name: 'Artigos' }).click();
  await expect.poll(() => requested.length).toBeGreaterThan(0);
  expect(requested[0]).toContain('Computer%20Science%20Theory');
});

test('third-party titles are rendered as text, never as markup', async ({ page }) => {
  let executed = false;
  await page.exposeFunction('pwned', () => { executed = true; });
  await page.route('https://api.openalex.org/**', (route) => route.fulfill({
    json: { results: [{
      title: '<img src=x onerror="window.pwned()">Evil paper',
      authorships: [{ author: { display_name: '<b>Mallory</b>' } }],
      publication_year: 2024,
      primary_location: { source: { display_name: 'Venue' } },
      doi: 'javascript:window.pwned()',
      open_access: {},
    }] },
  }));
  const panel = await openPapers(page);
  await expect(panel.getByText('<img src=x onerror="window.pwned()">Evil paper')).toBeVisible();
  await expect(panel.locator('#openalex-results-list img, #openalex-results-list b')).toHaveCount(0);
  await expect(panel.locator('#openalex-results-list a[href^="javascript:"]')).toHaveCount(0);
  expect(executed).toBe(false);
});

test('an unavailable source says so and offers a retry', async ({ page }) => {
  await page.route('https://api.openalex.org/**', (route) => route.fulfill({ status: 429, json: { error: 'Rate limit exceeded' } }));
  const panel = await openPapers(page);
  await expect(panel.getByText(/indisponível no momento/)).toBeVisible();
  await expect(panel.getByRole('button', { name: 'Tentar novamente' })).toBeVisible();
  await expect(panel.getByRole('link', { name: 'Pesquisar no openalex.org' })).toHaveAttribute('href', /^https:\/\/openalex\.org\//);
});
