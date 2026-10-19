[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$package=Join-Path $root ('deploy/PoliMusic-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $package | Out-Null
foreach($name in @('default.asp','login.asp','register.asp','welcome.asp','api.asp','stream.asp','global.asa','web.config','README.md')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination $package}
foreach($name in @('assets','includes','scripts','database','tests','SongFilesAndImages_resources')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination $package -Recurse}
New-Item -ItemType Directory -Force (Join-Path $package 'App_Data') | Out-Null
# Local database credentials are deliberately excluded from the distributable ZIP.
$archive=$package+'.zip'
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $package).FullName -DestinationPath $archive
Write-Output "Paquete IIS: $archive"
