const { chromium } = require('playwright');
const path = require('path');

const OUT_DIR = path.join(__dirname, '..', 'docs', 'redesign', 'after');
const BASE_URL = 'http://127.0.0.1:8081';

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  // 1. WhatsApp dialog from appointments screen
  console.log('Navigating to demo...');
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  // Enable semantics
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) el.click();
  });
  await page.waitForTimeout(1000);

  // Click on appointments in sidebar
  console.log('Clicking appointments in sidebar...');
  await page.mouse.click(1316, 136);
  await page.waitForTimeout(2000);

  // Click on the phone number row or WhatsApp icon in appointment details
  // Let's inspect semantics nodes to find phone or whatsapp or click position
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

  console.log('Found nodes:', nodes.length);
  const phoneNode = nodes.find(n => n.label.includes('010') || n.label.includes('واتساب') || n.label.includes('WhatsApp'));
  if (phoneNode) {
    console.log('Found phone/whatsapp node:', phoneNode.label, phoneNode.rect);
    await page.mouse.click(phoneNode.rect.x + phoneNode.rect.width / 2, phoneNode.rect.y + phoneNode.rect.height / 2);
  } else {
    // Look at appointment details card: phone number is around x: 190, y: 175
    console.log('Trying coordinate click on phone number in details drawer...');
    await page.mouse.click(190, 175);
  }
  await page.waitForTimeout(1500);

  await page.screenshot({ path: path.join(OUT_DIR, '13_dialog_whatsapp_1440.png') });
  console.log('Saved 13_dialog_whatsapp_1440.png');

  // Close WhatsApp dialog
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 2. Patient details EMR dialog
  // On Patients tab, or when clicking patient
  console.log('Navigating to Patients tab...');
  await page.mouse.click(1316, 180);
  await page.waitForTimeout(2000);

  // In patients desktop layout, clicking patient in list updates profile on the left.
  // In `12_dialog_patient_details_emr_1440.png`, let's see what was captured:
  // It's the patient profile / details view.
  await page.screenshot({ path: path.join(OUT_DIR, '12_dialog_patient_details_emr_1440.png') });
  console.log('Saved 12_dialog_patient_details_emr_1440.png');

  // 3. Examination completed dialog
  // Go to appointments, click 'بدء الفحص'
  console.log('Going to examination cockpit...');
  await page.mouse.click(1316, 136);
  await page.waitForTimeout(2000);
  await page.mouse.click(382, 502);
  await page.waitForTimeout(3000);

  // In examination cockpit, click 'إنهاء الكشف' button
  // Let's find button for 'إنهاء الكشف'
  const examNodes = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('flt-semantics, [role="button"], [aria-label]')).map(el => {
      const rect = el.getBoundingClientRect();
      return {
        tag: el.tagName,
        label: el.getAttribute('aria-label') || el.innerText || '',
        rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height }
      };
    }).filter(n => n.label.trim().length > 0 && n.rect.width > 0);
  });

  const finishNode = examNodes.find(n => n.label.includes('إنهاء الكشف') || n.label.includes('اعتماد'));
  if (finishNode) {
    console.log('Found finishNode:', finishNode.label, finishNode.rect);
    await page.mouse.click(finishNode.rect.x + finishNode.rect.width / 2, finishNode.rect.y + finishNode.rect.height / 2);
  } else {
    // Bottom bar of examination cockpit: right side (in RTL) has the finish button
    console.log('Clicking bottom finish button...');
    await page.mouse.click(950, 860);
  }
  await page.waitForTimeout(1500);

  await page.screenshot({ path: path.join(OUT_DIR, '14_dialog_examination_completed_1440.png') });
  console.log('Saved 14_dialog_examination_completed_1440.png');

  await browser.close();
  console.log('Done capturing dialogs!');
})();
