const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const args = process.argv.slice(2);
const url = args[0];
const outputPath = args[1] || 'screenshot.png';
const viewportWidth = parseInt(args[2], 10) || 1920;
const viewportHeight = parseInt(args[3], 10) || 1080;
const waitSelector = args[4] || null;

if (!url) {
  console.error('Usage: node screenshot.js <url> [outputPath] [viewportWidth] [viewportHeight] [waitSelector]');
  process.exit(1);
}

(async () => {
  const outputDir = path.dirname(outputPath);
  if (outputDir && !fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: viewportWidth, height: viewportHeight },
    ignoreHTTPSErrors: true,
  });
  const page = await context.newPage();

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });

    // Lightning pages need extra time for components to render after network idle
    await page.waitForTimeout(3000);

    if (waitSelector) {
      await page.waitForSelector(waitSelector, { timeout: 30000 });
    }

    await page.screenshot({ path: outputPath, fullPage: false });
    console.log(JSON.stringify({ success: true, path: path.resolve(outputPath) }));
  } catch (err) {
    console.error(JSON.stringify({ success: false, error: err.message }));
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
