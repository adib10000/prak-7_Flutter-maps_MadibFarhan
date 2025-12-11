# Upload script for kampus4_30_restaurants.json to MockAPI
# Usage: Open PowerShell in the project root (C:\flutter_maps) and run:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\scripts\upload_kampus4_restaurants.ps1

$FilePath = Join-Path $PSScriptRoot '..\assets\data\kampus4_30_restaurants.json'
$Endpoint = 'https://69399f35c8d59937aa0886ec.mockapi.io/api/v1/locations'

if (-Not (Test-Path $FilePath)) {
    Write-Error "Data file not found: $FilePath"
    exit 1
}

Write-Host ('Reading data from {0}' -f $FilePath)
$json = Get-Content -Raw -Path $FilePath | ConvertFrom-Json

Write-Host ('Found {0} items. Posting to MockAPI: {1}' -f $json.Count, $Endpoint)

foreach ($item in $json) {
    $body = @{ 
        name = $item.name
        description = $item.description
        latitude = [double]$item.latitude
        longitude = [double]$item.longitude
    } | ConvertTo-Json -Depth 5

    try {
        # Try to POST and capture successful response
        $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Body $body -ContentType 'application/json'
        Write-Host ("Posted: {0} => id:{1}" -f $item.name, $resp.id)
    } catch {
        # Attempt to extract response body and status from the WebException if available
        $err = $_.Exception
        $msg = ""
        try {
            if ($err.Response -ne $null) {
                $status = $err.Response.StatusCode.Value__
                $stream = $err.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $bodyResp = $reader.ReadToEnd()
                $msg = "Status:$status - Body:$bodyResp"
            } else {
                $msg = $_.ToString()
            }
        } catch {
            $msg = $_.ToString()
        }
        Write-Warning ("Failed to post: {0} - {1}" -f $item.name, $msg)
    }
    Start-Sleep -Milliseconds 250
}

Write-Host 'Upload complete.'