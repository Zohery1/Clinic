const https = require('https');

const options = {
  hostname: 'sgbfmqplryyhypdvrlmn.supabase.co',
  path: '/rest/v1/',
  method: 'GET',
  headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZtcXBscnl5aHlwZHZybG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzMzMTYsImV4cCI6MjA5NzkwOTMxNn0.HtW6qIoBsxjFYWLG0C4QXublMzB06glrpLccQZcPP8Q'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log(data);
  });
});

req.on('error', (e) => {
  console.error('Request error:', e);
});
req.end();
