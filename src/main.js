import {chestReveal} from './chest-reveal.js';
import {formatDamage} from './combat-feedback.js';
import {clearProgressStorage} from './progress-storage.js';
import { upgradeArt } from './upgrade-art.js';
import { Game, SHOP, WORLD, REGIONS, regionAt, advanceGame, ELEMENTS, CHARACTERS, isUnlocked, RARITIES, isBossWave, waveDuration } from './game.js';
import { createBabylonRenderer } from './babylon-renderer.js';
import { create2DRenderer } from './render2d.js';
const $ = id => document.getElementById(id);
let canvas=$('arena'), view;
function readProgress(){try{return JSON.parse(localStorage.getItem('wildfall-unlocks'))||{};}catch{return {};}}
const game=new Game(Math.random,readProgress());
let savedProgressRevision=game.progressRevision,knownUnlocks=new Set(CHARACTERS.filter(c=>isUnlocked(c,game.progress)).map(c=>c.id));
function saveProgress(){try{localStorage.setItem('wildfall-unlocks',JSON.stringify(game.progress));}catch{}}
window.addEventListener('pagehide',()=>{saveProgress();saveRun();});
let savedRun=readSavedRun(),lastAutosave=0,progressScreen=null,progressNotice='';
function readSavedRun(){try{const value=JSON.parse(localStorage.getItem('wildfall-run'));return new Game(Math.random,readProgress()).restoreSnapshot(value)?value:null;}catch{return null;}}
function saveRun(){const snapshot=game.snapshot();if(!snapshot)return false;try{localStorage.setItem('wildfall-run',JSON.stringify(snapshot));savedRun=snapshot;return true;}catch{return false;}}
function clearSavedRun(){savedRun=null;try{localStorage.removeItem('wildfall-run');}catch{}}
function saveAndQuit(){if(!saveRun()){$('save-status').hidden=false;$('save-status').textContent='Could not save in this browser. Your run is still paused; retry Save & quit.';return;}saveProgress();keys.clear();game.reset();shown='';toast('Run saved · continue from the main menu on this browser.');showState();hud();}
function quitRun(){clearSavedRun();saveProgress();keys.clear();game.reset();shown='';showState();hud();}
function resumeSaved(){if(!savedRun||!game.restoreSnapshot(savedRun)){clearSavedRun();shown='';toast('This saved run could not be loaded. Start a new journey.');return;}keys.clear();shown='';lastBoss=0;showState();hud();}

let graphics='3d';
// Start every visit in 3D, including browsers with an older saved 2D preference.
try { localStorage.removeItem('wildfall-graphics'); } catch {}
let cameraFree=false, quality='high';
try { cameraFree=localStorage.getItem('wildfall-camera-mode')==='free';quality=localStorage.getItem('wildfall-quality')||quality;if(!['high','low'].includes(quality))quality='high'; } catch {}
const keys=new Set(); let previous=performance.now(),shown='',sound=false,audio,toastTimer;
let best=0;try{best=Number(localStorage.getItem('wildfall-best'))||0;}catch{}
function beep(freq=440,duration=.1,type='sine',volume=.025){if(!sound)return;try{audio ||= new AudioContext();const o=audio.createOscillator(),g=audio.createGain();o.type=type;o.frequency.value=freq;g.gain.setValueAtTime(volume,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+duration);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+duration);}catch{}}
function toast(text){$('toast').textContent=text;$('toast').classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('visible'),3200);}
function start(){progressNotice='';keys.clear();game.prepareLoadout();shown='';lastBoss=0;showState();hud();}
function launch(){if(game.startLoadout()){clearSavedRun();keys.clear();shown='';canvas.focus();beep(550,.2);showState();hud();}}
function pause(){if(progressScreen){closeProgressPanel();return;}if(game.state==='paused')game.resume();else{pauseStatsOpen=false;game.pause();}keys.clear();showState();hud();}
function shop(){
 if(progressScreen){closeProgressPanel();return;}
 if(game.state==='playing'){game.pause();pauseStatsOpen=true;shown='';}
 else if(game.state==='paused'){pauseStatsOpen=true;renderPaused();}
 else if(['shop','draft','reward'].includes(game.state)){statsOpen=true;renderIntermission();}
 else toast('Start a run to inspect your equipment.');keys.clear();
}
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
$('shop-button').onclick=shop;$('pause-button').onclick=pause;$('run-menu').onclick=pause;
$('sound').onclick=()=>{sound=!sound;$('sound').textContent=sound?'SOUND ON':'SOUND OFF';$('sound').setAttribute('aria-label',sound?'Disable sound':'Enable sound');beep(660);};
window.addEventListener('keydown',e=>{
 if(progressScreen){if(e.code==='Escape'){e.preventDefault();closeProgressPanel();}return;}
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
window.addEventListener('blur',()=>{keys.clear();if(game.state==='playing')game.pause();saveRun();});
document.addEventListener('visibilitychange',()=>{if(document.hidden){keys.clear();if(game.state==='playing')game.pause();saveRun();}});
for(const b of document.querySelectorAll('[data-move]')){const key={left:'ArrowLeft',right:'ArrowRight',up:'ArrowUp',down:'ArrowDown'}[b.dataset.move];b.onpointerdown=e=>{e.preventDefault();b.setPointerCapture(e.pointerId);keys.add(key);};b.onpointerup=b.onpointercancel=()=>keys.delete(key);}
$('touch-interact').onclick=()=>game.interact();
function updateCameraLabel(){
 $('camera-mode').textContent='Camera: '+(cameraFree?'Free':'Locked');$('camera-mode').setAttribute('aria-pressed',String(cameraFree));
 $('camera-mode').title=cameraFree?'Move the pointer over the game to look. Press C to lock.':'Right-drag to look. Press C for free mouse look.';
}
function toggleCamera(){cameraFree=!cameraFree;updateCameraLabel();try{localStorage.setItem('wildfall-camera-mode',cameraFree?'free':'locked');}catch{}if(game.state==='playing')canvas.focus();}
$('camera-mode').onclick=toggleCamera;
$('detail-button').onclick=()=>{quality=quality==='high'?'low':'high';view.setQuality?.(quality);lastSceneState='';$('detail-button').textContent='Detail: '+(quality==='high'?'High':'Low');try{localStorage.setItem('wildfall-quality',quality);}catch{}};
$('orbit-left').onclick=()=>view.orbit?.(-Math.PI/6);$('orbit-right').onclick=()=>view.orbit?.(Math.PI/6);
let shownShopRevision=-1;
function requestElement(element){
 if(element===game.player.element)return;
 toast(game.state==='shop'?'Elemental quivers appear among the four items. Reroll to find another.':'Buy an elemental quiver at the next wave break. Current gear is available in Inventory · B.');
}
for(const button of document.querySelectorAll('[data-element]'))button.onclick=()=>requestElement(button.dataset.element);
$('touch-dash').onpointerdown=e=>{e.preventDefault();game.dash();};$('touch-ability').onpointerdown=e=>{e.preventDefault();game.nova();};
$('progress-button').onclick=openProgressPanel;
function openProgressPanel(){
 if(game.state==='playing')game.pause();keys.clear();progressScreen='menu';renderProgressPanel();
}
function closeProgressPanel(){progressScreen=null;shown='';keys.clear();showState();}
function renderProgressPanel(){
 const active=['playing','paused','shop','draft','reward','won'].includes(game.state);
 if(progressScreen==='menu'){
  modal(`<div class="eyebrow">SETTINGS</div><h2>Progress & restart</h2><div class="progress-options"><button id="restart-current" ${active?'':'disabled'}><strong>Restart current run</strong><small>Start wave 1 with the same archer. Keep unlocked characters and your best score.</small></button><button id="delete-save" ${savedRun||active?'':'disabled'}><strong>Delete saved run</strong><small>Discard the current and saved run. Keep character unlocks and your best score.</small></button><button id="reset-progress" class="reset-danger"><strong>Reset all progress</strong><small>Delete all runs, character unlocks and your personal best.</small></button></div><button class="button secondary" id="close-progress">Back</button>`,'progress-modal');
  $('restart-current').onclick=()=>{progressScreen='restart';renderProgressPanel();};$('delete-save').onclick=()=>{progressScreen='delete';renderProgressPanel();};$('reset-progress').onclick=()=>{progressScreen='all';renderProgressPanel();};$('close-progress').onclick=closeProgressPanel;return;
 }
 const copy={restart:['Restart this run?','Your current equipment, coins, level and wave will be replaced by a fresh run with the same archer. Unlocked characters and your best score are kept.','Restart run'],delete:['Delete this run?','This discards the current run and its saved checkpoint. Character unlocks and your best score are kept.','Delete run'],all:['Reset all progress?','This deletes your current and saved runs, every earned character unlock and your personal best. This cannot be undone.','Reset everything']}[progressScreen];
 modal(`<div class="eyebrow">CONFIRM ${progressScreen==='all'?'FULL RESET':'RUN CHANGE'}</div><h2>${copy[0]}</h2><p>${copy[1]}</p><p id="progress-error" role="status" hidden></p><div class="modal-actions"><button class="button secondary" id="cancel-progress">Cancel</button><button class="button reset-danger" id="confirm-progress">${copy[2]}</button></div>`,'progress-modal');
 $('cancel-progress').onclick=()=>{progressScreen='menu';renderProgressPanel();};$('confirm-progress').onclick=applyProgressAction;
}
function applyProgressAction(){
 const action=progressScreen;let cleared=false;
 try{cleared=clearProgressStorage(localStorage,action==='all'?'all':'run');}catch{}
 if(!cleared){$('progress-error').hidden=false;$('progress-error').textContent='Could not update saved progress in this browser. Retry or cancel.';return;}
 savedRun=null;keys.clear();progressScreen=null;shown='';
 if(action==='restart'){
  const character=game.character;game.start({character});lastBoss=0;saveRun();
 }else{
  if(action==='all'){game.resetProgress();best=0;savedProgressRevision=game.progressRevision;knownUnlocks=new Set(CHARACTERS.filter(c=>isUnlocked(c,game.progress)).map(c=>c.id));progressNotice='Progress reset. Rowan is ready for a new journey.';}
  else{game.reset();progressNotice='Saved run deleted. Your unlocks and best score are kept.';}
 }
 showState();hud();
}
function modal(html,cls=''){ $('overlay').hidden=false;$('overlay').innerHTML=`<div class="modal ${cls}">${html}</div>`; }
function showState(){
 if(progressScreen)return;
 const state=game.state,entering=shown!==state;if(!entering&&!(['shop','draft','loadout','reward'].includes(state)&&shownShopRevision!==game.shopRevision))return;shown=state;$('toast').hidden=['shop','draft','reward','paused'].includes(state);
 $('pause-button').textContent=state==='paused'?'Resume · Esc':'Run menu · Esc';$('run-menu').hidden=['title','loadout','dead'].includes(state);$('run-menu').textContent=state==='paused'?'Resume run':'Run menu · Esc';
 if(state==='playing'){$('overlay').hidden=true;canvas.focus();return;}
 if(state==='title'){
 modal(`<div class="landing-rule"><span>WILDFALL</span><span>THE EMBERWILD</span></div><div class="eyebrow">AN ARCHER. A WILDERNESS. A LITTLE HOPE.</div><h2>Into the<br><em>Emberwild.</em></h2><p>An ancient wood. Four restless guardians.<br>Take up your bow and make a little light.</p><div class="landing-actions">${savedRun?`<button class="button" id="continue-run">Continue your story <span>Wave ${savedRun.data.wave} →</span></button>`:''}<button class="button ${savedRun?'secondary':''}" id="begin">${savedRun?'Begin a new story':'Choose your archer'} <span>→</span></button></div><div class="landing-details"><span>20 WAVES + ENDLESS</span><span>5 ARCHERS</span><span>ONE WILD WORLD</span></div><p class="subtext">WASD to wander · Your bow finds its own target.<br>Space to evade · E to unleash your signature ability.${best?`<br>Personal best · ${best} enemies defeated`:''}</p>${progressNotice?`<p class="save-note" id="progress-notice">${progressNotice}</p>`:''}`,'landing-modal');
 $('begin').onclick=start;if(savedRun)$('continue-run').onclick=resumeSaved;
 }else if(state==='loadout'){renderLoadout();}
 else if(state==='paused'){
 renderPaused();
 }else if(state==='draft'){if(entering)statsOpen=false;renderDraft();}
 else if(state==='shop'){if(entering)statsOpen=false;renderShop();}
 else if(state==='reward'){if(entering){chestRevealKey='';statsOpen=false;}renderChest();}
 else if(state==='dead'||state==='won'){
 best=Math.max(best,game.player.kills);try{localStorage.setItem('wildfall-best',String(best));}catch{}
 const won=state==='won';if(!won)clearSavedRun();modal(`<div class="crest">${won?'✧':'☾'}</div><div class="eyebrow">${won?'THE HOLLOW IS FREE':'EVERY SPARK LEAVES A STORY'}</div><h2>${won?'You brought the dawn.':'The wild remembers.'}</h2><p>${won?'All four guardians have fallen. Continue into endless waves with your current build, or start a new journey.':game.defeatReason||'Rest, Wayfarer. The woods will be waiting for your next journey.'}</p><p>Wave ${game.wave} &nbsp; · &nbsp; Level ${game.player.level} &nbsp; · &nbsp; ${game.player.kills} defeated<br>${game.bossesDefeated} guardians defeated &nbsp; · &nbsp; Best: ${best} defeated</p>${won?'<button id="endless" class="button">Continue endless →</button>':''}<button id="restart" class="button secondary">${won?'Wander again':'Try again'} &nbsp; →</button><p class="subtext">Coins and upgrades reset each run. Your best score is saved.</p>`);$('restart').onclick=start;if(won)$('endless').onclick=()=>{keys.clear();game.continueEndless();shown='';};
 }
}
function archerPortrait(c){
 const accent={ranger:'#67a995',scout:'#c67d55',warden:'#97b9cf',hex:'#b59bd5',tinker:'#c9ad65'}[c.id];
 return `<svg class="archer-portrait" viewBox="0 0 140 150" aria-hidden="true"><path d="M70 8 126 40V111L70 143 14 111V40Z" fill="#142629" stroke="${accent}" stroke-opacity=".35"/><circle cx="70" cy="68" r="38" fill="none" stroke="${accent}" stroke-opacity=".2"/><path d="M31 132 42 93 58 83H82L98 93 109 132" fill="${accent}"/><path d="M45 80Q31 28 70 25Q109 28 95 80L83 93H57Z" fill="#263f42" stroke="${accent}" stroke-width="2"/><path d="M54 51Q70 37 86 51V77L75 88H65L54 77Z" fill="#d6b69a"/><path d="M49 55Q50 32 70 31Q90 32 91 55L70 44Z" fill="${accent}"/><path d="m58 64 7 1m10 0 7-1" stroke="#263338" stroke-width="3"/><path d="M59 91 82 126M81 90 60 126" stroke="#dab675" stroke-width="3"/><path d="M104 48Q82 83 103 119M104 48V119" fill="none" stroke="#dab675" stroke-width="3"/>${c.id==='warden'?'<path d="M37 98 54 92 58 112 32 116M103 98 86 92 82 112 108 116" fill="#b5c8ca"/>':c.id==='hex'?'<path d="M74 12a12 12 0 1 0 11 18 10 10 0 1 1-11-18" fill="#c8b2e6"/>':c.id==='tinker'?'<path d="M51 40V20H89V40M44 41H96" fill="#94784b" stroke="#dab675" stroke-width="3"/><circle cx="61" cy="65" r="8" fill="none" stroke="#dab675" stroke-width="3"/><circle cx="80" cy="65" r="8" fill="none" stroke="#dab675" stroke-width="3"/>':c.id==='scout'?'<path d="m89 31 17-16-5 27" fill="#e8dbb4"/>':''}</svg>`;
}
function renderLoadout(){
 shownShopRevision=game.shopRevision;
 const c=CHARACTERS.find(c=>c.id===game.character);
 const section=(slot,label)=>{const skill=game.skill(slot);return `<section class="preset-card"><div class="loadout-label">${label}</div><h3>${skill.icon} ${skill.name}</h3><p>${skill.text}</p><span class="price">${skill.cooldown}s cooldown</span></section>`;};
 modal(`<button class="text-button loadout-fullscreen" id="loadout-fullscreen">⛶ Fullscreen</button><div class="eyebrow">FIVE ARCHERS · FIVE SIGNATURE PRESETS</div><h2>Choose your archer</h2><p class="loadout-intro">Each archer has their own design and fixed Space / E abilities. Scroll below the roster to review your preset.</p><div class="loadout-scroll"><div class="loadout-label">ARCHER ROSTER · UNLOCKS SAVED IN THIS BROWSER</div><div class="character-grid">${CHARACTERS.map(c=>{const unlocked=isUnlocked(c,game.progress);return `<button class="character-card ${game.character===c.id?'selected':''}" data-character="${c.id}" aria-pressed="${game.character===c.id}" ${unlocked?'':'disabled'}>${archerPortrait(c)}<strong style="color:${c.hood}">${c.name}</strong><small>${unlocked?c.text:c.goal+' · '+Math.min(c.target,game.progress[c.metric]||0)+'/'+c.target}</small></button>`;}).join('')}</div><h3 class="preset-name">${c.name} · signature abilities</h3><div class="preset-grid">${section('space','SPACE · DEFENSE & MOVEMENT')}${section('attack','E · OFFENSE')}</div></div><button class="button" id="launch-run">Enter the wild →</button>`,'loadout-modal');
 for(const b of document.querySelectorAll('[data-character]'))b.onclick=()=>{if(game.chooseCharacter(b.dataset.character))renderLoadout();};
 $('launch-run').onclick=launch;$('loadout-fullscreen').onclick=toggleFullscreen;
}
let statsOpen=false,pauseStatsOpen=false;
function buildSheet(){
 const p=game.player,groups=new Map();
 for(const entry of game.upgradeHistory){const key=(entry.source==='level'?'training':'item')+':'+entry.id+':'+entry.status,group=groups.get(key);if(group)group.count++;else groups.set(key,{...entry,count:1});}
 const fmt=n=>Number.isInteger(n)?n:n.toFixed(2).replace(/0$/,'');
 return `<div class="build-heading"><div class="eyebrow">KNOW YOUR RANGER</div><h3>Stats & inventory</h3><div class="sheet-links"><button id="jump-stats">Starting / current ↑</button><button id="jump-upgrades">Inventory & training (${game.upgradeHistory.length}) ↓</button></div></div><div class="build-scroll"><table class="stat-table"><thead><tr><th>Stat</th><th>Starting</th><th>Current</th></tr></thead><tbody>${game.statSheet().map(r=>`<tr><th scope="row">${r.name}</th><td>${fmt(r.base)}</td><td class="${r.current>r.base?'improved':''}">${fmt(r.current)}</td></tr>`).join('')}</tbody></table><p class="stat-note">Current = permanent stats. Temporary skill buffs are listed separately below. Shared elemental damage contributes only when an element is equipped.</p><div class="build-readout">${p.element.toUpperCase()} · ${game.attackDamage().toFixed(1)} current arrow hit<br>${game.profile().hit.toFixed(1)} elemental impact · ${Math.round(100-10000/(100+p.armor*6))}% damage reduction<br>${game.moveSpeed().toFixed(0)} current speed · ${(1/game.attackInterval()).toFixed(2)} current shots/sec</div><h4>Character skills</h4>${['space','attack'].map(slot=>{const sk=game.skill(slot);return `<div class="history-entry"><strong>${slot==='space'?'SPACE':'E'} · ${sk?.name||'Choose before starting'}</strong><small>${sk?.text||''}</small></div>`;}).join('')}<h4 id="history-heading">Equipment & training log · ${game.upgradeHistory.length}</h4><div id="upgrade-history">${[...groups.values()].map(e=>`<div class="history-entry rarity-${e.rarity} ${e.status==='replaced'?'replaced':''}">${upgradeArt(e)}<span class="inventory-type">${e.source==='level'?'LEVEL TRAINING':e.type||SHOP.find(i=>i.id===e.id)?.type||'Equipment'}</span><strong>${e.name}${e.count>1?' ×'+e.count:''}</strong><small>${e.source==='level'?'Level training':e.source==='shop'?'Shop purchase':e.source==='mythical chest'?'Mythical chest':'Item chest'}${' · '+RARITIES[e.rarity].label.toUpperCase()} · ${e.status==='replaced'?'REPLACED · no longer active':e.status==='used'?'Consumed':e.source==='level'?'Learned':'Equipped'}</small><small>${e.text}</small></div>`).join('')||'<p class="stat-note">Your carried equipment, consumed supplies and level training will appear here. Copies of an item are counted together.</p>'}</div></div>`;
}
function wireSheet(){
 $('jump-stats').onclick=()=>{document.querySelector('.build-scroll').scrollTo({top:0,behavior:'instant'});};
 $('jump-upgrades').onclick=()=>{const scroll=document.querySelector('.build-scroll'),heading=$('history-heading');scroll.scrollTo({top:scroll.scrollTop+heading.getBoundingClientRect().top-scroll.getBoundingClientRect().top,behavior:'instant'});};
}
function renderPaused(){
 modal(`<div class="build-tabs"><button id="paused-menu" aria-pressed="${!pauseStatsOpen}">Run menu</button><button id="paused-stats" aria-pressed="${pauseStatsOpen}">Stats & inventory</button></div><div class="shop-layout ${pauseStatsOpen?'stats-open':''}"><section class="shop-main"><div class="eyebrow">RUN MENU · WAVE ${game.wave}</div><h2>The forest can wait.</h2><p>Your run is paused. Inspect your equipment and stats here. The merchant opens after each wave.</p><p id="save-status" role="status" hidden></p><div class="run-menu-actions"><button class="button" id="resume">Resume run</button><button class="button" id="save-quit">Save & quit</button><button class="button secondary" id="progress-settings">Progress & restart</button><button class="button secondary" id="quit-run">Leave run</button></div><p class="save-note">Save & quit returns here later on this browser. Leave run discards the run.</p></section><section class="build-panel" aria-label="Paused stats and inventory">${buildSheet()}</section></div>`,'shop-modal build-modal pause-inventory');
 wireSheet();$('progress-settings').onclick=openProgressPanel;$('resume').onclick=pause;$('save-quit').onclick=saveAndQuit;$('quit-run').onclick=quitRun;
 $('paused-menu').onclick=()=>{pauseStatsOpen=false;renderPaused();};$('paused-stats').onclick=()=>{pauseStatsOpen=true;renderPaused();};
}
let chestRevealKey='';
function buildModal(content){
 modal(`<div class="build-tabs"><button id="show-offers" aria-pressed="${!statsOpen}">${game.state==='draft'?'Level choices':game.state==='reward'?'Chest reward':'Shop offers'}</button><button id="show-stats" aria-pressed="${statsOpen}">Stats & inventory (${game.upgradeHistory.length})</button></div><div class="shop-layout ${statsOpen?'stats-open':''}"><div class="shop-main">${content}</div><section class="build-panel" aria-label="Player stats and upgrade history">${buildSheet()}</section></div>`,'shop-modal build-modal merchant-modal');
 wireSheet();
 $('show-offers').onclick=()=>{statsOpen=false;renderIntermission();};
 $('show-stats').onclick=()=>{statsOpen=true;renderIntermission();};
}
function rewardModal(content,{kind,title,subtitle}){
 const inventory=statsOpen?`<section class="reward-inventory">${buildSheet()}</section>`:content;
 modal(`<header class="reward-header"><div><div class="eyebrow">${kind==='training'?'LEVEL REWARD':'CHEST REWARD'} · WAVE ${game.wave} COMPLETE</div><h2>${title}</h2><p>${subtitle}</p></div><button class="button secondary" id="reward-inventory-toggle" aria-pressed="${statsOpen}">${statsOpen?'← Back to reward':'Stats & inventory'}</button></header><div class="reward-content">${inventory}</div>`, 'reward-screen '+kind+'-screen');
 $('reward-inventory-toggle').onclick=()=>{statsOpen=!statsOpen;renderIntermission();};
 if(statsOpen)wireSheet();
}
function renderIntermission(){if(game.state==='draft')renderDraft();else if(game.state==='reward')renderChest();else renderShop();}
function renderChest(){
 shownShopRevision=game.shopRevision;const chest=game.chestQueue[0],item=chest.reward,myth=chest.tier==='mythical',cost=game.chestRerollCost(),alternatives=game.chestPool(chest.tier).some(i=>i.id!==item?.id);
 const revealKey=chest.id+':'+chest.rerolls+':'+item?.id,animate=revealKey!==chestRevealKey;chestRevealKey=revealKey;
 rewardModal(`<div class="treasure-stage">${chestReveal(item,myth,animate)}<section class="treasure-item rarity-${item?.rarity||'common'} ${myth?'mythical':''}"><div class="eyebrow rarity-label">${item?RARITIES[item.rarity].label.toUpperCase():'ITEM'} · ${item?.type||'Equipment'}</div><h3>${item?.name||'A well-stocked ranger'}</h3><p>${item?.text||'You already own every eligible item. Sell this chest for gold.'}</p><span class="treasure-free">YOURS TO KEEP · NO GOLD REQUIRED</span></section></div><footer class="treasure-footer"><div class="reward-actions"><button class="button" id="take-chest" ${!item||!game.offer(item,{reward:true}).available?'disabled':''}>Keep item →</button><button class="button secondary" id="reroll-chest" ${game.player.coins<cost||!alternatives?'disabled':''}>↻ Reroll · ◈ ${cost}</button><button class="button secondary" id="sell-chest">Sell · ◈ ${game.chestSellValue()}</button></div><small>${game.player.coins.toLocaleString()} gold available · This chest has its own reroll price.</small></footer>`,{kind:'treasure',title:myth?'A mythical discovery':'Open your treasure',subtitle:`${game.chestQueue.length} ${game.chestQueue.length===1?'chest':'chests'} to open · Keep, reroll or sell each reward before visiting the merchant.`});
 if(statsOpen)return;
 $('take-chest').onclick=()=>{if(game.resolveChest('take')){beep(990);showState();hud();}};
 $('sell-chest').onclick=()=>{if(game.resolveChest('sell')){beep(660);showState();hud();}};
 $('reroll-chest').onclick=()=>{if(game.rerollChest()){beep(550);renderChest();hud();}};
}
function statLine(compact=false){const p=game.player;return `<div class="shop-player-stats"><span>LEVEL <b id="shop-level">${p.level}</b></span><span>♥ <b>${Math.ceil(p.hp)}/${p.maxHp}</b></span><span>◈ <b>${p.coins.toLocaleString()}</b> GOLD</span></div>${compact?'':`<div class="shop-stat-line">➶ ${p.damage.toFixed(1)} physical · ✧ ${p.elementalDamage.toFixed(1)} elemental · ⬡ ${p.armor} armor · ➟ ${Math.round(p.speed)} speed · ◈ ${p.economy} Economy (${Math.round(game.economyDiscount()*100)}% savings)</div>`}${game.shopReason==='wave'&&game.waveSalvage?`<div class="salvage-receipt">Wave ${game.waveSalvage.wave} recovery · +${Number(game.waveSalvage.xp.toFixed(1))} XP${compact?'':' (100% + item bonuses)'} · +${game.waveSalvage.gold} gold${compact?'':` (${Math.round(game.waveSalvage.rate*100)}% + combat bonuses)`}</div>`:''}`;}
function renderDraft(){
 shownShopRevision=game.shopRevision;
 rewardModal(`<div class="training-intro"><span class="training-level">${game.levelRewards[0]}</span><div><strong>LEVEL UP</strong><p>Choose one permanent boost.<br>${game.freePicks} free ${game.freePicks===1?'choice':'choices'} remaining.</p></div></div><div class="training-choices">${game.draftChoices.map((c,i)=>`<button class="training-choice" data-upgrade="${c.id}"><span class="choice-number">0${i+1}</span><span class="choice-symbol" aria-hidden="true">${c.icon}</span><strong>${c.name}</strong><span class="choice-description">${c.text}</span><span class="choice-action">Choose boost →</span></button>`).join('')}</div><p class="reward-next">${game.chestQueue.length?'Next: open your recovered chests.':'Next: visit the merchant.'} Your gold stays untouched.</p>`,{kind:'training',title:'Choose your next strength',subtitle:'A reward for your experience. Pick one of four boosts to shape your build.'});
 if(statsOpen)return;
 for(const b of document.querySelectorAll('[data-upgrade]'))b.onclick=()=>{if(game.chooseUpgrade(b.dataset.upgrade)){beep(880);showState();hud();}};
}
function equipmentSummary(limit=4){
 const p=game.player,items=SHOP.filter(i=>i.id!=='heal'&&(i.category==='affinity'?p.element===i.element:i.category==='element'?p.element===i.element&&game.rank(i)>0:(p.ranks[i.id]||0)>0));
 return items.slice(0,limit).map(i=>i.name+(game.rank(i)>1?' ×'+game.rank(i):'')+(i.id==='phoenix'&&p.phoenixUsed?' (spent)':'')).join(' · ')+(items.length>limit?' · +'+(items.length-limit)+' more in Inventory · B':'');
}
function renderShop(){
 shownShopRevision=game.shopRevision;
 const p=game.player,element=ELEMENTS[p.element],rank=p.elementUpgrades;
 const cards=game.shopOffers.map(slot=>{
   const item=SHOP.find(i=>i.id===slot.id),offer=game.offer(item),disabled=slot.sold||!offer.available||p.coins<offer.price;
   return `<button class="shop-card rarity-${item.rarity||'common'} ${slot.sold?'sold-card':''}" data-buy="${item.id}" ${disabled?'disabled':''}>${upgradeArt(item)}<span class="item-rarity">${RARITIES[item.rarity].label}${slot.sold?' · ✓':''}</span><span class="equipment-type">${item.type}</span><strong>${item.name}${item.max?` · ${offer.rank}/${item.max} owned`:''}</strong><small>${slot.sold?'Added to your inventory · reroll for new stock':item.text}</small><span class="price">${slot.sold?'SOLD':!offer.available?offer.reason:`${offer.price<offer.basePrice?'<s>'+offer.basePrice+'</s> ':''}◈ ${offer.price} GOLD`}</span></button>`;
 }).join('');
 const equipment=equipmentSummary();
 buildModal(`<div class="merchant-sign"><span aria-hidden="true">⚖</span><div class="eyebrow">THE TRAVELING MERCHANT</div><h2>Gear for the next wave</h2><small>Four items on the counter · Wave ${game.wave} cleared</small></div>${statLine(true)}<div class="shop-build"><strong>${element?element.icon+' '+element.name:'➶ Physical'} build</strong><span>Quiver fittings: ${rank.power} tips · ${rank.duration} coatings · ${rank.special} attachments</span><small>${equipment||'Find equipment, supplies, companion charms and elemental quivers in the four shop slots.'}</small></div><div class="shop-catalog"><div class="shop-grid">${cards}</div></div><div class="shop-bottom"><button class="button secondary" id="reroll-shop" ${p.coins<game.rerollCost()?'disabled':''}>↻ Reroll · ◈ ${game.rerollCost()}</button><button class="button" id="leave-shop">${game.pendingWave?'Begin wave '+game.pendingWave:'Continue journey'} →</button></div><div class="shop-footnote">Equipment equips on purchase; supplies are consumed. Buy any or all. Reroll anytime; the price rises each roll and resets after the next wave. Changing elemental quivers discards the old quiver’s fittings. Item copies stack up to their listed limit.</div>`);
 for(const b of document.querySelectorAll('[data-buy]'))b.onclick=()=>{if(game.buy(b.dataset.buy)){beep(880);renderShop();hud();}};
 $('reroll-shop').onclick=()=>{if(game.reroll()){beep(660);renderShop();hud();}};
 $('leave-shop').onclick=()=>{game.closeShop();showState();hud();};
}
let lastBoss=0, bossBannerUntil=0;
function updateWaveClock(){
 const clock=$('wave-clock'),show=['playing','paused'].includes(game.state);clock.hidden=!show;if(!show)return;
 const remaining=Math.max(0,Math.ceil(waveDuration(game.wave)-game.waveTime));
 const text=String(Math.floor(remaining/60)).padStart(2,'0')+':'+String(remaining%60).padStart(2,'0');
 if($('wave-clock-time').textContent!==text)$('wave-clock-time').textContent=text;
 $('wave-clock-label').textContent=(isBossWave(game.wave)?'BOSS · ':'WAVE ')+game.wave;
 clock.classList.toggle('urgent',remaining<=10);clock.classList.toggle('boss-wave',isBossWave(game.wave));
}
function hud(){
 const p=game.player;
 if(savedProgressRevision!==game.progressRevision){saveProgress();savedProgressRevision=game.progressRevision;for(const c of CHARACTERS)if(isUnlocked(c,game.progress)&&!knownUnlocks.has(c.id)){knownUnlocks.add(c.id);toast('ARCHER UNLOCKED · '+c.name);}}
 const character=CHARACTERS.find(c=>c.id===game.character);$('character-name').textContent=character.name;$('hud-character-name').textContent=character.name.split(' · ')[0].toUpperCase();
 $('hud-level').textContent='LV. '+p.level;$('hud-free-picks').textContent=game.freePicks+' pending '+(game.freePicks===1?'choice':'choices');
 $('hud-health-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hud-health-fill').style.width=(p.hp/p.maxHp*100)+'%';
 $('hud-xp-text').textContent=`${Math.floor(p.xp)} / ${p.xpNext}`;$('hud-xp-fill').style.width=(p.xp/p.xpNext*100)+'%';
 const hpMeter=$('hud-health-fill').parentElement,xpMeter=$('hud-xp-fill').parentElement;
 hpMeter.setAttribute('aria-valuenow',String(Math.ceil(p.hp)));hpMeter.setAttribute('aria-valuemax',String(p.maxHp));xpMeter.setAttribute('aria-valuenow',String(p.xp));xpMeter.setAttribute('aria-valuemax',String(p.xpNext));
 hpMeter.classList.toggle('critical',p.hp/p.maxHp<.3);
 const hit=game.damageNumbers.findLast(n=>n.target==='player');hpMeter.classList.toggle('taking-damage',!!hit);$('hud-incoming-damage').hidden=!hit;if(hit)$('hud-incoming-damage').textContent='−'+formatDamage(hit.amount)+' HP';
 $('hud-coins').textContent=p.coins.toLocaleString();$('hud-kills').textContent=p.kills+' defeated';$('hud-pets').textContent=game.pets.length+' companions';
 $('equipped-element').dataset.equipped=p.element;$('hud-element').textContent=p.element[0].toUpperCase()+p.element.slice(1);$('hud-element-icon').textContent={physical:'➶',fire:'ϟ',ice:'❄',poison:'☠'}[p.element];
 const defensive=game.skill('space'),offensive=game.skill('attack');
 $('hud-space-name').textContent='SPACE · '+(defensive?.name||'DEFENSE');$('hud-attack-name').textContent='E · '+(offensive?.name||'OFFENSE');
 $('hud-dash').textContent=p.spaceTime>0?'ACTIVE '+p.spaceTime.toFixed(1)+'s':p.dashCooldown>0?p.dashCooldown.toFixed(1)+'s':'READY';$('hud-dash-fill').style.width=(1-p.dashCooldown/game.dashDuration())*100+'%';
 const attackTime=Math.max(p.rapidTime,p.furyTime,p.gearTime);$('hud-burst').textContent=attackTime>0?'ACTIVE '+attackTime.toFixed(1)+'s':p.novaCooldown>0?p.novaCooldown.toFixed(1)+'s':'READY';$('hud-burst-fill').style.width=(1-p.novaCooldown/game.attackCooldown())*100+'%';
 $('defense-name').textContent=(defensive?.name||'Defense')+' · Space';$('active-name').textContent=(offensive?.name||'Offense')+' · E';$('touch-dash').textContent='SPACE';$('touch-dash').title=defensive?.name||'Defense';$('touch-ability').title=offensive?.name||'Offense';
$('hp-text').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('hp-fill').style.width=(p.hp/p.maxHp*100)+'%';$('xp-text').textContent=`${Math.floor(p.xp)} / ${p.xpNext}`;$('xp-fill').style.width=(p.xp/p.xpNext*100)+'%';$('level-badge').textContent='LV. '+p.level;$('coins').textContent=p.coins;$('kills').textContent=p.kills;
 $('wave').textContent=`WAVE ${String(game.wave).padStart(2,'0')} / ${game.endless?'∞ ENDLESS':'20'}`;const remaining=Math.max(0,Math.ceil(waveDuration(game.wave)-game.waveTime));$('timer').textContent=String(Math.floor(remaining/60)).padStart(2,'0')+':'+String(remaining%60).padStart(2,'0')+' LEFT';
 $('phase').textContent=isBossWave(game.wave)?(game.bossSpawned&&!game.enemies.some(e=>e.kind==='boss')?'GUARDIAN DOWN · SURVIVE':'GUARDIAN · 75s DEADLINE'):regionAt(p).name.toUpperCase();
 updateWaveClock();
 $('location').textContent=`${Math.round(p.x)}, ${Math.round(p.y)} · ${game.chestQueue.length+game.chests.length} chests secured / dropped`;
 const nearby=game.chests.some(c=>Math.hypot(c.x-p.x,c.y-p.y)<90);$('interact-hint').hidden=!nearby||game.state!=='playing';
 $('weapon-description').textContent=`${Math.round(game.attackDamage())} hit · ${p.element}${p.multi?' · triple shot':''}${p.piercing?' · pierces 3':p.ricochet?' · ricochet':' · first hit stops'}`;
 $('dash-status').textContent=p.spaceTime>0?`Active · ${p.spaceTime.toFixed(1)}s`:p.dashCooldown>0?`Recovering · ${p.dashCooldown.toFixed(1)}s`:defensive?.text||'Choose before starting';
 $('pet-status').textContent=game.pets.length?game.pets.map(p=>p.kind==='fox'?'Fox · fan darts':p.kind==='wolf'?'Wolf · bite + howl':'Beetle · coin/XP collector').join(' + '):'Unlock companions in the shop';
 $('armor-stat').textContent=p.armor+' · '+Math.round(100-10000/(100+p.armor*6))+'% reduction';$('speed-stat').textContent=Math.round(game.moveSpeed())+' / sec';$('passive-status').textContent=equipmentSummary(5)||'Inspect equipment in Inventory · B';
 $('element-base-stat').textContent=p.elementalDamage.toFixed(1);$('element-rank-stat').textContent=`Power ${p.elementUpgrades.power} · Duration ${p.elementUpgrades.duration} · Ability ${p.elementUpgrades.special}`;
 for(const button of document.querySelectorAll('[data-element]')){const el=button.dataset.element,equipped=p.element===el;button.classList.toggle('equipped',equipped);button.classList.toggle('locked',!equipped);button.setAttribute('aria-pressed',String(equipped));button.title=equipped?'Currently equipped':el==='physical'?'Attunement replaces physical arrows':'Open shop to swap elements (clears old elemental ranks)';}
 $('pickup-radius').textContent=p.magnet+' pickup radius';
 minimap();
 $('active-status').textContent=attackTime>0?`Active · ${attackTime.toFixed(1)}s`:p.novaCooldown>0?`Recharging · ${p.novaCooldown.toFixed(1)}s`:offensive?.text||'Choose before starting';
 const boss=game.enemies.find(e=>e.kind==='boss');$('boss-hud').hidden=!boss;
 if(boss && lastBoss!==game.wave){lastBoss=game.wave;bossBannerUntil=performance.now()+2600;$('boss-arrival-name').textContent=boss.name;$('boss-arrival-tip').textContent=['Dodge the charge. Strike while he recovers.','Keep moving between the frozen volleys.','Break through the summons. End the long night.','Avoid the impact circles and threaded golden barrages.'][boss.tier-1];beep(180,.5,'triangle');}
 $('boss-arrival').hidden=!boss || performance.now()>bossBannerUntil || game.state!=='playing';
 document.querySelector('.arena-panel').classList.toggle('boss-wave',!!boss);
 if(boss){$('boss-name').textContent=boss.name;$('boss-hp').textContent=`${Math.ceil(boss.hp)} / ${boss.maxHp}`;$('boss-fill').style.width=(boss.hp/boss.maxHp*100)+'%';}
 for(let i=1;i<=4;i++){const el=$('journey-'+i);el.classList.toggle('done',game.bossesDefeated>=i);el.querySelector('.journey-check').textContent=game.bossesDefeated>=i?'✓':'◇';}
}
function minimap(){
 const c=$('minimap'),m=c.getContext('2d'),sx=c.width/WORLD.width,sy=c.height/WORLD.height;
 m.fillStyle='#13291de8';m.fillRect(0,0,c.width,c.height);
 for(const r of REGIONS){m.fillStyle=r.color;m.beginPath();m.ellipse(r.x*sx,r.y*sy,r.r*sx,r.r*sy,0,0,Math.PI*2);m.fill();}
 for(const c of game.chests){m.fillStyle=c.tier==='mythical'?'#ff5369':'#83d99c';m.fillRect(c.x*sx-1,c.y*sy-1,2,2);}
 for(const e of game.enemies)if(e.kind==='boss'){m.fillStyle='#f2a4d8';m.beginPath();m.arc(e.x*sx,e.y*sy,4,0,Math.PI*2);m.fill();}
 m.fillStyle='#fff6d2';m.beginPath();m.arc(game.player.x*sx,game.player.y*sy,3,0,Math.PI*2);m.fill();
}
let lastHud=-Infinity,lastSceneState='',lastSceneCharacter='',lastSceneSize='';
function frame(now){
 const dt=(now-previous)/1000;previous=now;
 if(game.state==='playing')view.orbit?.(((keys.has('KeyR')?1:0)-(keys.has('KeyQ')?1:0))*Math.min(.25,dt)*1.8);
 const x=(keys.has('KeyD')||keys.has('ArrowRight')?1:0)-(keys.has('KeyA')||keys.has('ArrowLeft')?1:0),y=(keys.has('KeyS')||keys.has('ArrowDown')?1:0)-(keys.has('KeyW')||keys.has('ArrowUp')?1:0);
 advanceGame(game,dt,view.movement?view.movement(x,y):{moveX:x,moveY:y});
 if(now-lastAutosave>10000){if(game.state==='dead')clearSavedRun();else saveRun();lastAutosave=now;}
 if(game.message){toast(game.message);game.message='';}if(game.event){beep(game.event==='hurt'?130:game.event==='boss'?880:440,.15);game.event=null;}
 const sceneSize=canvas.clientWidth+':'+canvas.clientHeight;if(game.state==='playing'||lastSceneState!==game.state||lastSceneCharacter!==game.character||sceneSize!==lastSceneSize||view.needsRedraw?.()){view.render(now/1000);lastSceneState=game.state;lastSceneCharacter=game.character;lastSceneSize=sceneSize;}if(now-lastHud>=100 || shown!==game.state){hud();lastHud=now;}showState();requestAnimationFrame(frame);
}
function setGraphics(mode) {
  lastSceneState='';
  const wasPlaying = game.state === 'playing';
  view?.dispose();
  const replacement=canvas.cloneNode(false); canvas.replaceWith(replacement); canvas=replacement;
  try { view=mode==='3d'?createBabylonRenderer(canvas,game):create2DRenderer(canvas,game); graphics=mode; }
  catch (error) {
    console.warn('3D rendering unavailable; using the illustrated view.',error.message);document.querySelectorAll('.combat-feedback').forEach(c=>c.remove());
    const fallback=canvas.cloneNode(false);canvas.replaceWith(fallback);canvas=fallback;
    view=create2DRenderer(canvas,game);graphics='2d';toast('3D needs WebGL2 · switched to the illustrated view');
  }
  canvas.dataset.renderer=graphics==='3d'?view.engineName:'Canvas 2D';
  $('graphics-button').textContent=graphics==='3d'?'3D VIEW':'2D VIEW';
  $('graphics-button').setAttribute('aria-label',graphics==='3d'?'Switch to 2D graphics':'Switch to 3D graphics');
  view.setQuality?.(quality);lastSceneState='';$('detail-button').textContent='Detail: '+(quality==='high'?'High':'Low');
  updateCameraLabel();
  let pointer=null,drag=false;
  canvas.addEventListener('wheel',e=>{if(view.zoom){e.preventDefault();view.zoom(e.deltaY);}},{passive:false});
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
