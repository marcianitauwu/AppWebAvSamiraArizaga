import {chromium} from '../.local/node_modules/playwright/index.mjs';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';

const base=process.env.POLIMUSIC_URL||'http://localhost:8091/';
const password=process.env.POLIMUSIC_TEST_PASSWORD;
if(!password)throw new Error('Set POLIMUSIC_TEST_PASSWORD.');
await fs.mkdir('.local/screenshots',{recursive:true});
const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const page=await browser.newPage({viewport:{width:1440,height:1000}});
const errors=[];page.on('pageerror',error=>errors.push(error.message));
page.on('response',async response=>{if(response.url().includes('api.asp')){const text=await response.text().catch(()=>'');if(text)try{JSON.parse(text);}catch{console.log('Invalid API JSON:',response.url(),response.status(),text.slice(0,1400));}}});
async function login(target,username){
    await target.goto(new URL('login.asp',base).href);await target.locator('#username').fill(username);await target.locator('#password').fill(password);
    await target.locator('#auth-submit').click();await target.waitForURL('**/default.asp',{timeout:30000});
    await target.locator('.hero').waitFor();
}
try{
    await page.goto(new URL('login.asp',base).href);await page.screenshot({path:'.local/screenshots/login-desktop.png',fullPage:true});
    await login(page,'userAdmin');assert.equal(await page.locator('[data-nav="admin"]').count(),1);
    await page.screenshot({path:'.local/screenshots/home-desktop.png',fullPage:true});
    await page.locator('.hero [data-play]').click();await page.waitForFunction(()=>{const a=document.querySelector('audio');return !a.paused&&a.currentTime>0;});
    await page.locator('#toggle-play').click();assert.ok(await page.locator('audio').evaluate(a=>a.paused));
    await page.locator('#queue-toggle').click();await page.locator('#queue-panel').waitFor({state:'visible'});await page.locator('#queue-close').click();
    await page.locator('#shuffle').click();assert.equal(await page.locator('#shuffle').getAttribute('aria-pressed'),'true');
    await page.locator('#repeat').click();assert.equal(await page.locator('#repeat').getAttribute('aria-pressed'),'true');
    await page.locator('#global-search').fill('Adventure');await page.waitForURL('**/default.asp#search');await page.locator('[data-song-row]').first().waitFor();assert.match(await page.locator('#content').textContent(),/Adventure/);
    await page.locator('#global-search').fill('zzzz_no_music_zzzz');await page.getByText('No encontramos coincidencias').waitFor();
    await page.goto(new URL('default.asp#admin/artists',base).href);await page.locator('[data-add]').waitFor();
    const title='QA Navegador '+Date.now();await page.locator('[data-add]').click();await page.locator('#editor').waitFor({state:'visible'});
    await page.locator('#field-name').fill(title);await page.locator('#field-lastname').fill('Prueba');await page.locator('#editor-save').click();await page.locator('#editor').waitFor({state:'hidden'});
    const row=page.locator('.admin-table tr').filter({hasText:title});await row.waitFor();
    await row.locator('[data-edit]').click();await page.locator('#field-lastname').fill('Editado');await page.locator('#editor-save').click();await page.locator('#editor').waitFor({state:'hidden'});
    await page.locator('.admin-table tr').filter({hasText:title}).locator('[data-delete]').click();await page.locator('#delete-confirm').click();await page.locator('#confirmation').waitFor({state:'hidden'});
    await page.locator('.admin-table tr').filter({hasText:title}).waitFor({state:'detached'});
    await page.screenshot({path:'.local/screenshots/admin-desktop.png',fullPage:true});
    await page.locator('#logout').click();await page.waitForURL('**/login.asp');
    const context=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true});const mobile=await context.newPage();
    mobile.on('pageerror',error=>errors.push(error.message));await login(mobile,'Samira.Arizaga');
    assert.equal(await mobile.locator('[data-nav="admin"]').count(),0);
    assert.ok(await mobile.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    await mobile.screenshot({path:'.local/screenshots/home-mobile.png',fullPage:true});
    await mobile.locator('#menu-toggle').click();await mobile.locator('[data-nav="albums"]').click();await mobile.locator('.music-card').first().waitFor();
    await mobile.locator('.music-card a').last().click();await mobile.locator('.collection-hero').waitFor();
    await mobile.goto(new URL('default.asp#admin/users',base).href);await mobile.getByText('Acceso restringido',{exact:true}).waitFor();
    await mobile.locator('#logout').click();await mobile.waitForURL('**/login.asp');
    await mobile.screenshot({path:'.local/screenshots/login-mobile.png',fullPage:true});
    assert.ok(await mobile.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    assert.deepEqual(errors,[]);console.log('PASS desktop/mobile UI, real audio playback, search, player controls, admin CRUD, RBAC and logout.');
}catch(error){await page.screenshot({path:'.local/screenshots/browser-failure.png',fullPage:true});console.log('Browser failure URL:',page.url());console.log('Visible page:',(await page.locator('body').innerText()).slice(0,2000));throw error;}finally{await browser.close();}
