// @ts-check
// Acceptance tests for docs/specs/001-design-system-v1/spec.md (AC2, AC4–AC9).
import { test, expect } from '@playwright/test';

const SECTION = '/en-US/academics/computer-science-theory/cryptography-theory/';
const WIKI = `${SECTION}wiki/`;
const REFERENCE_PAGES = [
  '/en-US/',
  '/pt-BR/',
  '/en-US/categories/',
  '/en-US/academics/',
  '/en-US/academics/computer-science-theory/',
  SECTION,
  WIKI,
  '/en-US/search/',
  '/this-page-does-not-exist/',
];

test.describe('AC2 identity', () => {
  test('header shows the globe mark, the name and the Better Web attribution', async ({ page }) => {
    await page.goto('/en-US/');
    const banner = page.getByRole('banner');
    await expect(banner.getByRole('link', { name: /Internet Public Library/ }).first()).toBeVisible();
    await expect(banner.locator('[data-ipl-mark]').first()).toBeVisible();
    await expect(banner).toContainText('Better Web');
    await expect(banner.getByText('IP', { exact: true })).toHaveCount(0);
  });

  test('footer uses the same attribution', async ({ page }) => {
    await page.goto('/pt-BR/');
    const footer = page.getByRole('contentinfo');
    await expect(footer).toContainText('Better Web');
    await expect(footer).not.toContainText('Open Digital Brasil');
  });
});

test.describe('AC4 article typography', () => {
  for (const path of [SECTION, WIKI]) {
    test(`${path} reads like an article`, async ({ page, isMobile }) => {
      await page.goto(path);
      await expect(page.locator('h1')).toHaveCount(1);

      const prose = page.locator('.ipl-prose').first();
      await expect(prose).toBeVisible();
      const metrics = await prose.evaluate((element) => {
        const probe = document.createElement('span');
        probe.style.cssText = 'position:absolute;visibility:hidden;width:1ch';
        element.appendChild(probe);
        const ch = probe.getBoundingClientRect().width;
        probe.remove();
        const paragraph = element.querySelector('p');
        const heading = element.querySelector('h2');
        return {
          widthInCh: element.getBoundingClientRect().width / ch,
          bodySize: paragraph ? getComputedStyle(paragraph).fontSize : null,
          headingFont: heading ? getComputedStyle(heading).fontFamily : null,
        };
      });
      expect(metrics.widthInCh).toBeLessThanOrEqual(75);
      expect(metrics.headingFont).toMatch(/Source Serif/);
      if (!isMobile) expect(metrics.bodySize).toBe('18px');
    });
  }
});

test.describe('AC5 content first on mobile', () => {
  test.use({ viewport: { width: 390, height: 844 } });
  for (const path of ['/en-US/academics/', '/en-US/academics/computer-science-theory/', SECTION, WIKI]) {
    test(`${path} shows its title in the first viewport`, async ({ page }) => {
      await page.goto(path);
      const box = await page.locator('h1').boundingBox();
      expect(box).not.toBeNull();
      expect(box.y + box.height).toBeLessThanOrEqual(844);

      const navBeforeTitle = await page.evaluate(() => {
        const title = document.querySelector('h1');
        return [...document.querySelectorAll('main nav:not([aria-label="Breadcrumb"])')].filter(
          (nav) => nav.compareDocumentPosition(title) & Node.DOCUMENT_POSITION_FOLLOWING,
        ).length;
      });
      expect(navBeforeTitle).toBe(0);
    });
  }
});

test.describe('AC6 search', () => {
  test('header search is a labeled GET form available on every viewport', async ({ page }) => {
    await page.goto('/en-US/academics/');
    const search = page.getByRole('banner').getByRole('search');
    const field = search.getByRole('searchbox');
    await expect(field).toBeVisible();
    await expect(field).toHaveAttribute('name', 'q');
    await expect(search.locator('form[method="get"], form:not([method])').first()).toBeAttached();
  });

  test('searching from the home lands on results from the index', async ({ page }) => {
    await page.goto('/en-US/');
    const field = page.getByRole('banner').getByRole('search').getByRole('searchbox');
    await field.fill('crypto');
    await field.press('Enter');
    await expect(page).toHaveURL(/\/en-US\/search\/\?q=crypto/);
    await expect(page.locator('#search-results a').first()).toBeVisible();
  });
});

test.describe('AC7 honest actions', () => {
  test('edit and suggest go to GitHub with page context', async ({ page }) => {
    await page.goto(SECTION);
    for (const name of [/^edit/i, /suggest a resource/i]) {
      const link = page.getByRole('link', { name }).first();
      await expect(link).toHaveAttribute('href', /^https:\/\/github\.com\/InternetPublicLibrary\/.*cryptography/i);
    }
  });

  test('shell offers no account actions', async ({ page }) => {
    await page.goto('/en-US/');
    await expect(page.getByRole('link', { name: /log in|sign up|create account/i })).toHaveCount(0);
  });
});

test.describe('AC8 appearance', () => {
  test('dark choice persists across reloads', async ({ page }) => {
    await page.goto('/en-US/');
    await page.getByRole('button', { name: /appearance/i }).click();
    await page.getByRole('menuitemradio', { name: /dark/i }).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    const background = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    expect(background).toBe('rgb(21, 28, 34)');
  });

  test('theme is resolved by the first script in <head>, before styles paint', async ({ page }) => {
    await page.goto('/en-US/');
    const first = await page.evaluate(() => {
      const script = document.head.querySelector('script');
      return script ? { inline: !script.src, text: script.textContent || '' } : null;
    });
    expect(first?.inline).toBe(true);
    expect(first?.text).toContain('data-theme');
  });
});

test.describe('AC9 keyboard, reflow and motion', () => {
  test('skip link is the first focusable element', async ({ page, isMobile }) => {
    test.skip(isMobile, 'keyboard path checked on desktop');
    await page.goto('/en-US/');
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toHaveText(/skip to (main )?content/i);
  });

  test('every disclosure button exposes aria-expanded', async ({ page }) => {
    await page.goto(SECTION);
    const missing = await page.$$eval('button[aria-controls]', (buttons) =>
      buttons.filter((button) => !button.hasAttribute('aria-expanded')).map((button) => button.outerHTML.slice(0, 80)),
    );
    expect(missing).toEqual([]);
  });

  test('no horizontal scroll at 320px', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 720 });
    for (const path of REFERENCE_PAGES) {
      await page.goto(path);
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
      expect(overflow, path).toBeLessThanOrEqual(0);
    }
  });

  test('reduced motion disables animations and transitions', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto('/en-US/');
    const moving = await page.evaluate(() =>
      [...document.querySelectorAll('body *')].filter((element) => {
        const style = getComputedStyle(element);
        const animated = style.animationName !== 'none' && parseFloat(style.animationDuration) > 0.01;
        const transitioned = style.transitionDuration.split(',').some((value) => parseFloat(value) > 0.01);
        return animated || transitioned;
      }).length,
    );
    expect(moving).toBe(0);
  });
});
