// @ts-check
import { test, expect } from '@playwright/test';

test.describe('language entry point', () => {
  test('redirects English browsers to the en-US home', async ({ browser }) => {
    const context = await browser.newContext({ locale: 'en-US' });
    const page = await context.newPage();
    await page.goto('/');
    await expect(page).toHaveURL(/\/en-US\/$/);
    await context.close();
  });

  test('redirects Portuguese browsers to the pt-BR home', async ({ browser }) => {
    const context = await browser.newContext({ locale: 'pt-BR' });
    const page = await context.newPage();
    await page.goto('/');
    await expect(page).toHaveURL(/\/pt-BR\/$/);
    await context.close();
  });
});

test.describe('generated category pages', () => {
  test('subcategory page is served at its directory URL', async ({ page }) => {
    const response = await page.goto('/en-US/academics/computer-science-theory/');
    expect(response?.status()).toBe(200);
    await expect(page.locator('h1')).toHaveText('Computer Science Theory');
  });

  test('keywords cloud links to the search page', async ({ page }) => {
    await page.goto('/en-US/academics/computer-science-theory/');
    const keyword = page.locator('#keywords-cloud a').first();
    await expect(keyword).toHaveAttribute('href', /^\/en-US\/search\/\?q=/);
  });

  test('section page opens its generated wiki', async ({ page }) => {
    await page.goto('/en-US/academics/computer-science-theory/cryptography-theory/');
    await page.getByRole('link', { name: 'Read Full Wiki' }).click();
    await expect(page).toHaveURL(/\/cryptography-theory\/wiki\/$/);
    await expect(page.getByRole('heading', { level: 1 }).first()).toBeVisible();
  });

  test('wiki back link returns to its section', async ({ page }) => {
    await page.goto('/pt-BR/negocios/financas/trading/wiki/');
    const backLink = page.locator('a[href="/pt-BR/negocios/financas/trading/"]').first();
    await expect(backLink).toBeAttached();
    const response = await page.request.get('/pt-BR/negocios/financas/trading/');
    expect(response.status()).toBe(200);
  });
});

test.describe('language switcher', () => {
  test('falls back to the pt-BR home when the page has no translation at the same path', async ({ page, isMobile }) => {
    test.skip(isMobile, 'switcher button is part of the desktop header');
    await page.goto('/en-US/academics/computer-science-theory/');
    await page.locator('#lang-switcher-btn').click();
    await page.locator('#lang-options').getByRole('link', { name: /Português/ }).click();
    await expect(page).toHaveURL(/\/pt-BR\/$/);
  });

  test('404 page offers working language links', async ({ page }) => {
    await page.goto('/this-page-does-not-exist/');
    for (const href of ['/en-US/', '/pt-BR/']) {
      await expect(page.locator(`#lang-options a[href="${href}"]`)).toBeAttached();
    }
  });
});

test.describe('pt-BR header links', () => {
  for (const path of ['/pt-BR/random-resource/', '/pt-BR/categorias/', '/pt-BR/contribuir/']) {
    test(`${path} is linked and reachable`, async ({ page }) => {
      await page.goto('/pt-BR/');
      await expect(page.locator(`a[href="${path}"]`).first()).toBeAttached();
      const response = await page.request.get(path);
      expect(response.status()).toBe(200);
    });
  }
});

test('home page loads without uncaught script errors', async ({ page }) => {
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto('/en-US/');
  await page.waitForLoadState('networkidle');
  expect(errors).toEqual([]);
});
