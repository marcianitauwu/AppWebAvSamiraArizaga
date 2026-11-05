# Ejecutar con Windows PowerShell 5.1 desde cualquier directorio.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
if (!$msbuild) { throw 'Instala Visual Studio con desarrollo web ASP.NET y .NET Framework 4.8.' }
& $msbuild (Join-Path $root 'WebAppPoliMusicV3\WebAppPoliMusicV3.csproj') /t:Build /p:Configuration=Debug /v:minimal /nologo
if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación.' }
$bin = Join-Path $root 'WebAppPoliMusicV3\bin'
Add-Type -Path (Join-Path $bin 'EntityLayer.PoliMusicV3.dll')
Add-Type -Path (Join-Path $bin 'DAL.PoliMusicV3.dll')
Add-Type -Path (Join-Path $bin 'BLL.PoliMusicV3.dll')
[xml]$config = Get-Content (Join-Path $root 'WebAppPoliMusicV3\Web.config')
$connection = ($config.configuration.connectionStrings.add | Where-Object name -eq 'BDD_PoliMusicConnectionString').connectionString
$service = New-Object BLL.PoliMusicV3.Song($connection)
$songs = $service.Read()
if ($songs.Rows.Count -ne ($songs.Rows | Group-Object ID_SONG).Count) { throw 'La consulta duplica canciones.' }
if ($null -ne $service.ReadById(0)) { throw 'Se aceptó un ID inválido.' }
if ($service.RegisterPlay(0) -ne 0) { throw 'Se aceptó una reproducción con ID inválido.' }
if ($service.Search($null).Rows.Count -ne $songs.Rows.Count) { throw 'La búsqueda vacía no devolvió el catálogo.' }
if ([BLL.PoliMusicV3.Song]::BuildLikePattern('100%_[') -ne '%100[%][_][[]%') { throw 'No se escaparon los comodines LIKE.' }
if ($songs.Rows.Count -gt 0) {
    $id = [int]$songs.Rows[0].ID_SONG
    if ($service.ReadById($id).ID -ne $id) { throw 'No se recuperó la entidad solicitada.' }
}
Write-Host ('OK: compilación, acceso SQL, unicidad, entidades, búsqueda y validación de ID. Canciones: ' + $songs.Rows.Count)
