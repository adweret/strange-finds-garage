param([switch]$Tests)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $toolBin = Join-Path $env:USERPROFILE '.rokit\bin'
    & "$toolBin\stylua.exe" --check src tests
    if ($LASTEXITCODE -ne 0) { throw 'StyLua failed' }
    & "$toolBin\selene.exe" src
    if ($LASTEXITCODE -ne 0) { throw 'Selene failed' }
    & "$toolBin\selene.exe" --config tests/selene.toml tests
    if ($LASTEXITCODE -ne 0) { throw 'Test lint failed' }
    New-Item -ItemType Directory -Force -Path 'build' | Out-Null
    if ($Tests) {
        $testProject = Get-Content -Raw 'default.project.json' | ConvertFrom-Json -AsHashtable
        $testProject.tree.ServerStorage = @{ GarageTests = @{ '$path' = 'tests' }; TestEZ = @{ '$path' = 'vendor/TestEZ' } }
        $testJson = $testProject | ConvertTo-Json -Depth 20
        $existingJson = if (Test-Path -LiteralPath 'test.project.json') { Get-Content -Raw 'test.project.json' } else { '' }
        if ($existingJson.Trim() -ne $testJson.Trim()) { Set-Content -Encoding utf8 'test.project.json' $testJson }
        & "$toolBin\rojo.exe" build test.project.json -o 'build\StrangeFinds-Test.rbxlx'
    } else {
        & "$toolBin\rojo.exe" build -o 'build\StrangeFinds.rbxlx'
    }
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
} finally { Pop-Location }
