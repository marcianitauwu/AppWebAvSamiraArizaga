[CmdletBinding()]
param([int]$Port=8091,[switch]$Restart,[switch]$DebugErrors)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$iis=Join-Path ${env:ProgramFiles} 'IIS Express'
if(-not (Test-Path (Join-Path $iis 'iisexpress.exe'))){throw 'Instala IIS Express o usa Deploy-IIS.ps1 en IIS.'}
$local=Join-Path $root '.local'
New-Item -ItemType Directory -Force $local | Out-Null
[xml]$config=Get-Content (Join-Path $iis 'config/templates/PersonalWebServer/applicationhost.config')
$site=$config.configuration.'system.applicationHost'.sites.site
$site.SetAttribute('name','PoliMusic'); $site.SelectSingleNode('application/virtualDirectory').SetAttribute('physicalPath',[string]$root)
$site.bindings.binding.SetAttribute('bindingInformation','*:'+ $Port +':localhost')
$config.configuration.'system.webServer'.asp.SetAttribute('scriptErrorSentToBrowser',([string][bool]$DebugErrors).ToLowerInvariant())
$config.configuration.'system.webServer'.asp.cache.SetAttribute('scriptEngineCacheMax','0')
$config.configuration.'system.webServer'.asp.cache.SetAttribute('scriptFileCacheSize','0')
$config.configuration.'system.applicationHost'.sites.siteDefaults.logFile.SetAttribute('directory',[string]$local)
$config.configuration.'system.applicationHost'.sites.siteDefaults.traceFailedRequestsLogging.SetAttribute('directory',[string]$local)
$configPath=Join-Path $local 'applicationhost.config'
if($Restart){
    Get-CimInstance Win32_Process -Filter "Name='iisexpress.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.Contains($configPath) } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
}
$config.Save($configPath)
Write-Output "PoliMusic: http://localhost:$Port/"
& (Join-Path $iis 'iisexpress.exe') "/config:$configPath" '/site:PoliMusic' '/systray:false'
