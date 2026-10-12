// @ts-check
import { test, expect } from '@playwright/test';

// Spec 006: progress per step is kept in the reader's browser and announced; steps work as <details>.
test('learning path progress persists across reloads and is announced', async ({ page }) => {
  await page.goto('/en-US/learning-paths/frontend/');
  const steps = page.locator('.learning-path-step');
  const total = await steps.count();
  expect(total).toBeGreaterThan(5);

  const bar = page.getByRole('progressbar');
  await expect(bar).toHaveAttribute('aria-valuenow', '0');

  // Only the next unfinished step is open with JavaScript.
  await expect(page.locator('.learning-path-step details[open]')).toHaveCount(1);

  const first = steps.first();
  await first.getByRole('checkbox', { name: 'I finished this step' }).check();
  await expect(bar).toHaveAttribute('aria-valuenow', '1');
  await expect(page.getByRole('status')).toContainText(`1 / ${total}`);

  await page.reload();
  await expect(page.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '1');
  // A finished step is collapsed, so read its checkbox directly.
  await expect(page.locator('.learning-path-step').first().locator('input[type="checkbox"]')).toBeChecked();
  // After a reload the second step is the next one to open.
  await expect(page.locator('.learning-path-step').nth(1).locator('details')).toHaveAttribute('open', '');
});

test('learning path is readable without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  await page.goto('/pt-BR/learning-paths/python/');
  const open = page.locator('.learning-path-step details[open]');
  expect(await open.count()).toBe(await page.locator('.learning-path-step').count());
  await expect(page.locator('.learning-path-step a[href^="https://"]').first()).toBeVisible();
  await context.close();
});
