# Define search locations (excluding AppData for now to avoid freezing)
$locations = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
    # "$env:USERPROFILE\AppData"  # Uncomment to include AppData, but it's slow
)

# Define file extensions to scan
$fileTypes = '*.txt', '*.json', '*.log', '*.conf'

# Define output file
$outputFile = "$env:USERPROFILE\Desktop\KeysFound.txt"
$results = @()

# Define regex patterns for private keys and seed phrases
$patterns = @(
    '\b[5KL][1-9A-HJ-NP-Za-km-z]{50,51}\b',         # Bitcoin WIF
    '\b0x[a-fA-F0-9]{64}\b',                        # Ethereum private key
    '\b[a-fA-F0-9]{64}\b',                          # Raw hex private key
    '\b(?:\w+\b[\s,]*){12,24}'                      # BIP39 seed phrases
)

# Max file size in bytes (5MB)
$maxFileSize = 5MB

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

# Remove duplicates and save results
$results | Sort-Object -Unique | Out-File -Encoding UTF8 $outputFile

Write-Host "`n✅ Scan complete. Results saved to: $outputFile"
