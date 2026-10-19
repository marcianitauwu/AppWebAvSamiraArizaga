# PoliMusic · ASP clásico

Aplicación de música con diseño morado y turquesa adaptable, SQL Server y ASP clásico con **JScript del servidor**. No necesita ASP.NET, Node.js ni npm en producción. JavaScript del navegador controla la interfaz y el elemento HTML5 `audio`.

## Funciones

- Login, registro, logout y sesiones de 30 minutos. El registro siempre crea usuarios normales.
- Inicio, búsqueda de canciones/artistas/álbumes/playlists y páginas de detalle.
- Reproductor persistente al navegar: play/pausa, anterior/siguiente, progreso, volumen, silencio, cola, aleatorio y repetición.
- Administración con crear, consultar, editar y eliminar usuarios, canciones, artistas, álbumes y playlists, incluyendo sus relaciones.
- Rol `USER_TYPE=1`: administrador. Rol `USER_TYPE=0`: usuario normal. Cada endpoint comprueba el rol leyendo la cuenta actual de SQL Server.
- Playlists públicas para todos los usuarios autenticados; playlists privadas para su propietario y administradores.
- PBKDF2-SHA256 con sal aleatoria y 600.000 iteraciones, consultas ADO parametrizadas, CSRF, límite de intentos de login, transacciones, validación de rutas y protección de archivos internos.

## Estado de los datos recibidos

Se utilizó la base existente `BDD_PoliMusic` en `localhost` y sus tablas `TBL_*`. El archivo mencionado `BDD_PoliMusic.sql` no estaba en la carpeta; `database/000-schema.sql` documenta el esquema observado y permite crear las tablas en una base vacía. `database/001-security.sql` agrega únicamente tablas auxiliares de credenciales, límites de acceso y tickets de sesión, e índices únicos de usuario/correo.

Las contraseñas originales se migran a `PM_CREDENTIAL`; `TBL_USER.PASSWORD` pasa a contener `[PBKDF2]`. La aplicación de consola anterior deberá adaptarse si comparaba contraseñas en texto plano. No se eliminaron los registros existentes. El instalador conserva las contraseñas migradas salvo que se indique `-ResetDemoPasswords` explícitamente.

Las cuentas de esta entrega son `userAdmin` (administrador) y `Samira.Arizaga` (usuario normal). La contraseña existente de `Samira.Arizaga` se conserva. Las credenciales no se incluyen en el paquete ZIP ni en archivos versionados.

Los recursos contienen **un solo MP3: `bensound-adventure.mp3`**. Las otras canciones existentes conservan sus datos y aparecen como «No disponible». No se sustituye su audio por otra canción. Las portadas de álbumes/artistas ausentes usan SVG propios de PoliMusic; las imágenes de playlists suministradas se utilizan donde existen.

## Requisitos

- Windows con IIS y la característica **ASP** e **ISAPI Extensions**.
- SQL Server con `BDD_PoliMusic` y el login SQL configurado.
- Microsoft OLE DB Driver for SQL Server, proveedor **MSOLEDBSQL** de 64 bits.
- .NET Framework 4.8, usado exclusivamente por el pequeño componente COM `PoliMusic.Security` para calcular PBKDF2 con rendimiento nativo. La aplicación web continúa siendo ASP clásico.
- Navegador moderno con JavaScript. Para acceso desde otras computadoras, configura el binding del sitio y HTTPS en IIS.

## Configurar la base en otra instalación

Abre PowerShell en la carpeta del proyecto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
$sqlPassword = Read-Host 'Contraseña de SQL Server' -AsSecureString
$demoPassword = Read-Host 'Contraseña para las cuentas demo que falten' -AsSecureString
.\scripts\Initialize-Database.ps1 -SqlServer localhost -Database BDD_PoliMusic `
  -SqlUser usr_polimusic -SqlPassword $sqlPassword -DemoPassword $demoPassword
```

Si la base está vacía, importa primero `database/000-schema.sql` en la base `BDD_PoliMusic`. El instalador necesita permisos para crear las tablas auxiliares y migrar datos. No crea ni modifica logins SQL Server.

Se generan `App_Data/database.json` para mantenimiento y `App_Data/connection.txt` para ADO. Ambos están excluidos de Git y bloqueados por IIS. La cadena utiliza cifrado y `Trust Server Certificate=True` para el SQL Server local de pruebas. En un servidor con certificado válido configura la confianza y desactiva esa excepción.

## Ejecutar con IIS Express

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Install-Security.ps1 -CurrentUser
.\scripts\Start-Local.ps1 -Port 8091
```

Abre **http://localhost:8091/**. Instala y ejecuta IIS Express bajo el mismo usuario de Windows para que pueda activar el componente COM. El modo `-CurrentUser` registra solo el ProgID y CLSID de PoliMusic en ese usuario; para IIS se usa el registro de máquina del despliegue.

## Desplegar en IIS

El destino predeterminado respeta la carpeta solicitada: **`C:\intentpub\wwwroot\PoliMusic`**. La ruta convencional de IIS en esta computadora es `C:\inetpub\wwwroot`; puedes elegirla pasando `-Destination`. La aplicación virtual se llama `PoliMusic`, independientemente de su carpeta física.

En **PowerShell como administrador**, desde el proyecto ya configurado:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Deploy-IIS.ps1
```

Desde una terminal sin elevar puedes ejecutar `.\scripts\Deploy-IIS.ps1 -Elevate`; Windows mostrará el aviso UAC de administrador. El registro de instalación queda en `.local/deployment.log`.

El script copia solo archivos de ejecución, registra el componente criptográfico de 64 bits dentro de `App_Data/security`, crea un pool `PoliMusic` sin CLR administrado y la aplicación `/PoliMusic` en `Default Web Site`, configura ASP y permisos de lectura, protege los archivos privados y comprueba HTTP y SQL Server. El proceso web no necesita escribir en el proyecto. No altera el contenido de otras aplicaciones. Si el destino contiene archivos ajenos, se detiene; en despliegues sucesivos hace una copia previa en `deploy/`.

Dirección esperada: **http://localhost/PoliMusic/**.

Para el directorio convencional:

```powershell
.\scripts\Deploy-IIS.ps1 -Destination 'C:\inetpub\wwwroot\PoliMusic'
```

El instalador habilita las características de IIS para ASP y archivos estáticos. Para evitar los fallos de reutilización de JScript observados en esta versión de Windows, configura `scriptEngineCacheMax=0` y `scriptFileCacheSize=0` en el servidor y en la aplicación, y activa `comPlus.executeInMta` para PoliMusic. Los 30 minutos de sesión se establecen en `includes/core.asp`; `global.asa` queda vacío para evitar ejecutar eventos con el motor JScript en caché. Los valores globales también afectan la caché de otras aplicaciones ASP clásicas del servidor. No modifica el motor JScript ni sus políticas de Windows. [Referencia de la configuración de caché ASP](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/asp/cache), [configuración COM+ de ASP](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/asp/complus/).

## Recursos multimedia

Coloca los archivos nuevos en las subcarpetas de `SongFilesAndImages_resources`: `SongFiles`, `PlaylistImages`, `ArtistImages`, `AlbumImages` o `UserImages`. Después, selecciónalos en Administración. El formulario muestra solo archivos existentes. Las rutas antiguas `~/songFiles/...` y `~/playlistImages/...` también se reconocen. Las canciones se sirven mediante `stream.asp`, que comprueba la sesión y admite peticiones HTTP Range para adelantar y retroceder.

Solo el administrador puede modificar el catálogo; un usuario normal puede consultar y escuchar. El administrador puede editar la pertenencia de canciones a artistas/álbumes y el contenido de playlists. No puede eliminar su propia cuenta ni quitarse su rol. La eliminación de una cuenta elimina sus playlists y sus relaciones, y la eliminación de una canción elimina sus asociaciones, dentro de una transacción.

## Empaquetar

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Build-Package.ps1
```

Genera `deploy/PoliMusic-<fecha>.zip`, con recursos, código y scripts de instalación, **sin credenciales locales**. Después de extraerlo en otra computadora, configura su base y ejecuta el despliegue. No copies solo los `.asp`: también se necesitan `includes`, `assets`, recursos, `web.config` y la configuración protegida.

## Verificación

Las pruebas usan Node.js solo durante desarrollo:

```powershell
node tests/crypto.test.js
$env:POLIMUSIC_TEST_PASSWORD = Read-Host 'Contraseña de las cuentas demo'
node tests/integration.mjs
node tests/availability.mjs
```

`POLIMUSIC_URL` permite cambiar la URL base, por ejemplo `http://localhost/PoliMusic/`. La integración comprueba autenticación, roles, CSRF, archivos protegidos, playlists privadas, audio parcial, CRUD de las cinco entidades, relaciones, rollback, registro y logout. Crea registros temporales identificados con `QA` y los elimina al finalizar. La prueba de disponibilidad comprueba 60 solicitudes en grupos simultáneos, sin reintentar errores, para detectar los fallos intermitentes de ASP.

Para las pruebas visuales opcionales, instala Playwright en `.local` (`npm.cmd install --prefix .local --no-save playwright`) y ejecuta `node tests/browser.mjs`. Usa el Chrome existente de Windows y guarda capturas en `.local/screenshots`.

## Archivos principales

| Archivo | Función |
| --- | --- |
| `default.asp` | Aplicación autenticada y reproductor |
| `login.asp`, `register.asp` | Acceso y registro |
| `api.asp` | Autenticación, catálogo y CRUD con permisos |
| `welcome.asp` | Intercambio de ticket de login de un solo uso |
| `stream.asp` | Audio autenticado y HTTP Range |
| `includes/core.asp` | ADO, sesiones, validaciones y seguridad |
| `assets/app.js`, `assets/style.css` | Interfaz, navegación y reproductor |
| `scripts/PoliMusic.Security.cs` | PBKDF2 nativo expuesto como COM |
| `scripts/Deploy-IIS.ps1` | Instalación y comprobación de IIS |
