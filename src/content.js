export const CHARACTERS=[
 {id:'ranger',name:'Rowan · Wayfarer',icon:'➶',color:'#97af68',hood:'#c2ce91',text:'Balanced bow, steady stride. Your original ranger.',stats:{},goal:'Always available'},
 {id:'scout',name:'Ash · Cinder Scout',icon:'ϟ',color:'#d58554',hood:'#efbd86',text:'85 health · 22 physical damage · 235 speed. Fast, fragile and precise.',stats:{maxHp:85,damage:22,speed:235},goal:'Defeat 50 enemies across runs',metric:'kills',target:50},
 {id:'warden',name:'Briar · Ironwarden',icon:'⬡',color:'#629bab',hood:'#c1d7d9',text:'140 health · 4 armor · 190 speed · 16 physical damage. A walking fortress.',stats:{maxHp:140,armor:4,speed:190,damage:16},goal:'Defeat your first guardian',metric:'bosses',target:1},
 {id:'hex',name:'Nyx · Moonstring',icon:'☾',color:'#a184cb',hood:'#dfc2ef',text:'90 health · 15 physical damage · 24 shared elemental damage. Starts attuned to ice.',stats:{maxHp:90,damage:15,elementalDamage:24},element:'ice',goal:'Win a nine-wave run',metric:'wins',target:1}
];
export function cleanProgress(value){
 const p=value&&typeof value==='object'?value:{};
 return Object.fromEntries(['kills','bosses','wins'].map(k=>[k,Math.min(1e9,Math.max(0,Math.floor(Number(p[k])||0)))]));
}
export const isUnlocked=(character,progress)=>!character.metric||(progress[character.metric]||0)>=character.target;
export const ECONOMY_UPGRADES=[
 {id:'mint',name:'Pocket Mint',icon:'◈',text:'+20% combat gold per rank (max 3). Stacks with Heavy Pockets.',price:35,level:1,repeat:true,max:3,category:'economy'},
 {id:'bargain',name:'Silver Tongue',icon:'❧',text:'Shop purchases cost 15% less. Displayed prices include the discount.',price:45,level:1,category:'economy'},
 {id:'loaded',name:'Loaded Dice',icon:'◇',text:'Shop and chest rerolls cost 30% less (rounded up, minimum 1 gold).',price:40,level:2,category:'economy'},
 {id:'interest',name:'Nest Egg',icon:'◉',text:'After each wave, earn 10% of your saved gold (rounded down, max 20 gold per wave).',price:55,level:2,category:'economy'}
];
export const RARE_UPGRADES=[
 {id:'glass',name:'Glass Quiver',icon:'◇',text:'+60% physical damage, but lose 25 maximum health (minimum 25).',price:85,level:3,category:'rare',rarity:'rare'},
 {id:'goldrush',name:'Heavy Pockets',icon:'◈',text:'+50% gold from combat drops and guardian bounties, but −12% movement speed.',price:70,level:2,category:'rare',rarity:'rare'},
 {id:'fleet',name:'Featherweight Vow',icon:'➟',text:'+30% movement speed, but lose 15 maximum health (minimum 25).',price:70,level:2,category:'rare',rarity:'rare'},
 {id:'thornwake',name:'Thornwake Mantle',icon:'❧',text:'Taking damage releases a thorn nova for 150% physical damage within 135 units.',price:80,level:3,category:'rare',rarity:'rare'}
];
export const MYTHICAL_UPGRADES=[
 {id:'phoenix',name:'Phoenix IOU',icon:'ϟ',text:'Once per run, a fatal hit revives you at 50% health, grants 2s protection and unleashes a fiery blast.',category:'mythical',rarity:'mythical',price:180,level:1},
 {id:'stormcrown',name:'Stormglass Crown',icon:'♛',text:'Every fifth bow volley calls lightning on its target, damaging enemies within 115 units.',category:'mythical',rarity:'mythical',price:180,level:1},
 {id:'worldroot',name:'Worldroot Covenant',icon:'❧',text:'+60 maximum health, heal 60, +6 armor. Your Space skill roots nearby foes in a slowing grove.',category:'mythical',rarity:'mythical',price:180,level:1},
 {id:'orbit',name:'Orbit of Dawn',icon:'☼',text:'Three miniature suns orbit you, burning nearby enemies every 0.7 seconds for 70% physical damage.',category:'mythical',rarity:'mythical',price:180,level:1}
];
