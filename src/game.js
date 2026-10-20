import { WORLD, REGIONS, regionAt, SOLIDS, CHESTS, moveBody, seekBody, findFree, projectileBlocked } from './world.js';
export { WORLD, REGIONS, regionAt };
export const BOSSES=['The Briar King','The Frost Oracle','The Hollow Monarch'];
export const xpForLevel=level=>Math.floor(20*1.35**(level-1));
export const ELEMENTS={
  fire:{name:'Fire',icon:'ϟ',power:'Searing arrows',duration:'Enduring embers',special:'Explosive embers',detail:'Impacts splash elemental damage around the target.'},
  ice:{name:'Ice',icon:'❄',power:'Glacial force',duration:'Permafrost',special:'Shatter',detail:'Hitting an already chilled target deals bonus damage.'},
  poison:{name:'Poison',icon:'☠',power:'Toxic potency',duration:'Lingering venom',special:'Contagion',detail:'Poisoned enemies spread venom on death.'}
};
export const SHOP=[
  {id:'heal',name:'Forest tonic',icon:'♥',text:'Restore 60 health',price:20,level:1,repeat:true,category:'general'},
  {id:'power',name:'Honed broadheads',icon:'➶',text:'+25% physical arrow damage · retained on swaps',price:30,level:1,repeat:true,category:'general'},
  {id:'element-base',name:'Elemental foundation',icon:'✧',text:'+25% shared elemental damage · retained on swaps',price:35,level:1,repeat:true,category:'general'},
  {id:'haste',name:'Quick hands',icon:'➟',text:'Attack 12% faster',price:35,level:1,repeat:true,max:5,category:'general'},
  {id:'vitality',name:'Wild heart',icon:'♥',text:'+25 maximum health · heal 35',price:35,level:1,repeat:true,category:'general'},
  {id:'speed',name:'Forest stride',icon:'➟',text:'+10% movement speed',price:30,level:1,repeat:true,max:5,category:'general'},
  {id:'nova',name:'Elemental burst',icon:'✺',text:'Unlock / empower E with your current element',price:40,level:2,repeat:true,category:'general'},
  {id:'multi',name:'Triple shot',icon:'⋔',text:'Three arrows of your current element',price:75,level:3,category:'general'},
  {id:'regen',name:'Living roots',icon:'❧',text:'Regenerate 2 health / second',price:70,level:4,category:'general'},
  {id:'pet',name:'Forest fox',icon:'♧',text:'Fires a fan of three physical darts · independent of your element',price:40,level:2,category:'pet'},
  {id:'wolf',name:'Wild wolf',icon:'♧',text:'Bites nearby enemies and howls to slow a pack · independent of your element',price:70,level:3,category:'pet'},
  {id:'collector',name:'Lantern beetle',icon:'◉',text:'Scouts nearby coins and XP and delivers them directly to you',price:35,level:1,category:'pet'},
  {id:'armor',name:'Bark mail',icon:'⬡',text:'+3 armor · reduces incoming damage',price:30,level:1,repeat:true,category:'general'},
  {id:'momentum',name:'Trailrunner',icon:'➟',text:'Build up to +35% speed while moving; stopping resets it',price:45,level:2,category:'ability'},
  {id:'ricochet',name:'Echo arrows',icon:'↝',text:'Your arrows bounce once to another nearby enemy for 65% damage',price:65,level:3,category:'ability'},
  {id:'dashburst',name:'Thunderstep',icon:'✺',text:'Dashing releases a physical shockwave and briefly slows nearby enemies',price:55,level:2,category:'ability'},
  {id:'gale',name:'Gale boots',icon:'≋',text:'Dash cooldown reduced from 2.6s to 1.6s',price:45,level:2,category:'ability'},
  {id:'reaper',name:'Harvest pact',icon:'♥',text:'Every fifth enemy defeated restores 6 health',price:60,level:3,category:'ability'},
  ...Object.entries(ELEMENTS).map(([element,e])=>({id:element,name:e.name+' attunement',icon:e.icon,text:'Swap to '+e.name+'. Replaces your current element and clears its ranks.',price:25,level:1,category:'affinity',element})),
  ...Object.entries(ELEMENTS).flatMap(([element,e])=>[
    {id:element+'-power',name:e.power,icon:e.icon,text:'+35% '+e.name.toLowerCase()+' damage multiplier',price:30,level:1,repeat:true,max:5,category:'element',element,rankKey:'power'},
    {id:element+'-duration',name:e.duration,icon:e.icon,text:element==='ice'?'Longer, stronger chill':element==='fire'?'+1 second burn duration':'+1.5 seconds poison duration',price:30,level:2,repeat:true,max:5,category:'element',element,rankKey:'duration'},
    {id:element+'-special',name:e.special,icon:e.icon,text:e.detail,price:45,level:3,repeat:true,max:3,category:'element',element,rankKey:'special'}
  ])
];
export const LEVEL_UPGRADES=[
  {id:'health',name:'Heartwood',icon:'♥',text:'+15 maximum health · restore 15 health'},
  {id:'damage',name:'Sharpshooter',icon:'➶',text:'+15% physical damage'},
  {id:'elemental',name:'Primal spark',icon:'✧',text:'+20% shared elemental damage · works with any element'},
  {id:'armor',name:'Ironbark',icon:'⬡',text:'+2 armor · reduces all incoming damage'},
  {id:'speed',name:'Lightfoot',icon:'➟',text:'+7% movement speed'}
];
const clamp=(n,min,max)=>Math.max(min,Math.min(max,n));
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
export class Game {
  constructor(random=Math.random){this.random=random;this.obstacles=SOLIDS;this.reset();}
  reset(){
    this.state='title';this.time=0;this.wave=1;this.waveTime=0;this.spawnTime=0;
    this.player={x:2400,y:2000,r:13,hp:100,maxHp:100,speed:210,armor:0,momentumTime:0,damage:18,elementalDamage:12,fireRate:.42,fireTimer:0,level:1,xp:0,xpNext:xpForLevel(1),coins:0,kills:0,magnet:75,dashCooldown:0,dashTime:0,dx:1,dy:0,invincible:0,nova:0,novaCooldown:0,multi:false,regen:false,pet:false,wolf:false,collector:false,element:'physical',elementUpgrades:{power:0,duration:0,special:0},ranks:{},aimX:0,aimY:-1,shotTime:0,moving:false};
    this.freePicks=0;this.levelRewards=[];this.draftChoices=[];this.shopOffers=[];this.rerolls=0;this.shopRound=null;this.shopBaseCost=5;this.shopReason='manual';this.shopReturn='playing';this.shopRevision=0;this.pendingWave=null;this.pendingVictory=false;
    this.pets=[];this.chests=CHESTS.map(c=>({...c,opened:false}));this.enemies=[];this.bullets=[];this.hostile=[];this.pickups=[];this.effects=[];this.bossesDefeated=0;this.bossSpawned=false;this.message='';this.event=null;
  }
  start(){this.reset();this.state='playing';this.message='Explore the open trails · F opens caches';}
  gainXP(amount){
    if(!Number.isFinite(amount)||amount<=0)return;
    const p=this.player;p.xp+=amount;let gained=0;
    while(p.xp>=p.xpNext){p.xp-=p.xpNext;p.level++;p.xpNext=xpForLevel(p.level);this.levelRewards.push(p.level);gained++;}
    this.freePicks=this.levelRewards.length;
    if(gained)this.message='Level '+p.level+' · stat choice waiting after this wave';
  }
  sample(items,count){
    const pool=[...items],out=[];
    while(pool.length&&out.length<count)out.push(pool.splice(Math.min(pool.length-1,Math.floor(this.random()*pool.length)),1)[0]);
    return out;
  }
  prepareDraft(){this.draftChoices=this.sample(LEVEL_UPGRADES,4);this.state='draft';this.shopRevision++;}
  chooseUpgrade(id){
    if(this.state!=='draft'||!this.levelRewards.length||!this.draftChoices.some(c=>c.id===id))return false;
    const p=this.player;
    if(id==='health'){p.maxHp+=15;p.hp=Math.min(p.maxHp,p.hp+15);}
    if(id==='damage')p.damage*=1.15;
    if(id==='elemental')p.elementalDamage*=1.2;
    if(id==='armor')p.armor+=2;
    if(id==='speed')p.speed*=1.07;
    this.levelRewards.shift();this.freePicks=this.levelRewards.length;
    if(this.freePicks)this.prepareDraft();
    else{this.draftChoices=[];this.state=this.pendingVictory?'won':'shop';this.shopRevision++;}
    return true;
  }
  prepareShop(){
    const round=this.pendingWave!==null?this.wave:Math.max(0,this.wave-1);
    if(this.shopRound===round)return;
    this.shopRound=round;this.shopBaseCost=5+Math.floor(Math.max(0,round-1)/2)*2;this.rerolls=0;this.rollOffers();
  }
  rollOffers(){this.shopOffers=this.sample(SHOP.filter(i=>this.offer(i).available),4).map(item=>({id:item.id,sold:false}));this.shopRevision++;}
  rerollCost(){return this.shopBaseCost+this.rerolls*5;}
  reroll(){
    if(this.state!=='shop'||this.player.coins<this.rerollCost())return false;
    this.player.coins-=this.rerollCost();this.rerolls++;this.rollOffers();return true;
  }
  openShop(reason='manual'){
    if(this.state!=='playing'&&this.state!=='paused')return false;
    this.prepareShop();this.shopReturn=this.state;this.shopReason=reason;this.state='shop';this.shopRevision++;return true;
  }
  closeShop(){
    if(this.state!=='shop')return false;
    if(this.pendingWave!==null){this.wave=this.pendingWave;this.pendingWave=null;this.waveTime=0;this.spawnTime=1;this.bossSpawned=false;this.player.hp=Math.min(this.player.maxHp,this.player.hp+15);this.state='playing';this.message='Wave '+this.wave+' · +15 health';}
    else this.state=this.shopReturn||'playing';
    return true;
  }
  rank(item){return item.category==='element'?this.player.elementUpgrades[item.rankKey]||0:this.player.ranks[item.id]||0;}
  offer(item){
    const p=this.player,rank=this.rank(item),price=item.price+(item.category==='element'?rank*10:0);
    let reason='';
    if(p.level<item.level)reason='Level '+item.level+' required';
    else if(item.category==='element'&&p.element!==item.element)reason='Requires '+ELEMENTS[item.element].name;
    else if(item.category==='affinity'&&p.element===item.element)reason='Currently equipped';
    else if(item.max&&rank>=item.max)reason='Maximum rank';
    else if(!item.repeat&&!['affinity','element'].includes(item.category)&&p[item.id])reason='Already owned';
    else if(item.id==='heal'&&p.hp>=p.maxHp)reason='Health full';
    return {available:!reason,reason,price,rank};
  }
  buy(id){
    if(this.state!=='shop')return false;
    const slot=this.shopOffers.find(i=>i.id===id&&!i.sold),item=SHOP.find(i=>i.id===id);if(!slot||!item)return false;
    const offer=this.offer(item);if(!offer.available||this.player.coins<offer.price)return false;
    this.player.coins-=offer.price;slot.sold=true;this.applyItem(item);this.shopRevision++;return true;
  }
  applyItem(item){
    const p=this.player,id=item.id;
    if(item.category==='affinity')this.swapElement(item.element);
    else if(item.category==='element')p.elementUpgrades[item.rankKey]++;
    else {
      p.ranks[id]=(p.ranks[id]||0)+1;
      if(id==='heal')p.hp=Math.min(p.maxHp,p.hp+60);
      else if(id==='power')p.damage*=1.25;
      else if(id==='element-base')p.elementalDamage*=1.25;
      else if(id==='haste')p.fireRate*=.88;
      else if(id==='vitality'){p.maxHp+=25;p.hp=Math.min(p.maxHp,p.hp+35);}
      else if(id==='speed')p.speed*=1.1;
      else if(id==='armor')p.armor+=3;
      else if(id==='nova')p.nova++;
      else p[id]=true;
    }
  }
  swapElement(element){
    if(!ELEMENTS[element]||this.player.element===element)return false;
    this.player.element=element;this.player.elementUpgrades={power:0,duration:0,special:0};
    this.bullets=this.bullets.filter(b=>b.kind==='pet');this.effects=[];
    for(const e of this.enemies){e.burn=0;e.slow=0;e.poison=0;e.poisonStacks=0;e.burnDamage=0;e.poisonDamage=0;}
    this.message=ELEMENTS[element].name+' attuned · previous elemental ranks removed';return true;
  }
  selectElement(element){
    if(element===this.player.element)return true;
    this.message='Swap elements in the shop · previous elemental upgrades will be lost';return false;
  }
  profile(element=this.player.element){
    if(element==='physical')return {element,hit:0,dot:0,duration:0,special:0,slow:0};
    const rank=element===this.player.element?this.player.elementUpgrades:{power:0,duration:0,special:0},hit=this.player.elementalDamage*(1+rank.power*.35);
    return {element,hit,dot:hit*(element==='fire'?.5:.22),duration:element==='fire'?3+rank.duration:element==='ice'?2.5+rank.duration:4+rank.duration*1.5,special:rank.special,slow:Math.min(.7,.45+rank.duration*.04)};
  }
  attackDamage(){return this.player.damage+this.profile().hit;}
  interact(){
    if(this.state!=='playing')return false;
    const chest=this.chests.find(c=>!c.opened&&dist(c,this.player)<85);
    if(!chest){this.message='Move closer to a glowing chest';return false;}
    chest.opened=true;this.player.coins+=25;this.gainXP(10);this.message='Hidden cache · +25 coins · +10 XP';return true;
  }
  statusHit(e,element,payload=this.profile(element)){
    if(element!==this.player.element||element==='physical')return;
    if(element==='fire'){e.burn=payload.duration;e.burnDamage=payload.dot;}
    if(element==='ice'){e.slow=payload.duration;e.slowStrength=payload.slow;}
    if(element==='poison'){e.poison=payload.duration;e.poisonDamage=payload.dot;e.poisonStacks=Math.min(5,(e.poisonStacks||0)+1);}
  }
  arrow(source,target,damage,element=this.player.element,kind='arrow',spread=0){
    const a=Math.atan2(target.y-source.y,target.x-source.x)+spread;
    this.bullets.push({x:source.x,y:source.y,vx:Math.cos(a)*520,vy:Math.sin(a)*520,r:4,life:1.65,damage,element,kind,payload:this.profile(element)});
  }
  dashDuration(){return this.player.gale?1.6:2.6;}
  moveSpeed(){return this.player.speed*(1+(this.player.momentum?Math.min(1,this.player.momentumTime/2)*.35:0));}
  dash(){
    const p=this.player;if(this.state!=='playing'||p.dashCooldown>0)return false;
    p.dashTime=.19;p.dashCooldown=this.dashDuration();p.invincible=.3;this.event='dash';
    if(p.dashburst){this.effects.push({x:p.x,y:p.y,r:145,type:'nova',element:'physical',life:.45,maxLife:.45});for(const e of this.enemies)if(dist(p,e)<145+e.r){e.hp-=p.damage*1.5;e.petSlow=1.5;}}
    return true;
  }
  nova(){
    const p=this.player;if(this.state!=='playing'||!p.nova||p.novaCooldown>0)return false;
    p.novaCooldown=8;this.effects.push({x:p.x,y:p.y,r:170,type:'nova',life:.6,maxLife:.6});
    for(const e of this.enemies)if(dist(p,e)<170+e.r){e.hp-=this.attackDamage()+p.nova*30;this.statusHit(e,p.element);}
    for(let i=0;i<12;i++)this.arrow(p,{x:p.x+Math.cos(i*Math.PI/6),y:p.y+Math.sin(i*Math.PI/6)},this.attackDamage()*.8);
    p.shotTime=.3;this.hostile=this.hostile.filter(b=>dist(p,b)>180);this.event='nova';return true;
  }
  spawn(boss=false){
    const a=this.random()*Math.PI*2,p=this.player,type=this.random(),tier=Math.floor(this.wave/3),r=boss?32+tier*3:type>.78?15:11;
    let point={x:clamp(p.x+Math.cos(a)*420,30,WORLD.width-30),y:clamp(p.y+Math.sin(a)*420,30,WORLD.height-30)};
    if(dist(point,p)<180)point={x:clamp(p.x+(p.x<WORLD.width/2?350:-350),30,WORLD.width-30),y:clamp(p.y+200,30,WORLD.height-30)};
    point=findFree(point,r,this.obstacles);
    const e=boss?{...point,r,hp:430*tier,maxHp:430*tier,speed:40+tier*6,damage:21+tier*3,kind:'boss',tier,attack:2.5,charge:0,slow:0,name:BOSSES[tier-1]}:{...point,r,hp:(type>.78?40:22)+this.wave*5,speed:(type>.78?43:type<.22?82:59)+this.wave*2,damage:10+this.wave,kind:type>.78?'brute':type<.22?'wisp':'crawler',slow:0};
    this.enemies.push(e);return e;
  }
  fireHostile(e,count,speed,offset=0){for(let i=0;i<count;i++){const a=offset+i/count*Math.PI*2;this.hostile.push({x:e.x,y:e.y,vx:Math.cos(a)*speed,vy:Math.sin(a)*speed,r:6,life:7});}}
  hurt(amount){const p=this.player;if(p.invincible>0||this.state!=='playing')return;p.hp=Math.max(0,p.hp-amount*100/(100+Math.max(0,p.armor)*6));p.invincible=.7;this.event='hurt';if(!p.hp)this.state='dead';}
  nextWave(){
    if(this.wave===9){this.pendingVictory=true;if(this.freePicks)this.prepareDraft();else this.state='won';return;}
    this.pendingWave=this.wave+1;this.enemies=[];this.hostile=[];this.bullets=[];this.effects=[];this.shopReturn='playing';this.shopReason='wave';this.shopRound=null;this.prepareShop();if(this.freePicks)this.prepareDraft();else this.state='shop';this.shopRevision++;
    this.message='Wave '+this.wave+' cleared · visit the shop before continuing';
  }
  collect(item){
    if(item.collected)return;
    item.collected=true;
    if(item.kind==='xp')this.gainXP(item.amount);
    if(item.kind==='coin')this.player.coins+=item.amount;
    if(item.kind==='heal')this.player.hp=Math.min(this.player.maxHp,this.player.hp+item.amount);
  }
  updatePets(dt){
    const p=this.player;
    for(const [index,id] of ['pet','wolf','collector'].entries()){
      if(!p[id])continue;
      const kind=id==='pet'?'fox':id;let pet=this.pets.find(a=>a.kind===kind);
      if(!pet){pet={...findFree({x:p.x+(index? -90:90),y:p.y+55},12,this.obstacles),r:12,kind,attack:0,howl:0,roam:0,angle:index*Math.PI,fireTime:0};this.pets.push(pet);}
      pet.attack-=dt;pet.howl-=dt;pet.roam-=dt;pet.fireTime=Math.max(0,pet.fireTime-dt);
      const candidates=id==='collector'?this.pickups.filter(i=>!i.collected&&i.kind!=='heal'&&dist(i,p)<300):this.enemies.filter(e=>e.hp>0&&dist(e,p)<450&&dist(e,pet)<370);
      const target=candidates.length?candidates.reduce((a,b)=>dist(pet,a)<dist(pet,b)?a:b):null;
      let goal;
      if(dist(pet,p)>315)goal=p;
      else if(target){const a=Math.atan2(pet.y-target.y,pet.x-target.x),reach=id==='pet'?105:id==='wolf'?18:0;goal={x:target.x+Math.cos(a)*reach,y:target.y+Math.sin(a)*reach};}
      else {if(pet.roam<=0){pet.angle=this.random()*Math.PI*2+index*2;pet.roam=1.5+this.random();}goal={x:p.x+Math.cos(pet.angle)*130,y:p.y+Math.sin(pet.angle)*130};}
      const leash=id==='collector'?300:230,d=dist(goal,p);if(d>leash)goal={x:p.x+(goal.x-p.x)/d*leash,y:p.y+(goal.y-p.y)/d*leash};
      seekBody(pet,goal,dist(pet,p)>250?350:id==='collector'?260:id==='wolf'?240:180,dt,this.obstacles);
      if(dist(pet,p)>420)Object.assign(pet,findFree({x:p.x+80,y:p.y+30},pet.r,this.obstacles));
      if(!target)continue;
      pet.aimX=target.x-pet.x;pet.aimY=target.y-pet.y;
      if(id==='collector'){if(dist(pet,target)<24){this.collect(target);pet.fireTime=.3;}continue;}
      if(id==='wolf'){
        if(dist(pet,target)<target.r+32&&pet.attack<=0){target.hp-=p.damage*1.3;pet.attack=.8;pet.fireTime=.3;this.effects.push({x:target.x,y:target.y,r:22,type:'hit',element:'physical',life:.25,maxLife:.25});}
        if(pet.howl<=0&&dist(pet,target)<100){for(const e of candidates)if(dist(e,pet)<135)e.petSlow=2;pet.howl=6;this.effects.push({x:pet.x,y:pet.y,r:135,type:'nova',element:'ice',life:.55,maxLife:.55});}
      }else if(pet.attack<=0&&!projectileBlocked(pet,target,this.obstacles)){
        for(const spread of [-.12,0,.12])this.arrow(pet,target,p.damage*.45,'physical','pet',spread);pet.attack=1.1;pet.fireTime=.25;
      }
    }
  }
  update(dt,input={}){
    if(this.state!=='playing')return;dt=Math.min(.05,Math.max(0,dt));this.time+=dt;this.waveTime+=dt;const p=this.player;
    for(const key of ['dashCooldown','novaCooldown','invincible','dashTime','shotTime'])p[key]=Math.max(0,p[key]-dt);
    if(p.regen)p.hp=Math.min(p.maxHp,p.hp+dt*2);
    let mx=input.moveX??((input.right?1:0)-(input.left?1:0)),my=input.moveY??((input.down?1:0)-(input.up?1:0));const len=Math.hypot(mx,my);
    p.moving=!!len;p.momentumTime=len?Math.min(2,p.momentumTime+dt):0;if(len){mx/=len;my/=len;p.dx=mx;p.dy=my;}
    const isDash=p.dashTime>0;moveBody(p,(isDash?p.dx*700:mx*this.moveSpeed())*dt,(isDash?p.dy*700:my*this.moveSpeed())*dt,this.obstacles);
    if(isDash)this.effects.push({x:p.x,y:p.y,r:13,type:'trail',life:.2,maxLife:.2});
    this.enemies=this.enemies.filter(e=>e.kind==='boss'||dist(e,p)<1000);
    for(const e of this.enemies)if(e.kind==='boss'&&dist(e,p)>850)Object.assign(e,findFree({x:clamp(p.x+350,40,WORLD.width-40),y:clamp(p.y-200,40,WORLD.height-40)},e.r,this.obstacles));
    this.spawnTime-=dt;if(this.wave%3===0&&!this.bossSpawned){this.spawn(true);this.bossSpawned=true;}
    if(this.spawnTime<=0&&this.enemies.length<70&&(this.wave%3===0||this.waveTime<25)){this.spawn();this.spawnTime=Math.max(.3,1.15-this.wave*.08);}
    p.fireTimer-=dt;const targets=this.enemies.filter(e=>e.hp>0&&dist(p,e)<600&&!projectileBlocked(p,e,this.obstacles));
    if(p.fireTimer<=0&&targets.length){
      const nearest=targets.reduce((a,b)=>dist(p,a)<dist(p,b)?a:b),a=Math.atan2(nearest.y-p.y,nearest.x-p.x);p.aimX=Math.cos(a);p.aimY=Math.sin(a);p.shotTime=.3;
      for(const spread of p.multi?[-.16,0,.16]:[0])this.arrow(p,nearest,this.attackDamage(),p.element,'arrow',spread);p.fireTimer=p.fireRate;
    }
    this.updatePets(dt);
    for(const e of this.enemies){
      if(e.burn>0){e.burn=Math.max(0,e.burn-dt);e.hp-=(e.burnDamage||0)*dt;}
      if(e.poison>0){e.poison=Math.max(0,e.poison-dt);e.hp-=(e.poisonDamage||0)*(e.poisonStacks||1)*dt;}else e.poisonStacks=0;
      if(e.hp<=0)continue;
      e.slow=Math.max(0,e.slow-dt);e.petSlow=Math.max(0,(e.petSlow||0)-dt);const a=Math.atan2(p.y-e.y,p.x-e.x),speed=e.speed*(1-Math.max(e.slow>0?(e.slowStrength||.45):0,e.petSlow>0?.3:0));
      if(e.kind==='boss'){
        e.attack-=dt;if(e.attack<0){
          if(e.tier===1){e.charge=1.1;e.cx=Math.cos(a);e.cy=Math.sin(a);this.effects.push({x:e.x,y:e.y,r:80,type:'warning',life:.4,maxLife:.4});}
          if(e.tier===2)this.fireHostile(e,12,115,this.time*.2);
          if(e.tier===3){this.fireHostile(e,16,135,this.time);this.spawn();this.spawn();}
          e.attack=e.tier===1?3.5:e.tier===2?2.6:2.4;
        }
      }
      if(e.charge>0){e.charge-=dt;if(e.charge<.7)moveBody(e,e.cx*290*dt,e.cy*290*dt,this.obstacles);}
      else seekBody(e,p,speed,dt,this.obstacles);
      if(e.hp>0&&dist(e,p)<e.r+p.r)this.hurt(e.damage);
    }
    for(const b of this.bullets){
      const old={x:b.x,y:b.y};b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;
      if(projectileBlocked(old,b,this.obstacles)){b.life=0;continue;}
      for(const e of this.enemies)if(e!==b.hitEnemy&&e.hp>0&&b.life>0&&dist(b,e)<b.r+e.r){
        const chilled=e.slow>0;e.hp-=b.damage;const profile=b.payload||this.profile(b.element);
        if(b.element==='ice'&&chilled)e.hp-=profile.hit*.5*profile.special;
        this.statusHit(e,b.element,profile);b.life=0;
        if(p.ricochet&&b.kind==='arrow'&&!b.bounced){
          const next=this.enemies.filter(other=>other!==e&&other.hp>0&&dist(other,e)<210&&!projectileBlocked(e,other,this.obstacles)).sort((a,c)=>dist(a,e)-dist(c,e))[0];
          if(next){const a=Math.atan2(next.y-e.y,next.x-e.x);b.x=e.x;b.y=e.y;b.vx=Math.cos(a)*520;b.vy=Math.sin(a)*520;b.damage*=.65;b.bounced=true;b.hitEnemy=e;b.life=.6;}
        }
        if(b.element==='fire'&&profile.special){for(const other of this.enemies)if(other!==e&&other.hp>0&&dist(other,e)<65){other.hp-=profile.hit*.4*profile.special;this.statusHit(other,'fire',profile);}this.effects.push({x:e.x,y:e.y,r:65,type:'nova',life:.3,maxLife:.3,element:'fire'});}
        this.effects.push({x:b.x,y:b.y,r:12,type:'hit',element:b.element,life:.2,maxLife:.2});break;
      }
    }
    this.bullets=this.bullets.filter(b=>b.life>0&&b.x>0&&b.x<WORLD.width&&b.y>0&&b.y<WORLD.height);
    for(const b of this.hostile){const old={x:b.x,y:b.y};b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;if(projectileBlocked(old,b,this.obstacles))b.life=0;if(b.life>0&&dist(b,p)<b.r+p.r){this.hurt(14);b.life=0;}}
    this.hostile=this.hostile.filter(b=>b.life>0&&b.x>0&&b.x<WORLD.width&&b.y>0&&b.y<WORLD.height);
    for(const e of this.enemies)if(e.hp<=0){
      p.kills++;if(p.reaper&&p.kills%5===0)p.hp=Math.min(p.maxHp,p.hp+6);const boss=e.kind==='boss';
      if(p.element==='poison'&&p.elementUpgrades.special&&e.poison>0)for(const other of this.enemies)if(other!==e&&other.hp>0&&dist(e,other)<90+p.elementUpgrades.special*15)this.statusHit(other,'poison');
      this.pickups.push({x:e.x-7,y:e.y,kind:'xp',amount:boss?35:5,r:5},{x:e.x+7,y:e.y,kind:'coin',amount:boss?15:3,r:5});if(this.random()<.07)this.pickups.push({x:e.x,y:e.y+8,kind:'heal',amount:12,r:6});
      this.effects.push({x:e.x,y:e.y,r:boss?75:25,type:'death',life:.5,maxLife:.5});if(boss){this.bossesDefeated++;this.message=e.name+' defeated · +60 coins';p.coins+=60;this.event='boss';}
    }
    this.enemies=this.enemies.filter(e=>e.hp>0);
    for(const item of this.pickups){const d=dist(p,item);if(d<p.magnet){item.x+=(p.x-item.x)*Math.min(1,dt*9);item.y+=(p.y-item.y)*Math.min(1,dt*9);}if(d<20)this.collect(item);}
    this.pickups=this.pickups.filter(i=>!i.collected).slice(-500);this.effects.forEach(e=>e.life-=dt);this.effects=this.effects.filter(e=>e.life>0);
    if(this.state==='playing'&&((this.wave%3!==0&&this.waveTime>=25)||(this.wave%3===0&&this.bossSpawned&&!this.enemies.some(e=>e.kind==='boss'))))this.nextWave();
  }
}
export function advanceGame(game,elapsed,input={}){
  let remaining=Math.min(.25,Math.max(0,Number.isFinite(elapsed)?elapsed:0));
  while(remaining>1e-8&&game.state==='playing'){const step=Math.min(1/60,remaining);game.update(step,input);remaining-=step;}
}
