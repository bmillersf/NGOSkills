/**
 * Activate an Agentforce ServiceAgent / EinsteinServiceAgent BotDefinition.
 *
 * Why this exists:
 *   ServiceAgent activation is UI-only in Salesforce as of API v66.
 *   - BotVersion.Status is read-only via REST/Tooling sObject PATCH (returns INVALID_FIELD_FOR_INSERT_UPDATE).
 *   - There is no `<status>` element in the Bot or BotVersion source-format metadata.
 *   - The Connect API endpoints `/connect/einstein-bot/...` and `/connect/copilots/...` return 404.
 *   - The Setup `/lightning/setup/EinsteinCopilot/<botId>/edit` URL just routes back to the Setup home;
 *     the actual Builder lives at the Lightning app `/AiCopilot/copilotStudio.app#/copilot/builder`,
 *     which is opened by clicking "Open in Builder" from the agent detail page.
 *   - The Builder's Activate button surfaces a "Configuration Issues Detected" modal that needs
 *     the "Ignore & Activate" confirmation. Without that confirm click, activation never starts.
 *
 * Usage:
 *   TARGET_ORG=<alias> BOT_DEV_NAME=<DeveloperName> npx playwright test scripts/activate-service-agent.spec.ts
 *
 * Optional:
 *   IGNORE_AND_ACTIVATE=false   -> click "Review Activation Checklist" instead (default: true)
 *   ACTIVATION_TIMEOUT_MS=180000
 *
 * Returns: exit 0 on Active, exit 1 otherwise.
 */
import { test, expect, Page, Frame } from '@playwright/test';
const { execFileSync } = require('child_process');

const TARGET_ORG = process.env.TARGET_ORG || 'finca';
const BOT_DEV_NAME = process.env.BOT_DEV_NAME || (() => {
  throw new Error('Set BOT_DEV_NAME env var to the BotDefinition.DeveloperName to activate.');
})();
const IGNORE_AND_ACTIVATE = process.env.IGNORE_AND_ACTIVATE !== 'false';
const ACTIVATION_TIMEOUT_MS = parseInt(process.env.ACTIVATION_TIMEOUT_MS || '180000', 10);

function sfCli(args: string[]): any {
  const out = execFileSync('sf', args, {
    encoding: 'utf8', env: { ...process.env, NO_COLOR: '1', SF_LOG_LEVEL: 'error' },
  });
  const cleaned = out.replace(/\[[0-9;]*m/g, '');
  return JSON.parse(cleaned.slice(cleaned.indexOf('{')));
}

function getOrg() {
  return sfCli(['org', 'display', '--target-org', TARGET_ORG, '--json']).result;
}

function lookupBotId(): { botId: string; botVersionId: string; botLabel: string } {
  const def = sfCli(['data', 'query', '--target-org', TARGET_ORG,
    '--query', `SELECT Id, MasterLabel FROM BotDefinition WHERE DeveloperName='${BOT_DEV_NAME}'`,
    '--json']).result.records[0];
  if (!def) throw new Error(`No BotDefinition with DeveloperName=${BOT_DEV_NAME}`);
  const ver = sfCli(['data', 'query', '--target-org', TARGET_ORG,
    '--query', `SELECT Id, Status FROM BotVersion WHERE BotDefinitionId='${def.Id}' ORDER BY VersionNumber DESC LIMIT 1`,
    '--json']).result.records[0];
  if (!ver) throw new Error(`No BotVersion for ${BOT_DEV_NAME}`);
  return { botId: def.Id, botVersionId: ver.Id, botLabel: def.MasterLabel };
}

function botStatus(botId: string): string {
  const r = sfCli(['data', 'query', '--target-org', TARGET_ORG,
    '--query', `SELECT Status FROM BotVersion WHERE BotDefinitionId='${botId}' ORDER BY VersionNumber DESC LIMIT 1`,
    '--json']);
  return r.result.records[0]?.Status || 'Unknown';
}

async function loginViaFrontdoor(page: Page, instanceUrl: string, sid: string) {
  await page.goto(`${instanceUrl}/secur/frontdoor.jsp?sid=${encodeURIComponent(sid)}`,
    { waitUntil: 'load', timeout: 60000 });
  await page.waitForURL(/lightning|\/setup\//, { timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(4000);
}

// Walks main DOM + open shadow roots — clicks the first matching anchor.
async function clickAgentLinkInList(f: Frame, label: string): Promise<string | null> {
  return f.evaluate((target: string) => {
    function walk(root: any, hits: any[]) {
      if (!root) return;
      const links = root.querySelectorAll ? root.querySelectorAll('a') : [];
      for (const el of links) {
        const t = (el.innerText || el.textContent || '').trim();
        if (t === target) hits.push(el);
      }
      const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
      for (const el of all) { try { if (el.shadowRoot) walk(el.shadowRoot, hits); } catch {} }
    }
    const hits: any[] = [];
    walk(document.body, hits);
    if (hits.length === 0) return null;
    const a = hits[0] as HTMLAnchorElement;
    const href = a.href;
    a.click();
    return href;
  }, label);
}

// Clicks the first button matching either "Open in Builder" or "Activate" (not "Activate Agent" header tile).
async function clickByExactLabel(f: Frame, label: string): Promise<string | null> {
  return f.evaluate((target: string) => {
    function walk(root: any, hits: any[]) {
      if (!root) return;
      const els = root.querySelectorAll ? root.querySelectorAll('button, a, [role="button"]') : [];
      for (const el of els) {
        const t = ((el as HTMLElement).innerText || el.textContent || '').trim();
        if (t === target) hits.push(el);
      }
      const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
      for (const el of all) { try { if (el.shadowRoot) walk(el.shadowRoot, hits); } catch {} }
    }
    const hits: any[] = [];
    walk(document.body, hits);
    if (hits.length === 0) return null;
    (hits[0] as HTMLElement).click();
    return target;
  }, label);
}

// Clicks a modal button whose text contains all given keywords (case-insensitive).
async function clickModalByKeywords(f: Frame, keywords: string[]): Promise<string | null> {
  return f.evaluate((kws: string[]) => {
    const lkws = kws.map(k => k.toLowerCase());
    function matches(t: string): boolean { return lkws.every(k => t.toLowerCase().includes(k)); }
    function walk(root: any, hits: any[]) {
      if (!root) return;
      const buttons = root.querySelectorAll ? root.querySelectorAll('button') : [];
      for (const el of buttons) {
        const t = ((el as HTMLElement).innerText || el.textContent || '').trim();
        if (matches(t)) hits.push({ el, t });
      }
      const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
      for (const el of all) { try { if (el.shadowRoot) walk(el.shadowRoot, hits); } catch {} }
    }
    const hits: any[] = [];
    walk(document.body, hits);
    if (hits.length === 0) return null;
    hits[0].el.click();
    return hits[0].t;
  }, keywords);
}

test(`activate ServiceAgent ${BOT_DEV_NAME}`, async ({ browser }) => {
  test.setTimeout(ACTIVATION_TIMEOUT_MS + 120000);
  const { botId, botLabel } = lookupBotId();
  console.log(`Activating BotDefinition ${BOT_DEV_NAME} (${botId}) "${botLabel}"`);
  const initial = botStatus(botId);
  console.log(`Initial status: ${initial}`);
  if (initial === 'Active') { console.log('Already Active.'); return; }

  const { accessToken, instanceUrl } = getOrg();
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  page.on('console', m => { if (m.type() === 'error') console.log('[err]', m.text().slice(0, 220)); });
  await loginViaFrontdoor(page, instanceUrl, accessToken);

  // ── Step 1: Open Agentforce Agents list ────────────────────────────────────
  await page.goto(`${instanceUrl}/lightning/setup/EinsteinCopilot/home`,
    { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(8000);

  // ── Step 2: Click the agent name (anchor uses target=_blank → popup) ───────
  let agentHref: string | null = null;
  for (const f of page.frames()) {
    try {
      const r = await clickAgentLinkInList(f, botLabel);
      if (r) { agentHref = r; break; }
    } catch {}
  }
  if (!agentHref) throw new Error(`Agent "${botLabel}" not found in /lightning/setup/EinsteinCopilot/home — check label/perms`);
  const popup = await page.context().waitForEvent('page', { timeout: 15000 }).catch(() => null);
  let activePage: Page = popup || page;
  if (popup) {
    await popup.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => {});
    await popup.waitForTimeout(8000);
  } else {
    await page.waitForTimeout(8000);
  }

  // ── Step 3: Click "Open in Builder" — opens the Agentforce Builder app ─────
  let openedBuilder = false;
  for (const f of activePage.frames()) {
    try {
      const r = await clickByExactLabel(f, 'Open in Builder');
      if (r) { openedBuilder = true; break; }
    } catch {}
  }
  if (!openedBuilder) throw new Error('"Open in Builder" button not found — agent detail did not load');
  const builderPopup = await activePage.context().waitForEvent('page', { timeout: 15000 }).catch(() => null);
  if (builderPopup) {
    await builderPopup.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => {});
    await builderPopup.waitForTimeout(15000); // SPA load is heavy
    activePage = builderPopup;
  } else {
    await activePage.waitForTimeout(15000);
  }
  console.log(`In Builder: ${activePage.url()}`);

  // ── Step 4: Click the in-Builder Activate button ───────────────────────────
  let activateClicked = false;
  for (const f of activePage.frames()) {
    try {
      const r = await clickByExactLabel(f, 'Activate');
      if (r) { activateClicked = true; break; }
    } catch {}
  }
  if (!activateClicked) throw new Error('Builder "Activate" button not found');

  // ── Step 5: Confirm "Configuration Issues Detected" modal ──────────────────
  const confirmKws = IGNORE_AND_ACTIVATE
    ? ['ignore', 'activate']    // "Ignore & Activate" — primary path
    : ['review', 'activation']; // "Review Activation Checklist" — opt-out path
  let confirmed: string | null = null;
  for (let attempt = 0; attempt < 8 && !confirmed; attempt++) {
    for (const f of activePage.frames()) {
      try {
        const r = await clickModalByKeywords(f, confirmKws);
        if (r) { confirmed = r; break; }
      } catch {}
    }
    if (!confirmed) await activePage.waitForTimeout(2500);
  }
  console.log(`Confirmed: ${confirmed || '(no modal found — agent may not require it)'}`);

  // ── Step 6: Poll BotVersion.Status until Active ────────────────────────────
  const start = Date.now();
  let status = botStatus(botId);
  while (status !== 'Active' && Date.now() - start < ACTIVATION_TIMEOUT_MS) {
    await activePage.waitForTimeout(5000);
    status = botStatus(botId);
    console.log(`  [${Math.round((Date.now()-start)/1000)}s] BotVersion.Status: ${status}`);
  }
  expect(status, `BotVersion did not reach Active within ${ACTIVATION_TIMEOUT_MS}ms`).toBe('Active');
});
