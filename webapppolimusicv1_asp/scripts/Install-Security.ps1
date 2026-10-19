[CmdletBinding()]
param([switch]$CurrentUser,[string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(-not $OutputDirectory){$OutputDirectory=Join-Path $root '.local/security'}
$source=Join-Path $PSScriptRoot 'PoliMusic.Security.cs'
# Keep each source version in its own folder so IIS can finish unloading the
# previous assembly without locking the binary of the next deployment.
$version=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.Substring(0,16).ToLowerInvariant()
$OutputDirectory=Join-Path $OutputDirectory $version
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$framework=Join-Path $env:windir 'Microsoft.NET/Framework64/v4.0.30319'
$dll=Join-Path $OutputDirectory 'PoliMusic.Security.dll'
if(-not (Test-Path -LiteralPath $dll)){
    & (Join-Path $framework 'csc.exe') /nologo /target:library "/out:$dll" $source
    if($LASTEXITCODE -ne 0){throw 'No se pudo compilar PoliMusic.Security.'}
}
# Use an explicit registry hive instead of HKCR, whose merged view can redirect
# writes to an existing per-user COM registration even from an admin process.
$regFile=Join-Path $OutputDirectory 'PoliMusic.Security.reg'
& (Join-Path $framework 'RegAsm.exe') $dll /codebase /nologo "/regfile:$regFile"
if($LASTEXITCODE -ne 0){throw 'No se pudo generar el registro COM.'}
$hive=if($CurrentUser){'HKEY_CURRENT_USER\Software\Classes\'}else{'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\'}
$registration=(Get-Content -LiteralPath $regFile -Raw).Replace('HKEY_CLASSES_ROOT\',$hive)
[IO.File]::WriteAllText($regFile,$registration,[Text.Encoding]::Unicode)
& reg.exe import $regFile /reg:64
if($LASTEXITCODE -ne 0){throw 'No se pudo importar el registro COM. El registro de maquina requiere permisos de administrador.'}
$probe=New-Object -ComObject PoliMusic.Security
$probeHash=$probe.Pbkdf2('testpassword','00112233445566778899aabbccddeeff',10000)
if($probeHash.Length -ne 64){throw 'Falló la comprobación de activación COM.'}
Write-Output 'PoliMusic.Security registrado y verificado para PBKDF2-SHA256 nativo.'
