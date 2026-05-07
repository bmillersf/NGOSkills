/**
 * Publish an EmbeddedServiceConfig (MIAW deployment) by direct ID.
 *
 * Why this exists:
 *   - There is no public Connect API or sObject method to publish/republish an ESC.
 *   - The metadata-format <EmbeddedServiceConfig>.<isEnabled> deploy does not flip the
 *     "Published" state used by the live runtime config endpoint
 *     (`/embeddedservice/v1/embedded-service-config`). That endpoint snapshots the wiring
 *     at the moment of UI publish, so if you change MessagingChannel.SessionHandlerId,
 *     change branding, change auth mode, or wire to a new bot, you MUST re-publish via
 *     the Setup UI for changes to take effect on the live site.
 *   - The Setup list page filters on label, so navigating directly by ID is the only
 *     reliable way to drive Publish on a freshly-created ESC that the operator has not
 *     yet bookmarked.
 *
 * Usage:
 *   TARGET_ORG=<alias> ESC_ID=<04I...> npx playwright test publish-esc.spec.ts
 *   # OR
 *   TARGET_ORG=<alias> ESC_DEV_NAME=<name> npx playwright test publish-esc.spec.ts
 */
import { test, expect, Page } from '@playwright/test';
const { execFileSync } = require('child_process');

const TARGET_ORG = process.env.TARGET_ORG || 'finca';
const ESC_ID_ENV = process.env.ESC_ID;
const ESC_DEV_NAME = process.env.ESC_DEV_NAME;

function sfCli(args: string[]): any {
  const out = execFileSync('sf', args, {
    encoding: 'utf8', env: { ...process.env, NO_COLOR: '1', SF_LOG_LEVEL: 'error' },
  });
  const cleaned = out.replace(/\[[0-9;]*m/g, '');
  return JSON.parse(cleaned.slice(cleaned.indexOf('{')));
}

function resolveEscId(): string {
  if (ESC_ID_ENV) return ESC_ID_ENV;
  if (!ESC_DEV_NAME) throw new Error('Set ESC_ID or ESC_DEV_NAME');
  const r = sfCli(['data', 'query', '--target-org', TARGET_ORG, '--use-tooling-api',
    '--query', `SELECT Id FROM EmbeddedServiceConfig WHERE DeveloperName='${ESC_DEV_NAME}'`,
    '--json']);
  const id = r.result.records[0]?.Id;
  if (!id) throw new Error(`No EmbeddedServiceConfig with DeveloperName=${ESC_DEV_NAME}`);
  return id;
}

async function loginViaFrontdoor(page: Page, instanceUrl: string, sid: string) {
  await page.goto(`${instanceUrl}/secur/frontdoor.jsp?sid=${encodeURIComponent(sid)}`,
    { waitUntil: 'load', timeout: 60000 });
  await page.waitForURL(/lightning|\/setup\//, { timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(4000);
}

test('publish EmbeddedServiceConfig by ID', async ({ browser }) => {
  test.setTimeout(180_000);
  const escId = resolveEscId();
  const { accessToken, instanceUrl } = sfCli(['org', 'display', '--target-org', TARGET_ORG, '--json']).result;

  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  await loginViaFrontdoor(page, instanceUrl, accessToken);

  const detailUrl = `${instanceUrl}/lightning/setup/EmbeddedServiceDeployments/${escId}/view`;
  console.log('Opening:', detailUrl);
  await page.goto(detailUrl, { waitUntil: 'load', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.screenshot({ path: `/tmp/publish-esc-${escId}.png`, fullPage: true });

  // Click Publish in any frame
  let published = false;
  for (const f of page.frames()) {
    try {
      const btn = f.locator('button, a[role="button"], input[type="button"], input[type="submit"]')
        .filter({ hasText: /^Publish$/i });
      if (await btn.count() > 0) {
        await btn.first().click();
        await page.waitForTimeout(4000);
        // Some orgs render a confirm dialog
        const confirm = f.getByRole('button', { name: /^Publish$/i });
        if (await confirm.count() > 1) {
          await confirm.last().click();
          await page.waitForTimeout(2000);
        }
        published = true;
        break;
      }
    } catch {}
  }
  await page.waitForTimeout(8000);
  await page.screenshot({ path: `/tmp/publish-esc-${escId}-after.png`, fullPage: true });
  expect(published, 'Publish button not found on ESC detail page').toBe(true);
});
