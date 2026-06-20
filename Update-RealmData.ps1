# ==============================================================================
#  Update-RealmData.ps1
#  Utility script to fetch the latest WoW realm data from LibRealmInfo's
#  public database on GitHub and rebuild RealmData.lua.
#
#  How to use:
#  1. Right-click this file and select "Run with PowerShell" (or execute it
#     from your PowerShell terminal).
#  2. This script runs completely offline from the game and does NOT interact
#     with World of Warcraft or its memory, making it 100% compliant with
#     Blizzard's Terms of Service and Midnight addon policies.
# ==============================================================================

$Url = "https://raw.githubusercontent.com/janekjl/LibRealmInfo/master/LibRealmInfo.lua"
Write-Host "Fetching latest realm data from $Url..." -ForegroundColor Cyan

try {
    # Force TLS 1.2/1.3 for secure download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    $content = Invoke-RestMethod -Uri $Url -UseBasicParsing
} catch {
    Write-Error "Failed to fetch realm data: $_"
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "Parsing realmData..." -ForegroundColor Cyan
$realmData = @{}
# Match lines like: [1]="Lightbringer,PvE,enUS,US,PST",
$realmPattern = '\[(\d+)\]\s*=\s*"([^"]+)"'
$matches = [regex]::Matches($content, $realmPattern)
foreach ($m in $matches) {
    $id = [int]$m.Groups[1].Value
    $parts = $m.Groups[2].Value.Split(',')
    if ($parts.Length -ge 4) {
        $name = $parts[0].Trim()
        $rules = $parts[1].Trim()
        $locale = $parts[2].Trim()
        $region = $parts[3].Trim()
        
        # Normalize locale tag to 2-letter standard (enUS -> EN, deDE -> DE, etc.)
        $lang = $locale.Substring(2, 2).ToUpper()
        if ($lang -eq "US" -or $lang -eq "GB") { $lang = "EN" }
        
        $realmData[$id] = [PSCustomObject]@{
            Name = $name
            Locale = $lang
            Region = $region
        }
    }
}
Write-Host "Found $($realmData.Count) realms." -ForegroundColor Green

Write-Host "Parsing connectionData..." -ForegroundColor Cyan
$connectionBlockPattern = 'connectionData\s*=\s*\{([\s\S]*?)\}'
$blockMatch = [regex]::Match($content, $connectionBlockPattern)
$connectionData = @()
if ($blockMatch.Success) {
    $block = $blockMatch.Groups[1].Value
    $connectionLinePattern = '"([^"]+)"'
    $lineMatches = [regex]::Matches($block, $connectionLinePattern)
    foreach ($lm in $lineMatches) {
        $parts = $lm.Groups[1].Value.Split(',')
        if ($parts.Length -gt 2) {
            # Parts: connectionID, region, realmId1, realmId2, ...
            $connId = $parts[0]
            $region = $parts[1]
            $realmIds = @()
            for ($i = 2; $i -lt $parts.Length; $i++) {
                $rId = [int]$parts[$i]
                $realmIds += $rId
            }
            $connectionData += [PSCustomObject]@{
                Region = $region
                RealmIds = $realmIds
            }
        }
    }
}
Write-Host "Found $($connectionData.Count) connection groups." -ForegroundColor Green

# Group into EU/US clusters
$euClusters = [System.Collections.Generic.List[string]]::new()
$naClusters = [System.Collections.Generic.List[string]]::new()
$seenClusters = @{}

foreach ($conn in $connectionData) {
    $realmNames = [System.Collections.Generic.List[string]]::new()
    foreach ($rId in $conn.RealmIds) {
        if ($realmData.ContainsKey($rId)) {
            $realmNames.Add($realmData[$rId].Name)
        }
    }
    if ($realmNames.Count -gt 0) {
        # Sort names to guarantee consistent signature
        $sortedNames = $realmNames | Sort-Object
        $clusterSig = $sortedNames -join ","
        if ($seenClusters.ContainsKey($clusterSig)) { continue }
        $seenClusters[$clusterSig] = $true
        
        $luaList = '    {' + (($sortedNames | ForEach-Object { "`"$_`"" }) -join ",") + '},'
        
        if ($conn.Region -eq "EU") {
            $euClusters.Add($luaList)
        } elseif ($conn.Region -eq "US") {
            $naClusters.Add($luaList)
        }
    }
}

# Generate the RealmData.lua contents
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('--  RealmData.lua')
$null = $sb.AppendLine('--  Static reference data for RealmDisplay.')
$null = $sb.AppendLine('--  Automatically regenerated using Update-RealmData.ps1')
$null = $sb.AppendLine('--  Generated on: ' + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('RealmDisplay_Data = RealmDisplay_Data or {}')
$null = $sb.AppendLine()
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('-- 1. REGION -> REALMS & LOCALES')
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('RealmDisplay_Data.realms = {')

# Group realms by region
$realmsByRegion = $realmData.Values | Group-Object Region
foreach ($group in $realmsByRegion) {
    $regionName = $group.Name
    $null = $sb.AppendLine("    $regionName = {")
    
    $lineBuffer = ""
    $sortedGroup = $group.Group | Sort-Object Locale, Name
    foreach ($realm in $sortedGroup) {
        $escapedName = $realm.Name.Replace('"', '\"')
        $entry = "[`"$escapedName`"]=`"$($realm.Locale)`""
        if (($lineBuffer.Length + $entry.Length + 2) -gt 86) {
            $null = $sb.AppendLine("        " + $lineBuffer)
            $lineBuffer = $entry + ","
        } else {
            if ($lineBuffer -eq "") {
                $lineBuffer = $entry + ","
            } else {
                $lineBuffer += $entry + ","
            }
        }
    }
    if ($lineBuffer -ne "") {
        $null = $sb.AppendLine("        " + $lineBuffer)
    }
    $null = $sb.AppendLine("    },")
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('-- 2. EU CONNECTED REALM CLUSTERS')
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('RealmDisplay_Data.euClusters = {')
foreach ($cluster in $euClusters) {
    $null = $sb.AppendLine($cluster)
}
$null = $sb.AppendLine('}')
$null = $sb.AppendLine()

$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('-- 3. NA / US CONNECTED REALM CLUSTERS')
$null = $sb.AppendLine('-- ============================================================')
$null = $sb.AppendLine('RealmDisplay_Data.naClusters = {')
foreach ($cluster in $naClusters) {
    $null = $sb.AppendLine($cluster)
}
$null = $sb.AppendLine('}')

# Save the output file
$outputPath = Join-Path $PSScriptRoot "Data\RealmData.lua"
Write-Host "Writing updated data to: $outputPath" -ForegroundColor Cyan
[System.IO.File]::WriteAllText($outputPath, $sb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "`nSuccess! RealmData.lua has been successfully updated." -ForegroundColor Green
Read-Host "Press Enter to exit"
