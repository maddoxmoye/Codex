import * as T from 'three';
import {WORLD,REGIONS,regionAt,SCENERY,SOLIDS} from './world.js';

// Procedural painted terrain and foliage for the entire existing collision map.
export function createStyledWorld({scene,geometry:geo,mat:material,mesh}){
 const textures=[],instances=[],wind={value:0};let seed=3792;const random=()=>{seed=seed*16807%2147483647;return(seed-1)/2147483646;};
 const wx=x=>(x-WORLD.width/2)/100,wz=y=>(y-WORLD.height/2)/100;
 const group=(parent,x=0,y=0,z=0)=>{const g=new T.Group();g.position.set(x,y,z);parent.add(g);return g;};
 const sphere=geo(new T.SphereGeometry(1,12,9)),rockGeo=geo(new T.IcosahedronGeometry(1,1)),box=geo(new T.BoxGeometry(1,1,1)),cylinder=geo(new T.CylinderGeometry(1,1,1,10)),cone=geo(new T.ConeGeometry(1,1,9)),crystal=geo(new T.OctahedronGeometry(1));
 const p={trunk:material('#705343'),bark:material('#443c32'),stone:material('#8b9688',{flatShading:true}),moss:material('#849558'),bone:material('#d9ceaa'),gold:material('#d1ae65',{metalness:.5,roughness:.38}),leaf:['#345f45','#547c4a','#7a984f','#9bad67'].map(c=>material(c)),frost:['#698d9b','#a7c7ce','#ccdedc','#e0e6d7'].map(c=>material(c)),ember:['#715344','#98664c','#ba8359','#d5a26e'].map(c=>material(c)),venom:['#4b485a','#685775','#92768e','#a69aaa'].map(c=>material(c))};
 const makeTexture=(width,height,draw)=>{const c=document.createElement('canvas');c.width=width;c.height=height;draw(c.getContext('2d'),width,height);const t=new T.CanvasTexture(c);t.colorSpace=T.SRGBColorSpace;textures.push(t);return t;};
 const map=makeTexture(2048,1707,(ctx,w,h)=>{
  ctx.fillStyle='#73805a';ctx.fillRect(0,0,w,h);
  for(const [i,r] of REGIONS.slice(1).entries()){
   const x=r.x/WORLD.width*w,y=r.y/WORLD.height*h,radius=r.r/WORLD.width*w,g=ctx.createRadialGradient(x,y,radius*.4,x,y,radius*1.12),color=['#9caeb2','#9c765b','#75667d'][i];g.addColorStop(0,color);g.addColorStop(.75,color);g.addColorStop(1,color+'00');ctx.fillStyle=g;ctx.fillRect(x-radius*1.2,y-radius*1.2,radius*2.4,radius*2.4);
  }
  for(let i=0;i<37000;i++){const x=random()*w,y=random()*h,r=2+random()*11;ctx.fillStyle=i%2?'#d5d6a229':'#243d2b25';ctx.beginPath();ctx.ellipse(x,y,r,r*.5,random()*6.28,0,Math.PI*2);ctx.fill();}
  // Soft edges and meanders replace rectangular strips through the biomes.
  const paths=[...REGIONS.slice(1),{x:2400,y:3950}];for(const r of paths)for(let i=0;i<150;i++){
   const t=i/149,x=(2400+(r.x-2400)*t+Math.sin(t*Math.PI*3)*35)/WORLD.width*w,y=(2000+(r.y-2000)*t)/WORLD.height*h,radius=(40+Math.sin(t*12)*8)/WORLD.width*w,g=ctx.createRadialGradient(x,y,0,x,y,radius);g.addColorStop(0,'#b5a17c');g.addColorStop(.65,'#ac997480');g.addColorStop(1,'#ac997400');ctx.fillStyle=g;ctx.fillRect(x-radius,y-radius,radius*2,radius*2);
  }
 });map.anisotropy=8;
 const terrain=geo(new T.PlaneGeometry(WORLD.width/100,WORLD.height/100,1,1));const ground=mesh(scene,terrain,material('#ffffff',{map}),0,.005,0,1,1,1,false);ground.rotation.x=-Math.PI/2;
 for(const o of SCENERY){
  const x=wx(o.x),z=wz(o.y),s=o.scale,region=regionAt(o),leaves=region===REGIONS[1]?p.frost:region===REGIONS[2]?p.ember:region===REGIONS[3]?p.venom:p.leaf;
  if(o.type==='tree'){
   const g=group(scene,x,0,z),tr=mesh(g,cylinder,p.trunk,0,2.1*s,0,.2*s,4.2*s,.19*s);tr.rotation.z=(random()-.5)*.06;
   for(let i=0;i<5;i++){const a=i*Math.PI*2/5,root=mesh(g,cone,p.bark,Math.cos(a)*.23*s,.15*s,Math.sin(a)*.23*s,.14*s,.72*s,.13*s);root.rotation.z=Math.cos(a)*.6;root.rotation.x=Math.sin(a)*.6;}
   for(let i=0;i<7;i++){const a=i*2.4,r=i===0?0:.75*s;const branch=mesh(g,cylinder,p.trunk,Math.cos(a)*r*.5,3.3*s,Math.sin(a)*r*.5,.07*s,1.4*s,.07*s);branch.rotation.z=-Math.cos(a)*.8;branch.rotation.x=Math.sin(a)*.8;const crown=mesh(g,rockGeo,leaves[i%4],Math.cos(a)*r,(4.05+Math.sin(i)*.32)*s,Math.sin(a)*r,1.12*s,.82*s,1.02*s);crown.rotation.y=random()*Math.PI;}
  }else{const rock=mesh(scene,rockGeo,p.stone,x,.26*s,z,.3*s,.3*s,.3*s);rock.rotation.set(random()*.4,random()*6.28,.1);mesh(scene,sphere,leaves[2],x,.5*s,z,.25*s,.065*s,.23*s,false);}
 }
 const bladePositions=[],bladeUvs=[];for(let blade=0;blade<3;blade++){const a=blade*Math.PI*2/3,c=Math.cos(a),sn=Math.sin(a),h=.18+blade*.045,offset=(blade-1)*.035,points=[[-.027,0,0],[.027,0,0],[-.012,h*.58,.018],[.012,h*.58,.018],[.035,h,.055]];for(const i of [0,1,2,1,3,2,2,3,4]){const[x,y,z]=points[i];bladePositions.push(x*c-z*sn+offset,y,x*sn+z*c);bladeUvs.push(.5,y/h);}}
 const bladeGeo=geo(new T.BufferGeometry());bladeGeo.setAttribute('position',new T.Float32BufferAttribute(bladePositions,3));bladeGeo.setAttribute('uv',new T.Float32BufferAttribute(bladeUvs,2));bladeGeo.computeVertexNormals();
 const grassMat=material('#a7b986',{side:T.DoubleSide});grassMat.onBeforeCompile=shader=>{shader.uniforms.worldWind=wind;shader.vertexShader='uniform float worldWind;\n'+shader.vertexShader;shader.vertexShader=shader.vertexShader.replace('#include <begin_vertex>','#include <begin_vertex>\ntransformed.x += sin(worldWind*1.6 + instanceMatrix[3].x*.7 + instanceMatrix[3].z*.4)*.07*uv.y*uv.y;');};
 const dummy=new T.Object3D(),color=new T.Color(),grass=new T.InstancedMesh(bladeGeo,grassMat,7500);
 const clearPath=(x,y)=>REGIONS.slice(1).some(r=>{const dx=r.x-2400,dy=r.y-2000,t=Math.max(0,Math.min(1,((x-2400)*dx+(y-2000)*dy)/(dx*dx+dy*dy)));return Math.hypot(x-2400-dx*t,y-2000-dy*t)<55;});
 for(let i=0;i<7500;i++){
  const x=25+random()*(WORLD.width-50),y=25+random()*(WORLD.height-50),r=regionAt({x,y}),skip=Math.hypot(x-2400,y-2000)<155||clearPath(x,y)||SOLIDS.some(o=>Math.hypot(x-o.x,y-o.y)<o.r+14);
  dummy.position.set(wx(x),.015,wz(y));dummy.rotation.set(0,random()*6.28,0);dummy.scale.setScalar(skip?.001:.55+random());dummy.updateMatrix();grass.setMatrixAt(i,dummy.matrix);color.set(r===REGIONS[1]?'#b4cbd0':r===REGIONS[2]?'#a58358':r===REGIONS[3]?'#8c7c9b':'#71875a');color.multiplyScalar(.75+random()*.4);grass.setColorAt(i,color);
 }grass.receiveShadow=true;scene.add(grass);instances.push(grass);
 const flowerShape=new T.Shape();for(let i=0;i<=40;i++){const a=i/40*Math.PI*2,r=.06*(1+.35*Math.cos(a*5));if(!i)flowerShape.moveTo(Math.cos(a)*r,Math.sin(a)*r);else flowerShape.lineTo(Math.cos(a)*r,Math.sin(a)*r);}
 const flowerGeo=geo(new T.ShapeGeometry(flowerShape)),flowerMat=material('#e4d6af',{side:T.DoubleSide}),flowers=new T.InstancedMesh(flowerGeo,flowerMat,1000);
 for(let i=0;i<1000;i++){const x=random()*WORLD.width,y=random()*WORLD.height,r=regionAt({x,y});dummy.position.set(wx(x),.17,wz(y));dummy.rotation.set(-Math.PI/2+.2,0,random()*6.28);dummy.scale.setScalar(.65+random()*.5);dummy.updateMatrix();flowers.setMatrixAt(i,dummy.matrix);color.set(r===REGIONS[1]?'#cbe0eb':r===REGIONS[2]?'#dcb381':r===REGIONS[3]?'#c5a1da':i%4?'#f0ddaa':'#a0adcf');flowers.setColorAt(i,color);}scene.add(flowers);instances.push(flowers);
 // Canvas panels and an open flap sit inside the original shelter footprint.
 const tent=group(scene,-1.4,0,-1.3),canvasMat=material('#b4b18a',{side:T.DoubleSide}),roof=geo(new T.BufferGeometry());
 roof.setAttribute('position',new T.Float32BufferAttribute([-.8,0,.6,0,1.2,.6,0,1.2,-.6,-.8,0,.6,0,1.2,-.6,-.8,0,-.6,.8,0,.6,.8,0,-.6,0,1.2,-.6,.8,0,.6,0,1.2,-.6,0,1.2,.6,-.8,0,-.6,0,1.2,-.6,.8,0,-.6],3));roof.computeVertexNormals();mesh(tent,roof,canvasMat);
 const flap=geo(new T.BufferGeometry());flap.setAttribute('position',new T.Float32BufferAttribute([-.8,0,.605,0,1.2,.605,-.28,0,.605,.8,0,.605,.28,0,.605,0,1.2,.605],3));flap.computeVertexNormals();mesh(tent,flap,material('#839271',{side:T.DoubleSide}));for(const z of [-.6,.6])mesh(tent,cylinder,p.trunk,0,.58,z,.025,1.18,.025);mesh(tent,box,p.bark,0,1.2,0,.04,.04,1.4);for(const x of [-.79,.79])for(const z of [-.58,.58])mesh(tent,cylinder,p.trunk,x,.12,z,.018,.24,.018);
 // A lantern on the shelter's footprint uses its existing solid collider.
 const lantern=group(scene,-1.95,1.55,-1.6);mesh(lantern,cylinder,p.gold,0,.16,0,.12,.05,.12);mesh(lantern,cylinder,p.gold,0,-.16,0,.12,.05,.12);const glow=material('#ffe2a0',{emissive:'#ffbc5f',emissiveIntensity:2.2});mesh(lantern,sphere,glow,0,0,0,.08,.14,.08,false);for(const x of [-.09,.09])for(const z of [-.09,.09])mesh(lantern,cylinder,p.gold,x,0,z,.012,.3,.012);
 const light=new T.PointLight('#ffc77e',1.5,3.5,2);light.position.copy(lantern.position);scene.add(light);
 // Carved motifs decorate the existing sector structures, without new obstacles.
 const rune=material('#c5dfeb',{emissive:'#7bacc2',emissiveIntensity:.45});for(const x of [-15,-13])for(let i=0;i<3;i++){const mark=mesh(scene,box,rune,x,.7+i*.26,-9.78,.13,.027,.012,false);mark.rotation.z=i%2?.6:-.6;}
 const mossMat=material('#b6c8be');for(const x of [-15,-13])mesh(scene,sphere,mossMat,x,2.03,-10,.26,.05,.28,false);
 const distant=material('#829e91',{flatShading:true});for(let i=0;i<18;i++){const a=i/18*Math.PI*2;mesh(scene,cone,distant,Math.cos(a)*45,2,Math.sin(a)*45,6,6+random()*9,6,false);}
 return{update(time){wind.value=time;},setQuality(high){grass.count=high?7500:3000;flowers.count=high?1000:350;},dispose(){for(const t of textures)t.dispose();}};
}
