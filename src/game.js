import {CHARACTERS,cleanProgress,isUnlocked,ECONOMY_UPGRADES,RARE_UPGRADES,MYTHICAL_UPGRADES} from './content.js';
export {CHARACTERS,isUnlocked,MYTHICAL_UPGRADES} from './content.js';
import { WORLD, REGIONS, regionAt, SOLIDS, firstObstacleHit, segmentHit, moveBody, seekBody, findFree, projectileBlocked } from './world.js';
export { WORLD, REGIONS, regionAt };
export const BOSSES=['The Briar King','The Frost Oracle','The Hollow Monarch'];
export const xpForLevel=level=>Math.floor(20*1.35**(level-1));
export const ELEMENTS={
  fire:{name:'Fire',icon:'ϟ',power:'Searing arrows',duration:'Enduring embers',special:'Explosive embers',detail:'Impacts splash elemental damage around the target.'},
  ice:{name:'Ice',icon:'❄',power:'Glacial force',duration:'Permafrost',special:'Shatter',detail:'Hitting an already chilled target deals bonus damage.'},
  poison:{name:'Poison',icon:'☠',power:'Toxic potency',duration:'Lingering venom',special:'Contagion',detail:'Poisoned enemies spread venom on death.'}
};
export const SKILLS={
  space:[
    {id:'dash',name:'Windskip',icon:'➟',cooldown:2.6,duration:.19,text:'Dash in your movement direction with brief invulnerability.'},
    {id:'shield',name:'Shell Yeah!',icon:'⬡',cooldown:12,duration:3,text:'A golden shell blocks ALL incoming damage for 3 seconds.'},
    {id:'sprint',name:'Hare Trigger',icon:'≋',cooldown:10,duration:4,text:'+70% movement speed for 4 seconds; dodge all damage for the first 0.8 seconds.'},
    {id:'repel',name:'Bramble Bouncer',icon:'❧',cooldown:9,duration:1.5,text:'Shove nearby enemies away, erase nearby hostile shots and block damage for 1.5 seconds.'}
  ],
  attack:[
    {id:'rapid',name:'Arrowpalooza',icon:'⋔',cooldown:14,duration:5,text:'Double your bow attack speed for 5 seconds.'},
    {id:'burst',name:'Quiverquake',icon:'✺',cooldown:8,duration:0,text:'Detonate a close-range elemental blast and launch 12 arrows in a ring.'},
    {id:'salvo',name:'Flock & Awe',icon:'➶',cooldown:11,duration:0,text:'Fire 8 empowered arrows at nearby enemies; with no targets, fire an aimed fan.'},
    {id:'fury',name:'Hunter’s Moon',icon:'☾',cooldown:14,duration:4,text:'Double your physical and elemental arrow impact damage for 4 seconds.'}
  ]
};
export const BASE_STATS=Object.freeze({maxHp:100,damage:18,elementalDamage:12,armor:0,speed:210,fireRate:.42,magnet:75});
export const SHOP=[
  {id:'heal',name:'Forest tonic',icon:'♥',text:'Restore 60 health',price:20,level:1,repeat:true,category:'general'},
  {id:'power',name:'Honed broadheads',icon:'➶',text:'+25% physical arrow damage · retained on swaps',price:30,level:1,repeat:true,category:'general'},
  {id:'element-base',name:'Elemental foundation',icon:'✧',text:'+25% shared elemental damage · retained on swaps',price:35,level:1,repeat:true,category:'general'},
  {id:'haste',name:'Quick hands',icon:'➟',text:'Attack 12% faster',price:35,level:1,repeat:true,max:5,category:'general'},
  {id:'vitality',name:'Wild heart',icon:'♥',text:'+25 maximum health · heal 35',price:35,level:1,repeat:true,category:'general'},
  {id:'speed',name:'Forest stride',icon:'➟',text:'+10% movement speed',price:30,level:1,repeat:true,max:5,category:'general'},
  {id:'nova',name:'Wild amplification',icon:'✺',text:'+25% offensive skill power; timed offensive skills last 10% longer',price:40,level:2,repeat:true,max:5,category:'general'},
  {id:'multi',name:'Triple shot',icon:'⋔',text:'Three arrows of your current element',price:75,level:3,category:'general'},
  {id:'regen',name:'Living roots',icon:'❧',text:'Regenerate 2 health / second',price:70,level:4,category:'general'},
  {id:'pet',name:'Forest fox',icon:'♧',text:'Fires a fan of three physical darts · independent of your element',price:40,level:2,category:'pet'},
  {id:'wolf',name:'Wild wolf',icon:'♧',text:'Bites nearby enemies and howls to slow a pack · independent of your element',price:70,level:3,category:'pet'},
  {id:'collector',name:'Lantern beetle',icon:'◉',text:'Scouts nearby coins and XP and delivers them directly to you',price:35,level:1,category:'pet'},
  {id:'armor',name:'Bark mail',icon:'⬡',text:'+3 armor · reduces incoming damage',price:30,level:1,repeat:true,category:'general'},
  {id:'momentum',name:'Trailrunner',icon:'➟',text:'Build up to +35% speed while moving; stopping resets it',price:45,level:2,category:'ability'},
  ...ECONOMY_UPGRADES,
  ...RARE_UPGRADES,
  {id:'piercing',name:'Thread the Needle',icon:'⇥',text:'Arrows pierce two extra targets, losing 25% damage per hit. Excludes Echo arrows.',price:65,level:2,category:'ability'},
  {id:'ricochet',name:'Echo arrows',icon:'↝',text:'Your arrows bounce once to another nearby enemy for 65% damage. Excludes piercing',price:65,level:3,category:'ability'},
  {id:'dashburst',name:'Thunderstep',icon:'✺',text:'Using your Space skill releases a physical shockwave and briefly slows nearby enemies',price:55,level:2,category:'ability'},
  {id:'gale',name:'Gale boots',icon:'≋',text:'Reduce your selected Space skill cooldown by 38%',price:45,level:2,category:'ability'},
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
  constructor(random=Math.random,progress={}){this.random=random;this.progress=cleanProgress(progress);this.progressRevision=0;this.obstacles=SOLIDS;this.reset();}
  reset(){
    this.state='title';this.time=0;this.wave=1;this.waveTime=0;this.spawnTime=0;
    this.player={x:2400,y:2000,r:13,hp:100,maxHp:100,speed:210,armor:0,momentumTime:0,damage:18,elementalDamage:12,fireRate:.42,fireTimer:0,level:1,xp:0,xpNext:xpForLevel(1),coins:0,kills:0,magnet:75,dashCooldown:0,dashTime:0,spaceTime:0,rapidTime:0,furyTime:0,dx:1,dy:0,invincible:0,nova:0,novaCooldown:0,multi:false,regen:false,pet:false,wolf:false,collector:false,element:'physical',elementUpgrades:{power:0,duration:0,special:0},ranks:{},aimX:0,aimY:-1,shotTime:0,moving:false};
    this.character='ranger';this.startStats={...BASE_STATS};this.chestQueue=[];this.chestSerial=0;this.hazards=[];this.shots=0;this.orbitTimer=0;this.victoryRecorded=false;this.goldRemainder=0;this.interestWaves=new Set();
    this.loadout={space:'dash',attack:'burst'};this.loadoutChoices={space:[],attack:[]};this.upgradeHistory=[];this.freePicks=0;this.levelRewards=[];this.draftChoices=[];this.shopOffers=[];this.rerolls=0;this.shopRound=null;this.shopBaseCost=5;this.shopReason='manual';this.shopReturn='playing';this.shopRevision=0;this.pendingWave=null;this.pendingVictory=false;
    this.pets=[];this.chests=[];this.enemies=[];this.bullets=[];this.hostile=[];this.pickups=[];this.effects=[];this.bossesDefeated=0;this.bossSpawned=false;this.message='';this.event=null;
  }
  prepareLoadout(){
    this.reset();this.state='loadout';this.loadout={space:null,attack:null};
    this.loadoutChoices={space:this.sample(SKILLS.space,3),attack:this.sample(SKILLS.attack,3)};this.shopRevision++;
  }
  chooseSkill(slot,id){
    if(this.state!=='loadout'||!this.loadoutChoices[slot]?.some(s=>s.id===id))return false;
    this.loadout[slot]=id;this.shopRevision++;return true;
  }
  startLoadout(){
    if(this.state!=='loadout'||!this.loadout.space||!this.loadout.attack)return false;
    return this.start({...this.loadout,character:this.character});
  }
  start(loadout={space:'dash',attack:'burst'}){
    if(!SKILLS.space.some(s=>s.id===loadout.space)||!SKILLS.attack.some(s=>s.id===loadout.attack))return false;
    const character=CHARACTERS.find(c=>c.id===(loadout.character||'ranger'));if(!character||!isUnlocked(character,this.progress))return false;
    this.reset();this.character=character.id;this.startStats={...BASE_STATS,...character.stats};Object.assign(this.player,this.startStats,{hp:this.startStats.maxHp});if(character.element)this.player.element=character.element;
    this.loadout={space:loadout.space,attack:loadout.attack};this.state='playing';this.message='Red markers warn attacks · dropped chests open after the wave';return true;
  }
  chooseCharacter(id){const c=CHARACTERS.find(c=>c.id===id);if(this.state!=='loadout'||!c||!isUnlocked(c,this.progress))return false;this.character=id;this.shopRevision++;return true;}
  skill(slot){return SKILLS[slot].find(s=>s.id===this.loadout[slot]);}
  recordUpgrade(item,source){this.upgradeHistory.push({id:item.id,name:item.name,text:item.text,category:item.category||'stat',element:item.element||null,source,level:this.player.level,wave:this.wave,rarity:item.rarity||'common',status:item.id==='heal'?'used':'active'});}
  statSheet(){
    const p=this.player;
    return [
      ['Maximum health',this.startStats.maxHp,p.maxHp],['Physical damage',this.startStats.damage,p.damage],
      ['Shared elemental damage',this.startStats.elementalDamage,p.elementalDamage],['Armor',this.startStats.armor,p.armor],
      ['Movement speed',this.startStats.speed,p.speed],['Bow shots / second',1/this.startStats.fireRate,1/p.fireRate],
      ['Pickup range',this.startStats.magnet,p.magnet],['Health regen / second',0,p.regen?2:0],
      ['Combat gold bonus (%)',0,Math.round((this.goldMultiplier()-1)*100)],['Shop discount (%)',0,p.bargain?15:0],
      ['Reroll discount (%)',0,p.loaded?30:0],['Wave interest (%)',0,p.interest?10:0]
    ].map(([name,base,current])=>({name,base,current}));
  }
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
    this.recordUpgrade(LEVEL_UPGRADES.find(c=>c.id===id),'level');
    this.levelRewards.shift();this.freePicks=this.levelRewards.length;
    if(this.freePicks)this.prepareDraft();
    else{this.draftChoices=[];this.continueRewards();}
    return true;
  }
  prepareShop(){
    const round=this.pendingWave!==null?this.wave:Math.max(0,this.wave-1);
    if(this.shopRound===round)return;
    this.shopRound=round;this.shopBaseCost=5+Math.floor(Math.max(0,round-1)/2)*2;this.rerolls=0;this.rollOffers();
  }
  weightedSample(items,count){const pool=[...items],out=[];while(pool.length&&out.length<count){const weights=pool.map(i=>i.rarity==='rare'?.25:1),sum=weights.reduce((a,b)=>a+b,0);let roll=this.random()*sum,index=0;while(index<pool.length-1&&roll>=weights[index]){roll-=weights[index];index++;}out.push(pool.splice(index,1)[0]);}return out;}
  rollOffers(){this.shopOffers=this.weightedSample(SHOP.filter(i=>this.offer(i).available),4).map(item=>({id:item.id,sold:false}));this.shopRevision++;}
  goldMultiplier(){return 1+(this.player.ranks.mint||0)*.2+(this.player.goldrush?.5:0);}
  earnCombatGold(amount){
    if(!Number.isFinite(amount)||amount<=0)return 0;
    const total=amount*this.goldMultiplier()+this.goldRemainder,whole=Math.floor(total+1e-9);
    this.goldRemainder=Math.max(0,total-whole);this.player.coins+=whole;return whole;
  }
  discountedPrice(base,kind='shop'){return Math.max(1,Math.ceil(base*(kind==='reroll'?(this.player.loaded?.7:1):(this.player.bargain?.85:1))));}
  payInterest(){
    if(this.interestWaves.has(this.wave))return 0;
    this.interestWaves.add(this.wave);const bonus=this.player.interest?Math.min(20,Math.floor(this.player.coins*.1)):0;this.player.coins+=bonus;return bonus;
  }
  rerollCost(){return this.discountedPrice(this.shopBaseCost+this.rerolls*5,'reroll');}
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
  offer(item,{reward=false}={}){
    const p=this.player,rank=this.rank(item),basePrice=item.price+(item.category==='element'?rank*10:0),price=this.discountedPrice(basePrice);
    let reason='';
    if((item.id==='piercing'&&p.ricochet)||(item.id==='ricochet'&&p.piercing))reason='Conflicts with '+(p.piercing?'Thread the Needle':'Echo arrows');
    else if(!reward&&p.level<item.level)reason='Level '+item.level+' required';
    else if(item.category==='element'&&p.element!==item.element)reason='Requires '+ELEMENTS[item.element].name;
    else if(item.category==='affinity'&&p.element===item.element)reason='Currently equipped';
    else if(item.max&&rank>=item.max)reason='Maximum rank';
    else if(!item.repeat&&!['affinity','element'].includes(item.category)&&p[item.id])reason='Already owned';
    else if(item.id==='heal'&&p.hp>=p.maxHp)reason='Health full';
    return {available:!reason,reason,price,basePrice,rank};
  }
  buy(id){
    if(this.state!=='shop')return false;
    const slot=this.shopOffers.find(i=>i.id===id&&!i.sold),item=SHOP.find(i=>i.id===id);if(!slot||!item)return false;
    const offer=this.offer(item);if(!offer.available||this.player.coins<offer.price)return false;
    this.player.coins-=offer.price;slot.sold=true;this.applyItem(item);this.recordUpgrade(item,'shop');this.shopRevision++;return true;
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
      else if(id==='glass'){p.damage*=1.6;p.maxHp=Math.max(25,p.maxHp-25);p.hp=Math.min(p.hp,p.maxHp);p[id]=true;}
      else if(id==='goldrush'){p.speed*=.88;p[id]=true;}
      else if(id==='fleet'){p.speed*=1.3;p.maxHp=Math.max(25,p.maxHp-15);p.hp=Math.min(p.hp,p.maxHp);p[id]=true;}
      else if(id==='worldroot'){p.maxHp+=60;p.hp=Math.min(p.maxHp,p.hp+60);p.armor+=6;p[id]=true;}
      else p[id]=true;
    }
  }
  swapElement(element){
    if(!ELEMENTS[element]||this.player.element===element)return false;
    for(const entry of this.upgradeHistory)if(entry.element&&entry.element!==element&&entry.status==='active')entry.status='replaced';
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
  attackDamage(){return (this.player.damage+this.profile().hit)*(this.player.furyTime>0?2+this.player.nova*.25:1);}
  dropChest(e,tier='normal'){
    const c={id:++this.chestSerial,x:e.x,y:e.y,r:15,tier};this.chests.push(c);return c;
  }
  secureChest(c){
    if(!this.chests.includes(c))return false;
    this.chests=this.chests.filter(x=>x!==c);this.chestQueue.push({id:c.id,tier:c.tier,rerolls:0,reward:null,sourceWave:this.wave});
    this.message=(c.tier==='mythical'?'Mythical':'Ability')+' chest secured · opens after the wave';return true;
  }
  interact(){
    if(this.state!=='playing')return false;
    const c=this.chests.find(c=>dist(c,this.player)<90);if(!c){this.message='Dropped chests are secured by walking nearby · rewards after the wave';return false;}
    return this.secureChest(c);
  }
  chestPool(tier){return (tier==='mythical'?MYTHICAL_UPGRADES:SHOP.filter(i=>['ability','pet','rare'].includes(i.category)||['nova','multi','regen'].includes(i.id))).filter(i=>this.offer(i,{reward:true}).available);}
  rollChest(chest){const choices=this.chestPool(chest.tier).filter(i=>i.id!==chest.reward?.id);if(!choices.length)return false;chest.reward=this.weightedSample(choices,1)[0];this.shopRevision++;return true;}
  chestRerollCost(){const c=this.chestQueue[0];return c?this.discountedPrice((c.tier==='mythical'?15:5)+c.rerolls*(c.tier==='mythical'?10:5),'reroll'):0;}
  chestSellValue(){return this.chestQueue[0]?.tier==='mythical'?90:20;}
  rerollChest(){
    const c=this.chestQueue[0],cost=this.chestRerollCost();if(this.state!=='reward'||!c||this.player.coins<cost)return false;
    if(!this.rollChest(c))return false;this.player.coins-=cost;c.rerolls++;this.shopRevision++;return true;
  }
  resolveChest(action){
    const c=this.chestQueue[0];if(this.state!=='reward'||!c||!['take','sell'].includes(action))return false;
    if(action==='take'){if(!c.reward||!this.offer(c.reward,{reward:true}).available)return false;this.applyItem(c.reward);this.recordUpgrade(c.reward,c.tier==='mythical'?'mythical chest':'chest');}
    else this.player.coins+=this.chestSellValue();
    this.chestQueue.shift();this.continueRewards();return true;
  }
  finishVictory(){if(!this.victoryRecorded){this.progress.wins++;this.progressRevision++;this.victoryRecorded=true;}this.state='won';}
  continueRewards(){
    if(this.freePicks){this.prepareDraft();return;}
    const c=this.chestQueue[0];
    if(c){if(!c.reward)this.rollChest(c);this.state='reward';}
    else if(this.pendingVictory)this.finishVictory();else{this.prepareShop();this.state='shop';}
    this.shopRevision++;
  }
  statusHit(e,element,payload=this.profile(element)){
    if(element!==this.player.element||element==='physical')return;
    if(element==='fire'){e.burn=payload.duration;e.burnDamage=payload.dot;}
    if(element==='ice'){e.slow=payload.duration;e.slowStrength=payload.slow;}
    if(element==='poison'){e.poison=payload.duration;e.poisonDamage=payload.dot;e.poisonStacks=Math.min(5,(e.poisonStacks||0)+1);}
  }
  arrow(source,target,damage,element=this.player.element,kind='arrow',spread=0){
    const a=Math.atan2(target.y-source.y,target.x-source.x)+spread;
    this.bullets.push({x:source.x,y:source.y,vx:Math.cos(a)*520,vy:Math.sin(a)*520,r:4,life:1.65,damage,element,kind,payload:this.profile(element),hitEnemies:new Set(),pierceLeft:kind==='arrow'&&this.player.piercing?2:0,style:kind==='pet'?'fox':this.player.furyTime>0?'moon':this.player.rapidTime>0?'rapid':'arrow'});
  }
  dashDuration(){return (this.skill('space')?.cooldown||2.6)*(this.player.gale?1.6/2.6:1);}
  attackCooldown(){return this.skill('attack')?.cooldown||8;}
  attackInterval(){return this.player.fireRate/(this.player.rapidTime>0?2+this.player.nova*.25:1);}
  moveSpeed(){return this.player.speed*(1+(this.player.momentum?Math.min(1,this.player.momentumTime/2)*.35:0))*(this.loadout.space==='sprint'&&this.player.spaceTime>0?1.7:1);}
  dash(){
    const p=this.player,skill=this.skill('space');if(this.state!=='playing'||p.dashCooldown>0||!skill)return false;
    p.dashCooldown=this.dashDuration();p.spaceTime=skill.duration;this.event='dash';
    if(skill.id==='dash'){p.dashTime=.19;p.invincible=Math.max(p.invincible,.3);}
    if(skill.id==='shield'||skill.id==='repel')p.invincible=Math.max(p.invincible,skill.duration);
    if(skill.id==='sprint')p.invincible=Math.max(p.invincible,.8);
    if(skill.id==='repel'){
      for(const e of this.enemies)if(dist(p,e)<190){const a=Math.atan2(e.y-p.y,e.x-p.x);moveBody(e,Math.cos(a)*130,Math.sin(a)*130,this.obstacles);e.petSlow=2;}
      this.hostile=this.hostile.filter(b=>dist(p,b)>210);
    }
    this.effects.push({x:p.x,y:p.y,r:skill.id==='repel'?190:75,type:skill.id==='repel'?'bramble':skill.id==='sprint'?'hare':skill.id==='shield'?'shell':'wind',life:.65,maxLife:.65});
    if(p.worldroot){for(const e of this.enemies)if(dist(e,p)<230){e.petSlow=3;e.root=1;}this.effects.push({x:p.x,y:p.y,r:230,type:'worldroot',life:1,maxLife:1});}
    if(p.dashburst){this.effects.push({x:p.x,y:p.y,r:145,type:'thunder',element:'physical',life:.45,maxLife:.45});for(const e of this.enemies)if(dist(p,e)<145+e.r){e.hp-=p.damage*1.5;e.petSlow=1.5;}}
    return true;
  }
  nova(){
    const p=this.player,skill=this.skill('attack');if(this.state!=='playing'||p.novaCooldown>0||!skill)return false;
    p.novaCooldown=this.attackCooldown();const power=1+p.nova*.25,duration=skill.duration*(1+p.nova*.1);
    if(skill.id==='rapid'){p.rapidTime=duration;p.fireTimer=0;this.effects.push({x:p.x,y:p.y,r:85,type:'rapid',life:.65,maxLife:.65});}
    if(skill.id==='fury'){p.furyTime=duration;p.fireTimer=0;this.effects.push({x:p.x,y:p.y,r:90,type:'moon',life:.9,maxLife:.9});}
    if(skill.id==='burst'){
      this.effects.push({x:p.x,y:p.y,r:170,type:'quake',element:p.element,life:.6,maxLife:.6});
      for(const e of this.enemies)if(dist(p,e)<170+e.r){e.hp-=(this.attackDamage()+30)*power;this.statusHit(e,p.element);}
      for(let i=0;i<12;i++)this.arrow(p,{x:p.x+Math.cos(i*Math.PI/6),y:p.y+Math.sin(i*Math.PI/6)},this.attackDamage()*.8*power);
      this.hostile=this.hostile.filter(b=>dist(p,b)>180);
    }
    if(skill.id==='salvo'){
      const targets=this.enemies.filter(e=>e.hp>0&&dist(e,p)<600&&!projectileBlocked(p,e,this.obstacles)).sort((a,b)=>dist(a,p)-dist(b,p));
      for(let i=0;i<8;i++){this.arrow(p,targets.length?targets[i%targets.length]:{x:p.x+p.aimX*100,y:p.y+p.aimY*100},this.attackDamage()*1.4*power,p.element,'arrow',targets.length?0:(i-3.5)*.12);this.bullets.at(-1).style='flock';}this.effects.push({x:p.x,y:p.y,r:70,type:'flock',life:.55,maxLife:.55});
    }
    p.shotTime=.3;this.event='nova';return true;
  }
  spawn(boss=false,kindOverride=null){
    const a=this.random()*Math.PI*2,p=this.player,type=this.random(),tier=Math.floor(this.wave/3),r=boss?32+tier*3:type>.78?15:11;
    let point={x:clamp(p.x+Math.cos(a)*420,30,WORLD.width-30),y:clamp(p.y+Math.sin(a)*420,30,WORLD.height-30)};
    if(dist(point,p)<180)point={x:clamp(p.x+(p.x<WORLD.width/2?350:-350),30,WORLD.width-30),y:clamp(p.y+200,30,WORLD.height-30)};
    point=findFree(point,r,this.obstacles);
    const e=boss?{...point,r,hp:430*tier,maxHp:430*tier,speed:40+tier*6,damage:21+tier*3,kind:'boss',tier,attack:2.5,charge:0,slow:0,name:BOSSES[tier-1]}:{...point,r,hp:(type>.78?40:22)+this.wave*5,speed:(type>.78?43:type<.22?82:59)+this.wave*2,damage:10+this.wave,kind:type>.78?'brute':type<.22?'wisp':'crawler',slow:0};
    if(!boss){e.kind=kindOverride||(type<.25?'crawler':type<.4?'wisp':type<.55?'brute':type<.7?'archer':type<.85?'boar':type<.95?'shaman':'bomber');e.attack=1.8;e.charge=0;if(e.kind==='boar'){e.r=17;e.speed=70;}if(e.kind==='shaman')e.hp*=1.4;e.maxHp=e.hp;}
    this.enemies.push(e);return e;
  }
  fireHostile(e,count,speed,offset=0){for(let i=0;i<count;i++){const a=offset+i/count*Math.PI*2;this.hostile.push({x:e.x,y:e.y,vx:Math.cos(a)*speed,vy:Math.sin(a)*speed,r:6,life:7});}}
  hurt(amount){
    const p=this.player;if(p.invincible>0||this.state!=='playing')return;
    p.hp=Math.max(0,p.hp-amount*100/(100+Math.max(0,p.armor)*6));p.invincible=.7;this.event='hurt';
    if(p.thornwake){for(const e of this.enemies)if(dist(p,e)<135)e.hp-=p.damage*1.5;this.effects.push({x:p.x,y:p.y,r:135,type:'bramble',life:.6,maxLife:.6});}
    if(!p.hp&&p.phoenix&&!p.phoenixUsed){p.phoenixUsed=true;for(const entry of this.upgradeHistory)if(entry.id==='phoenix')entry.status='used';p.hp=p.maxHp*.5;p.invincible=2;for(const e of this.enemies)if(dist(e,p)<250)e.hp-=this.attackDamage()*4;this.effects.push({x:p.x,y:p.y,r:250,type:'phoenix',life:1.2,maxLife:1.2});this.message='Phoenix IOU · death postponed';}
    else if(!p.hp)this.state='dead';
  }
  nextWave(){
    const interest=this.payInterest();
    for(const c of [...this.chests])this.secureChest(c);
    this.hazards=[];this.enemies=[];this.hostile=[];this.bullets=[];this.effects=[];
    this.pendingVictory=this.wave===9;this.pendingWave=this.pendingVictory?null:this.wave+1;this.shopReturn='playing';this.shopReason='wave';
    if(!this.pendingVictory){this.shopRound=null;this.rerolls=0;this.shopBaseCost=5+Math.floor(Math.max(0,this.wave-1)/2)*2;this.shopOffers=[];}this.continueRewards();
    this.message='Wave '+this.wave+' cleared'+(interest?' · +'+interest+' interest':'')+' · resolve your rewards';
  }
  warnAttack(e,kind,delay,r=80){
    const atPlayer=kind==='bomb';this.hazards.push({x:atPlayer?this.player.x:e.x,y:atPlayer?this.player.y:e.y,tx:this.player.x,ty:this.player.y,r,kind,delay,maxDelay:delay,source:e,shape:['volley','charge'].includes(kind)?'line':'circle',width:kind==='charge'?(e.r+this.player.r)*2:14});
  }
  specialEnemy(e,dt,speed){
    const p=this.player,d=dist(e,p);e.attack=(e.attack??1.8)-dt;
    if(e.kind==='boar'&&e.attack<=0&&d<350){const a=Math.atan2(p.y-e.y,p.x-e.x);e.cx=Math.cos(a);e.cy=Math.sin(a);e.charge=1.4;e.attack=4.5;this.warnAttack(e,'charge',.7,220);const h=this.hazards.at(-1);h.tx=e.x+e.cx*220;h.ty=e.y+e.cy*220;}
    if(['archer','bomber','shaman'].includes(e.kind)){
      if(e.attack<=0&&d<480){this.warnAttack(e,e.kind==='archer'?'volley':e.kind==='bomber'?'bomb':'hex',e.kind==='archer'?.7:1.15,e.kind==='shaman'?150:90);e.attack=e.kind==='archer'?2.8:4;}
      if(d>270)seekBody(e,p,speed,dt,this.obstacles);
      else if(d<160)seekBody(e,{x:e.x+(e.x-p.x),y:e.y+(e.y-p.y)},speed*.8,dt,this.obstacles);
      return true;
    }
    return false;
  }
  updateHazards(dt){
    for(const h of this.hazards){
      if(h.source?.hp<=0){h.delay=-1;continue;}
      h.delay-=dt;if(h.delay>0)continue;
      if(h.kind==='volley'){const a=Math.atan2(h.ty-h.y,h.tx-h.x);this.hostile.push({x:h.x,y:h.y,vx:Math.cos(a)*290,vy:Math.sin(a)*290,r:5,life:3,style:'arrow',damage:15});}
      else if(h.kind==='barrage')this.fireHostile(h.source,h.source.tier===2?12:16,h.source.tier===2?115:135,this.time);
      else if(h.kind!=='charge'){
        if(dist(h,this.player)<h.r+this.player.r)this.hurt(h.kind==='hex'?18:24);
        if(h.kind==='hex')for(const e of this.enemies)if(e.hp>0&&e!==h.source&&dist(h,e)<h.r){e.hp=Math.min(e.maxHp||e.hp+10,e.hp+10);e.guard=3;}
        this.effects.push({x:h.x,y:h.y,r:h.r,type:h.kind==='hex'?'hex-blast':'enemy-blast',life:.5,maxLife:.5});
      }
    }
    this.hazards=this.hazards.filter(h=>h.delay>0);
  }
  hitBullet(b,e){
    b.hitEnemies??=new Set();b.hitEnemies.add(e);
    const chilled=e.slow>0,profile=b.payload||this.profile(b.element);e.hp-=b.damage*((e.guard||0)>0?.7:1);
    if(b.element==='ice'&&chilled)e.hp-=profile.hit*.5*profile.special;
    this.statusHit(e,b.element,profile);
    if(b.element==='fire'&&profile.special){for(const other of this.enemies)if(other!==e&&other.hp>0&&dist(other,e)<65){other.hp-=profile.hit*.4*profile.special;this.statusHit(other,'fire',profile);}this.effects.push({x:e.x,y:e.y,r:65,type:'embers',life:.4,maxLife:.4});}
    this.effects.push({x:e.x,y:e.y,r:18,type:'hit',element:b.element,life:.25,maxLife:.25});
    if(b.kind==='arrow'&&this.player.piercing&&b.pierceLeft>0){b.pierceLeft--;b.damage*=.75;return 'pierce';}
    if(b.kind==='arrow'&&this.player.ricochet&&!this.player.piercing&&!b.bounced){
      const next=this.enemies.filter(o=>o!==e&&o.hp>0&&!b.hitEnemies.has(o)&&dist(o,e)<210&&!projectileBlocked(e,o,this.obstacles)).sort((a,c)=>dist(a,e)-dist(c,e))[0];
      if(next){const a=Math.atan2(next.y-e.y,next.x-e.x);b.x=e.x;b.y=e.y;b.vx=Math.cos(a)*520;b.vy=Math.sin(a)*520;b.damage*=.65;b.bounced=true;b.life=.6;this.effects.push({x:e.x,y:e.y,r:35,type:'echo',life:.3,maxLife:.3});return 'bounce';}
    }
    b.life=0;return 'stop';
  }
  collect(item){
    if(item.collected)return;
    item.collected=true;
    if(item.kind==='xp')this.gainXP(item.amount);
    if(item.kind==='coin')this.earnCombatGold(item.amount);
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
        if(dist(pet,target)<target.r+32&&pet.attack<=0){target.hp-=p.damage*1.3;pet.attack=.8;pet.fireTime=.3;this.effects.push({x:target.x,y:target.y,r:28,type:'claw',element:'physical',life:.25,maxLife:.25});}
        if(pet.howl<=0&&dist(pet,target)<100){for(const e of candidates)if(dist(e,pet)<135)e.petSlow=2;pet.howl=6;this.effects.push({x:pet.x,y:pet.y,r:135,type:'howl',element:'ice',life:.55,maxLife:.55});}
      }else if(pet.attack<=0&&!projectileBlocked(pet,target,this.obstacles)){
        for(const spread of [-.12,0,.12])this.arrow(pet,target,p.damage*.45,'physical','pet',spread);pet.attack=1.1;pet.fireTime=.25;
      }
    }
  }
  update(dt,input={}){
    if(this.state!=='playing')return;dt=Math.min(.05,Math.max(0,dt));this.time+=dt;this.waveTime+=dt;const p=this.player;
    for(const key of ['dashCooldown','novaCooldown','invincible','dashTime','shotTime','spaceTime','rapidTime','furyTime'])p[key]=Math.max(0,p[key]-dt);
    if(p.regen)p.hp=Math.min(p.maxHp,p.hp+dt*2);
    let mx=input.moveX??((input.right?1:0)-(input.left?1:0)),my=input.moveY??((input.down?1:0)-(input.up?1:0));const len=Math.hypot(mx,my);
    p.moving=!!len;p.momentumTime=len?Math.min(2,p.momentumTime+dt):0;if(len){mx/=len;my/=len;p.dx=mx;p.dy=my;}
    const isDash=p.dashTime>0;moveBody(p,(isDash?p.dx*700:mx*this.moveSpeed())*dt,(isDash?p.dy*700:my*this.moveSpeed())*dt,this.obstacles);
    if(isDash)this.effects.push({x:p.x,y:p.y,r:22,type:'wind',life:.2,maxLife:.2});
    if(p.spaceTime>0&&this.loadout.space==='sprint'&&Math.floor(this.time*20)!==Math.floor((this.time-dt)*20))this.effects.push({x:p.x,y:p.y,r:18,type:'hare',life:.4,maxLife:.4});
    if(p.orbit){this.orbitTimer-=dt;if(this.orbitTimer<=0){this.orbitTimer=.7;for(const e of this.enemies)if(dist(p,e)<115+e.r)e.hp-=p.damage*.7;}}
    this.enemies=this.enemies.filter(e=>e.kind==='boss'||dist(e,p)<1000);
    for(const e of this.enemies)if(e.kind==='boss'&&dist(e,p)>850)Object.assign(e,findFree({x:clamp(p.x+350,40,WORLD.width-40),y:clamp(p.y-200,40,WORLD.height-40)},e.r,this.obstacles));
    this.spawnTime-=dt;if(this.wave%3===0&&!this.bossSpawned){this.spawn(true);this.bossSpawned=true;}
    if(this.spawnTime<=0&&this.enemies.length<70&&(this.wave%3===0||this.waveTime<25)){this.spawn();this.spawnTime=Math.max(.3,1.15-this.wave*.08);}
    p.fireTimer-=dt;const targets=this.enemies.filter(e=>e.hp>0&&dist(p,e)<600&&!projectileBlocked(p,e,this.obstacles));
    if(p.fireTimer<=0&&targets.length){
      const nearest=targets.reduce((a,b)=>dist(p,a)<dist(p,b)?a:b),a=Math.atan2(nearest.y-p.y,nearest.x-p.x);p.aimX=Math.cos(a);p.aimY=Math.sin(a);p.shotTime=.3;
      for(const spread of p.multi?[-.16,0,.16]:[0])this.arrow(p,nearest,this.attackDamage(),p.element,'arrow',spread);p.fireTimer=this.attackInterval();
      this.shots++;if(p.stormcrown&&this.shots%5===0){for(const e of targets)if(dist(e,nearest)<115)e.hp-=(p.damage+this.profile().hit)*.9;this.effects.push({x:nearest.x,y:nearest.y,r:115,type:'lightning',life:.55,maxLife:.55});}
    }
    this.updatePets(dt);
    for(const e of this.enemies){
      if(e.burn>0){e.burn=Math.max(0,e.burn-dt);e.hp-=(e.burnDamage||0)*dt;}
      if(e.poison>0){e.poison=Math.max(0,e.poison-dt);e.hp-=(e.poisonDamage||0)*(e.poisonStacks||1)*dt;}else e.poisonStacks=0;
      if(e.hp<=0)continue;
      e.guard=Math.max(0,(e.guard||0)-dt);e.root=Math.max(0,(e.root||0)-dt);e.slow=Math.max(0,e.slow-dt);e.petSlow=Math.max(0,(e.petSlow||0)-dt);const a=Math.atan2(p.y-e.y,p.x-e.x),speed=e.speed*(1-Math.max(e.slow>0?(e.slowStrength||.45):0,e.petSlow>0?.3:0));
      if(e.kind==='boss'){
        e.attack-=dt;if(e.attack<0){
          if(e.tier===1){e.charge=1.4;e.cx=Math.cos(a);e.cy=Math.sin(a);this.warnAttack(e,'charge',.7,220);const h=this.hazards.at(-1);h.tx=e.x+e.cx*220;h.ty=e.y+e.cy*220;}
          if(e.tier===2)this.warnAttack(e,'barrage',.65,145);
          if(e.tier===3){this.warnAttack(e,'barrage',.65,145);this.spawn();this.spawn();}
          e.attack=e.tier===1?3.5:e.tier===2?2.6:2.4;
        }
      }
      const special=e.kind!=='boss'&&this.specialEnemy(e,dt,speed);
      if(e.root>0)continue;
      if(e.charge>0){e.charge-=dt;if(e.charge<.7)moveBody(e,e.cx*290*dt,e.cy*290*dt,this.obstacles);}
      else if(!special)seekBody(e,p,speed,dt,this.obstacles);
      if(e.hp>0&&dist(e,p)<e.r+p.r)this.hurt(e.damage);
    }
    for(const b of this.bullets){
      const old={x:b.x,y:b.y};b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;if(b.life<=0)continue;
      const wall=firstObstacleHit(old,b,this.obstacles),hits=this.enemies.filter(e=>e.hp>0&&!b.hitEnemies?.has(e)).map(e=>({e,t:segmentHit(old,b,e,b.r)})).filter(h=>h.t<=1&&h.t<wall).sort((a,c)=>a.t-c.t);
      let bounced=false;
      for(const h of hits){if(h.e.hp<=0)continue;const action=this.hitBullet(b,h.e);if(action==='bounce')bounced=true;if(action!=='pierce')break;}
      if(!bounced&&wall<=1)b.life=0;
    }
    this.bullets=this.bullets.filter(b=>b.life>0&&b.x>0&&b.x<WORLD.width&&b.y>0&&b.y<WORLD.height);
    this.updateHazards(dt);
    for(const b of this.hostile){const old={x:b.x,y:b.y};b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;if(projectileBlocked(old,b,this.obstacles))b.life=0;if(b.life>0&&dist(b,p)<b.r+p.r){this.hurt(b.damage||14);this.effects.push({x:b.x,y:b.y,r:35,type:'enemy-blast',life:.3,maxLife:.3});b.life=0;}}
    this.hostile=this.hostile.filter(b=>b.life>0&&b.x>0&&b.x<WORLD.width&&b.y>0&&b.y<WORLD.height);
    for(const e of this.enemies)if(e.hp<=0){
      p.kills++;this.progress.kills++;this.progressRevision++;if(p.reaper&&p.kills%5===0){p.hp=Math.min(p.maxHp,p.hp+6);this.effects.push({x:p.x,y:p.y,r:55,type:'harvest',life:.6,maxLife:.6});}const boss=e.kind==='boss';
      if(boss||this.random()<.045)this.dropChest(e,boss?'mythical':'normal');
      if(p.element==='poison'&&p.elementUpgrades.special&&e.poison>0)for(const other of this.enemies)if(other!==e&&other.hp>0&&dist(e,other)<90+p.elementUpgrades.special*15)this.statusHit(other,'poison');
      this.pickups.push({x:e.x-7,y:e.y,kind:'xp',amount:boss?35:5,r:5},{x:e.x+7,y:e.y,kind:'coin',amount:boss?15:3,r:5});if(this.random()<.07)this.pickups.push({x:e.x,y:e.y+8,kind:'heal',amount:12,r:6});
      this.effects.push({x:e.x,y:e.y,r:boss?75:25,type:'death',life:.5,maxLife:.5});if(boss){this.bossesDefeated++;this.progress.bosses++;this.progressRevision++;this.message=e.name+' defeated · mythical chest dropped';this.earnCombatGold(60);this.event='boss';}
    }
    this.enemies=this.enemies.filter(e=>e.hp>0);
    for(const item of this.pickups){const d=dist(p,item);if(d<p.magnet){item.x+=(p.x-item.x)*Math.min(1,dt*9);item.y+=(p.y-item.y)*Math.min(1,dt*9);}if(d<20)this.collect(item);}
    for(const c of [...this.chests])if(dist(c,p)<40)this.secureChest(c);
    this.pickups=this.pickups.filter(i=>!i.collected).slice(-500);this.effects.forEach(e=>e.life-=dt);this.effects=this.effects.filter(e=>e.life>0);
    if(this.state==='playing'&&((this.wave%3!==0&&this.waveTime>=25)||(this.wave%3===0&&this.bossSpawned&&!this.enemies.some(e=>e.kind==='boss'))))this.nextWave();
  }
}
export function advanceGame(game,elapsed,input={}){
  let remaining=Math.min(.25,Math.max(0,Number.isFinite(elapsed)?elapsed:0));
  while(remaining>1e-8&&game.state==='playing'){const step=Math.min(1/60,remaining);game.update(step,input);remaining-=step;}
}
