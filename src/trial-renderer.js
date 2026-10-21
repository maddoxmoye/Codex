import * as T from 'three';
import {EffectComposer} from 'three/addons/postprocessing/EffectComposer.js';
import {RenderPass} from 'three/addons/postprocessing/RenderPass.js';
import {UnrealBloomPass} from 'three/addons/postprocessing/UnrealBloomPass.js';
import {OutputPass} from 'three/addons/postprocessing/OutputPass.js';
import {drawCombatFeedback} from './combat-feedback.js';

// A deliberately small art study. Uses the real combat model, without changing its renderer.
export function createTrialRenderer(canvas,feedbackCanvas,game){
 const renderer=new T.WebGLRenderer({canvas,antialias:true,powerPreference:'high-performance'});
 renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.shadowMap.enabled=true;renderer.shadowMap.type=T.PCFSoftShadowMap;
 renderer.toneMapping=T.ACESFilmicToneMapping;renderer.toneMappingExposure=1.02;
 const scene=new T.Scene();scene.background=new T.Color('#acbfb0');scene.fog=new T.FogExp2('#acbfb0',.027);
 const camera=new T.PerspectiveCamera(48,1,.1,110),focus=new T.Vector3(),point=new T.Vector3();
 const hemi=new T.HemisphereLight('#daebf4','#34482e',1.5);scene.add(hemi);
 const sun=new T.DirectionalLight('#fff0c9',3.6);sun.position.set(-8,15,5);sun.castShadow=true;
 sun.shadow.mapSize.set(2048,2048);Object.assign(sun.shadow.camera,{left:-16,right:16,top:16,bottom:-16,near:.5,far:48});sun.shadow.bias=-.0002;sun.shadow.normalBias=.025;sun.shadow.radius=3;scene.add(sun);
 const rim=new T.DirectionalLight('#b8d9ed',1.3);rim.position.set(10,7,-12);scene.add(rim);
 const composer=new EffectComposer(renderer);composer.addPass(new RenderPass(scene,camera));
 const bloom=new UnrealBloomPass(new T.Vector2(800,600),.22,.55,1.45);composer.addPass(bloom);composer.addPass(new OutputPass());
 const geos=[],mats=[],textures=[],instances=[],dynamicMaterials=new Set(),enemyGroups=new Map(),arrows=new Map(),loots=new Map(),effects=new Map(),hazards=new Map();
 const geo=g=>(geos.push(g),g),material=(color,options={})=>{const m=new T.MeshStandardMaterial({color,roughness:.87,...options});mats.push(m);return m;};
 const basic=(color,options={})=>{const m=new T.MeshBasicMaterial({color,...options});mats.push(m);return m;};
 const rockGeo=geo(new T.IcosahedronGeometry(1,1));
 const sphere=geo(new T.SphereGeometry(1,16,12)),box=geo(new T.BoxGeometry(1,1,1)),cylinder=geo(new T.CylinderGeometry(1,1,1,10)),cone=geo(new T.ConeGeometry(1,1,9)),crystal=geo(new T.OctahedronGeometry(1)),capsule=geo(new T.CapsuleGeometry(.1,.35,4,8)),circle=geo(new T.CircleGeometry(1,40)),ring=geo(new T.RingGeometry(.86,1,64));
 const mesh=(parent,g,m,x=0,y=0,z=0,sx=1,sy=sx,sz=sx,shadow=true)=>{const o=new T.Mesh(g,m);o.position.set(x,y,z);o.scale.set(sx,sy,sz);o.castShadow=shadow;o.receiveShadow=true;parent.add(o);return o;};
 const flat=(parent,g,m,x,y,z,s=1)=>{const o=mesh(parent,g,m,x,y,z,s,s,s,false);o.rotation.x=-Math.PI/2;return o;};
 const group=(parent,x=0,y=0,z=0)=>{const o=new T.Group();o.position.set(x,y,z);parent.add(o);return o;};
 const curveMesh=(parent,points,r,m)=>mesh(parent,geo(new T.TubeGeometry(new T.CatmullRomCurve3(points.map(v=>new T.Vector3(...v))),16,r,6,false)),m);
 const palette={grass:material('#64815b'),trunk:material('#705343'),bark:material('#443c32'),stone:material('#8b9688',{flatShading:true}),stoneDark:material('#5f746a',{flatShading:true}),moss:material('#849558'),leaf:[material('#345f45'),material('#547c4a'),material('#7a984f'),material('#9bad67')],fern:material('#5b8b53',{side:T.DoubleSide}),gold:material('#d1ae65',{metalness:.5,roughness:.38}),cloth:material('#2a6255'),clothLight:material('#578875'),clothDark:material('#163f3a'),skin:material('#e5b794'),leather:material('#67462f'),boot:material('#3c352e'),bone:material('#dfd6ae'),metal:material('#bac5b5',{metalness:.65,roughness:.3}),black:material('#172722'),eye:basic('#e8d7a6'),fire:material('#f34d39',{emissive:'#ff441d',emissiveIntensity:2}),ice:material('#70c7ff',{emissive:'#4a9dff',emissiveIntensity:1.4}),poison:material('#a765f2',{emissive:'#9f42e5',emissiveIntensity:1.4}),physical:material('#f4dc9e',{emissive:'#dab85c',emissiveIntensity:.5})};
 let seed=3792;const random=()=>{seed=(seed*16807)%2147483647;return(seed-1)/2147483646;};
 const wx=x=>(x-2400)/100,wz=y=>(y-2000)/100;
 const makeTexture=(size,draw)=>{const c=document.createElement('canvas');c.width=c.height=size;draw(c.getContext('2d'),size);const t=new T.CanvasTexture(c);t.colorSpace=T.SRGBColorSpace;t.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());textures.push(t);return t;};
 const groundTexture=makeTexture(1024,(ctx,s)=>{
  ctx.fillStyle='#73805a';ctx.fillRect(0,0,s,s);
  for(let i=0;i<22000;i++){ctx.fillStyle=['#829365','#526a47','#8c9a68','#5c774f'][i%4];ctx.globalAlpha=.14+random()*.19;const r=2+random()*17;ctx.beginPath();ctx.ellipse(random()*s,random()*s,r,r*.5,random()*6.28,0,6.28);ctx.fill();}ctx.globalAlpha=1;
  // A painted, irregular sandy path through a mossy clearing.
  for(let i=0;i<210;i++){const t=i/209,x=s*(.47+Math.sin(t*5)*.045),y=s*t,r=23+Math.sin(t*13)*8+random()*10;const g=ctx.createRadialGradient(x,y,0,x,y,r);g.addColorStop(0,'#b7a17c');g.addColorStop(.6,'#af9d77');g.addColorStop(1,'#af9d7700');ctx.fillStyle=g;ctx.fillRect(x-r,y-r,r*2,r*2);}
  for(let i=0;i<4000;i++){ctx.fillStyle=i%2?'#d0be9560':'#3d573331';ctx.fillRect(random()*s,random()*s,random()*2+.4,random()*2+.4);}
 });
 groundTexture.wrapS=groundTexture.wrapT=T.ClampToEdgeWrapping;
 const groundMat=material('#ffffff',{map:groundTexture});
 const terrain=geo(new T.PlaneGeometry(64,64,64,64)),positions=terrain.attributes.position;
 for(let i=0;i<positions.count;i++){const x=positions.getX(i),y=positions.getY(i),d=Math.hypot(x,y);positions.setZ(i,d<11?0:Math.sin(x*.35)*Math.cos(y*.31)*Math.min(.7,(d-11)*.08));}terrain.computeVertexNormals();
 const ground=mesh(scene,terrain,groundMat,0,-.03,0,1,1,1,false);ground.rotation.x=-Math.PI/2;
 const contactTexture=makeTexture(64,(c,s)=>{const g=c.createRadialGradient(s/2,s/2,1,s/2,s/2,s/2);g.addColorStop(0,'#11271c90');g.addColorStop(.45,'#11271c50');g.addColorStop(1,'#11271c00');c.fillStyle=g;c.fillRect(0,0,s,s);});
 const contactMat=basic('#ffffff',{map:contactTexture,transparent:true,depthWrite:false});
 function rock(x,z,s=1){const o=mesh(scene,rockGeo,palette.stone,x,.3*s,z,.7*s,.55*s,.6*s);o.rotation.set(random()*.4,random()*6.28,random()*.3);mesh(scene,sphere,palette.moss,x-.1*s,.65*s,z,.49*s,.12*s,.4*s,false);flat(scene,circle,contactMat,x,.004,z,s);}
 function tree(x,z,s=1){
  const g=group(scene,x,0,z),tr=mesh(g,cylinder,palette.trunk,0,2.2*s,0,.24*s,4.4*s,.22*s);tr.rotation.z=(random()-.5)*.08;
  for(let i=0;i<5;i++){const a=i*1.256,root=mesh(g,cone,palette.bark,Math.cos(a)*.25*s,.13*s,Math.sin(a)*.25*s,.16*s,.7*s,.14*s);root.rotation.z=Math.cos(a)*.7;root.rotation.x=Math.sin(a)*.7;}
  for(let i=0;i<7;i++){const a=i*2.4,r=i===0?0:.8*s,branch=mesh(g,cylinder,palette.trunk,Math.cos(a)*r*.5,3.5*s+Math.sin(i)*.3*s,Math.sin(a)*r*.5,.09*s,1.5*s,.09*s);branch.rotation.z=-Math.cos(a)*.9;branch.rotation.x=Math.sin(a)*.9;const crown=mesh(g,rockGeo,palette.leaf[i%4],Math.cos(a)*r,(4.3+Math.sin(i)*.35)*s,Math.sin(a)*r,1.25*s,.86*s,1.1*s);crown.rotation.y=random()*6.28;}
  flat(g,circle,contactMat,0,.006,0,1.3*s);
 }
 // Keep the playable center spacious; foliage frames its perimeter.
 for(let i=0;i<44;i++){const a=i*2.399,r=14+random()*13,s=.9+random()*.7;tree(Math.cos(a)*r,Math.sin(a)*r,s);}
 for(const [x,z,s] of [[-7,-3,1.3],[8,-6,1.6],[-9,5,1.5],[9,6,1.25],[-4,-10,1],[4,10,.9]])rock(x,z,s);
 for(let i=0;i<45;i++){const a=random()*6.28,r=8+random()*13;rock(Math.cos(a)*r,Math.sin(a)*r,.15+random()*.4);}
 // Instanced grass keeps the richer clearing inexpensive to draw.
 const bladePositions=[],bladeUvs=[];
 for(let blade=0;blade<3;blade++){
  const a=blade*Math.PI*2/3,c=Math.cos(a),sn=Math.sin(a),h=.18+blade*.045,offset=(blade-1)*.035;
  const points=[[-.027,0,0],[.027,0,0],[-.012,h*.58,.018],[.012,h*.58,.018],[.035,h,.055]];
  for(const index of [0,1,2,1,3,2,2,3,4]){const [x,y,z]=points[index];bladePositions.push(x*c-z*sn+offset,y,x*sn+z*c);bladeUvs.push(.5,y/h);}
 }
 const bladeGeo=geo(new T.BufferGeometry());bladeGeo.setAttribute('position',new T.Float32BufferAttribute(bladePositions,3));bladeGeo.setAttribute('uv',new T.Float32BufferAttribute(bladeUvs,2));bladeGeo.computeVertexNormals();
 const grassMaterial=material('#82a05c',{side:T.DoubleSide});const wind={value:0};
 grassMaterial.onBeforeCompile=shader=>{shader.uniforms.trialWind=wind;shader.vertexShader='uniform float trialWind;\n'+shader.vertexShader;shader.vertexShader=shader.vertexShader.replace('#include <begin_vertex>','#include <begin_vertex>\ntransformed.x += sin(trialWind*1.6 + instanceMatrix[3].x*.7 + instanceMatrix[3].z*.4) * .09 * uv.y * uv.y;');};
 const grass=new T.InstancedMesh(bladeGeo,grassMaterial,4700),dummy=new T.Object3D(),color=new T.Color();
 for(let i=0;i<4700;i++){const x=(random()-.5)*49,z=(random()-.5)*49,pathX=Math.sin((z/64+.5)*5)*2.8-1.9,skip=Math.abs(x-pathX)<1.3||Math.hypot(x,z)<2;dummy.position.set(x,0,z);dummy.scale.setScalar(skip?.01:.55+random()*1.15);dummy.rotation.y=random()*Math.PI;dummy.updateMatrix();grass.setMatrixAt(i,dummy.matrix);color.setHSL(.22+random()*.08,.24+random()*.18,.24+random()*.2);grass.setColorAt(i,color);}grass.receiveShadow=true;scene.add(grass);instances.push(grass);
 const flowerShape=new T.Shape();for(let i=0;i<=60;i++){const a=i/60*Math.PI*2,r=.055*(1+.35*Math.cos(a*5));if(i===0)flowerShape.moveTo(Math.cos(a)*r,Math.sin(a)*r);else flowerShape.lineTo(Math.cos(a)*r,Math.sin(a)*r);}
 const flowerGeo=geo(new T.ShapeGeometry(flowerShape)),flowerMat=material('#e4d6af',{side:T.DoubleSide}),flowers=new T.InstancedMesh(flowerGeo,flowerMat,500);
 for(let i=0;i<500;i++){const a=random()*6.28,r=5+random()*15;dummy.position.set(Math.cos(a)*r,.15+random()*.15,Math.sin(a)*r);dummy.scale.setScalar(.6+random());dummy.rotation.set(-Math.PI/2+.25,0,random()*6.28);dummy.updateMatrix();flowers.setMatrixAt(i,dummy.matrix);color.set(i%4===0?'#9ba9cb':'#f0ddaa');flowers.setColorAt(i,color);}scene.add(flowers);instances.push(flowers);
 function fern(x,z,s){const g=group(scene,x,0,z);for(let i=0;i<7;i++){const a=i*Math.PI*2/7;for(let j=0;j<5;j++){const d=.12+j*.09,leaf=mesh(g,sphere,palette.fern,Math.cos(a)*d*s,(.45-j*.06)*s,Math.sin(a)*d*s,.055*s,.018*s,.18*s,false);leaf.rotation.y=-a;leaf.rotation.z=.3;}}}
 for(const [x,z] of [[-5,3],[5,5],[-7,-5],[6,-7],[-3,8]])fern(x,z,1.2);
 const mushroomRed=material('#b86249');for(let i=0;i<21;i++){const a=random()*6.28,r=7+random()*6,x=Math.cos(a)*r,z=Math.sin(a)*r;mesh(scene,cylinder,palette.bone,x,.12,z,.025,.25,.025);mesh(scene,sphere,mushroomRed,x,.27,z,.13,.065,.13);}
 // Ruined waystones, hanging lantern and a little camp establish a place rather than a flat arena.
 const rune=material('#e7ca82',{emissive:'#d7a35a',emissiveIntensity:.75});
 for(const [x,z,rot] of [[-4.5,-6,.14],[3.6,-8,-.12]]){const g=group(scene,x,0,z);g.rotation.z=rot;mesh(g,box,palette.stoneDark,0,.85,0,.58,1.7,.4);mesh(g,box,palette.moss,0,1.73,0,.66,.09,.47);for(let j=0;j<3;j++){const r=mesh(g,box,rune,0,.65+j*.22,.208,.13,.025,.012,false);r.rotation.z=j%2?.6:-.6;}}
 const archLeft=mesh(scene,cylinder,palette.trunk,-6,1.25,-2,.09,2.5,.09);archLeft.rotation.z=-.07;curveMesh(scene,[[-6,2.45,-2],[-5.7,2.75,-2],[-5.2,2.7,-2]],.055,palette.trunk);
 const lantern=group(scene,-5.2,2.25,-2);mesh(lantern,cylinder,palette.gold,0,.17,0,.17,.07,.17);mesh(lantern,cylinder,palette.gold,0,-.17,0,.17,.07,.17);const lanternGlow=material('#ffe2a0',{emissive:'#ffbc5f',emissiveIntensity:3});mesh(lantern,sphere,lanternGlow,0,0,0,.11,.16,.11,false);for(const x of [-.11,.11])for(const z of [-.11,.11])mesh(lantern,cylinder,palette.gold,x,0,z,.012,.32,.012);
 const lanternLight=new T.PointLight('#ffc77e',3,4,2);lanternLight.position.set(-5.2,2.25,-2);scene.add(lanternLight);
 // Distant blue-green silhouettes make the horizon feel deeper.
 const distant=material('#829e91',{flatShading:true});for(let i=0;i<20;i++){const a=i/20*Math.PI*2;mesh(scene,cone,distant,Math.cos(a)*43,2,Math.sin(a)*43,7,7+random()*8,7,false);}
 const moteCount=90,moteArray=new Float32Array(moteCount*3);for(let i=0;i<moteCount;i++){moteArray[i*3]=(random()-.5)*30;moteArray[i*3+1]=random()*5+.4;moteArray[i*3+2]=(random()-.5)*30;}
 const moteGeo=geo(new T.BufferGeometry());moteGeo.setAttribute('position',new T.BufferAttribute(moteArray,3));const moteMat=new T.PointsMaterial({color:'#ffebae',size:.035,transparent:true,opacity:.7,depthWrite:false});mats.push(moteMat);const motes=new T.Points(moteGeo,moteMat);scene.add(motes);

 function makeArcher(){
  const root=group(scene),body=group(root,0,.8,0),hips=group(root,0,.72,0);root.userData.body=body;
  mesh(body,sphere,palette.cloth,0,.31,0,.26,.39,.18);mesh(body,box,palette.leather,0,.06,0,.5,.08,.36);
  mesh(body,box,palette.gold,0,.06,.195,.075,.07,.018);const strap=mesh(body,box,palette.leather,.02,.34,.162,.065,.55,.025);strap.rotation.z=-.5;
  for(let i=0;i<3;i++)mesh(body,sphere,palette.gold,.11-i*.065,.49-i*.12,.19,.015,.015,.012);
  const head=group(body,0,.82,0);mesh(head,sphere,palette.skin,0,0,.018,.19,.235,.18);
  // Hood is a curved, open-backed shell around a visible face.
  const hoodGeo=geo(new T.SphereGeometry(1,18,14,Math.PI*.12,Math.PI*1.76,0,Math.PI*.91));
  const hood=mesh(head,hoodGeo,palette.clothDark,0,.055,-.04,.25,.285,.23);hood.rotation.y=Math.PI;
  mesh(head,sphere,palette.clothLight,0,.19,-.07,.22,.12,.19);
  mesh(head,sphere,palette.skin,0,-.008,.173,.14,.145,.035);mesh(head,sphere,palette.skin,0,-.025,.22,.034,.045,.035);
  for(const x of [-.065,.065]){mesh(head,sphere,palette.black,x,.025,.204,.018,.013,.009,false);const brow=mesh(head,box,palette.leather,x,.068,.2,.05,.009,.012);brow.rotation.z=x<0?-.1:.1;}
  const scarf=mesh(body,geo(new T.TorusGeometry(.175,.065,7,20)),palette.clothLight,0,.64,0,1,1,1);scarf.rotation.x=Math.PI/2;mesh(body,box,palette.clothLight,.11,.4,.2,.11,.3,.04);
  const cloakGeo=geo(new T.PlaneGeometry(.64,.91,8,9));const cloak=mesh(body,cloakGeo,material('#2d6655',{side:T.DoubleSide}),0,.23,-.2);cloak.rotation.x=.12;
  const cloakBase=Float32Array.from(cloakGeo.attributes.position.array);root.userData.cloak={mesh:cloak,base:cloakBase};
  const quiver=mesh(body,cylinder,palette.leather,.21,.28,-.25,.095,.59,.095);quiver.rotation.z=-.27;
  for(let i=0;i<5;i++){const x=.18+(i%3)*.035,z=-.25+(i%2)*.04;mesh(body,cylinder,palette.bone,x,.66+(i%2)*.035,z,.007,.52,.007);const feather=mesh(body,box,palette.bone,x,.91+(i%2)*.035,z,.043,.1,.01);feather.rotation.z=-.2;}
  const legs=[];for(const side of [-1,1]){const leg=group(hips,side*.13,0,0);mesh(leg,capsule,palette.leather,0,-.18,0,.91,1,.91);const knee=group(leg,0,-.36,0);mesh(knee,capsule,palette.clothDark,0,-.15,0,.84,.91,.84);mesh(knee,box,palette.boot,0,-.32,.055,.16,.17,.29);mesh(knee,box,palette.gold,.075*side,-.18,.01,.025,.045,.08);legs.push({leg,knee});}
  const left=group(body,-.24,.53,0),right=group(body,.24,.53,0);
  const forearms=[];for(const arm of [left,right]){mesh(arm,capsule,palette.cloth,0,-.12,0,.8,.65,.8);const elbow=group(arm,0,-.26,0);mesh(elbow,capsule,palette.clothLight,0,-.1,0,.66,.52,.66);mesh(elbow,cylinder,palette.leather,0,-.15,0,.073,.15,.073);mesh(elbow,sphere,palette.skin,0,-.25,0,.065,.075,.065);forearms.push(elbow);}
  const bow=group(left,0,-.44,.12);curveMesh(bow,[[0,-.55,0],[-.12,-.32,.03],[-.17,0,.1],[-.12,.32,.03],[0,.55,0]],.026,palette.leather);curveMesh(bow,[[0,-.55,0],[-.03,0,.012],[0,.55,0]],.008,palette.gold);mesh(bow,cylinder,palette.gold,-.17,0,.1,.034,.18,.034);
  const stringGeo=geo(new T.BufferGeometry());stringGeo.setAttribute('position',new T.BufferAttribute(new Float32Array([0,-.55,0,0,0,0,0,.55,0]),3));const stringMat=new T.LineBasicMaterial({color:'#e2d5ae'});mats.push(stringMat);bow.add(new T.Line(stringGeo,stringMat));
  root.userData.rig={body,head,hips,legs,left,right,forearms,bow,stringGeo};flat(root,circle,contactMat,0,.008,0,.49);
  return root;
 }
 // Merge repeated static meshes into instance batches, preserving world transforms.
 scene.updateMatrixWorld(true);const batches=new Map();
 scene.traverse(o=>{if(!o.isMesh||o.isInstancedMesh)return;let ancestor=o;while(ancestor){if(ancestor===lantern)return;ancestor=ancestor.parent;}const key=o.geometry.uuid+o.material.uuid+o.castShadow;if(!batches.has(key))batches.set(key,[]);batches.get(key).push(o);});
 for(const objects of batches.values()){if(objects.length<2)continue;const first=objects[0],batch=new T.InstancedMesh(first.geometry,first.material,objects.length);batch.castShadow=first.castShadow;batch.receiveShadow=first.receiveShadow;objects.forEach((o,i)=>{batch.setMatrixAt(i,o.matrixWorld);o.removeFromParent();});scene.add(batch);instances.push(batch);}
 const archer=makeArcher();
 function makeEnemy(e){
  const ownedStart=geos.length,root=group(scene),body=group(root),clones=[];const own=(base)=>{const m=base.clone();dynamicMaterials.add(m);clones.push({m,color:m.color.clone()});return m;};
  const moss=own(palette.leaf[1]),wood=own(palette.bark),stone=own(palette.stoneDark),bone=own(palette.bone);const legs=[];
  if(e.kind==='brute'){
   mesh(body,sphere,stone,0,.7,0,.52,.58,.37);mesh(body,sphere,moss,-.15,1.08,-.04,.42,.22,.31);mesh(body,box,wood,0,1.17,.12,.45,.4,.35);for(const x of [-.13,.13])mesh(body,sphere,palette.eye,x,1.19,.303,.038,.022,.012);
   for(const side of [-1,1]){const arm=group(body,side*.57,.98,0);mesh(arm,sphere,stone,0,-.28,0,.21,.4,.22);mesh(arm,sphere,moss,0,-.01,-.02,.24,.13,.23);const leg=group(body,side*.25,.35,0);mesh(leg,sphere,stone,0,-.18,.04,.18,.23,.23);legs.push({leg,arm});}
   for(let i=0;i<3;i++){const branch=mesh(body,cylinder,wood,(i-1)*.25,1.48,-.06,.045,.5,.045);branch.rotation.z=(i-1)*.7;mesh(body,sphere,moss,(i-1)*.34,1.69,-.06,.16,.08,.12);}
  }else if(e.kind==='archer'){
   mesh(body,sphere,wood,0,.55,0,.22,.35,.17);mesh(body,cone,moss,0,.43,0,.31,.5,.27);mesh(body,sphere,bone,0,1.02,.02,.21,.23,.18);mesh(body,sphere,wood,0,1.12,-.05,.26,.25,.22);
   mesh(body,sphere,bone,0,1,.14,.15,.14,.05);for(const x of [-.065,.065])mesh(body,sphere,palette.eye,x,1.03,.193,.035,.023,.008);
   for(const side of [-1,1]){const arm=group(body,side*.23,.74,0);mesh(arm,capsule,wood,0,-.17,.1,.6,.8,.6);const leg=group(body,side*.12,.31,0);mesh(leg,capsule,wood,0,-.15,0,.7,.7,.7);legs.push({leg,arm});}
   curveMesh(body,[[-.4,.35,.24],[-.59,.7,.3],[-.4,1.05,.24]],.022,wood);curveMesh(body,[[-.4,.35,.24],[-.4,1.05,.24]],.006,bone);
   for(const side of [-1,1]){curveMesh(body,[[side*.16,1.25,0],[side*.29,1.48,-.06],[side*.48,1.56,-.03]],.035,wood);}
  }else{
   mesh(body,sphere,wood,0,.36,0,.36,.28,.4);mesh(body,sphere,moss,0,.49,-.04,.4,.19,.34);mesh(body,sphere,bone,0,.28,.31,.22,.15,.17);
   for(const x of [-.15,.15])mesh(body,sphere,palette.eye,x,.4,.342,.035,.025,.012);for(const side of [-1,1])for(const z of [-.18,.2]){const leg=group(body,side*.32,.2,z);mesh(leg,capsule,wood,side*.06,-.035,.03,.62,.65,.62);leg.rotation.z=-side*.65;legs.push({leg});}
   for(const side of [-1,1]){const horn=mesh(body,cone,bone,side*.22,.53,.24,.055,.23,.055);horn.rotation.z=-side*.65;}
  }
  root.userData={body,legs,clones,ownedGeos:geos.splice(ownedStart),phase:random()*6.28};flat(root,circle,contactMat,0,.009,0,e.kind==='brute'?.67:.42);return root;
 }
 function makeArrow(b){const g=new T.Group(),m=!b.kind?palette.fire:palette[b.element]||palette.physical;
  const shaft=mesh(g,cylinder,palette.bone,0,0,0,.012,.5,.012);shaft.rotation.x=Math.PI/2;
  const tip=mesh(g,cone,palette.metal,0,0,.3,.045,.14,.035);tip.rotation.x=Math.PI/2;
  for(const side of [-1,1]){const f=mesh(g,box,palette.clothLight,side*.025,0,-.19,.055,.012,.13);f.rotation.y=side*.2;}
  mesh(g,sphere,m,0,0,.24,.04,.04,.1,false);const trail=mesh(g,cone,material(m.color,{emissive:m.color,emissiveIntensity:1.7,transparent:true,opacity:.45,depthWrite:false}),0,0,-.37,.035,.55,.035,false);trail.rotation.x=-Math.PI/2;g.userData.trailMat=trail.material;return g;
 }
 function sync(map,objects,create,update){for(const [key,o] of map)if(!objects.includes(key)){scene.remove(o);map.delete(key);if(o.userData.clones)for(const {m} of o.userData.clones){m.dispose();dynamicMaterials.delete(m);}for(const g of o.userData.ownedGeos||[])g.dispose();if(o.userData.trailMat){o.userData.trailMat.dispose();const i=mats.indexOf(o.userData.trailMat);if(i>=0)mats.splice(i,1);}}
  for(const value of objects){let o=map.get(value);if(!o){o=create(value);map.set(value,o);scene.add(o);}update(o,value);}}
 let yaw=.52,lift=3.1,distance=8.7,high=true,width=0,height=0,first=true;
 const feedback=feedbackCanvas.getContext('2d');
 function render(time,dt=1/60){
  const w=canvas.clientWidth,h=canvas.clientHeight;if(w!==width||h!==height){width=w;height=h;renderer.setSize(w,h,false);composer.setSize(w,h);feedbackCanvas.width=w;feedbackCanvas.height=h;camera.aspect=w/h;camera.updateProjectionMatrix();}
  wind.value=time;const p=game.player,px=wx(p.x),pz=wz(p.y),rig=archer.userData.rig;
  archer.position.set(px,0,pz);archer.rotation.y=Math.atan2(p.aimX,p.aimY);
  const walk=p.moving?Math.sin(time*11):0,breathe=Math.sin(time*2)*.009,draw=Math.max(0,Math.min(1,(.42-p.fireTimer)/.36));
  rig.body.position.y=.8+Math.abs(walk)*.025+breathe;rig.body.rotation.z=walk*.025;rig.head.rotation.z=-walk*.025;
  for(const [i,{leg,knee}] of rig.legs.entries()){leg.rotation.x=walk*(i?1:-1)*.55;knee.rotation.x=Math.max(0,-walk*(i?1:-1))*.65;}
  rig.left.rotation.set(-1.36,0,-.62);rig.right.rotation.set(-1.25,.12,-.45);rig.forearms[1].rotation.x=1.3+draw*.35;rig.bow.quaternion.copy(rig.left.quaternion).invert();
  const str=rig.stringGeo.attributes.position;str.setXYZ(1,0,0,-.19*draw);str.needsUpdate=true;
  const cloak=archer.userData.cloak,cp=cloak.mesh.geometry.attributes.position;for(let i=0;i<cp.count;i++){const x=cloak.base[i*3],y=cloak.base[i*3+1],tail=(.455-y)/.91;cp.setXYZ(i,x*(1+tail*.3),y,Math.sin(time*4+x*5)*tail*.035+tail*tail*(p.moving?.16:.04));}cp.needsUpdate=true;cloak.mesh.geometry.computeVertexNormals();
  const wanted=new T.Vector3(px,.9,pz);focus.lerp(wanted,first?1:1-Math.exp(-dt*7));camera.position.set(focus.x+Math.sin(yaw)*distance,focus.y+lift,focus.z+Math.cos(yaw)*distance);camera.lookAt(focus.x,focus.y+.1,focus.z);first=false;
  const enemies=game.enemies.filter(e=>e.hp>0);sync(enemyGroups,enemies,makeEnemy,(o,e)=>{
   o.position.set(wx(e.x),0,wz(e.y));o.rotation.y=Math.atan2(p.x-e.x,p.y-e.y);const data=o.userData,w=Math.sin(time*(e.kind==='brute'?5:9)+data.phase);
   data.body.position.y=Math.abs(w)*.035;data.body.rotation.x=e.kind==='archer'&&e.attack<.8?-.09:0;data.body.rotation.z=w*.025;data.legs.forEach(({leg,arm},i)=>{leg.rotation.x=w*(i%2?1:-1)*.3;if(arm)arm.rotation.x=e.kind==='archer'?-1.2:w*(i%2?-1:1)*.22;});
   const tint=e.burn>0?new T.Color('#ed503f'):e.poison>0?new T.Color('#9450d6'):e.slow>0?new T.Color('#609fec'):null;
   for(const {m,color} of data.clones){m.color.copy(color);if(tint)m.color.lerp(tint,.55);m.emissive.set(e.hitFlash>0?'#bfae80':tint||'#000000');m.emissiveIntensity=e.hitFlash>0?.75:tint?.18:0;}
  });
  sync(arrows,[...game.bullets,...game.hostile],makeArrow,(o,b)=>{o.position.set(wx(b.x),1.12,wz(b.y));o.rotation.y=Math.atan2(b.vx,b.vy);});
  sync(loots,game.pickups,l=>{const g=new T.Group(),m=l.kind==='coin'?palette.gold:l.kind==='xp'?palette.ice:palette.fire;mesh(g,l.kind==='coin'?cylinder:crystal,m,0,0,0,.06,.09,.06,false);return g;},(o,l)=>{o.position.set(wx(l.x),.16+Math.sin(time*3+l.x)*.035,wz(l.y));o.rotation.y=time;});
  sync(effects,game.effects,e=>{const g=new T.Group(),m=palette[e.element]||palette.physical;for(let i=0;i<8;i++){const a=i*Math.PI/4;mesh(g,crystal,m,Math.cos(a),.1,Math.sin(a),.045,.11,.045,false);}flat(g,ring,m,0,.025,0,.7);return g;},(o,e)=>{const progress=1-e.life/(e.maxLife||.5);o.position.set(wx(e.x),.04+progress*.14,wz(e.y));o.scale.setScalar(Math.max(.05,(e.r||25)/100*(.4+progress*.7)));o.rotation.y=progress*.5;});
  sync(hazards,game.hazards,h=>{const g=new T.Group();flat(g,ring,dangerMaterial,0,.035,0,1);if(h.shape==='line')mesh(g,box,dangerMaterial,0,.024,.5,.11,.006,1,false);return g;},(o,h)=>{o.position.set(wx(h.x),0,wz(h.y));if(h.shape==='line'){o.rotation.y=Math.atan2(h.tx-h.x,h.ty-h.y);o.scale.set(.6,1,Math.hypot(h.tx-h.x,h.ty-h.y)/100);}else o.scale.setScalar(h.r/100);});
  motes.rotation.y=Math.sin(time*.04)*.07;motes.position.y=Math.sin(time*.3)*.15;lantern.rotation.z=Math.sin(time*1.2)*.035;
  if(high)composer.render();else renderer.render(scene,camera);
  feedback.clearRect(0,0,w,h);drawCombatFeedback(feedback,game,(x,y,height)=>{point.set(wx(x),height,wz(y)).project(camera);if(point.z< -1||point.z>1)return null;return{x:(point.x+1)*w/2,y:(1-point.y)*h/2};},w,h,e=>e.kind==='brute'?1.95:e.kind==='archer'?1.8:.95);
 }
 const dangerMaterial=basic('#f06852',{transparent:true,opacity:.6,depthWrite:false});
 return{render,look(dx,dy){yaw-=dx*.005;lift=T.MathUtils.clamp(lift+dy*.018,1.8,8);},zoom(delta){distance=T.MathUtils.clamp(distance+delta*.008,4.4,13);},movement(x,y){return{moveX:x*Math.cos(yaw)+y*Math.sin(yaw),moveY:y*Math.cos(yaw)-x*Math.sin(yaw)};},setQuality(value){high=value;renderer.shadowMap.enabled=value;renderer.setPixelRatio(Math.min(devicePixelRatio||1,value?1.5:1));composer.setPixelRatio(renderer.getPixelRatio());if(width){renderer.setSize(width,height,false);composer.setSize(width,height);}grass.count=value?4700:2200;flowers.count=value?500:180;},dispose(){for(const m of mats)m.dispose();for(const m of dynamicMaterials)m.dispose();for(const o of enemyGroups.values())for(const g of o.userData.ownedGeos||[])g.dispose();for(const g of geos)g.dispose();for(const t of textures)t.dispose();for(const i of instances)i.dispose();sun.shadow.map?.dispose();for(const pass of composer.passes)pass.dispose?.();composer.dispose();renderer.dispose();}};
}
