import { Game, SHOP, WORLD, REGIONS, regionAt, advanceGame, ELEMENTS, CHARACTERS, isUnlocked, MYTHICAL_UPGRADES } from './game.js';
import { create3DRenderer } from './render3d.js';
import { create2DRenderer } from './render2d.js';
const $ = id => document.getElementById(id);
let canvas=$('arena'), view;
function readProgress(){try{return JSON.parse(localStorage.getItem('wildfall-unlocks'))||{};}catch{return {};}}
const game=new Game(Math.random,readProgress());
let savedProgressRevision=game.progressRevision,knownUnlocks=new Set(CHARACTERS.filter(c=>isUnlocked(c,game.progress)).map(c=>c.id));
function saveProgress(){try{localStorage.setItem('wildfall-unlocks',JSON.stringify(game.progress));}catch{}}
window.addEventListener('pagehide',saveProgress);
let graphics='3d';
// Start every visit in 3D, including browsers with an older saved 2D preference.
try { localStorage.removeItem('wildfall-graphics'); } catch {}
let cameraFree=false, quality=window.innerWidth<700?'low':'high';
try { cameraFree=localStorage.getItem('wildfall-camera-mode')==='free';quality=localStorage.getItem('wildfall-quality')||quality; } catch {}
const keys=new Set(); let previous=performance.now(),shown='',sound=false,audio,toastTimer;
let best=0;try{best=Number(localStorage.getItem('wildfall-best'))||0;}catch{}
function beep(freq=440,duration=.1,type='sine',volume=.025){if(!sound)return;try{audio ||= new AudioContext();const o=audio.createOscillator(),g=audio.createGain();o.type=type;o.frequency.value=freq;g.gain.setValueAtTime(volume,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+duration);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+duration);}catch{}}
function toast(text){$('toast').textContent=text;$('toast').classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('visible'),3200);}
function start(){keys.clear();game.prepareLoadout();shown='';lastBoss=0;}
function launch(){if(game.startLoadout()){keys.clear();shown='';canvas.focus();beep(550,.2);}}
function pause(){if(game.state==='playing')game.state='paused';else if(game.state==='paused')game.state='playing';keys.clear();}
function shop(){if(game.state==='shop')game.closeShop();else if(!game.openShop())toast(['reward','draft'].includes(game.state)?'Resolve your rewards before continuing.':'Begin your journey to visit the shop.');keys.clear();}
const stage=document.querySelector('.canvas-wrap');
function fullscreenLabel(){const active=document.fullscreenElement===stage||stage.classList.contains('expanded');$('fullscreen-button').textContent=active?'⤢ Exit fullscreen':'⛶ Fullscreen';$('fullscreen-button').setAttribute('aria-pressed',String(active));}
async function toggleFullscreen(){
 try{
  if(document.fullscreenElement===stage)await document.exitFullscreen();
  else if(stage.classList.contains('expanded')){stage.classList.remove('expanded');document.body.classList.remove('game-expanded');}
  else if(stage.requestFullscreen)await stage.requestFullscreen();
  else{stage.classList.add('expanded');document.body.classList.add('game-expanded');}
 }catch{stage.classList.toggle('expanded');document.body.classList.toggle('game-expanded',stage.classList.contains('expanded'));}
 fullscreenLabel();if(game.state==='playing')canvas.focus();
}
$('fullscreen-button').onclick=toggleFullscreen;document.addEventListener('fullscreenchange',()=>{keys.clear();fullscreenLabel();});
$('shop-button').onclick=shop;$('pause-button').onclick=pause;
$('sound').onclick=()=>{sound=!sound;$('sound').textContent=sound?'SOUND ON':'SOUND OFF';$('sound').setAttribute('aria-label',sound?'Disable sound':'Enable sound');beep(660);};
window.addEventListener('keydown',e=>{
 if(e.target.closest?.('button')&&['Space','Enter'].includes(e.code))return;
 if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code))e.preventDefault();
 keys.add(e.code);if(e.repeat)return;
 if(e.code==='KeyC')toggleCamera();
 if(e.code==='Digit0')requestElement('physical');
 if(e.code==='KeyF')game.interact();
 if(e.code==='Digit1')requestElement('fire');if(e.code==='Digit2')requestElement('ice');if(e.code==='Digit3')requestElement('poison');
 if(e.code==='Space')game.dash();if(e.code==='KeyE')game.nova();if(e.code==='KeyB')shop();if(e.code==='Escape'){if(stage.classList.contains('expanded')){stage.classList.remove('expanded');document.body.classList.remove('game-expanded');fullscreenLabel();return;}if(game.state==='shop')game.closeShop();else pause();}
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
let shownShopRevision=-1;
function requestElement(element){
 if(element===game.player.element)return;
 if(element==='physical'){toast('Attunement replaces physical arrows · swap elements in the shop');return;}
 if(game.state==='shop'){toast('Attunements appear among the four offers. Reroll to find another.');return;}
 if(game.openShop('swap')){shown='';keys.clear();toast('Find an attunement among the four offers · reroll for more');}
 else if(game.state==='draft')toast('Choose your level reward first');
 else toast('Begin your journey before choosing an element');
}
for(const button of document.querySelectorAll('[data-element]'))button.onclick=()=>requestElement(button.dataset.element);
$('touch-dash').onpointerdown=e=>{e.preventDefault();game.dash();};$('touch-ability').onpointerdown=e=>{e.preventDefault();game.nova();};
function modal(html,cls=''){ $('overlay').hidden=false;$('overlay').innerHTML=`<div class="modal ${cls}">${html}</div>`; }
function showState(){
 const state=game.state,entering=shown!==state;if(!entering&&!(['shop','draft','loadout','reward'].includes(state)&&shownShopRevision!==game.shopRevision))return;shown=state;$('toast').hidden=['shop','draft','reward'].includes(state);
 $('pause-button').textContent=state==='paused'?'Resume · Esc':'Pause · Esc';
 if(state==='playing'){$('overlay').hidden=true;canvas.focus();return;}
 if(state==='title'){
 modal(`<div class="crest">✧</div><div class="eyebrow">THE RANGER’S JOURNEY</div><h2>Beyond the clearing</h2><p>Roam the woods, frozen ruins, ember hills, and venom marsh. Choose your archer, collect enemy-dropped chests, tame companions, and commit to an elemental build. Earn a stat choice each level. After each wave, pick your rewards and browse four rotating shop offers.</p><button class="button" id="begin">Begin your journey &nbsp; →</button><p class="subtext">WASD to move · C for free mouse look · Red areas warn attacks<br>Your bow automatically targets nearby enemies. Bosses arrive on waves 3, 6, and 9.${best?`<br>Personal best: ${best} enemies defeated`:''}</p>`);
 $('begin').onclick=start;
 }else if(state==='loadout'){renderLoadout();}
 else if(state==='paused'){
 modal('<div class="crest">☾</div><div class="eyebrow">TAKE A BREATH</div><h2>The forest can wait.</h2><p>Your journey is paused. Come back when your spark is ready.</p><div class="modal-actions"><button class="button" id="resume">Keep wandering</button><button class="button secondary" id="paused-shop">Visit shop</button></div>');$('resume').onclick=pause;$('paused-shop').onclick=shop;
 }else if(state==='draft'){renderDraft();}
 else if(state==='shop'){renderShop();}
 else if(state==='reward'){renderChest();}
 else if(state==='dead'||state==='won'){
 best=Math.max(best,game.player.kills);try{localStorage.setItem('wildfall-best',String(best));}catch{}
 const won=state==='won';modal(`<div class="crest">${won?'✧':'☾'}</div><div class="eyebrow">${won?'THE HOLLOW IS FREE':'EVERY SPARK LEAVES A STORY'}</div><h2>${won?'You brought the dawn.':'The wild remembers.'}</h2><p>${won?'All three guardians have fallen. The forest is quiet once more.':'Rest, Wayfarer. The woods will be waiting for your next journey.'}</p><p>Wave ${game.wave} &nbsp; · &nbsp; Level ${game.player.level} &nbsp; · &nbsp; ${game.player.kills} defeated<br>${game.bossesDefeated} / 3 guardians &nbsp; · &nbsp; Best: ${best} defeated</p><button id="restart" class="button">${won?'Wander again':'Try again'} &nbsp; →</button><p class="subtext">Coins and upgrades reset each run. Your best score is saved.</p>`);$('restart').onclick=start;
 }
}
function renderLoadout(){
 shownShopRevision=game.shopRevision;
 const section=(slot,label)=>`<section class="loadout-section"><div class="loadout-label">${label} · CHOOSE ONE</div><div class="loadout-grid">${game.loadoutChoices[slot].map(skill=>`<button class="shop-card loadout-card ${game.loadout[slot]===skill.id?'selected':''}" data-skill="${skill.id}" data-slot="${slot}" aria-pressed="${game.loadout[slot]===skill.id}"><span class="card-symbol">${skill.icon}</span><strong>${skill.name}</strong><small>${skill.text}</small><span class="price">${skill.cooldown}s cooldown${game.loadout[slot]===skill.id?' · ✓ SELECTED':''}</span></button>`).join('')}</div></section>`;
 modal(`<button class="text-button loadout-fullscreen" id="loadout-fullscreen">⛶ Fullscreen</button><div class="eyebrow">YOUR RUN · YOUR TRICKS</div><h2>Pack a little mischief</h2><p class="loadout-intro">Three random choices for each slot. Pick one of each; both start unlocked.</p><div class="loadout-scroll"><div class="loadout-label">ARCHER ROSTER · UNLOCKS SAVED IN THIS BROWSER</div><div class="character-grid">${CHARACTERS.map(c=>{const unlocked=isUnlocked(c,game.progress);return `<button class="character-card ${game.character===c.id?'selected':''}" data-character="${c.id}" aria-pressed="${game.character===c.id}" ${unlocked?'':'disabled'}><strong style="color:${c.hood}">${c.icon} ${c.name}</strong><small>${unlocked?c.text:c.goal+' · '+Math.min(c.target,game.progress[c.metric]||0)+'/'+c.target}</small></button>`;}).join('')}</div>${section('space','SPACE · DEFENSE & MOVEMENT')}${section('attack','E · OFFENSE')}</div><button class="button" id="launch-run" ${game.loadout.space&&game.loadout.attack?'':'disabled'}>Enter the wild →</button>`,'loadout-modal');
 for(const b of document.querySelectorAll('[data-skill]'))b.onclick=()=>{game.chooseSkill(b.dataset.slot,b.dataset.skill);renderLoadout();};
 for(const b of document.querySelectorAll('[data-character]'))b.onclick=()=>{if(game.chooseCharacter(b.dataset.character))renderLoadout();};
 $('launch-run').onclick=launch;$('loadout-fullscreen').onclick=toggleFullscreen;
}
let statsOpen=false;
function buildSheet(){
 const p=game.player,groups=new Map();
 for(const entry of game.upgradeHistory){const key=entry.source+':'+entry.id+':'+entry.status,group=groups.get(key);if(group)group.count++;else groups.set(key,{...entry,count:1});}
 const fmt=n=>Number.isInteger(n)?n:n.toFixed(2).replace(/0$/,'');
 return `<div class="build-heading"><div class="eyebrow">KNOW YOUR RANGER</div><h3>Stats & upgrades</h3><div class="sheet-links"><button id="jump-stats">Starting / current ↑</button><button id="jump-upgrades">All upgrades (${game.upgradeHistory.length}) ↓</button></div></div><div class="build-scroll"><table class="stat-table"><thead><tr><th>Stat</th><th>Starting</th><th>Current</th></tr></thead><tbody>${game.statSheet().map(r=>`<tr><th scope="row">${r.name}</th><td>${fmt(r.base)}</td><td class="${r.current>r.base?'improved':''}">${fmt(r.current)}</td></tr>`).join('')}</tbody></table><p class="stat-note">Current = permanent stats. Temporary skill buffs are listed separately below. Shared elemental damage contributes only when an element is equipped.</p><div class="build-readout">${p.element.toUpperCase()} · ${game.attackDamage().toFixed(1)} current arrow hit<br>${game.profile().hit.toFixed(1)} elemental impact · ${Math.round(100-10000/(100+p.armor*6))}% damage reduction<br>${game.moveSpeed().toFixed(0)} current speed · ${(1/game.attackInterval()).toFixed(2)} current shots/sec</div><h4>Selected skills</h4>${['space','attack'].map(slot=>{const sk=game.skill(slot);return `<div class="history-entry"><strong>${slot==='space'?'SPACE':'E'} · ${sk?.name||'Choose before starting'}</strong><small>${sk?.text||''}</small></div>`;}).join('')}<h4 id="history-heading">Every upgrade taken · ${game.upgradeHistory.length}</h4><div id="upgrade-history">${[...groups.values()].map(e=>`<div class="history-entry rarity-${e.rarity} ${e.status==='replaced'?'replaced':''}"><strong>${e.name}${e.count>1?' ×'+e.count:''}</strong><small>${e.source==='level'?'Level reward':e.source==='shop'?'Shop purchase':e.source==='mythical chest'?'Mythical chest':'Ability chest'}${e.rarity!=='common'?' · '+e.rarity.toUpperCase():''} · ${e.status==='replaced'?'REPLACED · no longer active':e.status==='used'?'Consumed':'Active'}</small><small>${e.text}</small></div>`).join('')||'<p class="stat-note">Your stat choices and purchases will appear here, including repeat upgrades.</p>'}</div></div>`;
}
function buildModal(content){
 modal(`<div class="build-tabs"><button id="show-offers" aria-pressed="${!statsOpen}">${game.state==='draft'?'Level choices':game.state==='reward'?'Chest reward':'Shop offers'}</button><button id="show-stats" aria-pressed="${statsOpen}">Stats & upgrades (${game.upgradeHistory.length})</button></div><div class="shop-layout ${statsOpen?'stats-open':''}"><div class="shop-main">${content}</div><section class="build-panel" aria-label="Player stats and upgrade history">${buildSheet()}</section></div>`,'shop-modal build-modal');
 $('jump-stats').onclick=()=>{document.querySelector('.build-scroll').scrollTo({top:0,behavior:'instant'});};
 $('jump-upgrades').onclick=()=>{const scroll=document.querySelector('.build-scroll'),heading=$('history-heading');scroll.scrollTo({top:scroll.scrollTop+heading.getBoundingClientRect().top-scroll.getBoundingClientRect().top,behavior:'instant'});};
 $('show-offers').onclick=()=>{statsOpen=false;renderIntermission();};
 $('show-stats').onclick=()=>{statsOpen=true;renderIntermission();};
}
function renderIntermission(){if(game.state==='draft')renderDraft();else if(game.state==='reward')renderChest();else renderShop();}
function renderChest(){
 shownShopRevision=game.shopRevision;const chest=game.chestQueue[0],item=chest.reward,myth=chest.tier==='mythical',cost=game.chestRerollCost(),alternatives=game.chestPool(chest.tier).some(i=>i.id!==item?.id);
 buildModal(`<div class="eyebrow">${myth?'GUARDIAN MYTHICAL CHEST':'ENEMY-DROPPED ABILITY CHEST'} · ${game.chestQueue.length} LEFT</div><h2>${myth?'A legend in the lock':'A little stolen luck'}</h2>${statLine()}<div class="chest-reward ${myth?'mythical':'normal'}"><div class="reward-chest-icon">${myth?'♛':'▣'}</div><span class="rarity-label">${item?.rarity?.toUpperCase()||'ABILITY'} REWARD</span><h3>${item?.name||'A well-stocked ranger'}</h3><p>${item?.text||'You already own every eligible power. Sell this chest for gold.'}</p><small>Take this power for free, reroll it, or sell it for gold. Chest rolls have their own cost.</small></div><div class="reward-actions"><button class="button" id="take-chest" ${!item||!game.offer(item,{reward:true}).available?'disabled':''}>Take power</button><button class="button secondary" id="reroll-chest" ${game.player.coins<cost||!alternatives?'disabled':''}>↻ Reroll · ◈ ${cost}</button><button class="button secondary" id="sell-chest">Sell · ◈ ${game.chestSellValue()}</button></div><div class="shop-footnote">${myth?'Mythical powers come only from guardians. ':'Only this chest is rerolled. '}Reroll costs rise for this chest and start fresh on the next one.</div>`);
 $('take-chest').onclick=()=>{if(game.resolveChest('take')){beep(990);showState();hud();}};
 $('sell-chest').onclick=()=>{if(game.resolveChest('sell')){beep(660);showState();hud();}};
 $('reroll-chest').onclick=()=>{if(game.rerollChest()){beep(550);renderChest();hud();}};
}
function statLine(){const p=game.player;return `<div class="shop-player-stats"><span>LEVEL <b id="shop-level">${p.level}</b></span><span>♥ <b>${Math.ceil(p.hp)}/${p.maxHp}</b></span><span>◈ <b>${p.coins.toLocaleString()}</b> GOLD</span></div><div class="shop-stat-line">➶ ${p.damage.toFixed(1)} physical · ✧ ${p.elementalDamage.toFixed(1)} elemental · ⬡ ${p.armor} armor · ➟ ${Math.round(p.speed)} speed</div>`;}
function renderDraft(){
 shownShopRevision=game.shopRevision;
 buildModal(`<div class="eyebrow">WAVE ${game.wave} CLEARED · LEVEL REWARD</div><h2>Choose your next strength</h2>${statLine()}<div class="shop-build"><strong>Reward for level ${game.levelRewards[0]}</strong><span>${game.freePicks} ${game.freePicks===1?'choice':'choices'} remaining · pick one below</span></div><div class="shop-catalog"><div class="shop-grid draft-grid">${game.draftChoices.map(c=>`<button class="shop-card" data-upgrade="${c.id}"><span class="card-symbol">${c.icon}</span><strong>${c.name}</strong><small>${c.text}</small><span class="price">FREE · CHOOSE</span></button>`).join('')}</div></div><div class="shop-bottom"><span>One permanent stat upgrade per level earned. The shop follows your choices.</span></div>`);
 for(const b of document.querySelectorAll('[data-upgrade]'))b.onclick=()=>{if(game.chooseUpgrade(b.dataset.upgrade)){beep(880);showState();hud();}};
}
function renderShop(){
 shownShopRevision=game.shopRevision;
 const p=game.player,element=ELEMENTS[p.element],rank=p.elementUpgrades;
 const cards=game.shopOffers.map(slot=>{
   const item=SHOP.find(i=>i.id===slot.id),offer=game.offer(item),disabled=slot.sold||!offer.available||p.coins<offer.price;
   return `<button class="shop-card rarity-${item.rarity||'common'} ${slot.sold?'sold-card':''}" data-buy="${item.id}" ${disabled?'disabled':''}><span class="card-symbol">${slot.sold?'✓':item.icon}</span><strong>${item.rarity==='rare'?'RARE · ':''}${item.name}${item.category==='element'?` · ${offer.rank}/${item.max}`:''}</strong><small>${slot.sold?'Purchased · reroll for new offers':item.text}</small><span class="price">${slot.sold?'SOLD':!offer.available?offer.reason:`◈ ${offer.price} GOLD`}</span></button>`;
 }).join('');
 const abilities=[...SHOP,...MYTHICAL_UPGRADES].filter(i=>['ability','rare','mythical'].includes(i.category)&&p[i.id]).map(i=>i.name);
 buildModal(`<div class="eyebrow">FOUR FINDS · YOUR BUILD</div><h2>${game.pendingWave?`Wave ${game.wave} cleared`:"Wanderer's shop"}</h2>${statLine()}<div class="shop-build"><strong>${element?element.icon+' '+element.name:'➶ Physical'} build</strong><span>Ranks: ${rank.power} power · ${rank.duration} duration · ${rank.special} ability</span><small>${abilities.length?abilities.join(' · '):'Find unique abilities, companions and attunements in the rotating offers.'}</small></div><div class="shop-catalog"><div class="shop-grid">${cards}</div></div><div class="shop-bottom"><button class="button secondary" id="reroll-shop" ${p.coins<game.rerollCost()?'disabled':''}>↻ Reroll · ◈ ${game.rerollCost()}</button><button class="button" id="leave-shop">${game.pendingWave?'Begin wave '+game.pendingWave:'Continue journey'} →</button></div><div class="shop-footnote">Buy any or all. Reroll anytime; each roll costs 5 more gold. Resets after the next wave. Swapping elements clears the previous element’s ranks.</div>`);
 for(const b of document.querySelectorAll('[data-buy]'))b.onclick=()=>{if(game.buy(b.dataset.buy)){beep(880);renderShop();hud();}};
 $('reroll-shop').onclick=()=>{if(game.reroll()){beep(660);renderShop();hud();}};
 $('leave-shop').onclick=()=>game.closeShop();
}
let lastBoss=0, bossBannerUntil=0;
function hud(){
 const p=game.player;
 if(savedProgressRevision!==game.progressRevision){saveProgress();savedProgressRevision=game.progressRevision;for(const c of CHARACTERS)if(isUnlocked(c,game.progress)&&!knownUnlocks.has(c.id)){knownUnlocks.add(c.id);toast('ARCHER UNLOCKED · '+c.name);}}
 const character=CHARACTERS.find(c=>c.id===game.character);$('character-name').textContent=character.name;$('hud-character-name').textContent=character.name.split(' · ')[0].toUpperCase();
 $('hud-level').textContent='LV. '+p.level;$('hud-free-picks').textContent=game.freePicks+' pending '+(game.freePicks===1?'choice':'choices');
 $('hud-health-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hud-health-fill').style.width=(p.hp/p.maxHp*100)+'%';
 $('hud-xp-text').textContent=`${p.xp} / ${p.xpNext}`;$('hud-xp-fill').style.width=(p.xp/p.xpNext*100)+'%';
 const hpMeter=$('hud-health-fill').parentElement,xpMeter=$('hud-xp-fill').parentElement;
 hpMeter.setAttribute('aria-valuenow',String(Math.ceil(p.hp)));hpMeter.setAttribute('aria-valuemax',String(p.maxHp));xpMeter.setAttribute('aria-valuenow',String(p.xp));xpMeter.setAttribute('aria-valuemax',String(p.xpNext));
 hpMeter.classList.toggle('critical',p.hp/p.maxHp<.3);
 $('hud-coins').textContent=p.coins.toLocaleString();$('hud-kills').textContent=p.kills+' defeated';$('hud-pets').textContent=game.pets.length+' companions';
 $('equipped-element').dataset.equipped=p.element;$('hud-element').textContent=p.element[0].toUpperCase()+p.element.slice(1);$('hud-element-icon').textContent={physical:'➶',fire:'ϟ',ice:'❄',poison:'☠'}[p.element];
 const defensive=game.skill('space'),offensive=game.skill('attack');
 $('hud-space-name').textContent='SPACE · '+(defensive?.name||'DEFENSE');$('hud-attack-name').textContent='E · '+(offensive?.name||'OFFENSE');
 $('hud-dash').textContent=p.spaceTime>0?'ACTIVE '+p.spaceTime.toFixed(1)+'s':p.dashCooldown>0?p.dashCooldown.toFixed(1)+'s':'READY';$('hud-dash-fill').style.width=(1-p.dashCooldown/game.dashDuration())*100+'%';
 const attackTime=Math.max(p.rapidTime,p.furyTime);$('hud-burst').textContent=attackTime>0?'ACTIVE '+attackTime.toFixed(1)+'s':p.novaCooldown>0?p.novaCooldown.toFixed(1)+'s':'READY';$('hud-burst-fill').style.width=(1-p.novaCooldown/game.attackCooldown())*100+'%';
 $('defense-name').textContent=(defensive?.name||'Defense')+' · Space';$('active-name').textContent=(offensive?.name||'Offense')+' · E';$('touch-dash').textContent='SPACE';$('touch-dash').title=defensive?.name||'Defense';$('touch-ability').title=offensive?.name||'Offense';
$('hp-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hp-fill').style.width=(p.hp/p.maxHp*100)+'%';$('xp-text').textContent=`${p.xp} / ${p.xpNext}`;$('xp-fill').style.width=(p.xp/p.xpNext*100)+'%';$('level-badge').textContent='LV. '+p.level;$('coins').textContent=p.coins;$('kills').textContent=p.kills;
 $('wave').textContent=`WAVE ${String(game.wave).padStart(2,'0')} / 09`;$('timer').textContent=String(Math.floor(game.time/60)).padStart(2,'0')+':'+String(Math.floor(game.time%60)).padStart(2,'0');
 $('phase').textContent=game.wave%3===0?'GUARDIAN ENCOUNTER':regionAt(p).name.toUpperCase();
 $('location').textContent=`${Math.round(p.x)}, ${Math.round(p.y)} · ${game.chestQueue.length+game.chests.length} chests secured / dropped`;
 const nearby=game.chests.some(c=>Math.hypot(c.x-p.x,c.y-p.y)<90);$('interact-hint').hidden=!nearby||game.state!=='playing';
 $('weapon-description').textContent=`${Math.round(game.attackDamage())} hit · ${p.element}${p.multi?' · triple shot':''}${p.piercing?' · pierces 3':p.ricochet?' · ricochet':' · first hit stops'}`;
 $('dash-status').textContent=p.spaceTime>0?`Active · ${p.spaceTime.toFixed(1)}s`:p.dashCooldown>0?`Recovering · ${p.dashCooldown.toFixed(1)}s`:defensive?.text||'Choose before starting';
 $('pet-status').textContent=game.pets.length?game.pets.map(p=>p.kind==='fox'?'Fox · fan darts':p.kind==='wolf'?'Wolf · bite + howl':'Beetle · coin/XP collector').join(' + '):'Unlock companions in the shop';
 $('armor-stat').textContent=p.armor+' · '+Math.round(100-10000/(100+p.armor*6))+'% reduction';$('speed-stat').textContent=Math.round(game.moveSpeed())+' / sec';$('passive-status').textContent=[...SHOP,...MYTHICAL_UPGRADES].filter(i=>['ability','rare','mythical'].includes(i.category)&&p[i.id]).map(i=>i.name+(i.id==='phoenix'&&p.phoenixUsed?' (spent)':'')).join(' · ')||'Find unique abilities in the shop';
 $('element-base-stat').textContent=p.elementalDamage.toFixed(1);$('element-rank-stat').textContent=`Power ${p.elementUpgrades.power} · Duration ${p.elementUpgrades.duration} · Ability ${p.elementUpgrades.special}`;
 for(const button of document.querySelectorAll('[data-element]')){const el=button.dataset.element,equipped=p.element===el;button.classList.toggle('equipped',equipped);button.classList.toggle('locked',!equipped);button.setAttribute('aria-pressed',String(equipped));button.title=equipped?'Currently equipped':el==='physical'?'Attunement replaces physical arrows':'Open shop to swap elements (clears old elemental ranks)';}
 minimap();
 $('active-status').textContent=attackTime>0?`Active · ${attackTime.toFixed(1)}s`:p.novaCooldown>0?`Recharging · ${p.novaCooldown.toFixed(1)}s`:offensive?.text||'Choose before starting';
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
 for(const c of game.chests){m.fillStyle='#edd28a';m.fillRect(c.x*sx-1,c.y*sy-1,2,2);}
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
