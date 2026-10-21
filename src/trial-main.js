import {Game,advanceGame} from './game.js';
import {findFree} from './world.js';
import {createTrialRenderer} from './trial-renderer.js';

const $=id=>document.getElementById(id),canvas=$('trial-canvas');
// A fresh, in-memory practice game: this page never reads or writes saved progress.
const game=new Game();let view,playing=false,paused=false,started=false,cameraFree=false,quality=innerWidth>750,previous=performance.now(),spawnTimer=0,serial=0,drag=null,hudTime=0;
const keys=new Set(),reducedMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;
function spawn(){
 const kinds=['crawler','archer','brute'],kind=kinds[serial%3],e=game.spawn(false,kind),a=serial*2.399+.7;serial++;
 const p=game.player,range=kind==='archer'?400:440;
 Object.assign(e,{x:Math.max(1580,Math.min(3220,p.x+Math.cos(a)*range)),y:Math.max(1180,Math.min(2820,p.y+Math.sin(a)*range)),hp:kind==='brute'?145:kind==='archer'?80:66,maxHp:kind==='brute'?145:kind==='archer'?80:66,speed:kind==='brute'?48:kind==='archer'?65:80,damage:kind==='brute'?17:9,attack:2});Object.assign(e,findFree(e,e.r,game.obstacles));
}
function setElement(element){
 game.player.element=element;game.player.elementUpgrades={power:0,duration:0,special:element==='fire'?1:0};
 $('trial-element-name').textContent=element==='physical'?'LONGBOW':element.toUpperCase();
 document.querySelectorAll('[data-trial-element]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.trialElement===element)));
 if(started)canvas.focus();
}
function reset(){
 const element=started?game.player.element:'fire';
 game.start();game.obstacles=[{x:1700,y:1700,r:80},{x:3200,y:1400,r:100},{x:1500,y:2500,r:90},{x:3300,y:2600,r:80},{x:1950,y:1400,r:36},{x:2760,y:1200,r:38},{x:1800,y:1800,r:15}];
 Object.assign(game.player,{hp:100,maxHp:100,regenRate:1.1,fireRate:.78,damage:14,elementalDamage:8,critChance:.12});
 setElement(element||'fire');game.spawnTime=999;spawnTimer=4;serial=0;for(let i=0;i<3;i++)spawn();
 keys.clear();paused=false;playing=started;game.player.fireTimer=.3;
}
function enter(){started=true;playing=true;paused=false;reset();$('intro').hidden=true;$('trial-vitals').hidden=false;$('trial-skills').hidden=false;$('trial-pause').hidden=false;$('trial-touch').hidden=false;document.body.classList.add('playing');canvas.focus();}
function pause(value=true){
 if(!started)return;if(game.state==='dead')value=true;paused=value;keys.clear();$('trial-message').hidden=!value;
 $('trial-message-title').textContent=game.state==='dead'?'The woods got the last word.':'A moment in the sun.';
 $('trial-message-copy').textContent=game.state==='dead'?'Restart this practice clearing to try again. Your main-game progress is untouched.':'Move around, try the elements, and inspect the new look. This is a small visual study, with a gentler practice encounter.';
 $('trial-resume').hidden=game.state==='dead';$('trial-pause').textContent=value?'Resume':'Pause';
 if(!value)canvas.focus();
}
function dash(){if(playing&&!paused)game.dash();}
function volley(){if(playing&&!paused)game.nova();}
function toggleCamera(){cameraFree=!cameraFree;$('trial-camera').textContent=cameraFree?'Camera: Free':'Camera: Drag';$('trial-camera').setAttribute('aria-pressed',String(cameraFree));}
$('enter-trial').onclick=enter;$('trial-pause').onclick=()=>pause(!paused);$('trial-resume').onclick=()=>pause(false);$('trial-restart').onclick=()=>{reset();pause(false);};
$('trial-camera').onclick=toggleCamera;$('trial-detail').onclick=()=>{quality=!quality;view?.setQuality(quality);$('trial-detail').textContent='Detail: '+(quality?'High':'Low');$('trial-detail').setAttribute('aria-pressed',String(quality));};
$('trial-dash').onclick=()=>{dash();canvas.focus();};$('trial-volley').onclick=()=>{volley();canvas.focus();};
$('trial-fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await $('trial-stage').requestFullscreen();}catch{$('trial-stage').classList.toggle('expanded');}};
document.addEventListener('fullscreenchange',()=>{$('trial-fullscreen').textContent=document.fullscreenElement?'⤢ Exit fullscreen':'⛶ Fullscreen';keys.clear();});
document.querySelectorAll('[data-trial-element]').forEach(b=>b.onclick=()=>setElement(b.dataset.trialElement));
window.addEventListener('keydown',e=>{
 if(e.target.closest?.('button,a')&&['Space','Enter'].includes(e.code))return;
 if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code))e.preventDefault();keys.add(e.code);if(e.repeat)return;
 if(e.code==='Space')dash();if(e.code==='KeyE')volley();if(e.code==='KeyC')toggleCamera();if(e.code==='Escape')pause(!paused);
 const element={Digit0:'physical',Digit1:'fire',Digit2:'ice',Digit3:'poison'}[e.code];if(element)setElement(element);
});window.addEventListener('keyup',e=>keys.delete(e.code));
window.addEventListener('blur',()=>{keys.clear();drag=null;if(playing)pause(true);});document.addEventListener('visibilitychange',()=>{if(document.hidden&&playing)pause(true);});
canvas.oncontextmenu=e=>e.preventDefault();canvas.onpointerdown=e=>{drag={x:e.clientX,y:e.clientY,id:e.pointerId};canvas.setPointerCapture(e.pointerId);canvas.focus();};
canvas.onpointermove=e=>{if(paused)return;if(drag||cameraFree&&e.pointerType==='mouse'){const dx=drag?e.clientX-drag.x:e.movementX,dy=drag?e.clientY-drag.y:e.movementY;view?.look(Math.max(-60,Math.min(60,dx)),Math.max(-40,Math.min(40,dy)));if(drag){drag.x=e.clientX;drag.y=e.clientY;}}};
canvas.onpointerup=canvas.onpointercancel=()=>{drag=null;};canvas.addEventListener('wheel',e=>{e.preventDefault();view?.zoom(e.deltaY);},{passive:false});
for(const button of document.querySelectorAll('[data-trial-move]')){const key={left:'ArrowLeft',up:'ArrowUp',down:'ArrowDown',right:'ArrowRight'}[button.dataset.trialMove];button.onpointerdown=e=>{e.preventDefault();button.setPointerCapture(e.pointerId);keys.add(key);};button.onpointerup=button.onpointercancel=()=>keys.delete(key);}
function hud(){
 const p=game.player;$('trial-health').textContent=`${Math.ceil(p.hp)} / ${p.maxHp}`;$('trial-health-fill').style.width=`${Math.max(0,p.hp/p.maxHp)*100}%`;document.querySelector('.health-track').setAttribute('aria-valuenow',String(Math.ceil(p.hp)));$('trial-kills').textContent=`${p.kills} defeated`;
 $('dash-ready').textContent=p.dashCooldown>0?p.dashCooldown.toFixed(1)+'s':'READY';$('volley-ready').textContent=p.novaCooldown>0?p.novaCooldown.toFixed(1)+'s':'READY';
}
function frame(now){
 const dt=Math.min(.25,(now-previous)/1000);previous=now;
 if(playing&&!paused&&game.state==='playing'){
  game.waveTime=0;game.spawnTime=999;const x=(keys.has('KeyD')||keys.has('ArrowRight')?1:0)-(keys.has('KeyA')||keys.has('ArrowLeft')?1:0),y=(keys.has('KeyS')||keys.has('ArrowDown')?1:0)-(keys.has('KeyW')||keys.has('ArrowUp')?1:0);
  advanceGame(game,dt,view.movement(x,y));game.player.x=Math.max(1580,Math.min(3220,game.player.x));game.player.y=Math.max(1180,Math.min(2820,game.player.y));
  spawnTimer-=dt;if(spawnTimer<=0&&game.enemies.length<5){spawn();spawnTimer=3.5;}
  for(const number of game.damageNumbers)number.height=Math.max(1.9,number.height);game.chests=[];game.pickups=game.pickups.slice(-90);if(game.state==='dead')pause(true);
 }else if(!started){
  game.player.moving=false;game.player.fireTimer=.25;game.player.aimX=-.25;game.player.aimY=.97;
 }
 if(playing&&!paused&&game.state==='dead')pause(true);
 hudTime+=dt;if(hudTime>.1){hud();hudTime=0;}
 if(view)view.render(reducedMotion&&(!playing||paused)?0:now/1000,dt);
 requestAnimationFrame(frame);
}
try{reset();view=createTrialRenderer(canvas,$('trial-feedback'),game);view.setQuality(quality);$('trial-detail').textContent='Detail: '+(quality?'High':'Low');$('trial-detail').setAttribute('aria-pressed',String(quality));requestAnimationFrame(frame);}catch(error){console.error(error);$('trial-error').hidden=false;$('intro').hidden=true;}
