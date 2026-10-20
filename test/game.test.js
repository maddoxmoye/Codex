import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, BOSSES, WORLD, regionAt } from '../src/game.js';
const create=()=>{const g=new Game(()=>.5);g.start();g.spawnTime=999;g.player.x=500;g.player.y=330;return g;};
function advance(g,seconds,input={}){for(let i=0;i<seconds*20;i++)g.update(.05,input);}
test('movement is normalized, bounded, and paused outside play',()=>{
 const g=create(),start={...g.player};g.update(.05,{right:true,down:true});
 assert.ok(Math.abs(Math.hypot(g.player.x-start.x,g.player.y-start.y)-8.25)<.001);
 g.player.x=WORLD.width-23;g.update(.05,{right:true});assert.equal(g.player.x,WORLD.width-22);
 g.state='paused';const x=g.player.x;g.update(.05,{left:true});assert.equal(g.player.x,x);
});
test('auto fire damages enemies; kills drop collectible coins and XP',()=>{
 const g=create();g.player.damage=100;g.enemies.push({x:600,y:330,r:12,hp:20,speed:0,damage:0,slow:0,kind:'crawler'});
 advance(g,.5);assert.equal(g.player.kills,1);assert.equal(g.enemies.length,0);assert.equal(g.pickups.length,2);
 g.player.x=598;advance(g,.7);assert.equal(g.player.coins,3);assert.equal(g.player.xp,5);
});
test('XP queues levels and requires a valid reward choice per level',()=>{
 const g=create();g.gainXP(50);assert.equal(g.player.level,3);assert.equal(g.pendingLevels,2);assert.equal(g.state,'levelup');
 assert.equal(g.choose('invalid'),false);const choice=g.choices[0].id;assert.equal(g.choose(choice),true);assert.equal(g.state,'levelup');
 g.choose(g.choices[0].id);assert.equal(g.state,'playing');assert.equal(g.pendingLevels,0);
});
test('level two always offers arcane nova if still locked',()=>{
 const g=create();g.gainXP(20);assert.ok(g.choices.some(c=>c.id==='nova'));g.choose('nova');assert.equal(g.player.nova,1);
});
test('shop enforces state, coin costs, level gates and one-time ownership',()=>{
 const g=create();g.player.coins=200;assert.equal(g.buy('power'),false);g.openShop();
 assert.equal(g.buy('multi'),false);assert.equal(g.player.coins,200);assert.equal(g.buy('heal'),false);
 g.player.hp=20;assert.equal(g.buy('heal'),true);assert.equal(g.player.hp,80);assert.equal(g.player.coins,180);
 g.player.level=4;assert.equal(g.buy('multi'),true);assert.equal(g.player.multi,true);assert.equal(g.buy('multi'),false);assert.equal(g.player.coins,105);
 assert.equal(g.buy('power'),true);assert.equal(g.player.damage,22.5);g.closeShop();assert.equal(g.state,'playing');
});
test('dash grants invulnerability and cannot be spammed',()=>{
 const g=create();assert.equal(g.dash(),true);g.hurt(50);assert.equal(g.player.hp,100);assert.equal(g.dash(),false);
 advance(g,3);assert.equal(g.dash(),true);
});
test('nova unlock, area damage, projectile clearing, and cooldown',()=>{
 const g=create();assert.equal(g.nova(),false);g.player.nova=1;
 const e={x:530,y:330,r:12,hp:200,slow:0};g.enemies.push(e);g.hostile=[{x:540,y:330},{x:900,y:400}];
 assert.equal(g.nova(),true);assert.equal(e.hp,120);assert.equal(e.slow,3);assert.equal(g.hostile.length,1);assert.equal(g.nova(),false);
});
test('bosses have distinct charge, barrage, and summoning patterns',()=>{
 for(let tier=1;tier<=3;tier++){
  const g=create();g.wave=tier*3;g.update(.05);const boss=g.enemies.find(e=>e.kind==='boss');assert.equal(boss.name,BOSSES[tier-1]);
  boss.attack=0;g.update(.05);
  if(tier===1)assert.ok(boss.charge>0);
  else assert.equal(g.hostile.length,tier===2?12:16);
  if(tier===3)assert.equal(g.enemies.length,3);
 }
});
test('all nine waves lead to victory, boss rewards, and tracked guardian defeats',()=>{
 const g=create();
 for(let wave=1;wave<=9;wave++){
  assert.equal(g.wave,wave);
  if(wave%3===0){g.update(.05);const b=g.enemies.find(e=>e.kind==='boss');b.hp=0;g.update(.05);}
  else{g.waveTime=25;g.update(.05);}
 }
 assert.equal(g.state,'won');assert.equal(g.bossesDefeated,3);assert.equal(g.player.coins,180);
});
test('damage causes death and restarting clears run progress',()=>{
 const g=create();g.player.coins=100;g.hurt(120);assert.equal(g.state,'dead');assert.equal(g.player.hp,0);
 g.start();assert.equal(g.state,'playing');assert.equal(g.player.hp,100);assert.equal(g.player.coins,0);assert.equal(g.wave,1);
});
test('shop and level-up menus freeze time and attacks',()=>{
 const g=create();g.openShop();advance(g,3);assert.equal(g.time,0);g.closeShop();g.gainXP(20);advance(g,3);assert.equal(g.time,0);
});
test('frost slows on impact, multi-shot fires three bolts, regeneration heals',()=>{
 const g=create();g.player.multi=true;g.player.frost=true;g.player.element='ice';g.player.regen=true;g.player.hp=70;
 const e={x:590,y:330,r:18,hp:500,slow:0,speed:0,damage:0,kind:'brute'};g.enemies.push(e);g.update(.05);assert.equal(g.bullets.length,3);
 advance(g,.3);assert.ok(e.slow>0);assert.ok(g.player.hp>70);assert.ok(e.hp<500);
});

test('the world is traversable far beyond the old arena and identifies its biomes',()=>{
 const g=create();g.player.x=2400;g.player.y=2000;advance(g,2,{right:true});assert.ok(g.player.x>2700);
 assert.equal(regionAt({x:1000,y:1000}).name,'Frostveil Ruins');assert.equal(regionAt({x:3700,y:1000}).name,'Ember Highlands');assert.equal(regionAt({x:3400,y:3200}).name,'Venom Marsh');
});
test('element selection requires unlocks, equips purchases and keeps each arrow element',()=>{
 const g=create();assert.equal(g.selectElement('poison'),false);g.player.coins=100;g.openShop();g.buy('fire');assert.equal(g.player.element,'fire');g.closeShop();
 g.arrow(g.player,{x:600,y:330},18,g.player.element);assert.equal(g.bullets[0].element,'fire');assert.equal(g.bullets[0].kind,'arrow');
 assert.equal(g.selectElement('physical'),true);assert.equal(g.bullets[0].element,'fire');
});
test('fire and poison deal damage over time and poison stacks cap at five',()=>{
 const g=create();const e={x:700,y:330,r:12,hp:500,speed:0,damage:0,slow:0,kind:'brute'};g.enemies.push(e);g.player.fireTimer=999;
 g.statusHit(e,'fire');g.statusHit(e,'poison');for(let i=0;i<9;i++)g.statusHit(e,'poison');assert.equal(e.poisonStacks,5);
 advance(g,1);assert.ok(e.hp<482);assert.ok(e.burn<3);assert.ok(e.poison<4);
 advance(g,5);assert.equal(e.poisonStacks,0);
});
test('unlocked companions follow their owner and fire real elemental projectiles',()=>{
 const g=create();g.player.pet=true;g.player.wolf=true;g.player.fireTimer=999;g.enemies.push({x:700,y:330,r:12,hp:500,speed:0,damage:0,slow:0,kind:'brute'});
 g.update(.05);assert.equal(g.pets.length,2);assert.equal(g.bullets.length,2);assert.deepEqual(g.bullets.map(b=>b.element),['fire','ice']);
 const x=g.pets[0].x;g.player.x+=100;g.update(.05);assert.ok(g.pets[0].x>x);
});
test('exploration chests require proximity and grant rewards only once per run',()=>{
 const g=create(),c=g.chests[0];assert.equal(g.interact(),false);g.player.x=c.x;g.player.y=c.y;
 assert.equal(g.interact(),true);assert.equal(g.player.coins,25);assert.equal(g.player.xp,10);assert.equal(c.opened,true);assert.equal(g.interact(),false);assert.equal(g.player.coins,25);
 g.start();assert.equal(g.chests[0].opened,false);
});
test('spawns stay near a moving player and inside world edges',()=>{
 const g=create();for(const [x,y] of [[2400,2000],[30,30],[4770,3970]]){g.player.x=x;g.player.y=y;const e=g.spawn();assert.ok(e.x>=30&&e.x<=4770);assert.ok(e.y>=30&&e.y<=3970);assert.ok(Math.hypot(e.x-x,e.y-y)<650);}
});
