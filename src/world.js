export const WORLD = { width: 4800, height: 4000 };
export const REGIONS = [
  { name: 'Whispering Woods', x: 2400, y: 2000, r: 1100, color: '#426142' },
  { name: 'Frostveil Ruins', x: 1000, y: 1000, r: 760, color: '#8aafb8' },
  { name: 'Ember Highlands', x: 3700, y: 1000, r: 780, color: '#ad704a' },
  { name: 'Venom Marsh', x: 3400, y: 3200, r: 800, color: '#6f8240' }
];
export const regionAt = p => REGIONS.slice(1).find(r => Math.hypot(p.x-r.x,p.y-r.y)<r.r) || REGIONS[0];
export const CHESTS = []; // Chests now drop dynamically from enemies; they are not solid scenery.
const center={x:2400,y:2000};
function segmentDistance(p,a,b){const dx=b.x-a.x,dy=b.y-a.y,t=Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/(dx*dx+dy*dy)));return Math.hypot(p.x-a.x-dx*t,p.y-a.y-dy*t);}
let seed=47382;
const random=()=>{seed=seed*16807%2147483647;return(seed-1)/2147483646;};
export const EDGE_BAND=600;
export const OPEN_INTERIOR={left:EDGE_BAND,right:WORLD.width-EDGE_BAND,top:EDGE_BAND,bottom:WORLD.height-EDGE_BAND};
export const SCENERY=[];
const fitsEdge=(p,r)=>Math.min(p.x,p.y,WORLD.width-p.x,WORLD.height-p.y)+r<=EDGE_BAND;
function inClearing(p){return Math.hypot(p.x-2400,p.y-2000)<330 || REGIONS.slice(1).some(r=>Math.hypot(p.x-r.x,p.y-r.y)<230) || REGIONS.slice(1).some(r=>segmentDistance(p,center,r)<125) || CHESTS.some(c=>Math.hypot(p.x-c.x,p.y-c.y)<105);}
// The interior stays open for combat; groves and rocks live entirely in the outer band.
for(let i=0;i<340;i++){
  const p={x:90+random()*4620,y:90+random()*3820},scale=.65+random()*.55;
  if(!fitsEdge(p,72*scale)||inClearing(p)||SCENERY.some(o=>Math.hypot(p.x-o.x,p.y-o.y)<175))continue;
  SCENERY.push({...p,type:'tree',scale,r:60*scale,cameraR:72*scale,height:260*scale});
}
for(let i=0;i<100;i++){
  const p={x:70+random()*4660,y:70+random()*3860},scale=.65+random()*.6;
  if(!fitsEdge(p,30*scale)||inClearing(p)||SCENERY.some(o=>Math.hypot(p.x-o.x,p.y-o.y)<95))continue;
  SCENERY.push({...p,type:'rock',scale,r:30*scale,cameraR:30*scale,height:52*scale});
}
export const STRUCTURES=[
  {type:'tent',x:2260,y:1870,r:90,cameraR:95,height:120},
  {type:'campfire',x:2400,y:1890,r:34,cameraR:30,height:65},
  {type:'pillar',x:900,y:1000,r:27,cameraR:28,height:220},
  {type:'pillar',x:1100,y:1000,r:27,cameraR:28,height:220},
  {type:'brazier',x:3700,y:1000,r:140,cameraR:140,height:230},
  ...Array.from({length:4},(_,i)=>({type:'venom-stone',x:3400+Math.cos(i*Math.PI/2)*100,y:3200+Math.sin(i*Math.PI/2)*100,r:22,cameraR:22,height:60}))
];
export const SOLIDS=[...SCENERY,...STRUCTURES,...CHESTS];
const cellSize=200,cells=new Map();
for(const o of SOLIDS)for(let x=Math.floor((o.x-o.r)/cellSize);x<=Math.floor((o.x+o.r)/cellSize);x++)for(let y=Math.floor((o.y-o.r)/cellSize);y<=Math.floor((o.y+o.r)/cellSize);y++){
  const key=x+','+y;if(!cells.has(key))cells.set(key,[]);cells.get(key).push(o);
}
function near(p,r,obstacles){
  if(obstacles!==SOLIDS)return obstacles;
  const result=new Set();
  for(let x=Math.floor((p.x-r)/cellSize);x<=Math.floor((p.x+r)/cellSize);x++)for(let y=Math.floor((p.y-r)/cellSize);y<=Math.floor((p.y+r)/cellSize);y++)for(const o of cells.get(x+','+y)||[])result.add(o);
  return result;
}
export function blocked(p,r=13,obstacles=SOLIDS,minHeight=0){
  for(const o of near(p,r,obstacles))if((o.height||100)>minHeight&&Math.hypot(p.x-o.x,p.y-o.y)<r+o.r-.001)return true;
  return false;
}
export function moveBody(body,dx,dy,obstacles=SOLIDS){
  const steps=Math.max(1,Math.ceil(Math.hypot(dx,dy)/7)),r=body.r||13;
  for(let i=0;i<steps;i++){
    const x=Math.max(22,Math.min(WORLD.width-22,body.x+dx/steps));if(!blocked({x,y:body.y},r,obstacles))body.x=x;
    const y=Math.max(22,Math.min(WORLD.height-22,body.y+dy/steps));if(!blocked({x:body.x,y},r,obstacles))body.y=y;
  }
}
export function seekBody(body,target,speed,dt,obstacles=SOLIDS){
  const angle=Math.atan2(target.y-body.y,target.x-body.x),before=Math.hypot(target.x-body.x,target.y-body.y);
  if(before<2)return;
  let best=null,score=-Infinity;
  for(const offset of [0,.65,-.65,1.25,-1.25,1.9,-1.9]){
    const next={x:body.x,y:body.y,r:body.r};moveBody(next,Math.cos(angle+offset)*Math.min(speed*dt,before),Math.sin(angle+offset)*Math.min(speed*dt,before),obstacles);
    const moved=Math.hypot(next.x-body.x,next.y-body.y);if(moved<.01)continue;
    const value=before-Math.hypot(target.x-next.x,target.y-next.y)+moved*.05-Math.abs(offset)*.015;
    if(value>score){best=next;score=value;}
    if(offset===0 && moved>speed*dt*.95)break;
  }
  if(best){body.dx=best.x-body.x;body.dy=best.y-body.y;body.x=best.x;body.y=best.y;}
}
export function findFree(p,r=13,obstacles=SOLIDS){
  const initial={x:Math.max(22,Math.min(WORLD.width-22,p.x)),y:Math.max(22,Math.min(WORLD.height-22,p.y))};
  if(!blocked(initial,r,obstacles))return initial;
  for(let radius=15;radius<=360;radius+=15)for(let i=0;i<16;i++){
    const q={x:Math.max(22,Math.min(WORLD.width-22,p.x+Math.cos(i*Math.PI/8)*radius)),y:Math.max(22,Math.min(WORLD.height-22,p.y+Math.sin(i*Math.PI/8)*radius))};
    if(!blocked(q,r,obstacles))return q;
  }
  return initial;
}
export function segmentHit(a,b,body,padding=0){
  const dx=b.x-a.x,dy=b.y-a.y,ox=a.x-body.x,oy=a.y-body.y,r=body.r+padding,A=dx*dx+dy*dy,C=ox*ox+oy*oy-r*r;
  if(C<=0)return 0;if(!A)return Infinity;const B=2*(ox*dx+oy*dy),D=B*B-4*A*C;if(D<0)return Infinity;
  const t=(-B-Math.sqrt(D))/(2*A);return t>=0&&t<=1?t:Infinity;
}
export function firstObstacleHit(a,b,obstacles=SOLIDS){
  const length=Math.hypot(b.x-a.x,b.y-a.y);let first=Infinity;
  for(const o of near({x:(a.x+b.x)/2,y:(a.y+b.y)/2},length/2+3,obstacles))if((o.height||100)>50)first=Math.min(first,segmentHit(a,b,o,3));
  return first;
}
export function projectileBlocked(a,b,obstacles=SOLIDS){return firstObstacleHit(a,b,obstacles)<=1;}
