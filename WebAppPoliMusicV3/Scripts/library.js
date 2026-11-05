document.addEventListener('DOMContentLoaded', function () {
    var audio = document.querySelector('audio');
    var status = document.getElementById('playerStatus');
    if (!audio || !status) return;
    audio.addEventListener('playing', function () { status.textContent = 'Disfruta tu música.'; });
    audio.addEventListener('error', function () { status.textContent = 'No se pudo abrir el audio. Selecciona otra canción.'; });
    if (audio.getAttribute('autoplay') && audio.src) {
        var promise = audio.play();
        if (promise && promise.catch) promise.catch(function () { status.textContent = 'Pulsa el botón de reproducción para escuchar.'; });
    }
});