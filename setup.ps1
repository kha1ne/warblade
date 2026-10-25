# Project-local stable tools, verified on 2026-10-25. No administrator rights needed.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$toolsDir = Join-Path $PSScriptRoot '.tools'
New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null

function Install-ZipTool {
    param([string]$Url, [string]$Hash, [string]$Destination, [string]$Executable)
    if (Test-Path -LiteralPath $Executable) { return }
    $archive = Join-Path $toolsDir ([IO.Path]::GetFileName($Url))
    Write-Host "Downloading $Url"
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $archive
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $Hash) {
        throw "Checksum mismatch: $archive"
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $Destination -Force
    if (-not (Test-Path -LiteralPath $Executable)) { throw "Missing tool: $Executable" }
    Remove-Item -LiteralPath $archive
}

$cmakeExe = Join-Path $toolsDir 'cmake-4.4.4-windows-x86_64\bin\cmake.exe'
Install-ZipTool `
    -Url 'https://github.com/Kitware/CMake/releases/download/v4.4.4/cmake-4.4.4-windows-x86_64.zip' `
    -Hash 'bace36e94b31c68ab6fa295f26dfa11219e0701cf7c94b0284a7d1cb13dac536' `
    -Destination $toolsDir -Executable $cmakeExe

$ninjaExe = Join-Path $toolsDir 'ninja\ninja.exe'
Install-ZipTool `
    -Url 'https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip' `
    -Hash '07fc8261b42b20e71d1720b39068c2e14ffcee6396b76fb7a795fb460b78dc65' `
    -Destination (Join-Path $toolsDir 'ninja') -Executable $ninjaExe

$vcpkgDir = Join-Path $toolsDir 'vcpkg'
$vcpkgCommit = '9eec002df1cd109f8f104cd966a763daf9751489'
if (-not (Test-Path -LiteralPath $vcpkgDir)) {
    git clone --depth 1 --branch 2026.10.16 https://github.com/microsoft/vcpkg.git $vcpkgDir
    if ($LASTEXITCODE -ne 0) { throw 'Could not clone vcpkg.' }
}
$actualCommit = git -C $vcpkgDir rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $vcpkgCommit) {
    throw 'The local vcpkg checkout does not match the pinned release.'
}
if (-not (Test-Path -LiteralPath (Join-Path $vcpkgDir 'vcpkg.exe'))) {
    & (Join-Path $vcpkgDir 'bootstrap-vcpkg.bat') -disableMetrics
    if ($LASTEXITCODE -ne 0) { throw 'Could not bootstrap vcpkg.' }
}

$innoDir = Join-Path $toolsDir 'innosetup-7.1.0'
$innoExe = Join-Path $innoDir 'ISCC.exe'
if (-not (Test-Path -LiteralPath $innoExe)) {
    $innoInstaller = Join-Path $toolsDir 'innosetup-7.1.0-x64.exe'
    Write-Host 'Downloading Inno Setup 7.1.0'
    Invoke-WebRequest -UseBasicParsing `
        -Uri 'https://github.com/jrsoftware/issrc/releases/download/is-7_1_0/innosetup-7.1.0-x64.exe' `
        -OutFile $innoInstaller
    if ((Get-FileHash -LiteralPath $innoInstaller -Algorithm SHA256).Hash -ne
        '0362a383ed217d4c4239b5933866dd96d3eb2102737da92f80f6057a4b40df2f') {
        throw 'Inno Setup checksum mismatch.'
    }
    # Official portable compiler mode: no registration, shortcuts, or file associations.
    $innoArgs = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-',
                  '/CURRENTUSER', '/PORTABLE=1', '/NOICONS',
                  ('/DIR="' + $innoDir + '"'),
                  ('/LOG="' + (Join-Path $toolsDir 'innosetup-install.log') + '"'))
    $innoProcess = Start-Process -FilePath $innoInstaller -ArgumentList $innoArgs `
        -WindowStyle Hidden -Wait -PassThru
    if ($innoProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $innoExe)) {
        throw 'Inno Setup preparation failed. See .tools\innosetup-install.log.'
    }
    Remove-Item -LiteralPath $innoInstaller
}

& $cmakeExe --version
& $ninjaExe --version
& (Join-Path $vcpkgDir 'vcpkg.exe') version
Write-Host 'Ready. Run .\build.bat debug run'
Write-Host 'Inno Setup 7.1.0 ready. Create an installer with .\build.bat release package'
