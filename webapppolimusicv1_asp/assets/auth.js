'use strict';
const form = document.querySelector('#auth-form');
const message = document.querySelector('#auth-message');
const submit = document.querySelector('#auth-submit');
let csrf;
async function loadSession() {
    const response = await fetch('api.asp?action=session', {cache:'no-store'});
    const data = await response.json();
    if (!response.ok) throw new Error(data.error);
    if (data.user) { location.replace('default.asp'); return; }
    csrf = data.csrf;
}
loadSession().catch(error => {message.textContent=error.message;message.className='form-message error';});
document.querySelector('.password-toggle').addEventListener('click', event => {
    const input = document.querySelector('#password'), button = event.currentTarget;
    input.type = input.type==='password'?'text':'password';
    button.setAttribute('aria-label',input.type==='password'?'Mostrar contraseña':'Ocultar contraseña');
    button.setAttribute('aria-pressed',String(input.type==='text'));
});
form.addEventListener('submit', async event => {
    event.preventDefault(); message.textContent=''; submit.disabled=true;submit.setAttribute('aria-busy','true');
    const original=submit.innerHTML;submit.textContent='Un momento…';
    try {
        if(!csrf) await loadSession();
        const body = new URLSearchParams(new FormData(form));body.set('csrf',csrf);
        const response = await fetch(form.action,{method:'POST',body});
        const data = await response.json();if(!response.ok)throw new Error(data.error);
        if(data.redirect){location.replace(data.redirect);return;}
        message.className='form-message success';message.textContent=data.message;
        form.reset();setTimeout(()=>location.assign('login.asp'),1600);
    } catch(error) {message.className='form-message error';message.textContent=error.message||'No se pudo conectar con PoliMusic.';submit.disabled=false;}
    finally {submit.innerHTML=original;submit.removeAttribute('aria-busy');}
});
