// Small inline illustrations keep the standalone game sharp and work offline.
const path=d=>`<path d="${d}"/>`;
const circle=(x,y,r)=>`<circle cx="${x}" cy="${y}" r="${r}"/>`;
const arrow=path('M10 37 36 11m-12 0h12v12M10 28v9h9');
const boot=path('M13 9h13l-2 17 12 5q5 2 3 8H10V28l3-19Z');
const heart=path('M24 37 9 23C-1 7 19 4 24 15 29 4 49 7 39 23Z');
const leaf=path('M10 37Q3 9 37 9q4 30-24 26m-3 2 22-22m-12 9-1-9m7 14 8-1');
const coin=circle(24,24,15)+circle(24,24,10)+path('M24 17v14m-4-12h8m-8 10h8');
const shield=path('M24 6 39 12v12q-2 12-15 18Q11 36 9 24V12Z');
const spark=path('m24 5 5 13 14 6-14 5-5 14-5-14-14-5 14-6Z');
const drawings={
 magnet:circle(24,24,17)+path('m30 12-3 15-15 9 9-15ZM21 21l6 6')+circle(24,24,3),
 heal:path('M18 7h12m-10 0v10l-9 13q-5 11 7 11h12q12 0 7-11l-9-13V7M15 29h18m-9-9v13m-5-7h10'),
 power:arrow+path('m29 13 6 6m-21 9 6 6'),
 'element-base':path('m24 5 14 19-14 19L10 24ZM10 24h28M24 5v38')+circle(24,24,5),
 haste:path('M7 18h13M5 25h12M9 32h11M26 9l-4 17 10-5-4 18 15-23-12 4 4-11Z'),
 vitality:heart+path('M24 20v12m-6-6h12'),speed:boot+path('M3 14h8M2 21h8'),
 nova:spark+circle(24,24,7),
 multi:path('M24 41V7m-6 6 6-6 6 6M11 36V14m-6 6 6-6 6 6m20 22V14m-6 6 6-6 6 6'),
 regen:leaf+path('M23 28v12m-6-6h12'),
 pet:path('m7 13 10 5 7-3 7 3 10-5-4 19-13 10-13-10ZM7 13l13 13m21-13L28 26m-8 7 4 3 4-3')+circle(17,26,1)+circle(31,26,1),
 wolf:path('m9 7 12 11h6L39 7l-2 23-13 12-13-12ZM12 21l8 5m16-5-8 5m-9 6 5 4 5-4'),
 collector:circle(24,26,11)+path('M24 15v22M13 21l-7-4m7 10H5m9 6-7 5m28-17 7-4m-7 10h8m-9 6 7 5M20 15l-4-7m12 7 4-7')+circle(24,7,4),
 armor:shield+path('M15 16h18m-18 7h18m-15 7h12M24 12v25'),
 momentum:boot+path('m31 8 7 5-7 5m5 2 7 5-7 5'),
 economy:path('M8 20h32M12 20v17m8-17v17m8-17v17m8-17v17M7 40h34M24 6 7 17h34Z')+circle(24,13,2),
 mint:coin+path('M34 13q0-9 10-8 0 11-10 8'),
 bargain:path('M7 9h34v22H26L15 40v-9H7ZM14 17h20m-20 7h14')+path('M28 12v16'),
 loaded:path('m10 8 25 3 4 27-26 3Z')+circle(20,18,2)+circle(29,29,2)+circle(19,31,2),
 interest:path('M7 32q17 15 34 0M10 26q14 12 28 0m-14-4V7m-6 6 6-6 6 6')+circle(24,26,9),
 glass:path('m14 9 22 4-7 29-18-4ZM17 20l10 5-8 6m3-24 3 7m7-8-4 10m9-7-5 9'),
 goldrush:path('m13 7 11 4 11-4-4 12q15 19 4 22H13Q2 38 17 19Zm4 12h14')+circle(24,31,6),
 fleet:leaf+path('M6 40 40 6m-11 0h11v11'),
 thornwake:path('M15 9h18l9 30-11-7-7 9-7-9-11 7ZM15 9l9 8 9-8m-19 8-5-1 3 7m24-6 5-1-3 7'),
 piercing:path('M6 24h36m-7-7 7 7-7 7M16 8v12m0 8v12M29 8v12m0 8v12'),
 ricochet:path('M5 36 22 19l11 11 10-19m-10 0h10v10')+circle(22,19,4)+circle(33,30,4),
 dashburst:boot+path('m34 5-6 14h9l-6 12 13-18h-9l5-8'),
 gale:boot+path('M3 8h12q7 0 3 6M2 18h10m18-7h8q8 0 5 6'),
 reaper:heart+path('M10 40 34 12q10 0 9 11L30 9'),
 phoenix:path('M24 41V23M24 29 7 16 4 7l20 13L44 7l-3 9-17 13M24 20l-5-7 5-8 5 8-5 7m-7 18 7-7 7 7'),
 stormcrown:path('m7 14 9 7 8-12 8 12 9-7-4 21H11Zm6 27h22M26 19l-8 10h8l-5 11'),
 worldroot:path('M24 34V16m0 8L13 15m11 7 11-10M24 33l-12 8m12-8 12 8m-12-8-2 11')+circle(24,13,9)+circle(13,17,7)+circle(35,15,7),
 orbit:circle(24,24,8)+`<ellipse cx="24" cy="24" rx="21" ry="12" transform="rotate(-30 24 24)"/>`+circle(8,32,4)+circle(39,15,4)+circle(29,35,4),
};
const book=path('M10 7h25v34H10q-5-4 0-8h25M10 7v26m6-18h13m-13 6h10');
const pouch=path('m15 7 9 4 9-4-3 13q17 18 5 21H13Q1 38 18 20Zm3 13h12');
const vest=path('m14 7 10 7 10-7 9 11-8 6v17H13V24l-8-6Zm10 7v27');
const necklace=path('M9 7q0 20 15 25Q39 27 39 7m-15 21-7 8 7 8 7-8Z');
const vial=path('M18 5h12m-10 0v13L12 31q-4 10 5 11h14q9-1 5-11l-8-13V5M14 30h20');
Object.assign(drawings,{
 haste:circle(24,24,13)+path('M12 9h24M12 39h24M17 10v28m7-28v28m7-28v28'),
 vitality:necklace+`<g transform="translate(12 27) scale(.5)">${heart}</g>`,
 nova:circle(23,22,13)+circle(23,22,8)+path('m33 32 10 11M23 9v26M10 22h26'),
 multi:path('M12 19h25l-4 23H16ZM17 19V5m7 14V3m7 16V7m-17 1 3-3 3 3m1-2 3-3 3 3m1 4 3-3 3 3'),
 regen:path('M8 15h32v22H8Zm4-5h24v5M13 22h22m-22 8h22')+`<g transform="translate(13 8) scale(.5)">${leaf}</g>`,
 economy:book, bargain:circle(24,18,11)+path('m17 28-3 15 10-6 10 6-3-15m-12-9 4 4 7-9'),
 interest:path('M10 16h28v25H10ZM8 11h32v5H8Zm10 9h12m-6 0v16')+circle(24,7,5),
 fleet:drawings.thornwake+path('M15 15q16 0 15 20M14 21l13-4m-10 13 14-4'),
 reaper:necklace+path('m24 31 7-1-7 14-4-9Z'),
 phoenix:path('M10 42 34 5q16 12-1 25L14 38m8-10 14-10m-9 4-2-9m-7 23 15-7'),
 worldroot:path('M9 22h30v20H9ZM7 17h34v5H7Zm17 6v17m0-23V7m0 5L15 6m9 9 11-9')+circle(14,7,4)+circle(35,7,4),
 'rivet-pouch':pouch+circle(20,30,2)+circle(28,34,2),
 'padded-vest':vest+path('M14 25h20m-20 7h20M18 16v24m12-24v24'),
 'wool-wrap':path('M8 15h32v25H8Zm-3 8h38M8 32h32M16 9h16v6m-8 8v11m-5-5h10'),
 'tin-badge':shield+path('m24 16 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1Z'),
 'field-journal':book+path('m19 29 13-17m-6 1 6-1-1 7'),
 'coin-purse':pouch+circle(24,31,6),
 'archery-glove':path('M10 29V17q3-4 5 0v8-15q3-4 5 0v13V7q3-4 5 0v16V10q3-4 5 0v18l5-7q6-2 6 4L30 41H16Z'),
 'copper-ring':circle(24,28,12)+path('m16 12 8-8 8 8-8 9Z'),
 'trail-socks':boot+path('M13 14h12m-13 5h12m-13 5h12'),
 spyglass:path('m7 30 7 10 26-21L30 6Zm7-6 10 11m-2-18 10 10m-1-15 6 7'),
 'barbed-heads':arrow+path('m20 19-9 1 5 6m11-14-9 1 5 6'),
 'vampire-fang':necklace+path('m20 31 10-2-5 15Z'),
 'lucky-button':circle(24,24,17)+circle(19,19,2)+circle(29,19,2)+circle(19,29,2)+circle(29,29,2)+path('m19 19 10 10m0-10L19 29'),
 'iron-buckle':path('M3 18h42v14H3ZM14 10h21v30H14Zm5 6h11v18H19Zm-1 8h23'),
 runestone:path('m16 6 18 4 6 20-12 13-18-9-3-17Zm7 6-8 13h11l-6 12 13-18H22Z'),
 'wind-chime':path('M9 10h30m-21 0V4h12v6M12 10v22m8-22v30m8-30v25m8-25v19M9 32h6m2 8h6m2-5h6m2-6h6'),
 clockface:circle(24,27,15)+circle(24,6,4)+path('M24 18v10l7 5'),
 'beetle-pack':path('M13 15h22v27H13ZM17 15V8h14v7m-18 9h22m-18 5h14v9H17Z')+circle(24,19,3),
 'wolf-collar':path('M5 20q19-14 38 0v13q-19 14-38 0Zm7-4v8m9-11v8m10-8v8m9-5v8')+circle(24,37,5),
 'fox-whistle':path('M11 29q0-13 13-13t13 13l5 6H6Zm13-13V8m-7 32q7 7 14 0')+circle(24,6,3),
 'flask-harness':vest+`<g transform="translate(13 19) scale(.5)">${vial}</g>`,
 'fletching-kit':path('M8 39 33 6m-9 7 9-7 6 9-6 13-17 7m7-15 14-5m-21 16 17-5'),
 'boss-lens':circle(23,22,13)+circle(23,22,8)+path('M37 22v13q-1 11 8 9M17 18l6 8 6-8'),
 'marked-prey':circle(24,24,16)+path('M16 14v20m6-20v20m6-20v20m-16-6 24-9'),
 'spark-spurs':boot+circle(37,33,7)+path('M37 22v22m-11-11h22m-19-8 16 16m0-16-16 16'),
 'second-wind':necklace+path('m24 30-3 6h5l-2 7 7-10h-5l2-3'),
 'mercury-glass':path('M11 5h26m-24 0q0 12 11 19-11 7-11 19m22-38q0 12-11 19 11 7 11 19M11 43h26M17 13h14m-14 23 7-7 7 7Z'),
 'obsidian-heads':path('m24 4 17 29-17-6-17 6Zm0 23v17m-6-4h12M24 4l6 23'),
 'salvage-satchel':path('M9 14h30v28H9ZM15 14V6h18v8M9 18l15 13 15-13M20 28v7h8v-7'),
 'weathered-buckler':circle(24,24,18)+circle(24,24,6)+path('m12 10 8 7m10 14 7 6M9 26l6 4-3 6'),
 'voltaic-spool':path('M10 8h28M10 40h28M15 8v32m18-32v32m-18-25h18m-18 6h18m-18 6h18m-18 6h18m-13-20-7 12h8l-5 11 12-17h-8l4-6'),
 'crimson-thimble':path('M13 40V19q0-15 11-15t11 15v21Zm0-8h22m-18-13h3m8 0h3m-14 7h3m8 0h3')+path('M35 36q12-2 8-12'),
});
drawings.pet+=path('M33 35h11v7H29');drawings.wolf+=path('M33 35h11v7H29');drawings.collector+=path('M14 40h20m-17 0 2 4');
drawings.health=drawings.vitality;drawings.damage=drawings.power;drawings.elemental=drawings['element-base'];
const elements={
 fire:path('M25 5q3 13-5 17 0-6-6-9-1 9-6 16-2 14 16 15 18-1 16-15-2-9-9-13 0 8-6 10 7-14 0-21Z'),
 ice:path('M24 4v40M7 14l34 20M7 34l34-20M18 8l6 6 6-6M18 40l6-6 6 6M6 21l9-3-1-9m28 18-9 3 1 9M6 27l9 3-1 9m28-18-9-3 1-9'),
 poison:path('M18 7h12m-10 0v10-1l-9 14q-5 11 7 11h12q12 0 7-11l-9-14V7M13 30h22')+circle(21,27,2)+circle(29,34,2),
};
export function upgradeArt(item){
 const element=item.element||(['fire','ice','poison'].includes(item.id)?item.id:null);
 const base=elements[element];const component=item.rankKey==='power'?drawings.power:item.rankKey==='duration'?vial:item.rankKey==='special'?path('m24 5 13 12-4 24H15L11 17Z'):path('M12 13h24l-4 30H16ZM17 13V4m7 9V2m7 11V5');
 const drawing=base?component+`<g transform="translate(14 17) scale(.42)">${base}</g>`:drawings[item.id]||spark;
 const badge=item.rankKey==='power'?path('m34 17 5-6 5 6m-10 7 5-6 5 6'):item.rankKey==='duration'?circle(38,13,8)+path('M38 7v6l4 3'):item.rankKey==='special'?path('m38 4 2 6 6 3-6 2-2 7-2-7-6-2 6-3Z'):'';
 return `<span class="upgrade-art${element?' art-'+element:''}" aria-hidden="true"><svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${drawing}${badge?`<g class="art-badge">${badge}</g>`:''}</svg></span>`;
}
