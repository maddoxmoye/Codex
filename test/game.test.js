import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, BOSSES } from '../src/game.js';
const create=()=>{const g=new Game(()=>.5);g.start();g.spawnTime=999;return g;};
function advance(g,seconds,input={}){for(let i=0;i<seconds*20;i++)g.update(.05,input);}
test('movement is normalized, bounded, and paused outside play',()=>{
 const g=create(),start={...g.player};g.update(.05,{right:true,down:true});
 assert.ok(Math.abs(Math.hypot(g.player.x-start.x,g.player.y-start.y)-8.25)<.001);
 g.player.x=977;g.update(.05,{right:true});assert.equal(g.player.x,978);
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
 const g=create();g.player.multi=true;g.player.frost=true;g.player.regen=true;g.player.hp=70;
 const e={x:590,y:330,r:18,hp:500,slow:0,speed:0,damage:0,kind:'brute'};g.enemies.push(e);g.update(.05);assert.equal(g.bullets.length,3);
 advance(g,.3);assert.ok(e.slow>0);assert.ok(g.player.hp>70);assert.ok(e.hp<500);
});
