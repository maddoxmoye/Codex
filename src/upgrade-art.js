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
drawings.health=drawings.vitality;drawings.damage=drawings.power;drawings.elemental=drawings['element-base'];
const elements={
 fire:path('M25 5q3 13-5 17 0-6-6-9-1 9-6 16-2 14 16 15 18-1 16-15-2-9-9-13 0 8-6 10 7-14 0-21Z'),
 ice:path('M24 4v40M7 14l34 20M7 34l34-20M18 8l6 6 6-6M18 40l6-6 6 6M6 21l9-3-1-9m28 18-9 3 1 9M6 27l9 3-1 9m28-18-9-3 1-9'),
 poison:path('M18 7h12m-10 0v10-1l-9 14q-5 11 7 11h12q12 0 7-11l-9-14V7M13 30h22')+circle(21,27,2)+circle(29,34,2),
};
export function upgradeArt(item){
 const element=item.element||(['fire','ice','poison'].includes(item.id)?item.id:null);
 const drawing=elements[element]||drawings[item.id]||spark;
 const badge=item.rankKey==='power'?path('m34 17 5-6 5 6m-10 7 5-6 5 6'):item.rankKey==='duration'?circle(38,13,8)+path('M38 7v6l4 3'):item.rankKey==='special'?path('m38 4 2 6 6 3-6 2-2 7-2-7-6-2 6-3Z'):'';
 return `<span class="upgrade-art${element?' art-'+element:''}" aria-hidden="true"><svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${drawing}${badge?`<g class="art-badge">${badge}</g>`:''}</svg></span>`;
}
