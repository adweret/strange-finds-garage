$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Build.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
$releasePath = Join-Path $projectRoot 'build\StrangeFinds.rbxlx'
$document = [System.Xml.XmlDocument]::new()
$document.XmlResolver = $null
$document.Load($releasePath)
$names = @($document.SelectNodes('//Item/Properties/string[@name="Name"]') | ForEach-Object InnerText)
$forbidden = @('TestEZ', 'GarageTests', 'GarageTestDriver', 'TestDriver', 'SixClient', 'SixScenario')
$leaked = @($names | Where-Object { $_ -in $forbidden })
if ($leaked.Count -gt 0) { throw "Test code leaked into release: $($leaked -join ', ')" }
if ('ProfileStore' -notin $names -or 'Config' -notin $names -or 'GarageServer' -notin $names) {
    throw 'Release is missing required game modules'
}
$orientation = $document.SelectSingleNode('//Item[@class="StarterGui"]/Properties/token[@name="ScreenOrientation"]')
if ($null -eq $orientation -or $orientation.InnerText -ne '2') {
    throw 'Release must use LandscapeSensor (ScreenOrientation value 2)'
}
Get-FileHash -LiteralPath $releasePath -Algorithm SHA256 | Select-Object Path,Hash
Write-Output 'Release composition passed: production modules present; test modules absent.'
