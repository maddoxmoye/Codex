import { Game, SHOP, WORLD, REGIONS, regionAt, advanceGame, ELEMENTS } from './game.js';
import { create3DRenderer } from './render3d.js';
import { create2DRenderer } from './render2d.js';
const $ = id => document.getElementById(id);
let canvas=$('arena'), view;
const game=new Game();
let graphics='3d';
// Start every visit in 3D, including browsers with an older saved 2D preference.
try { localStorage.removeItem('wildfall-graphics'); } catch {}
let cameraFree=false, quality=window.innerWidth<700?'low':'high';
try { cameraFree=localStorage.getItem('wildfall-camera-mode')==='free';quality=localStorage.getItem('wildfall-quality')||quality; } catch {}
const keys=new Set(); let previous=performance.now(),shown='',sound=false,audio,toastTimer;
let best=0;try{best=Number(localStorage.getItem('wildfall-best'))||0;}catch{}
function beep(freq=440,duration=.1,type='sine',volume=.025){if(!sound)return;try{audio ||= new AudioContext();const o=audio.createOscillator(),g=audio.createGain();o.type=type;o.frequency.value=freq;g.gain.setValueAtTime(volume,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+duration);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+duration);}catch{}}
function toast(text){$('toast').textContent=text;$('toast').classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('visible'),3200);}
function start(){keys.clear();game.start();shown='';lastBoss=0;canvas.focus();beep(550,.2);}
function pause(){if(game.state==='playing')game.state='paused';else if(game.state==='paused')game.state='playing';keys.clear();}
function shop(){if(game.state==='shop')game.closeShop();else if(!game.openShop())toast('Begin your journey to visit the shop.');keys.clear();}
$('shop-button').onclick=shop;$('pause-button').onclick=pause;
$('sound').onclick=()=>{sound=!sound;$('sound').textContent=sound?'SOUND ON':'SOUND OFF';$('sound').setAttribute('aria-label',sound?'Disable sound':'Enable sound');beep(660);};
window.addEventListener('keydown',e=>{
 if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code))e.preventDefault();
 keys.add(e.code);if(e.repeat)return;
 if(e.code==='KeyC')toggleCamera();
 if(e.code==='Digit0')requestElement('physical');
 if(e.code==='KeyF')game.interact();
 if(e.code==='Digit1')requestElement('fire');if(e.code==='Digit2')requestElement('ice');if(e.code==='Digit3')requestElement('poison');
 if(e.code==='Space')game.dash();if(e.code==='KeyE')game.nova();if(e.code==='KeyB')shop();if(e.code==='Escape'){if(game.state==='shop')game.closeShop();else pause();}
});
window.addEventListener('keyup',e=>keys.delete(e.code));
window.addEventListener('blur',()=>{keys.clear();if(game.state==='playing')game.state='paused';});
document.addEventListener('visibilitychange',()=>{if(document.hidden){keys.clear();if(game.state==='playing')game.state='paused';}});
for(const b of document.querySelectorAll('[data-move]')){const key={left:'ArrowLeft',right:'ArrowRight',up:'ArrowUp',down:'ArrowDown'}[b.dataset.move];b.onpointerdown=e=>{e.preventDefault();b.setPointerCapture(e.pointerId);keys.add(key);};b.onpointerup=b.onpointercancel=()=>keys.delete(key);}
$('touch-interact').onclick=()=>game.interact();
function updateCameraLabel(){
 $('camera-mode').textContent='Camera: '+(cameraFree?'Free':'Locked');$('camera-mode').setAttribute('aria-pressed',String(cameraFree));
 $('camera-mode').title=cameraFree?'Move the pointer over the game to look. Press C to lock.':'Right-drag to look. Press C for free mouse look.';
}
function toggleCamera(){cameraFree=!cameraFree;updateCameraLabel();try{localStorage.setItem('wildfall-camera-mode',cameraFree?'free':'locked');}catch{}if(game.state==='playing')canvas.focus();}
$('camera-mode').onclick=toggleCamera;
$('detail-button').onclick=()=>{quality=quality==='high'?'low':'high';view.setQuality?.(quality);$('detail-button').textContent='Detail: '+(quality==='high'?'High':'Low');try{localStorage.setItem('wildfall-quality',quality);}catch{}};
$('orbit-left').onclick=()=>view.orbit?.(-Math.PI/6);$('orbit-right').onclick=()=>view.orbit?.(Math.PI/6);
let requestedShopTab=null, shopTab='general',spendFree=false,shownShopRevision=-1;
function requestElement(element){
 if(element===game.player.element)return;
 if(element==='physical'){toast('Attunement replaces physical arrows · swap elements in the shop');return;}
 if(game.state==='shop'){shopTab='element';renderShop();return;}
 if(game.openShop('swap')){requestedShopTab='element';shown='';keys.clear();}
 else toast('Begin your journey before choosing an element');
}
for(const button of document.querySelectorAll('[data-element]'))button.onclick=()=>requestElement(button.dataset.element);
$('touch-dash').onpointerdown=e=>{e.preventDefault();game.dash();};$('touch-ability').onpointerdown=e=>{e.preventDefault();game.nova();};
function modal(html,cls=''){ $('overlay').hidden=false;$('overlay').innerHTML=`<div class="modal ${cls}">${html}</div>`; }
function showState(){
 const state=game.state,entering=shown!==state;if(!entering&&!(state==='shop'&&shownShopRevision!==game.shopRevision))return;shown=state;
 $('pause-button').textContent=state==='paused'?'Resume · Esc':'Pause · Esc';
 if(state==='playing'){$('overlay').hidden=true;canvas.focus();return;}
 if(state==='title'){
 modal(`<div class="crest">✧</div><div class="eyebrow">THE RANGER’S JOURNEY</div><h2>Beyond the clearing</h2><p>Roam the woods, frozen ruins, ember hills, and venom marsh. Fight as an archer, discover chests, tame companions, and commit to an elemental build. Level up for free shop picks and prepare between waves.</p><button class="button" id="begin">Begin your journey &nbsp; →</button><p class="subtext">WASD to move · C for free mouse look · F to open chests<br>Your bow automatically targets nearby enemies. Bosses arrive on waves 3, 6, and 9.${best?`<br>Personal best: ${best} enemies defeated`:''}</p>`);
 $('begin').onclick=start;
 }else if(state==='paused'){
 modal('<div class="crest">☾</div><div class="eyebrow">TAKE A BREATH</div><h2>The forest can wait.</h2><p>Your journey is paused. Come back when your spark is ready.</p><div class="modal-actions"><button class="button" id="resume">Keep wandering</button><button class="button secondary" id="paused-shop">Visit shop</button></div>');$('resume').onclick=pause;$('paused-shop').onclick=shop;
 }else if(state==='shop'){if(entering){shopTab=requestedShopTab||'general';requestedShopTab=null;spendFree=game.freePicks>0;}renderShop();}
 else if(state==='dead'||state==='won'){
 best=Math.max(best,game.player.kills);try{localStorage.setItem('wildfall-best',String(best));}catch{}
 const won=state==='won';modal(`<div class="crest">${won?'✧':'☾'}</div><div class="eyebrow">${won?'THE HOLLOW IS FREE':'EVERY SPARK LEAVES A STORY'}</div><h2>${won?'You brought the dawn.':'The wild remembers.'}</h2><p>${won?'All three guardians have fallen. The forest is quiet once more.':'Rest, Wayfarer. The woods will be waiting for your next journey.'}</p><p>Wave ${game.wave} &nbsp; · &nbsp; Level ${game.player.level} &nbsp; · &nbsp; ${game.player.kills} defeated<br>${game.bossesDefeated} / 3 guardians &nbsp; · &nbsp; Best: ${best} defeated</p><button id="restart" class="button">${won?'Wander again':'Try again'} &nbsp; →</button><p class="subtext">Coins and upgrades reset each run. Your best score is saved.</p>`);$('restart').onclick=start;
 }
}
function renderShop(){
 const oldTab=document.querySelector('.shop-tabs .selected')?.dataset.tab,oldScroll=document.querySelector('.shop-catalog')?.scrollTop||0;
 shownShopRevision=game.shopRevision;
 const p=game.player,element=ELEMENTS[p.element],rank=p.elementUpgrades;
 const free=spendFree&&game.freePicks>0;
 const card=item=>{
   const offer=game.offer(item),disabled=!offer.available||(!free&&p.coins<offer.price);
   const label=!offer.available?offer.reason:free?'✧ USE FREE PICK':`◈ ${offer.price} GOLD`;
   return `<button class="shop-card ${item.category==='affinity'?'affinity-card':''}" data-buy="${item.id}" ${disabled?'disabled':''}><span class="card-symbol">${item.icon}</span><strong>${item.name}${item.category==='element'?` · ${offer.rank}/${item.max}`:''}</strong><small>${item.text}</small><span class="price">${label}</span></button>`;
 };
 const title=game.shopReason==='wave'?`Wave ${game.wave} cleared`:game.shopReason==='levelup'?`Level ${p.level} reached`:game.shopReason==='swap'?'Choose your attunement':"Wanderer's shop";
 modal(`<div class="eyebrow">REST · PREPARE · GROW</div><h2>${title}</h2><div class="shop-player-stats"><span>LEVEL <b id="shop-level">${p.level}</b></span><span>◈ <b>${p.coins.toLocaleString()}</b> GOLD</span><span>✧ <b id="shop-free-picks">${game.freePicks}</b> FREE PICKS</span></div><div class="shop-xp-line"><span>XP ${p.xp} / ${p.xpNext}</span><div><i style="width:${p.xp/p.xpNext*100}%"></i></div></div><div class="shop-build"><strong>${element?element.icon+' '+element.name:'➶ Physical'} build</strong><span>Shared elemental damage <b id="shop-element-base">${p.elementalDamage.toFixed(1)}</b></span><small>Element ranks: Power ${rank.power} · Duration ${rank.duration} · Ability ${rank.special}</small></div><div class="shop-payment"><button id="pay-free" ${game.freePicks?'':'disabled'} aria-pressed="${free}">Use free pick (${game.freePicks})</button><button id="pay-coins" aria-pressed="${!free}">Pay with gold</button></div><div class="shop-tabs"><button data-tab="general" class="${shopTab==='general'?'selected':''}">General</button><button data-tab="element" class="${shopTab==='element'?'selected':''}">Elements</button><button data-tab="pet" class="${shopTab==='pet'?'selected':''}">Companions</button></div><div class="shop-catalog">${shopTab==='element'?`<div class="swap-notice">One element at a time. Swapping removes the old element's ranks, effects and arrows. Shared elemental damage and general upgrades stay.</div><div class="shop-affinities">${SHOP.filter(i=>i.category==='affinity').map(card).join('')}</div>${element?`<div class="shop-category-label">${element.name.toUpperCase()} UPGRADES · ACTIVE ELEMENT ONLY</div>`:'<p class="shop-empty">Choose an attunement above to unlock its upgrades.</p>'}`:''}<div class="shop-grid">${SHOP.filter(i=>shopTab==='element'?i.category==='element'&&i.element===p.element:i.category===shopTab).map(card).join('')}</div></div><div class="shop-bottom"><span>${game.freePicks?'Unused free picks can be kept for later.':'Each new level grants one free pick.'}</span><button class="button" id="leave-shop">${game.pendingWave?'Begin wave '+game.pendingWave:'Continue journey'} &nbsp; →</button></div>`,'shop-modal');
 if(oldTab===shopTab)document.querySelector('.shop-catalog').scrollTop=oldScroll;
 for(const b of document.querySelectorAll('[data-buy]'))b.onclick=()=>{const item=SHOP.find(i=>i.id===b.dataset.buy);if(game.buy(b.dataset.buy,free)){if(item.category==='affinity')shopTab='element';if(!game.freePicks)spendFree=false;beep(880);renderShop();hud();}};
 for(const b of document.querySelectorAll('[data-tab]'))b.onclick=()=>{shopTab=b.dataset.tab;renderShop();};
 $('pay-free').onclick=()=>{spendFree=true;renderShop();};$('pay-coins').onclick=()=>{spendFree=false;renderShop();};
 $('leave-shop').onclick=()=>game.closeShop();
}
let lastBoss=0, bossBannerUntil=0;
function hud(){
 const p=game.player;
 $('hud-level').textContent='LV. '+p.level;$('hud-free-picks').textContent=game.freePicks+' free '+(game.freePicks===1?'pick':'picks');
 $('hud-health-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hud-health-fill').style.width=(p.hp/p.maxHp*100)+'%';
 $('hud-xp-text').textContent=`${p.xp} / ${p.xpNext}`;$('hud-xp-fill').style.width=(p.xp/p.xpNext*100)+'%';
 const hpMeter=$('hud-health-fill').parentElement,xpMeter=$('hud-xp-fill').parentElement;
 hpMeter.setAttribute('aria-valuenow',String(Math.ceil(p.hp)));hpMeter.setAttribute('aria-valuemax',String(p.maxHp));xpMeter.setAttribute('aria-valuenow',String(p.xp));xpMeter.setAttribute('aria-valuemax',String(p.xpNext));
 hpMeter.classList.toggle('critical',p.hp/p.maxHp<.3);
 $('hud-coins').textContent=p.coins.toLocaleString();$('hud-kills').textContent=p.kills+' defeated';$('hud-pets').textContent=game.pets.length+' companions';
 $('equipped-element').dataset.equipped=p.element;$('hud-element').textContent=p.element[0].toUpperCase()+p.element.slice(1);$('hud-element-icon').textContent={physical:'➶',fire:'ϟ',ice:'❄',poison:'☠'}[p.element];
 $('hud-dash').textContent=p.dashCooldown>0?p.dashCooldown.toFixed(1)+'s':'READY';$('hud-dash-fill').style.width=(1-p.dashCooldown/2.6)*100+'%';
 $('hud-burst').textContent=!p.nova?'LOCKED':p.novaCooldown>0?p.novaCooldown.toFixed(1)+'s':'READY';$('hud-burst-fill').style.width=(!p.nova?0:(1-p.novaCooldown/8)*100)+'%';
$('hp-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hp-fill').style.width=(p.hp/p.maxHp*100)+'%';$('xp-text').textContent=`${p.xp} / ${p.xpNext}`;$('xp-fill').style.width=(p.xp/p.xpNext*100)+'%';$('level-badge').textContent='LV. '+p.level;$('coins').textContent=p.coins;$('kills').textContent=p.kills;
 $('wave').textContent=`WAVE ${String(game.wave).padStart(2,'0')} / 09`;$('timer').textContent=String(Math.floor(game.time/60)).padStart(2,'0')+':'+String(Math.floor(game.time%60)).padStart(2,'0');
 $('phase').textContent=game.wave%3===0?'GUARDIAN ENCOUNTER':regionAt(p).name.toUpperCase();
 $('location').textContent=`${Math.round(p.x)}, ${Math.round(p.y)} · ${game.chests.filter(c=>c.opened).length}/24 caches`;
 const nearby=game.chests.some(c=>!c.opened&&Math.hypot(c.x-p.x,c.y-p.y)<85);$('interact-hint').hidden=!nearby||game.state!=='playing';
 $('weapon-description').textContent=`${Math.round(game.attackDamage())} hit · ${p.element}${p.multi?' · triple shot':''}`;
 $('dash-status').textContent=p.dashCooldown>0?`Recovering · ${p.dashCooldown.toFixed(1)}s`:'Ready · briefly invulnerable';
 $('pet-status').textContent=game.pets.length?game.pets.map(p=>p.kind==='fox'?'Forest fox':'Wild wolf').join(' + '):'Unlock companions in the shop';
 $('element-base-stat').textContent=p.elementalDamage.toFixed(1);$('element-rank-stat').textContent=`Power ${p.elementUpgrades.power} · Duration ${p.elementUpgrades.duration} · Ability ${p.elementUpgrades.special}`;
 for(const button of document.querySelectorAll('[data-element]')){const el=button.dataset.element,equipped=p.element===el;button.classList.toggle('equipped',equipped);button.classList.toggle('locked',!equipped);button.setAttribute('aria-pressed',String(equipped));button.title=equipped?'Currently equipped':el==='physical'?'Attunement replaces physical arrows':'Open shop to swap elements (clears old elemental ranks)';}
 minimap();
 $('active-status').textContent=!p.nova?'Unlock at level 2':p.novaCooldown>0?`Recharging · ${p.novaCooldown.toFixed(1)}s`:`Tier ${p.nova} · ${Math.round(game.attackDamage()+30*p.nova)} area damage`;
 const boss=game.enemies.find(e=>e.kind==='boss');$('boss-hud').hidden=!boss;
 if(boss && lastBoss!==game.wave){lastBoss=game.wave;bossBannerUntil=performance.now()+2600;$('boss-arrival-name').textContent=boss.name;$('boss-arrival-tip').textContent=['Dodge the charge. Strike while he recovers.','Keep moving between the frozen volleys.','Break through the summons. End the long night.'][boss.tier-1];beep(180,.5,'triangle');}
 $('boss-arrival').hidden=!boss || performance.now()>bossBannerUntil || game.state!=='playing';
 document.querySelector('.arena-panel').classList.toggle('boss-wave',!!boss);
 if(boss){$('boss-name').textContent=boss.name;$('boss-hp').textContent=`${Math.ceil(boss.hp)} / ${boss.maxHp}`;$('boss-fill').style.width=(boss.hp/boss.maxHp*100)+'%';}
 for(let i=1;i<=3;i++){const el=$('journey-'+i);el.classList.toggle('done',game.bossesDefeated>=i);el.querySelector('.journey-check').textContent=game.bossesDefeated>=i?'✓':'◇';}
}
function minimap(){
 const c=$('minimap'),m=c.getContext('2d'),sx=c.width/WORLD.width,sy=c.height/WORLD.height;
 m.fillStyle='#13291de8';m.fillRect(0,0,c.width,c.height);
 for(const r of REGIONS){m.fillStyle=r.color;m.beginPath();m.ellipse(r.x*sx,r.y*sy,r.r*sx,r.r*sy,0,0,Math.PI*2);m.fill();}
 for(const c of game.chests)if(!c.opened){m.fillStyle='#edd28a';m.fillRect(c.x*sx-1,c.y*sy-1,2,2);}
 for(const e of game.enemies)if(e.kind==='boss'){m.fillStyle='#f2a4d8';m.beginPath();m.arc(e.x*sx,e.y*sy,4,0,Math.PI*2);m.fill();}
 m.fillStyle='#fff6d2';m.beginPath();m.arc(game.player.x*sx,game.player.y*sy,3,0,Math.PI*2);m.fill();
}
let lastHud=-Infinity;
function frame(now){
 const dt=(now-previous)/1000;previous=now;
 if(game.state==='playing')view.orbit?.(((keys.has('KeyR')?1:0)-(keys.has('KeyQ')?1:0))*Math.min(.25,dt)*1.8);
 const x=(keys.has('KeyD')||keys.has('ArrowRight')?1:0)-(keys.has('KeyA')||keys.has('ArrowLeft')?1:0),y=(keys.has('KeyS')||keys.has('ArrowDown')?1:0)-(keys.has('KeyW')||keys.has('ArrowUp')?1:0);
 advanceGame(game,dt,view.movement?view.movement(x,y):{moveX:x,moveY:y});
 if(game.message){toast(game.message);game.message='';}if(game.event){beep(game.event==='hurt'?130:game.event==='boss'?880:440,.15);game.event=null;}
 view.render(now/1000);if(now-lastHud>=100 || shown!==game.state){hud();lastHud=now;}showState();requestAnimationFrame(frame);
}
function setGraphics(mode) {
  const wasPlaying = game.state === 'playing';
  view?.dispose();
  const replacement=canvas.cloneNode(false); canvas.replaceWith(replacement); canvas=replacement;
  try { view=mode==='3d'?create3DRenderer(canvas,game):create2DRenderer(canvas,game); graphics=mode; }
  catch (error) {
    console.warn('3D rendering unavailable; using the illustrated view.',error.message);
    const fallback=canvas.cloneNode(false);canvas.replaceWith(fallback);canvas=fallback;
    view=create2DRenderer(canvas,game);graphics='2d';toast('3D needs WebGL2 · switched to the illustrated view');
  }
  $('graphics-button').textContent=graphics==='3d'?'3D VIEW':'2D VIEW';
  $('graphics-button').setAttribute('aria-label',graphics==='3d'?'Switch to 2D graphics':'Switch to 3D graphics');
  view.setQuality?.(quality);$('detail-button').textContent='Detail: '+(quality==='high'?'High':'Low');
  updateCameraLabel();
  let pointer=null,drag=false;
  canvas.oncontextmenu=e=>e.preventDefault();
  canvas.onpointerdown=e=>{if(e.button===2){drag=true;pointer={x:e.clientX,y:e.clientY};canvas.setPointerCapture(e.pointerId);}};
  canvas.onpointermove=e=>{
    if(game.state==='playing' && (drag || (cameraFree&&e.pointerType==='mouse')) && pointer){
      const dx=e.clientX-pointer.x,dy=e.clientY-pointer.y;
      if(view.look)view.look(dx,dy);else view.orbit?.(dx*.006);
    }
    pointer={x:e.clientX,y:e.clientY};
  };
  canvas.onpointerup=canvas.onpointercancel=()=>{drag=false;pointer=null;};
  canvas.onpointerleave=()=>{if(!drag)pointer=null;};
  if (wasPlaying) canvas.focus();
}
$('graphics-button').onclick=()=>setGraphics(graphics==='3d'?'2d':'3d');
setGraphics(graphics);
requestAnimationFrame(frame);
