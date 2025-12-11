# MockAPI Upload Template — UAD Kampus 4 (30 restoran)

Endpoint base: `https://69399f35c8d59937aa0886ec.mockapi.io/api/v1/locations`

File: `assets/data/kampus4_30_restaurants.json` contains an array of 30 objects with fields: `name`, `description`, `latitude`, `longitude`.

How to upload (PowerShell - recommended on Windows):

1. Bulk POST using PowerShell loop (will POST each object individually):

```powershell
# Path to local JSON file
$json = Get-Content -Raw -Path "assets/data/kampus4_30_restaurants.json" | ConvertFrom-Json
$endpoint = 'https://69399f35c8d59937aa0886ec.mockapi.io/api/v1/locations'

foreach ($item in $json) {
  $body = @{ 
    name = $item.name
    description = $item.description
    latitude = [double]$item.latitude
    longitude = [double]$item.longitude
  } | ConvertTo-Json -Depth 5

  Invoke-RestMethod -Method Post -Uri $endpoint -Body $body -ContentType 'application/json'
  Start-Sleep -Milliseconds 250
}
```

2. cURL example (WSL / Git Bash / Linux):

```bash
ENDPOINT='https://69399f35c8d59937aa0886ec.mockapi.io/api/v1/locations'
cat assets/data/kampus4_30_restaurants.json | jq -c '.[]' | while read -r obj; do
  curl -s -X POST "$ENDPOINT" -H 'Content-Type: application/json' -d "$obj"
  sleep 0.25
done
```

Notes:
- MockAPI will create a new resource for each POST. If your MockAPI project already has data, you may want to clear existing entries first via the MockAPI dashboard or by deleting resources programmatically.
- Each created object on MockAPI will get an `id` assigned by MockAPI. If your app expects `id` to be present, use the returned object or GET the list after upload.
- If you prefer to import via the MockAPI web UI, you can paste individual JSON objects in the 'Create' form or use MockAPI's import feature if available on your plan.

Optional: sample Dart snippet to fetch the uploaded locations (already present in your app as `ApiService.getLocations()`):

```dart
final api = ApiService();
final locations = await api.getLocations();
// Use locations in your MapPage
```

If you want, I can:
- Run a one-time script that calls the MockAPI for you (I cannot run network requests from here, but can provide a PowerShell script file), or
- Patch `ApiService` to fallback to `assets/data/kampus4_30_restaurants.json` when network fails.

Tell me which next step you prefer.