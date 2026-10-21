import {Color3,Mesh,MeshBuilder,ParticleSystem,StandardMaterial,Texture,Vector3,VertexBuffer,VertexData} from '@babylonjs/core';
import {SCENERY,STRUCTURES,WORLD,REGIONS,regionAt} from '../world.js';
import {C,mergeStaticMeshes} from './art.js';
export const groundHeight=(x,z)=>.1*Math.sin(x*.23)*Math.cos(z*.27)+.045*Math.sin(z*.8+x*.24);
export function createTerrain(scene,groundMat){
 const ground=MeshBuilder.CreateGround('rolling painted earth',{width:64,height:56,subdivisions:140,updatable:true},scene),positions=ground.getVerticesData(VertexBuffer.PositionKind);
 for(let i=0;i<positions.length;i+=3)positions[i+1]=groundHeight(positions[i],positions[i+2]);ground.updateVerticesData(VertexBuffer.PositionKind,positions);ground.createNormals(true);
 // Babylon's recomputation reverses ground normals in right-handed scenes.
 // Keep the terrain facing the sun, regardless of the scene convention.
 const normals=ground.getVerticesData(VertexBuffer.NormalKind);for(let i=0;i<normals.length;i+=3)if(normals[i+1]<0){normals[i]*=-1;normals[i+1]*=-1;normals[i+2]*=-1;}ground.updateVerticesData(VertexBuffer.NormalKind,normals);
 ground.material=groundMat;ground.receiveShadows=true;ground.isPickable=false;return ground;
}
export function createEmberwild(art,shadows){
 const {scene,material,part,node,tube,ring,texture,palette:p}=art;let seed=42107;const rand=()=>{seed=seed*16807%2147483647;return(seed-1)/2147483646;};
 const terrainTexture=texture('painted-emberwild',2048,(ctx,s)=>{
  ctx.fillStyle='#687e66';ctx.fillRect(0,0,s,s);
  const map=(x,z)=>[(x+32)/64*s,(28-z)/56*s];
  for(let i=0;i<13000;i++){const x=rand()*s,y=rand()*s,r=10+rand()*50;ctx.fillStyle=['#83937719','#b2a97c18','#324e5020','#d6c6a015'][i%4];ctx.beginPath();ctx.ellipse(x,y,r,r*.5,rand()*6,0,Math.PI*2);ctx.fill();}
  const biomes=[[-14,-10,12,'#9daeb1'],[13,-10,12,'#9b775c'],[10,12,11,'#6d647c']];
  for(const [x,z,r,color] of biomes){const [a,b]=map(x,z),gr=ctx.createRadialGradient(a,b,0,a,b,r/64*s);gr.addColorStop(0,color);gr.addColorStop(1,color+'00');ctx.fillStyle=gr;ctx.fillRect(0,0,s,s);}
  ctx.lineCap='round';for(const region of REGIONS.slice(1)){const [x,y]=map((region.x-2400)/100,(region.y-2000)/100),[cx,cy]=map(0,0);for(const [w,col] of [[44,'#b8ae8f22'],[24,'#baa78b77'],[14,'#c5b09288']]){ctx.strokeStyle=col;ctx.lineWidth=w;ctx.beginPath();ctx.moveTo(cx,cy);ctx.bezierCurveTo(cx+(x-cx)*.4,cy+(y-cy)*.25,x-(x-cx)*.22,y,x,y);ctx.stroke();}}
  const [x,y]=map(0,-.5);const gr=ctx.createRadialGradient(x,y,0,x,y,90);gr.addColorStop(0,'#b5a487cc');gr.addColorStop(1,'#b5a48700');ctx.fillStyle=gr;ctx.fillRect(0,0,s,s);
  for(let i=0;i<45000;i++){ctx.fillStyle=i%2?'#e3dcc119':'#102f3822';ctx.fillRect(rand()*s,rand()*s,1+rand()*3,1+rand()*2);}
 });
 const groundMat=material('terrain','#ffffff',{texture:terrainTexture,rough:1});
 const ground=createTerrain(scene,groundMat);
 const staticRoot=node('landscape'),animated=[];
 const barkTexture=texture('handpainted-bark',256,(ctx,s)=>{ctx.fillStyle='#b49975';ctx.fillRect(0,0,s,s);for(let i=0;i<400;i++){ctx.strokeStyle=i%2?'#5f493a66':'#efe0b244';ctx.lineWidth=1+rand()*3;const x=rand()*s,y=rand()*s;ctx.beginPath();ctx.moveTo(x,y);ctx.bezierCurveTo(x+12,y+30,x-8,y+60,x+3,y+100);ctx.stroke();}});
 const bark=material('striated-trunks','#68574e',{texture:barkTexture}),leaves=['#38675f','#488174','#739d80','#b18b55','#8eaa83'].map((c,i)=>material('leaves-'+i,c));
 const biomeLeaves=[leaves,['#678e98','#91afb0','#c3d2c6','#9fbfc1','#dae1cd'].map((c,i)=>material('frost leaves '+i,c)),['#8f5e43','#af7448','#c69a60','#9e6544','#d4ae73'].map((c,i)=>material('ember leaves '+i,c)),['#665c7e','#7f7794','#a298b1','#58787a','#9c8d9f'].map((c,i)=>material('marsh leaves '+i,c))];
 for(const o of SCENERY){
  const x=(o.x-2400)/100,z=(o.y-2000)/100,y=groundHeight(x,z),root=node(o.type,staticRoot,x,y,z);root.scaling.setAll(o.scale);
  if(o.type==='tree'){const foliage=biomeLeaves[REGIONS.indexOf(regionAt(o))];
   part('cylinder',root,bark,0,1.4,0,.18,2.8,.18).rotation.z=.06;
   for(let i=0;i<5;i++){const a=i*2.4,dx=Math.cos(a),dz=Math.sin(a);tube(root,[[0,1.3,0],[dx*.45,2.45+i*.12,dz*.45],[dx*1.1,3.2+i*.13,dz*1.1]],.075,bark);const cluster=part('ico',root,foliage[(Math.floor(o.x)+i)%foliage.length],dx*.9,3.3+i*.16,dz*.9,1.03,.63,1.05);cluster.rotation.y=a;}
   part('ico',root,foliage[2],0,4.05,0,1,.65,.95);
   for(let i=0;i<5;i++){const a=i*1.26;const rootWood=part('cone',root,bark,Math.cos(a)*.24,.16,Math.sin(a)*.24,.11,.6,.13);rootWood.rotation.z=Math.cos(a)*.7;rootWood.rotation.x=Math.sin(a)*.7;}
  }else{const rock=part('ico',root,p.darkStone,0,.23,0,.37,.35,.32);rock.rotation.set(rand(),rand()*5,rand());part('ico',root,p.moss,0,.43,0,.31,.09,.27);}
 }
 // Stone markers are the actual solid landmark footprints used by the game.
 for(const o of STRUCTURES){const x=(o.x-2400)/100,z=(o.y-2000)/100,root=node(o.type,staticRoot,x,groundHeight(x,z),z);
  if(o.type==='tent'){
   const roof=MeshBuilder.CreateCylinder('canvas pavilion',{height:2.05,diameterBottom:1.95,diameterTop:0,tessellation:4},scene);roof.rotation.y=Math.PI/4;roof.rotation.z=Math.PI/2;roof.position.y=.72;roof.scaling.set(1,1.05,.82);roof.parent=root;roof.material=p.cloth;
   for(const side of [-1,1]){tube(root,[[side*.94,0,-.64],[side*.94,1.28,0],[side*.94,0,.64]],.035,p.wood);tube(root,[[side*.95,1.25,0],[side*1.22,.02,.95]],.012,p.bone);}tube(root,[[-1.05,1.25,0],[1.05,1.25,0]],.04,p.wood);part('box',root,p.leather,.65,.15,-.8,.38,.3,.3);
  }else if(o.type==='campfire'){
   for(let i=0;i<9;i++){const a=i/9*Math.PI*2;part('ico',root,p.darkStone,Math.cos(a)*.3,.08,Math.sin(a)*.3,.12,.09,.12);}for(let i=0;i<3;i++)part('cylinder',root,p.wood,0,.09,0,.045,.6,.045).rotation.set(Math.PI/2,i*2.1,0);
   const fire=node('lantern flame',root);for(let i=0;i<4;i++){const f=part('ico',fire,i%2?p.amber:p.fire,Math.sin(i)*.06,.27+i*.035,Math.cos(i)*.05,.1,.25,.1);f.rotation.z=i*.25;}animated.push({root:fire,type:'flame'});
  }else if(o.type==='pillar'){
   for(const [y,w,h] of [[.12,.64,.24],[1.12,.39,1.8],[2.12,.65,.22]]){const stone=part('box',root,p.stone,0,y,0,w,h,w);stone.rotation.y=.1;}
   for(let i=0;i<3;i++){const rune=part('box',root,p.magic,0,.8+i*.28,.21,.11,.035,.015);rune.rotation.z=i%2?.5:-.5;}
   part('ico',root,p.moss,0,2.25,0,.4,.1,.34);
  }else if(o.type==='brazier'){
   for(let i=0;i<3;i++)part('cylinder',root,p.darkStone,0,.14+i*.24,0,1.4-i*.22,.22,1.4-i*.22);
   for(let i=0;i<5;i++){const a=i*1.26;const tooth=part('cone',root,p.gold,Math.cos(a)*.65,.9,Math.sin(a)*.65,.12,.6,.12);tooth.rotation.z=-Math.cos(a)*.5;tooth.rotation.x=Math.sin(a)*.5;}
   const fire=node('ember altar',root);for(let i=0;i<3;i++)part('ico',fire,i%2?p.amber:p.fire,Math.sin(i)*.25,1.18+i*.1,Math.cos(i)*.25,.25,.65,.25);animated.push({root:fire,type:'flame'});
  }else{part('ico',root,p.darkStone,0,.28,0,.22,.42,.22);ring(root,p.poison,.16,.62,.03);}
 }
 // A traversable arch crowns Frostveil's two solid pillars.
 const arch=node('Frostveil arch',staticRoot,-14,groundHeight(-14,-10),-10);part('box',arch,p.stone,0,2.23,0,2.65,.27,.5);part('box',arch,p.darkStone,0,2.43,0,.5,.18,.6);part('ico',arch,p.ice,0,1.7,0,.095,.21,.095);
 for(const side of [-1,1]){const banner=art.node('weathered banner',arch,side*.8,1.56,.28);const paths=Array.from({length:5},(_,row)=>Array.from({length:5},(_,i)=>new Vector3((i/4-.5)*.34,.35-row*.16,-Math.sin(i/4*Math.PI)*.05)));const fabric=MeshBuilder.CreateRibbon('silk pennant',{pathArray:paths,sideOrientation:Mesh.DOUBLESIDE},scene);fabric.parent=banner;fabric.material=material('Frostveil silk','#486e80');animated.push({root:banner,type:'banner'});part('box',arch,p.gold,side*.8,1.9,.28,.42,.025,.035);}
 // Rune inlays and broken flagstones mark sectors, without blocking the open arena.
 for(const [i,r] of REGIONS.entries()){const x=(r.x-2400)/100,z=(r.y-2000)/100,root=node('waystone circle',staticRoot,x,groundHeight(x,z),z),m=[p.amber,p.ice,p.fire,p.poison][i];ring(root,m,1.45,.018,.013);for(let j=0;j<16;j++){const a=j/16*Math.PI*2,stone=part('box',root,j%4===0?m:p.stone,Math.cos(a)*1.5,.018,Math.sin(a)*1.5,.14,.03,.23);stone.rotation.y=-a;}}
 // Peripheral ridges and tall silhouettes create depth beyond the playable boundary.
 for(let i=0;i<80;i++){const a=i/80*Math.PI*2,x=Math.cos(a)*(30+rand()*8),z=Math.sin(a)*(26+rand()*7);const rock=part('ico',staticRoot,material('distant-cliffs','#6a8280'),x,-.2,z,2+rand()*3,2+rand()*5,2+rand()*3);rock.rotation.y=rand()*6;}
 for(let i=0;i<700;i++){const x=(rand()-.5)*47,z=(rand()-.5)*39;if(Math.hypot(x,z)<1.5)continue;const stone=part('ico',staticRoot,i%3?p.darkStone:p.stone,x,groundHeight(x,z)+.015,z,.025+rand()*.04,.018+rand()*.035,.03+rand()*.05);stone.rotation.y=rand()*6;}
 // Individually painted blades and wildflowers, merged into material batches.
 const grassMats=['#6e9378','#86a182','#a7ab85','#466e69'].map((c,i)=>material('meadow-'+i,c));
 const grassData=grassMats.map(()=>({positions:[],normals:[],indices:[],colors:[]}));
 for(let i=0;i<9000;i++){const x=(rand()-.5)*48,z=(rand()-.5)*40;if(Math.hypot(x,z)<1.7||rand()<.1)continue;const data=grassData[i%4],h=.12+rand()*.24,a=rand()*6,y=groundHeight(x,z);for(const turn of [0,1.3,2.5]){const dx=Math.cos(a+turn),dz=Math.sin(a+turn),w=.02+rand()*.018,index=data.positions.length/3;data.positions.push(x-dx*w,y,z-dz*w,x+dx*w,y,z+dz*w,x+dx*.05,y+h,z+dz*.05);for(let j=0;j<3;j++){data.normals.push(0,.9,.3);data.colors.push(j===2?1:.72,j===2?1:.8,j===2?.82:.68,1);}data.indices.push(index,index+1,index+2);}}
 grassData.forEach((data,i)=>{const mesh=new Mesh('tapered meadow '+i,scene),vertices=new VertexData();Object.assign(vertices,data);vertices.applyToMesh(mesh);mesh.material=grassMats[i];mesh.receiveShadows=true;mesh.isPickable=false;});
 const flowerMats=['#eee3c4','#c09165','#adbede'].map((c,i)=>material('wildflower-'+i,c));for(let i=0;i<450;i++){const x=(rand()-.5)*47,z=(rand()-.5)*39;if(Math.hypot(x,z)<2)continue;const y=groundHeight(x,z);part('cylinder',staticRoot,grassMats[3],x,y+.08,z,.009,.16,.009);for(let j=0;j<4;j++){const a=j*Math.PI/2;part('petal',staticRoot,flowerMats[i%3],x+Math.cos(a)*.025,y+.18,z+Math.sin(a)*.025,.032,.012,.032);}}
 // Bake opaque scenery by material. This is visual geometry; gameplay colliders
 // still come from SOLIDS, preserving every tree/landmark's physical footprint.
 const groups=new Map();for(const mesh of staticRoot.getChildMeshes()){if(mesh.isDisposed()||animated.some(a=>mesh.isDescendantOf(a.root)))continue;mesh.computeWorldMatrix(true);if(!groups.has(mesh.material))groups.set(mesh.material,[]);groups.get(mesh.material).push(mesh);}
 for(const [mat,list] of groups){const merged=mergeStaticMeshes(list);if(merged){merged.name='landscape / '+mat.name;merged.material=mat;merged.receiveShadows=true;merged.isPickable=false;shadows.addShadowCaster(merged);}}
 const sparkle=texture('mote',64,(ctx,s)=>{const g=ctx.createRadialGradient(s/2,s/2,0,s/2,s/2,s/2);g.addColorStop(0,'#fff9eaff');g.addColorStop(.2,'#ffe9b5aa');g.addColorStop(1,'#ffe9b500');ctx.fillStyle=g;ctx.fillRect(0,0,s,s);});sparkle.hasAlpha=true;
 const motes=new ParticleSystem('floating pollen',220,scene);motes.particleTexture=sparkle;motes.emitter=new Vector3(0,0,0);motes.minEmitBox=new Vector3(-8,.2,-7);motes.maxEmitBox=new Vector3(8,3,7);motes.color1.set(1,.8,.5,.45);motes.color2.set(.5,.9,.9,.2);motes.colorDead.set(.5,.5,.5,0);motes.minSize=.025;motes.maxSize=.065;motes.minLifeTime=4;motes.maxLifeTime=7;motes.emitRate=22;motes.direction1=new Vector3(-.1,.03,-.03);motes.direction2=new Vector3(.04,.12,.02);motes.minEmitPower=.15;motes.maxEmitPower=.3;motes.updateSpeed=.015;motes.start();
 return {height:groundHeight,update(time,x,z){for(const {root,type} of animated){if(type==='flame'){root.scaling.y=.92+Math.sin(time*7)*.12;root.rotation.y=time*.3;}else root.rotation.x=Math.sin(time*2.5)*.09;}motes.emitter.set(x,0,z);},dispose(){motes.dispose();}};
}
