/* =====================================================================
   PoliMusic - polimusic.js
   Controla el reproductor HTML5 de Song.aspx.
   Escrito en ES5 (sin dependencias) para funcionar en cualquier navegador
   compatible con ASP.NET Web Forms / .NET Framework 2.0.
   ===================================================================== */
(function () {
    "use strict";

    var player = null;
    var audio = null;
    var btnToggle = null;
    var progress = null;
    var progressFill = null;
    var progressKnob = null;
    var elCurrent = null;
    var elDuration = null;
    var volume = null;
    var volumeFill = null;
    var btnMute = null;
    var hfTime = null;
    var hfPlaying = null;

    var lastPersistedSecond = -1;
    var isSeeking = false;
    var lastVolume = 0.8;

    /* ---------- utilidades ---------- */

    function byId(id) {
        var el = document.getElementById(id);
        if (el) {
            return el;
        }
        // Respaldo por si ASP.NET cambia el ClientID del control.
        var inputs = document.getElementsByTagName("input");
        for (var i = 0; i < inputs.length; i++) {
            var idAttr = inputs[i].id || "";
            if (idAttr.length >= id.length && idAttr.substring(idAttr.length - id.length) === id) {
                return inputs[i];
            }
        }
        return null;
    }

    function addClass(el, name) {
        if (!el) { return; }
        if (el.classList) {
            el.classList.add(name);
            return;
        }
        if ((" " + el.className + " ").indexOf(" " + name + " ") < 0) {
            el.className += " " + name;
        }
    }

    function removeClass(el, name) {
        if (!el) { return; }
        if (el.classList) {
            el.classList.remove(name);
            return;
        }
        el.className = (" " + el.className + " ").replace(" " + name + " ", " ").replace(/^\s+|\s+$/g, "");
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0) {
            seconds = 0;
        }
        var total = Math.floor(seconds);
        var minutes = Math.floor(total / 60);
        var rest = total % 60;
        return minutes + ":" + (rest < 10 ? "0" : "") + rest;
    }

    function clamp(value, min, max) {
        if (value < min) { return min; }
        if (value > max) { return max; }
        return value;
    }

    function ratioFromEvent(element, ev) {
        var rect = element.getBoundingClientRect();
        if (!rect.width) {
            return 0;
        }
        var clientX = ev.touches && ev.touches.length ? ev.touches[0].clientX : ev.clientX;
        return clamp((clientX - rect.left) / rect.width, 0, 1);
    }

    /* ---------- estado persistente ---------- */

    function persistState() {
        if (!audio) { return; }

        if (hfPlaying) {
            hfPlaying.value = audio.paused ? "0" : "1";
        }

        if (hfTime) {
            var second = Math.floor(audio.currentTime || 0);
            // Solo se escribe cuando cambia el segundo para no saturar.
            if (second !== lastPersistedSecond) {
                lastPersistedSecond = second;
                hfTime.value = (audio.currentTime || 0).toFixed(2);
            }
        }
    }

    /* ---------- interfaz ---------- */

    function updateProgressUI() {
        if (!audio) { return; }

        var duration = audio.duration;
        var current = audio.currentTime || 0;
        var ratio = (isFinite(duration) && duration > 0) ? (current / duration) : 0;
        var percent = clamp(ratio * 100, 0, 100);

        if (progressFill) {
            progressFill.style.width = percent + "%";
        }
        if (progressKnob) {
            progressKnob.style.left = percent + "%";
        }
        if (elCurrent) {
            elCurrent.textContent = formatTime(current);
        }
        if (elDuration) {
            elDuration.textContent = formatTime(duration);
        }
        if (progress) {
            progress.setAttribute("aria-valuenow", String(Math.round(percent)));
        }
    }

    function updateVolumeUI(value) {
        var percent = clamp(value * 100, 0, 100);
        if (volumeFill) {
            volumeFill.style.width = percent + "%";
        }
        if (volume) {
            volume.setAttribute("aria-valuenow", String(Math.round(percent)));
        }
        if (btnMute) {
            if (value === 0 || (audio && audio.muted)) {
                addClass(btnMute, "is-muted");
                btnMute.setAttribute("aria-label", "Activar sonido");
            } else {
                removeClass(btnMute, "is-muted");
                btnMute.setAttribute("aria-label", "Silenciar");
            }
        }
    }

    function setPlayingUI(playing) {
        if (playing) {
            addClass(player, "is-playing");
            if (btnToggle) { btnToggle.setAttribute("aria-label", "Pausar"); }
        } else {
            removeClass(player, "is-playing");
            if (btnToggle) { btnToggle.setAttribute("aria-label", "Reproducir"); }
        }
    }

    /* ---------- reproduccion ---------- */

    function playAudio() {
        if (!audio || !audio.src) { return; }

        var promise = audio.play();

        // Los navegadores modernos devuelven una promesa que puede rechazarse
        // si bloquean la reproduccion automatica.
        if (promise && typeof promise.catch === "function") {
            promise.catch(function () {
                setPlayingUI(false);
                persistState();
            });
        }
    }

    function togglePlay() {
        if (!audio || !audio.src) { return; }

        if (audio.paused) {
            playAudio();
        } else {
            audio.pause();
        }
    }

    function seekTo(ratio) {
        if (!audio || !isFinite(audio.duration) || audio.duration <= 0) { return; }
        audio.currentTime = clamp(ratio, 0, 1) * audio.duration;
        updateProgressUI();
    }

    /* ---------- eventos de puntero para las barras ---------- */

    function bindSlider(element, onRatio, onEnd) {
        if (!element) { return; }

        var active = false;

        function move(ev) {
            if (!active) { return; }
            onRatio(ratioFromEvent(element, ev));
            if (ev.cancelable) { ev.preventDefault(); }
        }

        function up() {
            if (!active) { return; }
            active = false;
            document.onmousemove = null;
            document.onmouseup = null;
            document.ontouchmove = null;
            document.ontouchend = null;
            if (onEnd) { onEnd(); }
        }

        function down(ev) {
            active = true;
            onRatio(ratioFromEvent(element, ev));
            if (ev.cancelable) { ev.preventDefault(); }

            document.onmousemove = move;
            document.onmouseup = up;
            document.ontouchmove = move;
            document.ontouchend = up;
        }

        element.onmousedown = down;
        element.ontouchstart = down;

        element.onkeydown = function (ev) {
            var key = ev.keyCode;
            if (key === 37 || key === 39) {
                if (ev.cancelable) { ev.preventDefault(); }
                var delta = (key === 39) ? 0.05 : -0.05;
                var current = parseFloat(element.getAttribute("aria-valuenow") || "0") / 100;
                onRatio(clamp(current + delta, 0, 1));
                if (onEnd) { onEnd(); }
            }
        };
    }

    /* ---------- inicializacion ---------- */

    function init() {
        player = byId("pmPlayer");
        audio = byId("pmAudio");

        if (!player || !audio) { return; }

        btnToggle = byId("pmToggle");
        progress = byId("pmProgress");
        progressFill = byId("pmProgressFill");
        progressKnob = byId("pmProgressKnob");
        elCurrent = byId("pmCurrent");
        elDuration = byId("pmDuration");
        volume = byId("pmVolume");
        volumeFill = byId("pmVolumeFill");
        btnMute = byId("pmMute");
        hfTime = byId("hfPlayerTime");
        hfPlaying = byId("hfPlayerPlaying");

        var config = window.PM_PLAYER || { src: "", autoplay: false, startTime: 0 };

        audio.volume = lastVolume;
        updateVolumeUI(lastVolume);
        updateProgressUI();

        if (!config.src) {
            addClass(player, "is-idle");
        } else {
            removeClass(player, "is-idle");
            audio.src = config.src;

            var startAt = Number(config.startTime) || 0;
            if (startAt > 0) {
                var applyStart = function () {
                    audio.removeEventListener("loadedmetadata", applyStart, false);
                    try {
                        audio.currentTime = startAt;
                    } catch (ignore) { /* posicion no valida */ }
                    updateProgressUI();
                };
                if (audio.addEventListener) {
                    audio.addEventListener("loadedmetadata", applyStart, false);
                }
            }

            if (config.autoplay) {
                playAudio();
            }
        }

        /* --- boton play / pausa --- */
        if (btnToggle) {
            btnToggle.onclick = function () {
                if (hasClass(player, "is-idle")) { return; }
                togglePlay();
            };
        }

        /* --- eventos del elemento audio --- */
        audio.addEventListener("play", function () {
            setPlayingUI(true);
            persistState();
        }, false);

        audio.addEventListener("pause", function () {
            setPlayingUI(false);
            persistState();
        }, false);

        audio.addEventListener("ended", function () {
            setPlayingUI(false);
            persistState();
        }, false);

        audio.addEventListener("timeupdate", function () {
            if (!isSeeking) {
                updateProgressUI();
            }
            persistState();
        }, false);

        audio.addEventListener("loadedmetadata", function () {
            updateProgressUI();
        }, false);

        audio.addEventListener("error", function () {
            setPlayingUI(false);
            persistState();
        }, false);

        /* --- barra de progreso --- */
        bindSlider(progress, function (ratio) {
            isSeeking = true;
            if (progressFill) { progressFill.style.width = (ratio * 100) + "%"; }
            if (progressKnob) { progressKnob.style.left = (ratio * 100) + "%"; }
            if (elCurrent && isFinite(audio.duration)) {
                elCurrent.textContent = formatTime(ratio * audio.duration);
            }
        }, function () {
            isSeeking = false;
        });

        if (progress) {
            progress.onclick = function (ev) {
                seekTo(ratioFromEvent(progress, ev));
            };
        }

        /* --- volumen --- */
        bindSlider(volume, function (ratio) {
            audio.muted = false;
            audio.volume = clamp(ratio, 0, 1);
            if (audio.volume > 0) { lastVolume = audio.volume; }
            updateVolumeUI(audio.volume);
            persistState();
        }, null);

        if (btnMute) {
            btnMute.onclick = function () {
                if (audio.volume === 0 && !audio.muted) {
                    audio.volume = lastVolume || 0.8;
                    audio.muted = false;
                } else {
                    audio.muted = !audio.muted;
                }
                updateVolumeUI(audio.muted ? 0 : audio.volume);
                persistState();
            };
        }

        /* --- atajos de teclado --- */
        document.onkeydown = function (ev) {
            if (ev.ctrlKey || ev.altKey || ev.metaKey) { return; }

            var target = ev.target || ev.srcElement;
            var tag = target && target.tagName ? target.tagName.toUpperCase() : "";
            // No se intercepta la barra espaciadora sobre controles del
            // formulario (botones, enlaces, campos): Web Forms los necesita.
            if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" ||
                    tag === "BUTTON" || tag === "A" ||
                    (target && target.isContentEditable)) {
                return;
            }

            if (ev.keyCode === 32) {
                if (hasClass(player, "is-idle")) { return; }
                if (ev.cancelable) { ev.preventDefault(); }
                togglePlay();
            }
        };

        /* --- guardar el estado antes de abandonar la pagina --- */
        window.onbeforeunload = function () {
            persistState();
        };
    }

    function hasClass(el, name) {
        if (!el) { return false; }
        if (el.classList) { return el.classList.contains(name); }
        return (" " + el.className + " ").indexOf(" " + name + " ") >= 0;
    }

    /* ---------- arranque ---------- */

    if (document.readyState === "complete" || document.readyState === "interactive") {
        window.setTimeout(init, 0);
    } else if (document.addEventListener) {
        document.addEventListener("DOMContentLoaded", init, false);
    } else {
        window.attachEvent("onload", init);
    }
})();
