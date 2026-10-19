[CmdletBinding()]
param(
    [string]$Destination='C:\intentpub\wwwroot\PoliMusic',
    [string]$SiteName='Default Web Site',
    [string]$ApplicationName='PoliMusic',
    [switch]$Elevate
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    if(-not $Elevate){throw 'Abre PowerShell como administrador o ejecuta este script con -Elevate para mostrar el aviso UAC de Windows.'}
    $arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$PSCommandPath+'"'),'-Destination',('"'+$Destination+'"'),'-SiteName',('"'+$SiteName+'"'),'-ApplicationName',('"'+$ApplicationName+'"'))
    $child=Start-Process -FilePath powershell.exe -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru -Wait
    if($child.ExitCode -ne 0){throw 'Falló el despliegue elevado. Consulta .local/deployment.log.'}
    Write-Output ('Instalador finalizado. Dirección: http://localhost/'+$ApplicationName+'/')
    return
}
New-Item -ItemType Directory -Force (Join-Path $root '.local') | Out-Null
Start-Transcript -Path (Join-Path $root '.local/deployment.log') -Append | Out-Null
$restorePoolOnFailure=$false
try {
$Destination=[IO.Path]::GetFullPath($Destination)
if($Destination.TrimEnd('\') -eq [IO.Path]::GetPathRoot($Destination).TrimEnd('\') -or $Destination.TrimEnd('\') -eq $root.TrimEnd('\')){throw 'Elige una subcarpeta de despliegue distinta del código fuente.'}
if(-not (Test-Path (Join-Path $root 'App_Data/connection.txt'))){throw 'Ejecuta primero Initialize-Database.ps1 con las credenciales SQL.'}
$marker=Join-Path $Destination 'App_Data/polimusic-deployment.txt'
if((Test-Path -LiteralPath $Destination) -and (Get-ChildItem -LiteralPath $Destination -Force | Select-Object -First 1) -and -not (Test-Path -LiteralPath $marker)){
    $ownPartial=$true
    foreach($file in @('default.asp','web.config')){
        $targetFile=Join-Path $Destination $file
        if(-not (Test-Path -LiteralPath $targetFile) -or (Get-FileHash -LiteralPath $targetFile).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root $file)).Hash){$ownPartial=$false}
    }
    if(-not $ownPartial){throw 'La carpeta de destino contiene archivos ajenos. Usa una carpeta vacia para PoliMusic.'}
}
Import-Module WebAdministration
if(-not (Test-Path ('IIS:\Sites\'+$SiteName))){throw "No existe el sitio IIS '$SiteName'."}
$existing=Get-WebApplication -Site $SiteName -Name $ApplicationName -ErrorAction SilentlyContinue
if($existing -and [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($existing.physicalPath)) -ne $Destination){throw 'Ya existe una aplicación con ese nombre en otra carpeta.'}
foreach($featureName in @('IIS-ASP','IIS-ISAPIExtensions','IIS-StaticContent','IIS-DefaultDocument','IIS-HttpErrors','IIS-RequestFiltering')){
    $feature=Get-WindowsOptionalFeature -Online -FeatureName $featureName
    if($feature.State -ne 'Enabled'){Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart | Out-Null}
}
if(Test-Path -LiteralPath $marker){
    $backup=Join-Path $root ('deploy/IIS-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.zip')
    New-Item -ItemType Directory -Force (Split-Path $backup -Parent) | Out-Null
    # Allow shared reads of the crypto assembly while IIS has it loaded.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($Destination,$backup,[IO.Compression.CompressionLevel]::Optimal,$true)
    Write-Output "Copia previa: $backup"
}
$restorePoolOnFailure=$existing -and (Test-Path 'IIS:\AppPools\PoliMusic') -and (Get-WebAppPoolState PoliMusic).Value -eq 'Started'
if($restorePoolOnFailure){Stop-WebAppPool PoliMusic}
New-Item -ItemType Directory -Force $Destination,(Join-Path $Destination 'App_Data') | Out-Null
[IO.File]::WriteAllText($marker,'PoliMusic Classic ASP deployment')
foreach($name in @('default.asp','login.asp','register.asp','welcome.asp','api.asp','stream.asp','global.asa','web.config')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination $Destination -Force}
foreach($name in @('assets','includes','SongFilesAndImages_resources')){
    $target=Join-Path $Destination $name
    New-Item -ItemType Directory -Force $target | Out-Null
    Copy-Item -Path (Join-Path $root ($name+'/*')) -Destination $target -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $root 'App_Data/connection.txt') -Destination (Join-Path $Destination 'App_Data/connection.txt') -Force
& (Join-Path $PSScriptRoot 'Install-Security.ps1') -OutputDirectory (Join-Path $Destination 'App_Data/security')
if(-not (Test-Path 'IIS:\AppPools\PoliMusic')){New-WebAppPool -Name PoliMusic | Out-Null}
Set-ItemProperty 'IIS:\AppPools\PoliMusic' -Name managedRuntimeVersion -Value ''
Set-ItemProperty 'IIS:\AppPools\PoliMusic' -Name managedPipelineMode -Value Integrated
Set-ItemProperty 'IIS:\AppPools\PoliMusic' -Name enable32BitAppOnWin64 -Value $false
if(-not $existing){New-WebApplication -Site $SiteName -Name $ApplicationName -PhysicalPath $Destination -ApplicationPool PoliMusic | Out-Null}
else{Set-ItemProperty ('IIS:\Sites\'+$SiteName+'\'+$ApplicationName) -Name applicationPool -Value PoliMusic}
$location=$SiteName+'/'+$ApplicationName
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/asp' -Name scriptErrorSentToBrowser -Value $false
# Avoids JScript engine reuse failures on affected Windows 11 / Server builds.
# The engine cache is process-wide, so the server default also has to be zero.
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/asp/cache' -Name scriptEngineCacheMax -Value 0
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/asp/cache' -Name scriptFileCacheSize -Value 0
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/asp/cache' -Name scriptEngineCacheMax -Value 0
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/asp/cache' -Name scriptFileCacheSize -Value 0
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/asp/comPlus' -Name executeInMta -Value $true
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/asp/session' -Name timeout -Value '00:30:00'
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $location -Filter 'system.webServer/security/authentication/anonymousAuthentication' -Name userName -Value ''
$identity='IIS AppPool\PoliMusic'
$acl=Get-Acl -LiteralPath $Destination
$rule=New-Object Security.AccessControl.FileSystemAccessRule($identity,'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
$acl.SetAccessRule($rule);Set-Acl -LiteralPath $Destination -AclObject $acl
$private=Join-Path $Destination 'App_Data'
$acl=Get-Acl -LiteralPath $private;$acl.SetAccessRuleProtection($true,$false)
foreach($sid in @('S-1-5-18','S-1-5-32-544')){
    $account=New-Object Security.Principal.SecurityIdentifier($sid)
    $rule=New-Object Security.AccessControl.FileSystemAccessRule($account,'FullControl','ContainerInherit,ObjectInherit','None','Allow');$acl.SetAccessRule($rule)
}
$account=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$rule=New-Object Security.AccessControl.FileSystemAccessRule($account,'FullControl','ContainerInherit,ObjectInherit','None','Allow');$acl.SetAccessRule($rule)
$rule=New-Object Security.AccessControl.FileSystemAccessRule($identity,'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow');$acl.SetAccessRule($rule)
Set-Acl -LiteralPath $private -AclObject $acl
[IO.File]::WriteAllText($marker,'PoliMusic Classic ASP deployment')
if((Get-WebAppPoolState PoliMusic).Value -eq 'Started'){Stop-WebAppPool PoliMusic}
Start-WebAppPool PoliMusic
$url='http://localhost/'+$ApplicationName+'/'
$response=Invoke-WebRequest ($url+'login.asp') -UseBasicParsing
if($response.StatusCode -ne 200){throw 'La verificación HTTP del despliegue falló.'}
$session=Invoke-RestMethod ($url+'api.asp?action=session')
if(-not $session.csrf){throw 'No se pudo verificar la conexión ASP/SQL Server.'}
$asset=Invoke-WebRequest ($url+'assets/auth.js') -UseBasicParsing
if($asset.RawContentLength -lt 100 -or $asset.Headers['Content-Type'] -notmatch 'javascript'){throw 'IIS no esta sirviendo JavaScript. Comprueba IIS-StaticContent.'}
Write-Output "PoliMusic desplegado: $url"
Write-Output "Carpeta física: $Destination"
} catch {
    if($restorePoolOnFailure -and (Test-Path 'IIS:\AppPools\PoliMusic') -and (Get-WebAppPoolState PoliMusic).Value -ne 'Started'){
        try { Start-WebAppPool PoliMusic } catch { Write-Warning 'No se pudo reanudar el pool de PoliMusic.' }
    }
    throw
} finally { Stop-Transcript | Out-Null }
