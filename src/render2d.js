// Original illustrated view, kept as an option and for devices without WebGL2.
export function create2DRenderer(canvas, game) {
canvas.width = 1000; canvas.height = 660;
const ctx = canvas.getContext('2d');
const terrain=document.createElement('canvas');terrain.width=1000;terrain.height=660;const t=terrain.getContext('2d');
let seed=47382;function rand(){seed=(seed*16807)%2147483647;return(seed-1)/2147483646;}
function ellipse(c,x,y,rx,ry,color){c.fillStyle=color;c.beginPath();c.ellipse(x,y,rx,ry,0,0,Math.PI*2);c.fill();}
function poly(c,x,y,r,n,color,rotation=0){c.fillStyle=color;c.beginPath();for(let i=0;i<n;i++){const a=i/n*Math.PI*2+rotation;const px=x+Math.cos(a)*r,py=y+Math.sin(a)*r;i?c.lineTo(px,py):c.moveTo(px,py);}c.closePath();c.fill();}
function tree(x,y,size){ellipse(t,x,y+size*.33,size*.7,size*.26,'#07140d66');t.fillStyle='#443f2a';t.fillRect(x-size*.08,y-size*.2,size*.16,size*.6);for(let i=0;i<3;i++){t.fillStyle=['#132c21','#1c3928','#25432c'][i];t.beginPath();t.moveTo(x,y-size+i*size*.28);t.lineTo(x-size*(.64-i*.12),y+size*.13+i*size*.11);t.quadraticCurveTo(x,y+size*.36+i*size*.08,x+size*(.64-i*.12),y+size*.13+i*size*.11);t.closePath();t.fill();t.strokeStyle='#45603b40';t.beginPath();t.moveTo(x,y-size+i*size*.28);t.lineTo(x-size*(.55-i*.12),y+size*.1+i*size*.11);t.stroke();}}
function makeTerrain(){
 t.fillStyle='#1b3024';t.fillRect(0,0,1000,660);
 const g=t.createRadialGradient(500,320,30,500,320,640);g.addColorStop(0,'#40503a55');g.addColorStop(1,'#071b12cc');t.fillStyle=g;t.fillRect(0,0,1000,660);
 // Meandering old forest paths.
 t.strokeStyle='#807a4d0d';t.lineWidth=85;t.lineCap='round';t.beginPath();t.moveTo(160,680);t.bezierCurveTo(740,220,140,360,920,-30);t.stroke();
 for(let i=0;i<1500;i++){const x=rand()*1000,y=rand()*660;t.fillStyle=['#75845c15','#8f976912','#081b1833'][i%3];t.fillRect(x,y,1+rand()*3,1+rand()*2);}
 for(let i=0;i<110;i++){const x=rand()*1000,y=rand()*660;t.strokeStyle=i%3?'#72844b32':'#c7b66e24';t.lineWidth=1;t.beginPath();t.moveTo(x-3,y);t.lineTo(x-5,y-5);t.moveTo(x,y);t.lineTo(x+1,y-8);t.moveTo(x+3,y);t.lineTo(x+5,y-4);t.stroke();}
 for(let i=0;i<28;i++){const x=rand()*1000,y=rand()*660;if(Math.hypot(x-500,y-330)<80)continue;ellipse(t,x,y+5,12,5,'#07171066');poly(t,x,y,9+rand()*8,5,'#38483b',rand());t.fillStyle='#5e6b4b55';t.fillRect(x-4,y-5,6,2);}
 for(let i=0;i<24;i++){const x=rand()*1000,y=rand()*660;t.fillStyle='#9e9167';t.fillRect(x,y-3,2,5);ellipse(t,x+1,y-4,4,2,i%2?'#b58b5b':'#7c9e92');}
 // Weathered ritual circle.
 t.strokeStyle='#aeb57c16';t.lineWidth=2;t.beginPath();t.arc(500,330,88,0,Math.PI*2);t.stroke();t.setLineDash([3,15]);t.beginPath();t.arc(500,330,100,0,Math.PI*2);t.stroke();t.setLineDash([]);
 for(let i=0;i<10;i++){const a=i*Math.PI/5;poly(t,500+Math.cos(a)*90,330+Math.sin(a)*90,5,4,'#a7b57f35',a);}
 for(let i=0;i<22;i++){const x=i*50-20;tree(x,24+rand()*24,55+rand()*23);tree(x,660+rand()*25,50+rand()*28);}
 for(let i=0;i<12;i++){tree(rand()*25-5,i*61+60,45+rand()*24);tree(985+rand()*25,i*61+35,55+rand()*24);}
 for(const [x,y] of [[130,130],[858,525]]){t.fillStyle='#645d3a';t.fillRect(x-2,y-14,4,22);const glow=t.createRadialGradient(x,y-17,0,x,y-17,70);glow.addColorStop(0,'#e6ba5e2a');glow.addColorStop(1,'#e6ba5e00');t.fillStyle=glow;t.fillRect(x-70,y-87,140,140);t.fillStyle='#d6bc72';t.fillRect(x-5,y-23,10,11);t.strokeStyle='#4e5537';t.strokeRect(x-6,y-24,12,13);}
}
makeTerrain();
function drawPlayer(p,time){
 ctx.save();ctx.translate(p.x,p.y);if(p.invincible>0 && Math.floor(time*18)%2)ctx.globalAlpha=.45;
 ellipse(ctx,0,13,14,6,'#07120c88');
 const glow=ctx.createRadialGradient(0,0,0,0,0,47);glow.addColorStop(0,'#e1d39122');glow.addColorStop(1,'#cdd59b00');ctx.fillStyle=glow;ctx.fillRect(-47,-47,94,94);
 // Cloak, boots, hood, and lantern staff.
 ctx.fillStyle='#655c3c';ctx.fillRect(-6,8,5,9);ctx.fillRect(3,8,5,9);
 ctx.fillStyle='#9aab72';ctx.beginPath();ctx.moveTo(-6,-5);ctx.lineTo(-13,12);ctx.quadraticCurveTo(0,17,12,12);ctx.lineTo(6,-5);ctx.fill();
 ctx.fillStyle='#647a50';ctx.beginPath();ctx.moveTo(0,-9);ctx.lineTo(0,14);ctx.lineTo(-13,12);ctx.closePath();ctx.fill();
 ellipse(ctx,0,-8,9,10,'#b9c58b');ellipse(ctx,1,-6,6,5,'#333c2b');ctx.fillStyle='#f1d591';ctx.fillRect(-2,-7,2,2);ctx.fillRect(3,-7,2,2);
 ctx.strokeStyle='#a38d56';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(14,14);ctx.lineTo(19,-16);ctx.stroke();poly(ctx,19,-16,5,4,'#f2d291',Math.PI/4);ellipse(ctx,19,-16,2,3,'#fff2c2');ctx.restore();
}
function drawEnemy(e,time){
 ctx.save();ctx.translate(e.x,e.y);const bob=Math.sin(time*5+e.x)*2;ellipse(ctx,0,e.r*.7,e.r*.9,e.r*.32,'#06120c77');ctx.translate(0,bob);
 if(e.kind==='boss'){
 const colors=['#a18a52','#a2cbd0','#ba8abb'];const color=colors[e.tier-1];
 const aura=ctx.createRadialGradient(0,0,5,0,0,e.r*2);aura.addColorStop(0,color+'33');aura.addColorStop(1,color+'00');ctx.fillStyle=aura;ctx.fillRect(-e.r*2,-e.r*2,e.r*4,e.r*4);
 poly(ctx,0,0,e.r,7,['#4d5838','#384f5b','#493653'][e.tier-1],time*.1);poly(ctx,0,-3,e.r*.76,6,color,-Math.PI/2);poly(ctx,0,0,e.r*.55,5,['#39482c','#263c46','#302638'][e.tier-1]);
 for(let i=0;i<3;i++){const x=(i-1)*e.r*.44;poly(ctx,x,-e.r*.8,9,3,color,-Math.PI/2);}
 ctx.fillStyle='#f0dc9c';ctx.fillRect(-10,-5,6,4);ctx.fillRect(4,-5,6,4);
 if(e.charge>.7){ctx.strokeStyle='#dcaa79';ctx.setLineDash([6,7]);ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(e.cx*230,e.cy*230);ctx.stroke();ctx.setLineDash([]);}
 }else if(e.kind==='wisp'){
 ellipse(ctx,0,0,10,13,e.slow>0?'#8ec8d5':'#89afa5');ellipse(ctx,0,1,6,7,'#354f48');ctx.fillStyle='#dce8bc';ctx.fillRect(-4,-3,2,3);ctx.fillRect(3,-3,2,3);
 }else{
 const color=e.slow>0?'#8ab4c2':e.kind==='brute'?'#a8795a':'#7f945c';
 for(const side of [-1,1]){ctx.strokeStyle=color;ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(side*e.r*.5,2);ctx.lineTo(side*(e.r+5),Math.sin(time*8)*4+7);ctx.stroke();}
 poly(ctx,0,0,e.r,6,color,time*.12);poly(ctx,0,0,e.r*.7,5,e.kind==='brute'?'#594334':'#3c5036');ctx.fillStyle='#efd290';ctx.fillRect(-6,-4,3,3);ctx.fillRect(3,-4,3,3);
 }
 if(e.hp<e.maxHp && e.kind==='boss'){/* boss health is in the HUD */}
 ctx.restore();
}
function render(time){
 ctx.clearRect(0,0,1000,660);ctx.drawImage(terrain,0,0);
 // Fireflies animate independently of the simulation.
 for(let i=0;i<24;i++){const x=(i*173+Math.sin(time*.25+i)*22)%980+10,y=(i*89+Math.cos(time*.3+i)*18)%640+10;ctx.globalAlpha=.15+(.5+Math.sin(time+i)*.5)*.35;ellipse(ctx,x,y,1.4,1.4,'#d9e3a0');}ctx.globalAlpha=1;
 for(const i of game.pickups){ctx.save();ctx.translate(i.x,i.y+Math.sin(time*3+i.x)*2);ctx.shadowColor=i.kind==='coin'?'#e2bd73':'#c8a7e8';ctx.shadowBlur=10;poly(ctx,0,0,i.kind==='heal'?6:5,i.kind==='coin'?6:4,i.kind==='coin'?'#e2bd73':i.kind==='heal'?'#a4cd8c':'#bca1d7',Math.PI/4);ctx.restore();}
 for(const e of [...game.enemies].sort((a,b)=>a.y-b.y))drawEnemy(e,time);
 for(const b of game.bullets){ctx.save();ctx.shadowColor='#f2c375';ctx.shadowBlur=12;ctx.strokeStyle='#d4ad6c66';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(b.x-b.vx*.025,b.y-b.vy*.025);ctx.lineTo(b.x,b.y);ctx.stroke();ellipse(ctx,b.x,b.y,4,4,'#ffe3a5');ctx.restore();}
 for(const b of game.hostile){ctx.save();ctx.shadowColor='#c89edc';ctx.shadowBlur=12;poly(ctx,b.x,b.y,6,4,'#c7b2df',time);ctx.restore();}
 drawPlayer(game.player,time);
 for(const e of game.effects){const a=e.life/e.maxLife;ctx.save();ctx.globalAlpha=a;if(e.type==='nova'||e.type==='warning'){ctx.strokeStyle=e.type==='nova'?'#c7b4e9':'#e5b17a';ctx.lineWidth=3;ctx.beginPath();ctx.arc(e.x,e.y,e.r*(1-a)+10,0,Math.PI*2);ctx.stroke();}else if(e.type==='trail')ellipse(ctx,e.x,e.y,10,12,'#adcb9566');else{for(let j=0;j<6;j++){const angle=j*Math.PI/3;ellipse(ctx,e.x+Math.cos(angle)*e.r*(1-a),e.y+Math.sin(angle)*e.r*(1-a),2,2,'#c7cf90');}}ctx.restore();}
 const vignette=ctx.createRadialGradient(500,330,220,500,330,610);vignette.addColorStop(0,'#0000');vignette.addColorStop(1,'#03100966');ctx.fillStyle=vignette;ctx.fillRect(0,0,1000,660);
}

return { render, dispose() {} };
}
