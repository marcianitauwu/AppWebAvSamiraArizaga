# Laboratorio 4 PoliMusic con arquitectura N Tier

Samira Arizaga · Aplicaciones Web Avanzadas · 4 de noviembre de 2026

La versión 3 implementa el catálogo musical con Web Forms y .NET Framework 4.8. La solución conserva la versión 2 y separa la presentación, las reglas de negocio, el acceso a SQL Server y las entidades en cuatro proyectos.

## Ejecutar

1. Abrir `SlnAppPoliMusic.slnx` con una versión de Visual Studio compatible con soluciones SLNX y el componente Desarrollo de ASP.NET y web.
2. Restaurar los paquetes NuGet si faltan. Los proyectos requieren el targeting pack de .NET Framework 4.8.
3. Verificar la conexión `BDD_PoliMusicConnectionString` en `WebAppPoliMusicV3/Web.config`. La base existente debe contener TBL_USER, TBL_SONG, TBL_ARTIST, TBL_PLAYER, TBL_ALBUM y TBL_TRACKLIST.
4. Establecer `WebAppPoliMusicV3` como proyecto de inicio y `Default.aspx` como página inicial. Ejecutar con IIS Express.
5. Iniciar sesión con una cuenta existente o crear una cuenta en SignUp. Desde Inicio, abrir Canciones.

## Capas

- `WebAppPoliMusicV3`: páginas Login, SignUp, Logout, Default y Song; diseño en Site.Master; usa BLL y EntityLayer.
- `BLL.PoliMusicV3`: búsqueda, escape de comodines, validación de identificadores y conversión de filas a entidades.
- `DAL.PoliMusicV3`: consultas SQL parametrizadas, lectura del catálogo y actualización del contador PLAYS.
- `EntityLayer.PoliMusicV3`: User, Song, constantes y utilidades compartidas.

La página web no referencia DAL ni ejecuta SQL. Las asociaciones de artistas y álbumes se agregan para devolver una sola fila por canción.

## Funcionalidad

El catálogo tiene búsqueda por canción, artista o álbum, paginación de ocho registros y reproducción HTML5 de archivos MP3 locales. El botón de reproducción consulta la entidad por ID, comprueba el archivo, incrementa PLAYS y carga el reproductor. Si el navegador bloquea el inicio automático, se usa el control de reproducción nativo.

El registro valida campos, correo, confirmación de contraseña, fecha y duplicados; permite foto JPG/PNG o imagen predeterminada. Logout elimina el ticket y la sesión. Tanto usuarios normales como administradores acceden a las páginas implementadas.

Los cuatro MP3 disponibles de la versión 2 se incorporaron a SongFiles. La base contiene también Dreams, pero no se encontró `bensound-dreams.mp3` en el proyecto: se muestra como archivo no disponible. Para habilitarla, colocar el archivo correcto en `WebAppPoliMusicV3/SongFiles` y añadirlo al proyecto como contenido. No se modificó el esquema de datos ni las cuentas existentes.

## Verificación

Compilaciones Debug y Release correctas. Se ejecutaron 16 pruebas de navegador contra IIS Express y SQL Server: protección de páginas, credenciales incorrectas, registro público, confirmación, fecha inválida, registro sin foto, duplicados, login válido, catálogo de cinco canciones, archivo ausente, búsqueda, limpieza, reproducción MP3 real, vista móvil, Inicio y Logout. Se utilizó una cuenta temporal de pruebas y se eliminó después.

Para repetir la comprobación de las capas y la compilación sin cambiar datos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Tests\Verify-PoliMusic.ps1
```

El taller se publica en el GitHub configurado en origin, según la indicación de la estudiante. El informe PDF incorpora las evidencias de ejecución y publicación.
