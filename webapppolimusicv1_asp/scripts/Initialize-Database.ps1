[CmdletBinding()]
param(
    [string]$SqlServer = 'localhost',
    [string]$Database = 'BDD_PoliMusic',
    [string]$SqlUser = 'usr_polimusic',
    [Security.SecureString]$SqlPassword,
    [Security.SecureString]$DemoPassword,
    [switch]$ResetDemoPasswords
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$configPath = Join-Path $root 'App_Data/database.json'
if (-not $SqlPassword -and (Test-Path -LiteralPath $configPath)) {
    $settings = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $SqlServer = $settings.server; $Database = $settings.database; $SqlUser = $settings.user
    $SqlPassword = ConvertTo-SecureString $settings.password -AsPlainText -Force
}
if (-not $SqlPassword) { $SqlPassword = Read-Host 'Contraseña del login SQL Server' -AsSecureString }
$credential = New-Object System.Management.Automation.PSCredential($SqlUser, $SqlPassword)
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $SqlServer; $builder['Initial Catalog'] = $Database
$builder['User ID'] = $SqlUser; $builder['Password'] = $credential.GetNetworkCredential().Password
$builder['Encrypt'] = $true; $builder['TrustServerCertificate'] = $true
$cn = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$transaction = $null
function Invoke-Db([string]$Sql, [object[]]$Values = @(), [switch]$Scalar) {
    $cmd = $cn.CreateCommand(); $cmd.CommandTimeout = 60; $cmd.Transaction = $script:transaction
    $cmd.CommandText = $Sql
    for ($i=0; $i -lt $Values.Count; $i++) { [void]$cmd.Parameters.AddWithValue('@p'+$i, $Values[$i]) }
    if ($Scalar) { return $cmd.ExecuteScalar() }
    [void]$cmd.ExecuteNonQuery()
}
function Save-Hash([int]$Id, [string]$Password) {
    $salt = New-Object byte[] 16
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create(); $rng.GetBytes($salt); $rng.Dispose()
    $derive = [Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, 600000, [Security.Cryptography.HashAlgorithmName]::SHA256)
    $hash = [BitConverter]::ToString($derive.GetBytes(32)).Replace('-','').ToLowerInvariant(); $derive.Dispose()
    $saltHex = [BitConverter]::ToString($salt).Replace('-','').ToLowerInvariant()
    Invoke-Db 'DELETE FROM PM_CREDENTIAL WHERE ID_USER=@p0' @($Id)
    Invoke-Db 'INSERT PM_CREDENTIAL(ID_USER,SALT,PASSWORD_HASH,ITERATIONS) VALUES(@p0,@p1,@p2,600000)' @($Id,$saltHex,$hash)
    Invoke-Db "UPDATE TBL_USER SET PASSWORD='[PBKDF2]' WHERE ID_USER=@p0" @($Id)
}
try {
    $cn.Open()
    if (-not (Invoke-Db "SELECT OBJECT_ID('dbo.TBL_USER','U')" -Scalar)) { throw 'No existe el esquema de PoliMusic. Importa primero BDD_PoliMusic.sql.' }
    $transaction = $cn.BeginTransaction()
    Invoke-Db (Get-Content (Join-Path $root 'database/001-security.sql') -Raw)
    $cmd = $cn.CreateCommand(); $cmd.Transaction = $transaction
    $cmd.CommandText = 'SELECT u.ID_USER,u.PASSWORD FROM TBL_USER u LEFT JOIN PM_CREDENTIAL c ON c.ID_USER=u.ID_USER WHERE c.ID_USER IS NULL'
    $reader = $cmd.ExecuteReader(); $legacy = New-Object System.Data.DataTable; $legacy.Load($reader)
    foreach ($row in $legacy.Rows) { Save-Hash $row.ID_USER $row.PASSWORD }
    # Demo credentials are supplied by the caller, never embedded in tracked source.
    $demoPlain = if ($DemoPassword) { (New-Object System.Management.Automation.PSCredential('demo',$DemoPassword)).GetNetworkCredential().Password } else { $null }
    foreach ($account in @(@{name='userAdmin';email='admin@polimusic.local';role=1},@{name='Samira.Arizaga';email='samira.arizaga@epn.edu.ec';role=0})) {
        $id = Invoke-Db 'SELECT ID_USER FROM TBL_USER WHERE USERNAME=@p0' @($account.name) -Scalar
        if (-not $id) {
            if (-not $demoPlain) { throw 'Se necesita -DemoPassword para crear las cuentas de demostración que faltan.' }
            $id = Invoke-Db "INSERT TBL_USER(USERNAME,PASSWORD,EMAIL,USER_TYPE) OUTPUT INSERTED.ID_USER VALUES(@p0,'[PBKDF2]',@p1,@p2)" @($account.name,$account.email,$account.role) -Scalar
            Save-Hash $id $demoPlain
        } elseif ($ResetDemoPasswords -and $demoPlain) { Save-Hash $id $demoPlain }
        Invoke-Db 'UPDATE TBL_USER SET USER_TYPE=@p0 WHERE ID_USER=@p1' @($account.role,[int]$id)
    }
    $transaction.Commit(); $transaction = $null
    New-Item -ItemType Directory -Force (Join-Path $root 'App_Data') | Out-Null
    $settings = @{server=$SqlServer;database=$Database;user=$SqlUser;password=$credential.GetNetworkCredential().Password}
    [IO.File]::WriteAllText($configPath, ($settings | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    $ole = New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $ole['Provider']='MSOLEDBSQL'; $ole['Data Source']=$SqlServer
    $ole['Initial Catalog']=$Database; $ole['User ID']=$SqlUser; $ole['Password']=$credential.GetNetworkCredential().Password
    $ole['Use Encryption for Data']='True'; $ole['Trust Server Certificate']='True'
    [IO.File]::WriteAllText((Join-Path $root 'App_Data/connection.txt'), $ole.ConnectionString, [Text.Encoding]::ASCII)
    Write-Output 'Base de datos preparada. Se conservaron los registros y se migraron las contraseñas a PBKDF2-SHA256 (600000 iteraciones).'
} catch {
    if ($transaction) { $transaction.Rollback() }
    throw
} finally { $cn.Dispose() }
