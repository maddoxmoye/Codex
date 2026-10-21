// Camera volumes use render-space meters. Tree trunks and crowns are tested
// separately so a high canopy does not behave like a wall down to the ground.
function ellipsoidEntry(a,b,c,rx,ry,rz){
 const x=(a.x-c.x)/rx,y=(a.y-c.y)/ry,z=(a.z-c.z)/rz,dx=(b.x-a.x)/rx,dy=(b.y-a.y)/ry,dz=(b.z-a.z)/rz;
 const A=dx*dx+dy*dy+dz*dz,B=2*(x*dx+y*dy+z*dz),C=x*x+y*y+z*z-1,D=B*B-4*A*C;if(!A||D<0||C<=0)return 1;
 const t=(-B-Math.sqrt(D))/(2*A);return t>0&&t<1?t:1;
}
function cylinderEntry(a,b,o,r,height){
 const dx=b.x-a.x,dz=b.z-a.z,x=a.x-o.x,z=a.z-o.z,A=dx*dx+dz*dz,B=2*(x*dx+z*dz),C=x*x+z*z-r*r,D=B*B-4*A*C;
 if(!A||D<0||C<=0)return 1;const t=(-B-Math.sqrt(D))/(2*A),y=a.y+(b.y-a.y)*t;return t>0&&t<1&&y<height+.15?t:1;
}
export function cameraClearance(focus,position,obstacles){
 let fraction=1;for(const o of obstacles){
  if(o.type==='tree'){
   const s=o.scale||1;fraction=Math.min(fraction,cylinderEntry(focus,position,o,.23*s+.12,4.2*s));
   fraction=Math.min(fraction,ellipsoidEntry(focus,position,{x:o.x,y:4.1*s,z:o.z},1.9*s+.12,1.1*s+.12,1.9*s+.12));
  }else fraction=Math.min(fraction,cylinderEntry(focus,position,o,o.r+.12,o.height));
 }return fraction;
}
export function resolveFollowCamera(focus,yaw,lift,distance,obstacles,preferredOffset=0){
 let best=null;const minDistance=Math.min(4.4,distance);
 for(const elevation of [...new Set([lift,Math.max(lift,5.5),Math.max(lift,8)])])for(const offset of [...new Set([0,preferredOffset,.4,-.4,.8,-.8,1.2,-1.2,1.6,-1.6,2.2,-2.2,Math.PI])]){
  const angle=yaw+offset,position={x:focus.x+Math.sin(angle)*distance,y:focus.y+elevation,z:focus.z+Math.cos(angle)*distance},fraction=cameraClearance(focus,position,obstacles),safe=fraction>=1?1:Math.max(.05,fraction-.025),candidate={x:focus.x+(position.x-focus.x)*safe,y:focus.y+elevation*safe,z:focus.z+(position.z-focus.z)*safe,yaw:angle,offset,clearance:distance*safe};
  if(!best||candidate.clearance>best.clearance)best=candidate;
  if(candidate.clearance>=minDistance)return candidate;
 }return best;
}
