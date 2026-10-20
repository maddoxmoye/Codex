export const WORLD = { width: 1000, height: 660 };
export const BOSSES = ['The Briar King', 'The Frost Oracle', 'The Hollow Monarch'];
export const UPGRADES = [
  { id: 'power', name: 'Kindled flame', icon: '→', text: '+25% bolt damage', apply: g => { g.player.damage *= 1.25; } },
  { id: 'haste', name: 'Quick hands', icon: 'ϟ', text: 'Attack 15% faster', apply: g => { g.player.fireRate *= .85; } },
  { id: 'vitality', name: 'Wild heart', icon: '♥', text: '+25 maximum health & heal 35', apply: g => { g.player.maxHp += 25; g.player.hp = Math.min(g.player.maxHp, g.player.hp + 35); } },
  { id: 'speed', name: 'Forest stride', icon: '➟', text: '+12% movement speed', apply: g => { g.player.speed *= 1.12; } },
  { id: 'nova', name: 'Arcane nova', icon: '✺', text: 'Unlock / empower your E ability', apply: g => { g.player.nova++; } },
  { id: 'magnet', name: 'Starlit compass', icon: '✧', text: '+50 pickup range & heal 15', apply: g => { g.player.magnet += 50; g.player.hp = Math.min(g.player.maxHp, g.player.hp + 15); } }
];
export const SHOP = [
  { id: 'heal', name: 'Forest tonic', icon: '♥', text: 'Restore 60 health', price: 20, level: 1, repeat: true },
  { id: 'power', name: 'Emberstone', icon: '→', text: '+25% bolt damage', price: 30, level: 1, repeat: true },
  { id: 'nova', name: 'Arcane nova', icon: '✺', text: 'Unlock / empower E burst', price: 40, level: 2, repeat: true },
  { id: 'frost', name: 'Frostbound', icon: '❄', text: 'Bolts slow enemies by 45%', price: 55, level: 3 },
  { id: 'multi', name: 'Split flame', icon: '⋔', text: 'Fire two extra ember bolts', price: 75, level: 4 },
  { id: 'regen', name: 'Living roots', icon: '❧', text: 'Regenerate 2 health / second', price: 90, level: 5 }
];
const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
export class Game {
  constructor(random = Math.random) { this.random = random; this.reset(); }
  reset() {
    this.state = 'title'; this.time = 0; this.wave = 1; this.waveTime = 0; this.spawnTime = 0;
    this.player = { x: 500, y: 330, r: 13, hp: 100, maxHp: 100, speed: 165, damage: 18, fireRate: .52, fireTimer: 0, level: 1, xp: 0, xpNext: 20, coins: 0, kills: 0, magnet: 60, dashCooldown: 0, dashTime: 0, dx: 1, dy: 0, invincible: 0, nova: 0, novaCooldown: 0, frost: false, multi: false, regen: false };
    this.enemies = []; this.bullets = []; this.hostile = []; this.pickups = []; this.effects = []; this.pendingLevels = 0; this.bossesDefeated = 0; this.bossSpawned = false; this.choices = []; this.message = ''; this.event = null;
  }
  start() { this.reset(); this.state = 'playing'; this.message = 'Wave 1 · Stay in the light'; }
  choose(id) {
    if (this.state !== 'levelup' || !this.choices.some(c => c.id === id)) return false;
    UPGRADES.find(c => c.id === id).apply(this); this.pendingLevels--;
    this.state = 'playing'; if (this.pendingLevels) this.levelChoices(); return true;
  }
  levelChoices() {
    this.state = 'levelup';
    this.choices = [...UPGRADES].map(c => ({ c, n: this.random() })).sort((a,b) => a.n-b.n).slice(0,3).map(x => x.c);
    if (this.player.level === 2 && !this.player.nova && !this.choices.some(c => c.id === 'nova')) this.choices[0] = UPGRADES.find(c => c.id === 'nova');
  }
  gainXP(amount) {
    this.player.xp += amount;
    while (this.player.xp >= this.player.xpNext) { this.player.xp -= this.player.xpNext; this.player.level++; this.player.xpNext = Math.floor(this.player.xpNext * 1.3); this.pendingLevels++; }
    if (this.pendingLevels && this.state === 'playing') this.levelChoices();
  }
  openShop() { if (this.state !== 'playing' && this.state !== 'paused') return false; this.shopReturn = this.state; this.state = 'shop'; return true; }
  closeShop() { if (this.state === 'shop') this.state = this.shopReturn || 'playing'; }
  buy(id) {
    if (this.state !== 'shop') return false;
    const item = SHOP.find(i => i.id === id); const p = this.player;
    if (!item || p.level < item.level || p.coins < item.price || (!item.repeat && p[id]) || (id === 'heal' && p.hp >= p.maxHp)) return false;
    p.coins -= item.price;
    if (id === 'heal') p.hp = Math.min(p.maxHp, p.hp + 60);
    else if (id === 'power') p.damage *= 1.25;
    else if (id === 'nova') p.nova++;
    else p[id] = true;
    return true;
  }
  dash() {
    const p = this.player;
    if (this.state !== 'playing' || p.dashCooldown > 0) return false;
    p.dashTime = .19; p.dashCooldown = 2.6; p.invincible = .3; this.event = 'dash'; return true;
  }
  nova() {
    const p = this.player;
    if (this.state !== 'playing' || !p.nova || p.novaCooldown > 0) return false;
    p.novaCooldown = 8; this.effects.push({ x: p.x, y: p.y, r: 170, type: 'nova', life: .6, maxLife: .6 });
    for (const e of this.enemies) if (dist(p, e) < 170 + e.r) { e.hp -= 50 + 30 * p.nova; e.slow = 3; }
    this.hostile = this.hostile.filter(b => dist(p,b) > 180); this.event = 'nova'; return true;
  }
  spawn(boss = false) {
    const angle = this.random()*Math.PI*2; const type = this.random();
    let x = 500 + Math.cos(angle)*570, y = 330 + Math.sin(angle)*400;
    x = clamp(x, 30, 970); y = clamp(y, 30, 630);
    if (dist({x,y}, this.player) < 180) { x = this.player.x < 500 ? 940 : 60; y = this.player.y < 330 ? 600 : 60; }
    const tier = Math.floor(this.wave / 3);
    const e = boss ? { x, y, r: 32 + tier*3, hp: 430*tier, maxHp: 430*tier, speed: 40+tier*6, damage: 21+tier*3, kind: 'boss', tier, attack: 2.5, charge: 0, slow: 0, name: BOSSES[tier-1] } : { x, y, r: type > .78 ? 15 : 11, hp: (type > .78 ? 40 : 22) + this.wave*5, speed: (type > .78 ? 43 : type < .22 ? 82 : 59) + this.wave*2, damage: 10 + this.wave, kind: type > .78 ? 'brute' : type < .22 ? 'wisp' : 'crawler', slow: 0 };
    this.enemies.push(e); return e;
  }
  fireHostile(e, count, speed, offset = 0) {
    for(let i = 0; i < count; i++) { const a = offset + i/count*Math.PI*2; this.hostile.push({ x:e.x,y:e.y,vx:Math.cos(a)*speed,vy:Math.sin(a)*speed, r:6, life:7 }); }
  }
  hurt(amount) {
    const p = this.player; if (p.invincible > 0 || this.state !== 'playing') return;
    p.hp = Math.max(0, p.hp-amount); p.invincible = .7; this.event = 'hurt';
    if (!p.hp) this.state = 'dead';
  }
  nextWave() {
    if(this.wave === 9) { this.state = 'won'; return; }
    this.wave++; this.waveTime = 0; this.spawnTime = 1; this.bossSpawned = false;
    this.hostile = []; this.enemies = []; this.player.hp = Math.min(this.player.maxHp, this.player.hp + 15);
    this.message = this.wave % 3 === 0 ? 'A guardian stirs… ' + BOSSES[this.wave/3-1] : 'Wave ' + this.wave + ' · +15 health';
  }
  update(dt, input = {}) {
    if(this.state !== 'playing') return;
    dt = Math.min(.05, Math.max(0,dt)); this.time += dt; this.waveTime += dt; const p = this.player;
    for (const key of ['dashCooldown','novaCooldown','invincible','dashTime']) p[key] = Math.max(0,p[key]-dt);
    if (p.regen) p.hp = Math.min(p.maxHp,p.hp+dt*2);
    let mx = (input.right?1:0)-(input.left?1:0), my = (input.down?1:0)-(input.up?1:0); const len = Math.hypot(mx,my);
    if(len) { mx/=len; my/=len; p.dx=mx; p.dy=my; }
    const isDash = p.dashTime>0;
    p.x = clamp(p.x + (isDash?p.dx*700:mx*p.speed)*dt,22,978); p.y = clamp(p.y + (isDash?p.dy*700:my*p.speed)*dt,22,638);
    if(isDash) this.effects.push({ x:p.x,y:p.y,r:13,type:'trail',life:.2,maxLife:.2 });
    this.spawnTime -= dt;
    if(this.wave%3===0 && !this.bossSpawned) { this.spawn(true); this.bossSpawned=true; }
    if(this.spawnTime<=0 && this.enemies.length<70 && (this.wave%3===0 || this.waveTime<25)) { this.spawn(); this.spawnTime=Math.max(.3,1.15-this.wave*.08); }
    p.fireTimer -= dt;
    if(p.fireTimer<=0 && this.enemies.length) {
      const nearest = this.enemies.reduce((a,b)=> dist(p,a)<dist(p,b)?a:b); const angle = Math.atan2(nearest.y-p.y,nearest.x-p.x);
      for(const spread of (p.multi?[-.18,0,.18]:[0])) this.bullets.push({ x:p.x,y:p.y,vx:Math.cos(angle+spread)*440,vy:Math.sin(angle+spread)*440,r:4,life:2,damage:p.damage });
      p.fireTimer=p.fireRate;
    }
    for(const e of this.enemies) {
      e.slow=Math.max(0,e.slow-dt); let angle=Math.atan2(p.y-e.y,p.x-e.x); let speed=e.speed*(e.slow>0?.55:1);
      if(e.kind==='boss') {
        e.attack-=dt;
        if(e.attack<0) {
          if(e.tier===1) { e.charge=1.1; e.cx=Math.cos(angle); e.cy=Math.sin(angle); this.effects.push({x:e.x,y:e.y,r:80,type:'warning',life:.4,maxLife:.4}); }
          if(e.tier===2) this.fireHostile(e,12,115,this.time*.2);
          if(e.tier===3) { this.fireHostile(e,16,135,this.time); this.spawn(); this.spawn(); }
          e.attack=e.tier===1?3.5:e.tier===2?2.6:2.4;
        }
        if(e.charge>0) { e.charge-=dt; if(e.charge<.7) { speed=290; angle=Math.atan2(e.cy,e.cx); } else speed=0; }
      }
      e.x=clamp(e.x+Math.cos(angle)*speed*dt,e.r,1000-e.r); e.y=clamp(e.y+Math.sin(angle)*speed*dt,e.r,660-e.r);
      if(dist(e,p)<e.r+p.r) this.hurt(e.damage);
    }
    for(const b of this.bullets) {
      b.x+=b.vx*dt; b.y+=b.vy*dt; b.life-=dt;
      for(const e of this.enemies) if(e.hp>0 && b.life>0 && dist(b,e)<b.r+e.r) { e.hp-=b.damage; b.life=0; if(p.frost)e.slow=2; this.effects.push({x:b.x,y:b.y,r:12,type:'hit',life:.2,maxLife:.2}); break; }
    }
    this.bullets=this.bullets.filter(b=>b.life>0 && b.x>-20 && b.x<1020 && b.y>-20 && b.y<680);
    for(const b of this.hostile) { b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;if(dist(b,p)<b.r+p.r){this.hurt(14);b.life=0;} }
    this.hostile=this.hostile.filter(b=>b.life>0&&b.x>0&&b.x<1000&&b.y>0&&b.y<660);
    for(const e of this.enemies) if(e.hp<=0) {
      p.kills++; const boss=e.kind==='boss';
      this.pickups.push({x:e.x-7,y:e.y,kind:'xp',amount:boss?35:5,r:5},{x:e.x+7,y:e.y,kind:'coin',amount:boss?15:3,r:5});
      if(this.random()<.07)this.pickups.push({x:e.x,y:e.y+8,kind:'heal',amount:12,r:6});
      this.effects.push({x:e.x,y:e.y,r:boss?75:25,type:'death',life:.5,maxLife:.5});
      if(boss){this.bossesDefeated++;this.message=e.name+' defeated · +60 coins';p.coins+=60;this.event='boss';}
    }
    this.enemies=this.enemies.filter(e=>e.hp>0);
    for(const item of this.pickups) {
      const d=dist(p,item);if(d<p.magnet) { item.x+=(p.x-item.x)*Math.min(1,dt*9);item.y+=(p.y-item.y)*Math.min(1,dt*9); }
      if(d<20){item.collected=true;if(item.kind==='xp')this.gainXP(item.amount);if(item.kind==='coin')p.coins+=item.amount;if(item.kind==='heal')p.hp=Math.min(p.maxHp,p.hp+item.amount);}
    }
    this.pickups=this.pickups.filter(i=>!i.collected);
    this.effects.forEach(e=>e.life-=dt);this.effects=this.effects.filter(e=>e.life>0);
    if(this.state==='playing' && ((this.wave%3!==0 && this.waveTime>=25) || (this.wave%3===0 && this.bossSpawned && !this.enemies.some(e=>e.kind==='boss')))) this.nextWave();
  }
}
