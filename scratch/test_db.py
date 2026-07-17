import requests

url = "https://sgbfmqplryyhypdvrlmn.supabase.co/rest/v1/appointments"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZtcXBscnl5aHlwZHZybG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzMzMTYsImV4cCI6MjA5NzkwOTMxNn0.HtW6qIoBsxjFYWLG0C4QXublMzB06glrpLccQZcPP8Q",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZtcXBscnl5aHlwZHZybG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzMzMTYsImV4cCI6MjA5NzkwOTMxNn0.HtW6qIoBsxjFYWLG0C4QXublMzB06glrpLccQZcPP8Q",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Fetch first appointment
print("Fetching first appointment...")
res = requests.get(url + "?limit=1", headers=headers)
print("Fetch Status:", res.status_code)
if res.status_code == 200 and res.json():
    app = res.json()[0]
    print("Appointment:", app)
    app_id = app['id']
    old_status = app['status']
    
    print(f"Trying to update appointment {app_id} status to 'active'...")
    update_res = requests.patch(f"{url}?id=eq.{app_id}", headers=headers, json={"status": "active"})
    print("Update Status:", update_res.status_code)
    print("Update Response:", update_res.text)
else:
    print("No appointments found or error.")
