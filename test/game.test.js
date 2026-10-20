import test from 'node:test';
import assert from 'node:assert/strict';
import {Game,WORLD,REGIONS,regionAt,SHOP,BOSSES,xpForLevel,advanceGame} from '../src/game.js';
import {SCENERY,SOLIDS,STRUCTURES,CHESTS,blocked,moveBody,projectileBlocked,findFree} from '../src/world.js';
const create=()=>{const g=new Game(()=>.5);g.start();g.obstacles=[];g.spawnTime=999;g.player.x=500;g.player.y=330;return g;};
const enemy=(x=650,y=330,hp=500)=>({x,y,r:12,hp,speed:0,damage:0,slow:0,kind:'brute'});
const advance=(g,seconds,input={})=>{for(let i=0;i<Math.round(seconds*60);i++)advanceGame(g,1/60,input);};
function wealthy(g,level=5){g.player.level=level;g.player.coins=10000;g.openShop();}
function stockBuy(g,id){g.shopOffers=[{id,sold:false}];return g.buy(id);}

test('movement is normalized, bounded and frozen in menus',()=>{
 const g=create(),p=g.player;g.update(.05,{right:true,down:true});assert.ok(Math.abs(Math.hypot(p.x-500,p.y-330)-10.5)<.001);
 p.x=WORLD.width-23;g.update(.05,{right:true});assert.equal(p.x,WORLD.width-22);g.openShop();const x=p.x;advance(g,1,{left:true});assert.equal(p.x,x);
});
test('elapsed movement and time match at 10 and 60 FPS; long catch-up is bounded',()=>{
 const a=create(),b=create();for(let i=0;i<60;i++)advanceGame(a,1/60,{right:true});for(let i=0;i<10;i++)advanceGame(b,.1,{right:true});
 assert.ok(Math.abs(a.time-1)<1e-6);assert.ok(Math.abs(a.player.x-b.player.x)<1e-6);assert.ok(Math.abs(b.player.x-710)<1e-6);
 const g=create();advanceGame(g,10);assert.ok(Math.abs(g.time-.25)<1e-6);g.openShop();advanceGame(g,10);assert.ok(Math.abs(g.time-.25)<1e-6);
});
test('shared scenery keeps wide trails clear and uses substantially fewer trees',()=>{
 assert.ok(SCENERY.filter(o=>o.type==='tree').length<200);assert.ok(SCENERY.filter(o=>o.type==='tree').length>40);
 for(const r of REGIONS.slice(1))for(let t=.2;t<.85;t+=.1){const p={x:2400+(r.x-2400)*t,y:2000+(r.y-2000)*t};assert.equal(blocked(p,30,SCENERY),false);}
 assert.ok(SOLIDS.includes(SCENERY[0]));assert.equal(regionAt({x:1000,y:1000}).name,'Frostveil Ruins');
});
test('trees, rocks, buildings and chests stop walking and dashes',()=>{
 for(const o of [SCENERY.find(o=>o.type==='tree'),SCENERY.find(o=>o.type==='rock'),STRUCTURES[0],CHESTS[0]]){
  const g=create();g.obstacles=[o];g.player.x=o.x-o.r-g.player.r-2;g.player.y=o.y;g.player.dx=1;g.player.dy=0;
  advance(g,1,{right:true});assert.ok(g.player.x<=o.x-o.r-g.player.r+.01);assert.equal(blocked(g.player,g.player.r,g.obstacles),false);
  g.dash();advance(g,.3,{right:true});assert.ok(g.player.x<=o.x-o.r-g.player.r+.01);
 }
});
test('diagonal movement slides and spawn recovery returns a clear position',()=>{
 const obstacles=[{x:150,y:150,r:35,height:200}],body={x:102,y:150,r:13};moveBody(body,30,45,obstacles);assert.ok(body.y>150);assert.equal(blocked(body,13,obstacles),false);
 assert.equal(blocked(findFree({x:150,y:150},13,obstacles),13,obstacles),false);
});
test('solid tall scenery blocks arrows along the full flight segment',()=>{
 const g=create(),o={x:550,y:330,r:20,height:200};g.obstacles=[o];const e=enemy(630);g.enemies=[e];g.player.fireTimer=999;g.arrow(g.player,e,100);
 advance(g,.5);assert.equal(e.hp,500);assert.equal(g.bullets.length,0);assert.equal(projectileBlocked({x:500,y:330},{x:630,y:330},g.obstacles),true);
});
test('automatic arrows defeat enemies and drops grant coins and XP',()=>{
 const g=create();g.player.damage=100;g.enemies=[enemy(600,330,20)];advance(g,.35);assert.equal(g.player.kills,1);assert.equal(g.pickups.length,2);
 g.player.x=598;advance(g,.6);assert.equal(g.player.coins,3);assert.equal(g.player.xp,5);
});
test('XP scales, keeps overflow and queues one stat draft per level until wave ends',()=>{
 const g=create();g.gainXP(100);assert.equal(g.player.level,4);assert.equal(g.player.xp,17);assert.equal(g.player.xpNext,xpForLevel(4));assert.equal(g.freePicks,3);assert.deepEqual(g.levelRewards,[2,3,4]);assert.equal(g.state,'playing');
 assert.ok(xpForLevel(8)>xpForLevel(4));g.nextWave();assert.equal(g.state,'draft');assert.equal(g.draftChoices.length,4);assert.equal(new Set(g.draftChoices.map(c=>c.id)).size,4);
 assert.equal(g.closeShop(),false);assert.equal(g.chooseUpgrade('invalid'),false);assert.equal(g.freePicks,3);
 for(let left=3;left>0;left--){assert.equal(g.freePicks,left);assert.equal(g.chooseUpgrade(g.draftChoices[0].id),true);}
 assert.equal(g.freePicks,0);assert.equal(g.state,'shop');assert.equal(g.shopOffers.length,4);assert.equal(g.player.coins,0);g.closeShop();assert.equal(g.wave,2);
});
test('draft choices apply the advertised permanent stats and never spend gold',()=>{
 for(const id of ['health','damage','elemental','armor','speed']){
  const g=create(),p=g.player;p.hp=50;g.gainXP(20);g.nextWave();g.draftChoices=[{id}];assert.equal(g.chooseUpgrade(id),true);assert.equal(p.coins,0);
  if(id==='health'){assert.equal(p.maxHp,115);assert.equal(p.hp,65);}
  if(id==='damage')assert.ok(Math.abs(p.damage-20.7)<1e-6);
  if(id==='elemental'){assert.ok(Math.abs(p.elementalDamage-14.4)<1e-6);g.swapElement('ice');assert.ok(Math.abs(g.profile().hit-14.4)<1e-6);}
  if(id==='armor')assert.equal(p.armor,2);
  if(id==='speed')assert.equal(p.speed,224.70000000000002);
 }
});
test('shop offers four distinct eligible items; slots sell once and unoffered purchases fail',()=>{
 const g=create();wealthy(g);assert.equal(g.shopOffers.length,4);assert.equal(new Set(g.shopOffers.map(i=>i.id)).size,4);
 for(const slot of g.shopOffers)assert.equal(g.offer(SHOP.find(i=>i.id===slot.id)).available,true);
 const absent=SHOP.find(i=>g.offer(i).available&&!g.shopOffers.some(s=>s.id===i.id));assert.equal(g.buy(absent.id),false);
 const before=g.player.coins,slot=g.shopOffers[0],price=g.offer(SHOP.find(i=>i.id===slot.id)).price;
 assert.equal(g.buy(slot.id),true);assert.equal(g.player.coins,before-price);assert.equal(slot.sold,true);assert.equal(g.buy(slot.id),false);assert.equal(g.shopOffers.length,4);
 g.closeShop();assert.equal(g.buy(g.shopOffers[1].id),false);
});
test('all four offers can be bought; rerolls escalate, reject insufficient gold and reset only after a completed wave',()=>{
 const g=create();wealthy(g);g.shopOffers=['power','speed','element-base','armor'].map(id=>({id,sold:false}));
 for(const slot of g.shopOffers)assert.equal(g.buy(slot.id),true);assert.ok(g.shopOffers.every(s=>s.sold));
 const balance=g.player.coins;assert.equal(g.rerollCost(),5);assert.equal(g.reroll(),true);assert.equal(g.player.coins,balance-5);assert.equal(g.rerollCost(),10);assert.ok(g.shopOffers.every(s=>!s.sold));
 assert.equal(g.reroll(),true);assert.equal(g.rerollCost(),15);const slots=JSON.stringify(g.shopOffers);g.closeShop();g.openShop();assert.equal(g.rerollCost(),15);assert.equal(JSON.stringify(g.shopOffers),slots);
 g.player.coins=14;assert.equal(g.reroll(),false);assert.equal(g.player.coins,14);assert.equal(g.rerollCost(),15);
 g.closeShop();g.nextWave();assert.equal(g.rerollCost(),5);g.player.coins=100;g.reroll();assert.equal(g.rerollCost(),10);const postWave=JSON.stringify(g.shopOffers);g.closeShop();g.openShop();assert.equal(g.rerollCost(),10);assert.equal(JSON.stringify(g.shopOffers),postWave);
 g.closeShop();g.nextWave();assert.equal(g.rerollCost(),5);
 g.closeShop();g.nextWave();assert.equal(g.rerollCost(),7);
});
test('attunement is exclusive and swapping removes ranks, status effects and old arrows',()=>{
 const g=create();wealthy(g);stockBuy(g,'element-base');stockBuy(g,'power');stockBuy(g,'fire');stockBuy(g,'fire-power');stockBuy(g,'fire-duration');stockBuy(g,'fire-special');
 const shared=g.player.elementalDamage,physical=g.player.damage;assert.equal(g.profile().duration,4);assert.equal(g.profile().special,1);
 const e=enemy();g.enemies=[e];g.statusHit(e,'fire');g.arrow(g.player,e,g.attackDamage());assert.ok(e.burn>0);assert.ok(g.bullets.length);
 assert.equal(stockBuy(g,'ice'),true);assert.equal(g.player.element,'ice');assert.deepEqual(g.player.elementUpgrades,{power:0,duration:0,special:0});assert.equal(g.player.elementalDamage,shared);assert.equal(g.player.damage,physical);assert.equal(e.burn,0);assert.equal(g.bullets.length,0);
 assert.equal(stockBuy(g,'fire-power'),false);assert.equal(g.selectElement('fire'),false);assert.equal(g.player.element,'ice');stockBuy(g,'ice-power');stockBuy(g,'fire');assert.equal(g.player.elementUpgrades.power,0);
});
test('shared elemental damage boosts each affinity while specialization stays local',()=>{
 const g=create();wealthy(g);for(const el of ['fire','ice','poison']){stockBuy(g,el);const before=g.attackDamage();stockBuy(g,'element-base');assert.ok(g.attackDamage()>before);stockBuy(g,el+'-power');assert.ok(g.profile().hit>g.player.elementalDamage);}
 assert.equal(g.player.element,'poison');assert.equal(g.offer(SHOP.find(i=>i.id==='ice-special')).available,false);
});
test('elemental rank caps and level gates apply to shop offers',()=>{
 const g=create();wealthy(g,1);stockBuy(g,'ice');assert.equal(stockBuy(g,'ice-special'),false);assert.equal(g.player.coins,9975);
 for(let i=0;i<5;i++)assert.equal(stockBuy(g,'ice-power'),true);assert.equal(stockBuy(g,'ice-power'),false);assert.equal(g.player.elementUpgrades.power,5);
});
test('fire burns and explosive embers splash nearby enemies',()=>{
 const g=create();g.swapElement('fire');g.player.elementUpgrades.special=1;g.player.fireTimer=999;const a=enemy(600),b=enemy(625,350);g.enemies=[a,b];g.arrow(g.player,a,g.attackDamage());advance(g,.25);
 assert.ok(a.burn>0);assert.ok(b.burn>0);assert.ok(a.hp<470);assert.ok(b.hp<500);
});
test('ice chills and shatter adds damage to already chilled targets',()=>{
 const g=create();g.swapElement('ice');g.player.elementUpgrades.special=1;g.player.fireTimer=999;const e=enemy(600);g.enemies=[e];g.statusHit(e,'ice');g.arrow(g.player,e,g.attackDamage());advance(g,.25);
 assert.ok(e.slow>0);assert.equal(e.slowStrength,.45);assert.ok(e.hp<=464);
});
test('poison stacks, expires, and contagion spreads on a poisoned death',()=>{
 const g=create();g.swapElement('poison');g.player.elementUpgrades.special=1;g.player.fireTimer=999;const a=enemy(600),b=enemy(650);g.enemies=[a,b];for(let i=0;i<9;i++)g.statusHit(a,'poison');assert.equal(a.poisonStacks,5);
 advance(g,.25);assert.ok(a.hp<500);a.hp=0;g.update(.01);assert.ok(b.poison>0);assert.equal(g.player.kills,1);advance(g,5);assert.equal(b.poisonStacks,0);
});
test('fox fan darts and wolf bites/howls stay independent of selected element',()=>{
 const g=create();g.swapElement('ice');g.player.pet=true;g.player.wolf=true;g.player.fireTimer=999;const e=enemy(410,385);g.enemies=[e];g.update(.05);
 assert.equal(g.pets.length,2);assert.equal(g.bullets.length,3);assert.ok(g.bullets.every(b=>b.kind==='pet'&&b.element==='physical'));assert.ok(e.hp<500);assert.ok(e.petSlow>0);assert.equal(e.slow,0);
 const damage=g.bullets[0].damage;g.player.elementalDamage=1000;g.swapElement('fire');assert.equal(g.bullets.length,3);assert.equal(g.bullets[0].damage,damage);assert.ok(e.petSlow>0);
 g.update(.05);assert.ok(e.petSlow>0);assert.equal(e.burn||0,0);
});
test('collector seeks nearby coin and XP drops without stealing heals or awarding twice',()=>{
 const g=create();g.player.collector=true;g.player.fireTimer=999;g.pickups=[{x:365,y:385,kind:'xp',amount:20,r:5},{x:360,y:385,kind:'coin',amount:12,r:5},{x:365,y:385,kind:'heal',amount:12,r:5}];
 const xp=g.pickups[0];advance(g,2);assert.equal(g.player.level,2);assert.equal(g.player.xp,0);assert.equal(g.freePicks,1);assert.equal(g.state,'playing');assert.equal(g.player.coins,12);assert.equal(g.pickups.length,1);assert.equal(g.pickups[0].kind,'heal');g.collect(xp);assert.equal(g.player.xp,0);assert.equal(g.bullets.length,0);
});
test('pets roam when idle, navigate solid objects and remain near a moving player',()=>{
 const g=create();g.player.pet=true;g.player.wolf=true;advance(g,2);assert.equal(g.pets.length,2);assert.ok(g.pets.every(p=>Math.hypot(p.x-g.player.x,p.y-g.player.y)>70));
 for(let i=0;i<600;i++){advanceGame(g,1/60,{right:true});for(const pet of g.pets)assert.ok(Math.hypot(pet.x-g.player.x,pet.y-g.player.y)<280);}
 const pet=g.pets[0];g.obstacles=[{x:pet.x+50,y:pet.y,r:30,height:100}];advance(g,2);assert.equal(blocked(pet,pet.r,g.obstacles),false);
});
test('wave breaks open a frozen shop and advance only on continue',()=>{
 const g=create();g.waveTime=25;g.update(.01);assert.equal(g.state,'shop');assert.equal(g.wave,1);assert.equal(g.pendingWave,2);assert.equal(g.shopReason,'wave');const time=g.time;advance(g,2);assert.equal(g.time,time);
 g.closeShop();assert.equal(g.wave,2);assert.equal(g.state,'playing');assert.equal(g.waveTime,0);
});
test('level-up and wave clear in the same tick share one shop without losing rewards',()=>{
 const g=create();g.player.xp=15;g.waveTime=25;g.pickups=[{x:500,y:330,kind:'xp',amount:5}];g.update(.01);
 assert.equal(g.player.level,2);assert.equal(g.freePicks,1);assert.equal(g.shopReason,'wave');assert.equal(g.pendingWave,2);assert.equal(g.state,'draft');assert.equal(g.closeShop(),false);g.chooseUpgrade(g.draftChoices[0].id);g.closeShop();assert.equal(g.wave,2);assert.equal(g.freePicks,0);
});
test('all nine waves, intermissions and guardians reach victory',()=>{
 const g=create();for(let wave=1;wave<=9;wave++){
  assert.equal(g.wave,wave);if(wave%3===0){g.update(.01);g.enemies.find(e=>e.kind==='boss').hp=0;g.update(.01);}else{g.waveTime=25;g.update(.01);}
  if(wave<9){assert.equal(g.state,'shop');g.closeShop();}
 }
 assert.equal(g.state,'won');assert.equal(g.bossesDefeated,3);assert.equal(g.player.coins,180);
});
test('boss patterns remain distinct and solid objects stop charges',()=>{
 for(let tier=1;tier<=3;tier++){
  const g=create();g.wave=tier*3;g.update(.01);const boss=g.enemies.find(e=>e.kind==='boss');assert.equal(boss.name,BOSSES[tier-1]);boss.attack=0;g.update(.01);if(tier===1)assert.ok(boss.charge>0);else assert.equal(g.hostile.length,tier===2?12:16);
 }
 const g=create();g.wave=3;const b=g.spawn(true);b.x=600;b.y=330;b.charge=.6;b.cx=-1;b.cy=0;g.bossSpawned=true;g.obstacles=[{x:540,y:330,r:20,height:200}];advance(g,.3);assert.ok(b.x>=575-1);
});
test('chests award once, health and XP reset per run, and death stops play',()=>{
 const g=create(),c=g.chests[0];g.player.x=c.x;g.player.y=c.y;assert.equal(g.interact(),true);assert.equal(g.interact(),false);assert.equal(g.player.coins,25);assert.equal(g.player.xp,10);
 g.hurt(200);assert.equal(g.state,'dead');g.start();assert.equal(g.player.level,1);assert.equal(g.freePicks,0);assert.equal(g.chests[0].opened,false);
});
test('dash cooldown and burst use the active affinity without an unrelated ice effect',()=>{
 const g=create();assert.equal(g.dash(),true);g.hurt(40);assert.equal(g.player.hp,100);assert.equal(g.dash(),false);
 const e=enemy(530);g.enemies=[e];g.player.nova=1;assert.equal(g.nova(),true);assert.equal(e.slow,0);assert.equal(g.bullets.length,12);assert.equal(g.nova(),false);
});

test('armor reduces real incoming damage with diminishing returns',()=>{
 const g=create();g.player.armor=5;g.hurt(26);assert.equal(g.player.hp,80);g.player.invincible=0;g.player.armor=10;g.hurt(32);assert.equal(g.player.hp,60);
});
test('Trailrunner ramps speed, resets when stopped and respects solid scenery',()=>{
 const g=create();g.player.momentum=true;advance(g,2,{right:true});assert.ok(Math.abs(g.player.momentumTime-2)<1e-6);assert.ok(Math.abs(g.moveSpeed()-283.5)<1e-6);g.update(.01);assert.equal(g.moveSpeed(),210);
 g.obstacles=[{x:g.player.x+60,y:g.player.y,r:20,height:200}];advance(g,2,{right:true});assert.equal(blocked(g.player,g.player.r,g.obstacles),false);
});
test('Gale boots shorten cooldown; Thunderstep damages and slows without using elemental stats',()=>{
 const g=create();g.player.gale=true;g.player.dashburst=true;g.player.elementalDamage=999;const e=enemy(550);g.enemies=[e];assert.equal(g.dash(),true);assert.equal(g.player.dashCooldown,1.6);assert.equal(e.hp,473);assert.equal(e.petSlow,1.5);assert.equal(e.slow,0);assert.equal(g.effects[0].element,'physical');
});
test('Echo arrows bounce once for 65% damage and do not hit the first enemy again',()=>{
 const g=create();g.player.ricochet=true;g.player.fireTimer=999;const a=enemy(590),b=enemy(680);g.enemies=[a,b];g.arrow(g.player,a,100);advance(g,.6);assert.equal(a.hp,400);assert.equal(b.hp,435);assert.equal(g.bullets.length,0);
});
test('Harvest pact heals on every fifth kill and caps at maximum health',()=>{
 const g=create();g.player.reaper=true;g.player.hp=95;g.player.kills=4;g.enemies=[enemy(650,330,0)];g.update(.01);assert.equal(g.player.hp,100);g.enemies=[enemy(650,330,0)];g.player.hp=90;g.update(.01);assert.equal(g.player.hp,90);
});

test('final-wave earned stat rewards are resolved before victory',()=>{
 const g=create();g.wave=9;g.gainXP(20);g.nextWave();assert.equal(g.state,'draft');assert.equal(g.freePicks,1);g.chooseUpgrade(g.draftChoices[0].id);assert.equal(g.state,'won');assert.equal(g.freePicks,0);
});
