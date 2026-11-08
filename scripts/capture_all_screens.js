const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT_DIR = path.join(__dirname, '..', 'docs', 'redesign', 'before');
if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

const BASE_URL = 'http://127.0.0.1:8081';

const VIEWPORTS = [
  { name: '1440', width: 1440, height: 900 },
  { name: '768', width: 768, height: 1024 },
  { name: '390', width: 390, height: 844 }
];

async function captureRoute(page, url, fileBase) {
  for (const vp of VIEWPORTS) {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3000);
    const filename = `${fileBase}_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, filename), fullPage: true });
    console.log(`Saved: ${filename}`);
  }
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // 1. Login Screen
  console.log('Capturing Login Screen...');
  await captureRoute(page, `${BASE_URL}/#/login`, '01_login');

  // 2. Register Screen
  console.log('Capturing Register Screen...');
  await captureRoute(page, `${BASE_URL}/#/register`, '02_register');

  // 3. Reset Password Screen
  console.log('Capturing Reset Password Screen...');
  await captureRoute(page, `${BASE_URL}/#/reset`, '03_reset_password');

  // 4. Patient Queue Tracking Screen (Public Patient View)
  console.log('Capturing Patient Queue Tracking Screen...');
  await captureRoute(page, `${BASE_URL}/#/track?id=demo-apt-01`, '04_patient_queue_tracking');

  // Now Dashboard tabs at 1440, 768, 390
  console.log('Capturing Dashboard screens...');
  for (const vp of VIEWPORTS) {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3500);

    // Tab 0: Home / Overview
    let fn = `05_dashboard_home_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);

    if (vp.name === '1440') {
      // On 1440, test sidebar navigation:
      // Tab 1: Appointments (x: 1316, y: 136)
      await page.mouse.click(1316, 136);
      await page.waitForTimeout(2000);
      fn = `06_appointments_board_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Open Book Appointment Dialog (click on 'حجز جديد' button around x: 494, y: 186)
      await page.mouse.click(494, 186);
      await page.waitForTimeout(1500);
      fn = `10_dialog_book_appointment_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);
      // Close dialog by clicking background or close icon
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1000);

      // Tab 2: Patients Directory (x: 1316, y: 180)
      await page.mouse.click(1316, 180);
      await page.waitForTimeout(2000);
      fn = `07_patients_directory_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Click on a patient to open Patient EMR Profile Dialog (click center of table row, around x: 600, y: 280)
      await page.mouse.click(600, 280);
      await page.waitForTimeout(1500);
      fn = `12_dialog_patient_details_emr_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1000);

      // Tab 3: Reports & Analytics (x: 1316, y: 224)
      await page.mouse.click(1316, 224);
      await page.waitForTimeout(2000);
      fn = `08_reports_analytics_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Tab 4: Settings (x: 1316, y: 268)
      await page.mouse.click(1316, 268);
      await page.waitForTimeout(2000);
      fn = `09_settings_screen_1440.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);
    } else if (vp.name === '768') {
      // In 768px tablet, navigation is collapsed or rail
      // Let's capture Appointments
      // On 768, sidebar collapsed width is 72 on right edge: x is 768 - 36 = 732
      await page.mouse.click(732, 136);
      await page.waitForTimeout(2000);
      fn = `06_appointments_board_768.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Patients
      await page.mouse.click(732, 180);
      await page.waitForTimeout(2000);
      fn = `07_patients_directory_768.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Reports
      await page.mouse.click(732, 224);
      await page.waitForTimeout(2000);
      fn = `08_reports_analytics_768.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Settings
      await page.mouse.click(732, 268);
      await page.waitForTimeout(2000);
      fn = `09_settings_screen_768.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);
    } else if (vp.name === '390') {
      // In 390px mobile, navigation is bottom nav bar!
      // Bottom nav bar height is ~64px at bottom: y = 844 - 32 = 812
      // 5 items across width 390:
      // Item 0 (Home): 390 - 39 = 351 (RTL start)
      // Item 1 (Appointments): 390 - 39 - 78 = 273
      // Item 2 (Patients): 390 - 39 - 78*2 = 195
      // Item 3 (Reports): 390 - 39 - 78*3 = 117
      // Item 4 (Settings): 390 - 39 - 78*4 = 39
      
      // Tab 1: Appointments
      await page.mouse.click(273, 812);
      await page.waitForTimeout(2000);
      fn = `06_appointments_board_390.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Tab 2: Patients
      await page.mouse.click(195, 812);
      await page.waitForTimeout(2000);
      fn = `07_patients_directory_390.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Tab 3: Reports
      await page.mouse.click(117, 812);
      await page.waitForTimeout(2000);
      fn = `08_reports_analytics_390.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);

      // Tab 4: Settings
      await page.mouse.click(39, 812);
      await page.waitForTimeout(2000);
      fn = `09_settings_screen_390.png`;
      await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
      console.log(`Saved: ${fn}`);
    }
  }

  // Also capture Examination Screen
  console.log('Capturing Examination Screen...');
  // In demo mode, we can trigger examination screen or inspect existing screenshots
  // Let's check how examination screen is opened:
  // On appointments screen, clicking 'بدء الفحص' button on card 3
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.mouse.click(1316, 136); // Go to appointments
  await page.waitForTimeout(2000);
  
  // Click 'بدء الفحص' on active card (card 3 action button, around x: 382, y: 502)
  await page.mouse.click(382, 502);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '15_examination_cockpit_1440.png'), fullPage: true });
  console.log('Saved: 15_examination_cockpit_1440.png');

  // Examination mobile
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(OUT_DIR, '15_examination_cockpit_390.png'), fullPage: true });
  console.log('Saved: 15_examination_cockpit_390.png');

  await browser.close();
  console.log('All captures complete!');
})();
