const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT_DIR = path.join(__dirname, '..', 'docs', 'redesign', 'after');
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

  // 5-9. Dashboard Screens & Tabs across all 3 viewports
  console.log('Capturing Dashboard screens across all viewports...');
  for (const vp of VIEWPORTS) {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3500);

    // Tab 0: Home / Overview
    let fn = `05_dashboard_home_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);

    // Tab 1: Appointments Board
    await page.keyboard.press('Control+2');
    await page.waitForTimeout(2000);
    fn = `06_appointments_board_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);

    // Tab 2: Patients Directory
    await page.keyboard.press('Control+3');
    await page.waitForTimeout(2000);
    fn = `07_patients_directory_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);

    // Tab 3: Reports & Analytics
    await page.keyboard.press('Control+4');
    await page.waitForTimeout(2000);
    fn = `08_reports_analytics_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);

    // Tab 4: Settings Screen
    await page.keyboard.press('Control+5');
    await page.waitForTimeout(2000);
    fn = `09_settings_screen_${vp.name}.png`;
    await page.screenshot({ path: path.join(OUT_DIR, fn), fullPage: true });
    console.log(`Saved: ${fn}`);
  }

  // 10. Dialog: Book Appointment (1440)
  console.log('Capturing Book Appointment Dialog...');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.keyboard.press('Control+n');
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '10_dialog_book_appointment_1440.png') });
  console.log('Saved: 10_dialog_book_appointment_1440.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 11. Dialog: Add Patient (1440)
  console.log('Capturing Add Patient Dialog...');
  await page.keyboard.press('Control+3'); // Go to Patients tab
  await page.waitForTimeout(2000);
  // Click '+ مريض جديد' button on Patients list panel (around x: 1002, y: 130)
  await page.mouse.click(1002, 130);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '11_dialog_add_patient_1440.png') });
  console.log('Saved: 11_dialog_add_patient_1440.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 12. Patient Medical Profile / Details (1440)
  console.log('Capturing Patient Medical Profile...');
  await page.keyboard.press('Control+3');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(OUT_DIR, '12_patient_profile_1440.png') });
  await page.screenshot({ path: path.join(OUT_DIR, '12_dialog_patient_details_emr_1440.png') });
  console.log('Saved: 12_patient_profile_1440.png & 12_dialog_patient_details_emr_1440.png');

  // 13. Dialog: WhatsApp Message (1440)
  console.log('Capturing WhatsApp Message Dialog...');
  await page.keyboard.press('Control+2'); // Go to Appointments tab
  await page.waitForTimeout(2000);
  // Click on the phone number / WhatsApp button in the appointment details drawer (around x: 190, y: 175)
  await page.mouse.click(190, 175);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '13_dialog_whatsapp_1440.png') });
  console.log('Saved: 13_dialog_whatsapp_1440.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 14. Dialog: Examination Completed (1440)
  console.log('Capturing Examination Completed Dialog...');
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.keyboard.press('Control+e'); // Open Examination Cockpit
  await page.waitForTimeout(2500);
  // Click 'إنهاء الكشف' button at the bottom (around x: 950, y: 860)
  await page.mouse.click(950, 860);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '14_dialog_examination_completed_1440.png') });
  console.log('Saved: 14_dialog_examination_completed_1440.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 15. Examination Cockpit Screen (1440 & 390)
  console.log('Capturing Examination Cockpit Screen...');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.keyboard.press('Control+e');
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '15_examination_cockpit_1440.png'), fullPage: true });
  console.log('Saved: 15_examination_cockpit_1440.png');

  // Examination mobile (390)
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(`${BASE_URL}/#/demo`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.keyboard.press('Control+e');
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '15_examination_cockpit_390.png'), fullPage: true });
  console.log('Saved: 15_examination_cockpit_390.png');

  await browser.close();
  console.log('All 30 after captures successfully completed!');
})();
