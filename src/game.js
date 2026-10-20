export const WORLD = { width: 4800, height: 4000 };
export const REGIONS = [
  { name: 'Whispering Woods', x: 2400, y: 2000, r: 1100, color: '#426142' },
  { name: 'Frostveil Ruins', x: 1000, y: 1000, r: 760, color: '#8aafb8' },
  { name: 'Ember Highlands', x: 3700, y: 1000, r: 780, color: '#ad704a' },
  { name: 'Venom Marsh', x: 3400, y: 3200, r: 800, color: '#6f8240' }
];
export const regionAt = p => REGIONS.slice(1).find(r => Math.hypot(p.x-r.x,p.y-r.y)<r.r) || REGIONS[0];
export const BOSSES = ['The Briar King', 'The Frost Oracle', 'The Hollow Monarch'];
export const UPGRADES = [
  { id: 'power', name: 'Keen arrows', icon: '→', text: '+25% arrow damage', apply: g => { g.player.damage *= 1.25; } },
  { id: 'haste', name: 'Quick hands', icon: 'ϟ', text: 'Attack 15% faster', apply: g => { g.player.fireRate *= .85; } },
  { id: 'vitality', name: 'Wild heart', icon: '♥', text: '+25 maximum health & heal 35', apply: g => { g.player.maxHp += 25; g.player.hp = Math.min(g.player.maxHp, g.player.hp + 35); } },
  { id: 'speed', name: 'Forest stride', icon: '➟', text: '+12% movement speed', apply: g => { g.player.speed *= 1.12; } },
  { id: 'nova', name: 'Elemental burst', icon: '✺', text: 'Unlock / empower your E ability', apply: g => { g.player.nova++; } },
  { id: 'fire', name: 'Flame arrows', icon: 'ϟ', text: 'Unlock fire arrows · burns for 3s', apply: g => { g.player.fire=true;g.player.element='fire'; } },
  { id: 'frost', name: 'Glacial arrows', icon: '❄', text: 'Unlock ice arrows · slow by 45%', apply: g => { g.player.frost=true;g.player.element='ice'; } },
  { id: 'poison', name: 'Venom arrows', icon: '☠', text: 'Unlock poison · stacking damage', apply: g => { g.player.poison=true;g.player.element='poison'; } },
  { id: 'pet', name: 'Foxfire companion', icon: '♧', text: 'A fox follows and fires at enemies', apply: g => { g.player.pet=true; } },
  { id: 'magnet', name: 'Starlit compass', icon: '✧', text: '+50 pickup range & heal 15', apply: g => { g.player.magnet += 50; g.player.hp = Math.min(g.player.maxHp, g.player.hp + 15); } }
];
export const SHOP = [
  { id: 'heal', name: 'Forest tonic', icon: '♥', text: 'Restore 60 health', price: 20, level: 1, repeat: true },
  { id: 'power', name: 'Honed broadheads', icon: '→', text: '+25% arrow damage', price: 30, level: 1, repeat: true },
  { id: 'nova', name: 'Elemental burst', icon: '✺', text: 'Unlock / empower E burst', price: 40, level: 2, repeat: true },
  { id: 'frost', name: 'Frostbound', icon: '❄', text: 'Ice arrows: slow 45% · select with 2', price: 55, level: 3 },
  { id: 'multi', name: 'Triple shot', icon: '⋔', text: 'Fire three arrows per shot', price: 75, level: 4 },
  { id: 'fire', name: 'Flame arrows', icon: 'ϟ', text: 'Burn enemies · select with 1', price: 25, level: 1 },
  { id: 'poison', name: 'Venom arrows', icon: '☠', text: 'Stack poison · select with 3', price: 45, level: 3 },
  { id: 'pet', name: 'Foxfire companion', icon: '♧', text: 'Following fox fires burning embers', price: 40, level: 2 },
  { id: 'wolf', name: 'Frost wolf', icon: '❄', text: 'A second pet fires slowing ice', price: 80, level: 4 },
  { id: 'regen', name: 'Living roots', icon: '❧', text: 'Regenerate 2 health / second', price: 90, level: 5 }
];
const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
export class Game {
  constructor(random = Math.random) { this.random = random; this.reset(); }
  reset() {
    this.state = 'title'; this.time = 0; this.wave = 1; this.waveTime = 0; this.spawnTime = 0;
    this.player = { x: WORLD.width/2, y: WORLD.height/2, r: 13, hp: 100, maxHp: 100, speed: 210, damage: 18, fireRate: .42, fireTimer: 0, level: 1, xp: 0, xpNext: 20, coins: 0, kills: 0, magnet: 60, dashCooldown: 0, dashTime: 0, dx: 1, dy: 0, invincible: 0, nova: 0, novaCooldown: 0, frost: false, multi: false, regen: false, fire: false, poison: false, pet: false, wolf: false, element: 'physical', aimX: 0, aimY: -1, shotTime: 0, moving: false };
    this.pets=[]; this.chests=Array.from({length:24},(_,i)=>({x:i===0?2500:300+(i*719)%4200,y:i===0?1900:300+(i*1093)%3400,opened:false}));
    this.enemies = []; this.bullets = []; this.hostile = []; this.pickups = []; this.effects = []; this.pendingLevels = 0; this.bossesDefeated = 0; this.bossSpawned = false; this.choices = []; this.message = ''; this.event = null;
  }
  start() { this.reset(); this.state = 'playing'; this.message = 'Explore the Hollow · F opens nearby chests'; }
  choose(id) {
    if (this.state !== 'levelup' || !this.choices.some(c => c.id === id)) return false;
    UPGRADES.find(c => c.id === id).apply(this); this.pendingLevels--;
    this.state = 'playing'; if (this.pendingLevels) this.levelChoices(); return true;
  }
  levelChoices() {
    this.state = 'levelup';
    this.choices = UPGRADES.filter(c=> !['fire','frost','poison','pet'].includes(c.id) || !this.player[c.id]).map(c => ({ c, n: this.random() })).sort((a,b) => a.n-b.n).slice(0,3).map(x => x.c);
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
    else { p[id] = true; if (['fire','frost','poison'].includes(id)) p.element=id==='frost'?'ice':id; }
    return true;
  }
  selectElement(element) {
    const key = element === 'ice' ? 'frost' : element;
    if (!['fire','ice','poison','physical'].includes(element) || (element !== 'physical' && !this.player[key])) return false;
    this.player.element=element; this.message=element==='physical'?'Physical arrows equipped':element+' arrows equipped';return true;
  }
  interact() {
    if(this.state!=='playing')return false;
    const chest=this.chests.find(c=>!c.opened && dist(c,this.player)<85);
    if(!chest){this.message='Move closer to a glowing chest to open it';return false;}
    chest.opened=true;this.player.coins+=25;this.gainXP(10);this.message='Hidden cache · +25 coins · +10 XP';return true;
  }
  statusHit(e, element) {
    if(element==='fire'){e.burn=3;e.burnDamage=this.player.damage*.24;}
    if(element==='ice')e.slow=2.5;
    if(element==='poison'){e.poison=4;e.poisonStacks=Math.min(5,(e.poisonStacks||0)+1);}
  }
  arrow(source,target,damage,element='physical',kind='arrow',spread=0) {
    const a=Math.atan2(target.y-source.y,target.x-source.x)+spread;
    this.bullets.push({x:source.x,y:source.y,vx:Math.cos(a)*520,vy:Math.sin(a)*520,r:4,life:1.65,damage,element,kind});
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
    for (const e of this.enemies) if (dist(p, e) < 170 + e.r) { e.hp -= 50 + 30 * p.nova; e.slow = 3; this.statusHit(e,p.element); }
    for(let i=0;i<12;i++)this.arrow(p,{x:p.x+Math.cos(i*Math.PI/6),y:p.y+Math.sin(i*Math.PI/6)},p.damage*.8,p.element);
    p.shotTime=.3;
    this.hostile = this.hostile.filter(b => dist(p,b) > 180); this.event = 'nova'; return true;
  }
  spawn(boss = false) {
    const angle = this.random()*Math.PI*2; const type = this.random();
    let x = this.player.x + Math.cos(angle)*420, y = this.player.y + Math.sin(angle)*420;
    x = clamp(x, 30, WORLD.width-30); y = clamp(y, 30, WORLD.height-30);
    if (dist({x,y}, this.player) < 180) { x = clamp(this.player.x+(this.player.x<WORLD.width/2?350:-350),30,WORLD.width-30); y=clamp(this.player.y+200,30,WORLD.height-30); }
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
    for (const key of ['dashCooldown','novaCooldown','invincible','dashTime','shotTime']) p[key] = Math.max(0,p[key]-dt);
    if (p.regen) p.hp = Math.min(p.maxHp,p.hp+dt*2);
    let mx = input.moveX ?? ((input.right?1:0)-(input.left?1:0)), my = input.moveY ?? ((input.down?1:0)-(input.up?1:0)); const len = Math.hypot(mx,my);
    p.moving=!!len; if(len) { mx/=len; my/=len; p.dx=mx; p.dy=my; }
    const isDash = p.dashTime>0;
    p.x = clamp(p.x + (isDash?p.dx*700:mx*p.speed)*dt,22,WORLD.width-22); p.y = clamp(p.y + (isDash?p.dy*700:my*p.speed)*dt,22,WORLD.height-22);
    if(isDash) this.effects.push({ x:p.x,y:p.y,r:13,type:'trail',life:.2,maxLife:.2 });
    this.enemies=this.enemies.filter(e=>e.kind==='boss'||dist(e,p)<1000);
    for(const e of this.enemies)if(e.kind==='boss'&&dist(e,p)>850){e.x=clamp(p.x+350,40,WORLD.width-40);e.y=clamp(p.y-200,40,WORLD.height-40);}
    this.spawnTime -= dt;
    if(this.wave%3===0 && !this.bossSpawned) { this.spawn(true); this.bossSpawned=true; }
    if(this.spawnTime<=0 && this.enemies.length<70 && (this.wave%3===0 || this.waveTime<25)) { this.spawn(); this.spawnTime=Math.max(.3,1.15-this.wave*.08); }
    p.fireTimer -= dt;
    const targets=this.enemies.filter(e=>e.hp>0 && dist(p,e)<600);
    if(p.fireTimer<=0 && targets.length) {
      const nearest=targets.reduce((a,b)=>dist(p,a)<dist(p,b)?a:b);
      const angle=Math.atan2(nearest.y-p.y,nearest.x-p.x);p.aimX=Math.cos(angle);p.aimY=Math.sin(angle);p.shotTime=.3;
      for(const spread of (p.multi?[-.16,0,.16]:[0]))this.arrow(p,nearest,p.damage,p.element,'arrow',spread);
      p.fireTimer=p.fireRate;
    }
    for(const [id,kind] of [['pet','fox'],['wolf','wolf']]) {
      if(!p[id])continue;
      let pet=this.pets.find(a=>a.kind===kind);
      if(!pet){pet={x:p.x+35,y:p.y+35,kind,attack:0};this.pets.push(pet);}
      const side=kind==='fox'?1:-1, target={x:p.x+side*42,y:p.y+40};
      pet.x+=(target.x-pet.x)*Math.min(1,dt*6);pet.y+=(target.y-pet.y)*Math.min(1,dt*6);pet.attack-=dt;
      if(pet.attack<=0 && targets.length){const enemy=targets.reduce((a,b)=>dist(pet,a)<dist(pet,b)?a:b);this.arrow(pet,enemy,p.damage*.65,kind==='fox'?'fire':'ice','pet');pet.attack=1;}
    }
    for(const e of this.enemies) {
      if(e.burn>0){e.burn=Math.max(0,e.burn-dt);e.hp-=(e.burnDamage||4)*dt;}
      if(e.poison>0){e.poison=Math.max(0,e.poison-dt);e.hp-=3*(e.poisonStacks||1)*dt;}else e.poisonStacks=0;
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
      e.x=clamp(e.x+Math.cos(angle)*speed*dt,e.r,WORLD.width-e.r); e.y=clamp(e.y+Math.sin(angle)*speed*dt,e.r,WORLD.height-e.r);
      if(dist(e,p)<e.r+p.r) this.hurt(e.damage);
    }
    for(const b of this.bullets) {
      b.x+=b.vx*dt; b.y+=b.vy*dt; b.life-=dt;
      for(const e of this.enemies) if(e.hp>0 && b.life>0 && dist(b,e)<b.r+e.r) { e.hp-=b.damage; b.life=0; this.statusHit(e,b.element || (p.frost?'ice':'physical')); this.effects.push({x:b.x,y:b.y,r:12,type:'hit',element:b.element,life:.2,maxLife:.2}); break; }
    }
    this.bullets=this.bullets.filter(b=>b.life>0 && b.x>-20 && b.x<WORLD.width+20 && b.y>-20 && b.y<WORLD.height+20);
    for(const b of this.hostile) { b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;if(dist(b,p)<b.r+p.r){this.hurt(14);b.life=0;} }
    this.hostile=this.hostile.filter(b=>b.life>0&&b.x>0&&b.x<WORLD.width&&b.y>0&&b.y<WORLD.height);
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
    this.pickups=this.pickups.filter(i=>!i.collected).slice(-500);
    this.effects.forEach(e=>e.life-=dt);this.effects=this.effects.filter(e=>e.life>0);
    if(this.state==='playing' && ((this.wave%3!==0 && this.waveTime>=25) || (this.wave%3===0 && this.bossSpawned && !this.enemies.some(e=>e.kind==='boss')))) this.nextWave();
  }
}

// Consume elapsed time in safe steps rather than slowing the world at low render FPS.
// Cap catch-up after long stalls; paused/menu states never accumulate simulation time.
export function advanceGame(game, elapsed, input = {}) {
  let remaining = Math.min(.25, Math.max(0, Number.isFinite(elapsed) ? elapsed : 0));
  while (remaining > 1e-8 && game.state === 'playing') {
    const step = Math.min(1 / 60, remaining);
    game.update(step, input);
    remaining -= step;
  }
}
