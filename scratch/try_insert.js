const https = require('https');

const postData = JSON.stringify({
  clinic_id: 'd9b9b9b9-b9b9-b9b9-b9b9-b9b9b9b9b9b9', // dummy uuid format
  full_name: 'Test Test',
  medical_history: 'Test medical history'
});

const options = {
  hostname: 'sgbfmqplryyhypdvrlmn.supabase.co',
  path: '/rest/v1/patients',
  method: 'POST',
  headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZtcXBscnl5aHlwZHZybG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzMzMTYsImV4cCI6MjA5NzkwOTMxNn0.HtW6qIoBsxjFYWLG0C4QXublMzB06glrpLccQZcPP8Q',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response Body:', data);
  });
});

req.on('error', (e) => {
  console.error('Request error:', e);
});

req.write(postData);
req.end();
