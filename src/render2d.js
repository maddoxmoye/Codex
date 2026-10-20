import { WORLD, REGIONS, CHARACTERS } from './game.js';
import { SCENERY, STRUCTURES } from './world.js';
export function create2DRenderer(canvas,game){
 const ctx=canvas.getContext('2d');
 const circle=(x,y,r,color)=>{ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();};
 const ring=(x,y,r,color,width=2)=>{ctx.strokeStyle=color;ctx.lineWidth=width;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.stroke();};
 const line=(x,y,tx,ty,color,width=2)=>{ctx.strokeStyle=color;ctx.lineWidth=width;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(tx,ty);ctx.stroke();};
 const palette={wind:'#8ee4fa',hare:'#a1ed9b',shell:'#f4d080',bramble:'#a2d56c',worldroot:'#89c76c',rapid:'#ffe19a',moon:'#d3b1fa',flock:'#a9edff',thunder:'#8eeaff',lightning:'#a4edff',phoenix:'#ff9a55',harvest:'#a3e29b',howl:'#a7e4f0',echo:'#d0a3ee','enemy-blast':'#f07596','hex-blast':'#b5dd76',embers:'#ff995b',claw:'#fff0cd'};
 function render(time){
  const w=Math.max(1,Math.round(canvas.clientWidth)),h=Math.max(1,Math.round(canvas.clientHeight));if(canvas.width!==w||canvas.height!==h){canvas.width=w;canvas.height=h;}
  const p=game.player;ctx.fillStyle='#203b2a';ctx.fillRect(0,0,w,h);ctx.save();ctx.translate(w/2-p.x,h/2-p.y);
  for(const r of REGIONS.slice(1))circle(r.x,r.y,r.r,r.color);
  ctx.strokeStyle='#a6976333';ctx.lineWidth=250;ctx.beginPath();for(const r of REGIONS.slice(1)){ctx.moveTo(WORLD.width/2,WORLD.height/2);ctx.lineTo(r.x,r.y);}ctx.stroke();
  for(const o of [...SCENERY,...STRUCTURES])if(Math.abs(o.x-p.x)<w/2+150&&Math.abs(o.y-p.y)<h/2+150)circle(o.x,o.y,o.r,o.type==='tree'?'#416143':o.type==='rock'?'#7d8670':'#8c7651');
  for(const warning of game.hazards){
   const progress=1-warning.delay/warning.maxDelay;ctx.globalAlpha=.25;
   if(warning.shape==='line'){line(warning.x,warning.y,warning.tx,warning.ty,'#ff695f',warning.width);ctx.globalAlpha=.7;line(warning.x,warning.y,warning.x+(warning.tx-warning.x)*progress,warning.y+(warning.ty-warning.y)*progress,'#ff796b',warning.width);}
   else{circle(warning.x,warning.y,warning.r*progress,'#ff665f');ctx.globalAlpha=.9;ring(warning.x,warning.y,warning.r,'#ff8773',3);}ctx.globalAlpha=1;
  }
  for(const c of game.chests){ring(c.x,c.y,22,c.tier==='mythical'?'#ddacff':'#eed27a');ctx.fillStyle=c.tier==='mythical'?'#b88ad4':'#dfbb69';ctx.fillRect(c.x-12,c.y-9,24,18);line(c.x,c.y-9,c.x,c.y+9,'#5c4238',3);if(c.tier==='mythical')for(let i=0;i<3;i++)circle(c.x-8+i*8,c.y-13,3,'#ffdeb4');}
  for(const i of game.pickups)circle(i.x,i.y,6,i.kind==='xp'?'#bf9de4':i.kind==='heal'?'#a8da90':'#edc46b');
  for(const e of game.enemies){
   const color=e.kind==='boss'?'#ac83ba':{archer:'#d6bc92',boar:'#bc9063',shaman:'#b6d971',bomber:'#d58cb6'}[e.kind]|| (e.slow>0?'#a4deeb':e.poison>0?'#9cce62':e.burn>0?'#e29251':'#849960');
   circle(e.x,e.y,e.r,color);circle(e.x+4,e.y-4,3,'#ffebaf');
   if(e.kind==='boar'){line(e.x-8,e.y+10,e.x-13,e.y+18,'#fff0c4',3);line(e.x+8,e.y+10,e.x+13,e.y+18,'#fff0c4',3);}
   if(e.kind==='archer'){ctx.strokeStyle='#efb57b';ctx.lineWidth=3;ctx.beginPath();ctx.arc(e.x+15,e.y,14,-Math.PI/2,Math.PI/2);ctx.stroke();}
   if(e.kind==='shaman'){line(e.x+17,e.y-15,e.x+17,e.y+18,'#8c6c49',3);circle(e.x+17,e.y-18,6,'#caef90');}
   if(e.kind==='bomber'){circle(e.x+13,e.y,7,'#f69a64');line(e.x+13,e.y-6,e.x+17,e.y-15,'#ffdd87',2);}
   if(e.guard>0)ring(e.x,e.y,e.r+5,'#f7df8e');
  }
  for(const pet of game.pets){circle(pet.x,pet.y,12,pet.kind==='fox'?'#dba15c':pet.kind==='collector'?'#e8c463':'#b3d8e4');circle(pet.x+7,pet.y-5,6,'#e7e2bb');}
  for(const b of [...game.bullets,...game.hostile]){
   ctx.save();ctx.translate(b.x,b.y);ctx.rotate(Math.atan2(b.vy,b.vx));const hostile=game.hostile.includes(b),color=hostile?'#f591a0':b.pierceLeft?'#8de4ff':b.style==='moon'?'#dcb5ff':b.element==='fire'?'#ffa254':b.element==='ice'?'#91e7fa':b.element==='poison'?'#b1ee71':'#edd8a4';
   if(b.style==='flock'){line(-7,-9,2,0,'#d2efff',3);line(2,0,-7,9,'#d2efff',3);}else{line(-16,0,7,0,color,3);line(7,0,1,-4,color,3);line(7,0,1,4,color,3);}ctx.restore();
  }
  if(p.spaceTime>0&&game.loadout.space==='shield'){ring(p.x,p.y,30,'#ffdb81',4);for(let i=0;i<6;i++){const a=time+i*Math.PI/3;circle(p.x+Math.cos(a)*30,p.y+Math.sin(a)*30,3,'#ffdb81');}}
  if(p.spaceTime>0&&game.loadout.space==='repel')for(let i=0;i<12;i++){const a=time+i*Math.PI/6;line(p.x+Math.cos(a)*22,p.y+Math.sin(a)*22,p.x+Math.cos(a)*38,p.y+Math.sin(a)*38,'#b0e276',4);}
  if(p.spaceTime>0&&game.loadout.space==='sprint')for(const x of [-12,0,12])line(p.x+x,p.y+10,p.x+x-p.dx*35,p.y+10-p.dy*35,'#b5ed91',3);
  if(p.rapidTime>0)for(let i=0;i<6;i++){const a=time*5+i*Math.PI/3;circle(p.x+Math.cos(a)*28,p.y+Math.sin(a)*28,3,'#ffe194');}
  if(p.furyTime>0){ctx.strokeStyle='#e3baff';ctx.lineWidth=5;ctx.beginPath();ctx.arc(p.x,p.y-36,10,-Math.PI*.7,Math.PI*.7);ctx.stroke();}
  if(p.orbit)for(let i=0;i<3;i++){const a=time*2+i*Math.PI*2/3;circle(p.x+Math.cos(a)*100,p.y+Math.sin(a)*100,9,'#ffe99a');}
  if(!(p.invincible>0&&p.spaceTime<=0&&Math.floor(time*16)%2)){const c=CHARACTERS.find(c=>c.id===game.character);circle(p.x,p.y,14,c.color);circle(p.x,p.y-4,8,c.hood);ctx.strokeStyle='#c6a16b';ctx.lineWidth=3;ctx.beginPath();ctx.arc(p.x+9,p.y,14,-Math.PI/2,Math.PI/2);ctx.stroke();}
  for(const e of game.effects){
   const progress=1-e.life/e.maxLife,r=e.r*(.2+.8*progress),color=palette[e.type]||(e.element==='fire'?'#ffad6d':e.element==='ice'?'#a6e8ff':e.element==='poison'?'#b9e47a':'#e3daa9');ctx.globalAlpha=Math.max(0,1-progress);
   ring(e.x,e.y,r,color,e.type==='quake'?5:2);
   if(['thunder','lightning'].includes(e.type)){ctx.strokeStyle=color;ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(e.x-10,e.y-100);for(let i=0;i<5;i++)ctx.lineTo(e.x+(i%2?10:-10),e.y-100+i*25);ctx.stroke();}
   else for(let i=0;i<6;i++){const a=i*Math.PI/3+progress;line(e.x+Math.cos(a)*r*.5,e.y+Math.sin(a)*r*.5,e.x+Math.cos(a)*r,e.y+Math.sin(a)*r,color,['bramble','worldroot','claw'].includes(e.type)?4:2);}
   ctx.globalAlpha=1;
  }
  ctx.strokeStyle='#b3c487';ctx.lineWidth=4;ctx.strokeRect(0,0,WORLD.width,WORLD.height);ctx.restore();
 }
 return{render,dispose(){}};
}
