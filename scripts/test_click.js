const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://127.0.0.1:8081/#/demo', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  
  // Enable semantics
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) el.click();
  });
  await page.waitForTimeout(1000);

  // Inspect all semantics nodes with labels
  const nodes = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('flt-semantics, [role="button"], [aria-label]')).map(el => {
      const rect = el.getBoundingClientRect();
      return {
        tag: el.tagName,
        label: el.getAttribute('aria-label') || el.innerText || '',
        rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height }
      };
    }).filter(n => n.label.trim().length > 0 && n.rect.width > 0);
  });

  console.log('Total semantic nodes with rect:', nodes.length);
  for (const n of nodes) {
    if (['المواعيد', 'المرضى', 'التقارير', 'الإعدادات', 'حجز جديد', 'بدء الكشف'].some(k => n.label.includes(k))) {
      console.log(`Node [${n.label.replace(/\n/g, ' ')}] -> x:${n.rect.x}, y:${n.rect.y}, w:${n.rect.width}, h:${n.rect.height}`);
    }
  }

  // Click on 'المواعيد'
  const apptNode = nodes.find(n => n.label.includes('المواعيد') && n.rect.x > 1000); // sidebar is on the right in RTL!
  if (apptNode) {
    console.log('Clicking apptNode at:', apptNode.rect.x + apptNode.rect.width / 2, apptNode.rect.y + apptNode.rect.height / 2);
    await page.mouse.click(apptNode.rect.x + apptNode.rect.width / 2, apptNode.rect.y + apptNode.rect.height / 2);
  } else {
    // If not found by label, sidebar items are on the right edge: width is 1440, sidebar width is 248.
    // Right side x is ~ 1440 - 120 = 1320.
    // Item 0 (Home): y ~ 100
    // Item 1 (Appointments): y ~ 150
    // Item 2 (Patients): y ~ 200
    // Item 3 (Reports): y ~ 250
    // Item 4 (Settings): y ~ 300
    console.log('Fallback: clicking sidebar coordinates for appointments (x: 1320, y: 150)');
    await page.mouse.click(1320, 150);
  }

  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'test_after_click_appointments.png' });
  await browser.close();
})();
