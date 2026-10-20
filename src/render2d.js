import { WORLD, REGIONS } from './game.js';
// Accessible fallback uses the same world and follows the same ranger.
export function create2DRenderer(canvas,game) {
  canvas.width=1000;canvas.height=660;const ctx=canvas.getContext('2d');
  function circle(x,y,r,color){ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();}
  function render(time){
    const p=game.player;ctx.fillStyle='#203b2a';ctx.fillRect(0,0,1000,660);ctx.save();ctx.translate(500-p.x,330-p.y);
    for(const r of REGIONS.slice(1))circle(r.x,r.y,r.r,r.color);
    ctx.strokeStyle='#a6976333';ctx.lineWidth=60;ctx.beginPath();for(const r of REGIONS.slice(1)){ctx.moveTo(WORLD.width/2,WORLD.height/2);ctx.lineTo(r.x,r.y);}ctx.stroke();
    for(let i=0;i<500;i++){
      const x=70+(i*719)%(WORLD.width-140),y=70+(i*1093)%(WORLD.height-140);
      if(Math.abs(x-p.x)>550||Math.abs(y-p.y)>380)continue;
      circle(x,y,22,'#193222');circle(x-3,y-7,16,'#416143');
    }
    for(const c of game.chests){ctx.fillStyle=c.opened?'#695338':'#dfbb69';ctx.fillRect(c.x-12,c.y-9,24,18);}
    for(const i of game.pickups)circle(i.x,i.y,6,i.kind==='xp'?'#bf9de4':i.kind==='heal'?'#a8da90':'#edc46b');
    for(const e of game.enemies){circle(e.x,e.y,e.r,e.kind==='boss'?'#ac83ba':e.slow>0?'#a4deeb':e.poison>0?'#9cce62':e.burn>0?'#e29251':'#849960');circle(e.x+4,e.y-4,3,'#ffebaf');}
    for(const pet of game.pets){circle(pet.x,pet.y,12,pet.kind==='fox'?'#dba15c':'#b3d8e4');circle(pet.x+7,pet.y-5,6,'#e7e2bb');}
    for(const b of game.bullets){ctx.save();ctx.translate(b.x,b.y);ctx.rotate(Math.atan2(b.vy,b.vx));ctx.strokeStyle=b.element==='fire'?'#ffa254':b.element==='ice'?'#91e7fa':b.element==='poison'?'#b1ee71':'#edd8a4';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(-14,0);ctx.lineTo(6,0);ctx.lineTo(1,-4);ctx.moveTo(6,0);ctx.lineTo(1,4);ctx.stroke();ctx.restore();}
    for(const b of game.hostile)circle(b.x,b.y,6,'#d6aff0');
    if(!(p.invincible>0&&Math.floor(time*16)%2)){
      circle(p.x,p.y,14,'#9bb56f');circle(p.x,p.y-4,8,'#e9cb94');
      ctx.strokeStyle='#c6a16b';ctx.lineWidth=3;ctx.beginPath();ctx.arc(p.x+9,p.y,14,-Math.PI/2,Math.PI/2);ctx.stroke();
    }
    for(const e of game.effects)if(e.type==='nova'){ctx.strokeStyle='#b9cfff';ctx.lineWidth=3;ctx.beginPath();ctx.arc(e.x,e.y,e.r*(1-e.life/e.maxLife),0,Math.PI*2);ctx.stroke();}
    ctx.strokeStyle='#b3c487';ctx.lineWidth=4;ctx.strokeRect(0,0,WORLD.width,WORLD.height);ctx.restore();
  }
  return {render,dispose(){}};
}
