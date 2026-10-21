import * as T from 'three';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';

// The trial's articulated archer, shared with the full campaign's art direction.
export function createStyledActors({geometry:geo,mat:material,mesh,materials}){
 const sphere=geo(new T.SphereGeometry(1,14,10)),box=geo(new T.BoxGeometry(1,1,1)),cylinder=geo(new T.CylinderGeometry(1,1,1,10)),cone=geo(new T.ConeGeometry(1,1,9)),crystal=geo(new T.OctahedronGeometry(1)),capsule=geo(new T.CapsuleGeometry(.1,.35,4,8));
 const shared={cloth:material('#2a6255'),clothLight:material('#578875'),clothDark:material('#163f3a'),skin:material('#e5b794'),leather:material('#67462f'),boot:material('#3c352e'),bone:material('#dfd6ae'),metal:material('#bac5b5',{metalness:.65,roughness:.3}),black:material('#172722'),gold:material('#d1ae65',{metalness:.5,roughness:.38}),eye:material('#e8d7a6',{emissive:'#e8d7a6',emissiveIntensity:.8}),moss:material('#739052'),wood:material('#514432'),stone:material('#758779'),fire:material('#ff334d',{emissive:'#ff334d',emissiveIntensity:.75}),ice:material('#72c4ed',{emissive:'#438bde',emissiveIntensity:.4}),poison:material('#a765e2',{emissive:'#993bd8',emissiveIntensity:.4}),physical:material('#f4dc9e',{emissive:'#eac272',emissiveIntensity:.35})};
 const group=(parent,x=0,y=0,z=0)=>{const g=new T.Group();g.position.set(x,y,z);parent.add(g);return g;};
 const curveMesh=(parent,points,r,m)=>mesh(parent,geo(new T.TubeGeometry(new T.CatmullRomCurve3(points.map(v=>new T.Vector3(...v))),16,r,6)),m);
 function makeArcher(character){
  const palette={...shared,cloth:material(character.id==='ranger'?'#2a6255':character.color),clothLight:material(character.id==='ranger'?'#578875':character.hood),clothDark:material(new T.Color(character.id==='ranger'?'#163f3a':character.color).multiplyScalar(.55))};
  const root=new T.Group(),body=group(root,0,.8,0),hips=group(root,0,.72,0);root.userData.body=body;
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
  const stringGeo=geo(new T.BufferGeometry());stringGeo.setAttribute('position',new T.BufferAttribute(new Float32Array([0,-.55,0,0,0,0,0,.55,0]),3));const stringMat=new T.LineBasicMaterial({color:'#e2d5ae'});materials.push(stringMat);bow.add(new T.Line(stringGeo,stringMat));
  root.userData.rig={body,head,hips,legs,left,right,forearms,bow,stringGeo};
  if(character.id==='scout'){for(const side of [-1,1]){const ribbon=mesh(body,box,palette.clothLight,side*.16,.26,-.24,.1,.55,.025);ribbon.rotation.x=-.35;}const plume=mesh(head,cone,palette.bone,.15,.34,-.1,.04,.42,.04);plume.rotation.z=-.5;}
  if(character.id==='warden'){for(const side of [-1,1]){mesh(body,sphere,shared.metal,side*.32,.53,0,.22,.13,.25);mesh(head,cone,shared.gold,side*.16,.36,-.02,.035,.28,.035);}mesh(body,box,shared.metal,0,.32,.17,.33,.3,.045);mesh(body,box,shared.gold,0,.36,.2,.06,.22,.02);}
  if(character.id==='hex'){const moon=mesh(body,geo(new T.TorusGeometry(.18,.025,5,24,Math.PI*1.5)),shared.poison,0,1.22,0);moon.rotation.z=-.5;for(const side of [-1,1])mesh(body,crystal,shared.ice,side*.29,.57,-.04,.07,.2,.07);}
  if(character.id==='tinker'){mesh(head,cylinder,shared.leather,0,.3,-.03,.2,.29,.2);mesh(head,cylinder,shared.gold,0,.18,-.03,.26,.035,.26);for(const side of [-1,1])mesh(head,sphere,shared.gold,side*.075,.07,.21,.064,.052,.025);mesh(body,box,shared.gold,0,.3,-.3,.35,.4,.14);for(let i=0;i<8;i++){const a=i*Math.PI/4,gear=mesh(body,box,shared.leather,Math.cos(a)*.14,.3+Math.sin(a)*.14,-.39,.065,.065,.03);gear.rotation.z=a;}}
  const nocked=group(body,-.27,.42,.42);mesh(nocked,box,shared.bone,0,0,0,.014,.014,.5);const point=mesh(nocked,cone,shared.physical,0,0,.31,.035,.13,.035);point.rotation.x=Math.PI/2;root.userData.rig.nocked=nocked;root.userData.rig.point=point;
  const hitMaterials=new Map();root.traverse(o=>{if(!o.isMesh)return;const original=o.material;if(!hitMaterials.has(original)){const clone=original.clone();materials.push(clone);hitMaterials.set(original,{material:clone,emissive:original.emissive.clone(),intensity:original.emissiveIntensity});}o.material=hitMaterials.get(original).material;});root.userData.hitMaterials=[...hitMaterials.values()];
  return root;
 }

 const templates=new Map();
 function makeEnemy(e){
  const key=e.kind+(e.kind==='boss'?e.tier:'')+(e.elite?'elite':'');
  if(!templates.has(key)){
   const root=new T.Group(),body=group(root),p=shared;body.name='body';
   if(e.kind==='brute'||e.kind==='juggernaut'){
    const metal=e.kind==='juggernaut',shell=metal?p.metal:p.stone;
    mesh(body,sphere,shell,0,.8,0,.52,.59,.37);mesh(body,sphere,p.moss,-.15,1.2,-.04,.43,.2,.32);mesh(body,box,p.wood,0,1.32,.12,.45,.38,.35);
    for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.13,1.35,.303,.038,.022,.012);mesh(body,sphere,shell,side*.58,.62,0,.22,.43,.23);mesh(body,sphere,p.moss,side*.58,1.02,-.03,.24,.13,.23);mesh(body,sphere,shell,side*.25,.2,.04,.19,.25,.24);}
    if(metal){for(const side of [-1,1]){mesh(body,box,p.leather,side*.4,1.24,.03,.33,.25,.43);mesh(body,cone,p.gold,side*.48,1.58,.02,.09,.4,.09);}mesh(body,box,p.gold,0,.8,.37,.14,.48,.03);body.scale.setScalar(1.08);}
    else for(let i=0;i<3;i++){const branch=mesh(body,cylinder,p.wood,(i-1)*.25,1.66,-.06,.045,.48,.045);branch.rotation.z=(i-1)*.7;mesh(body,sphere,p.moss,(i-1)*.34,1.86,-.06,.16,.08,.12);}
   }else if(e.kind==='archer'||e.kind==='shaman'||e.kind==='stalker'){
    const caster=e.kind==='shaman',stalker=e.kind==='stalker',cloak=caster||stalker?p.poison:p.moss;
    mesh(body,sphere,p.wood,0,.61,0,.22,.35,.17);mesh(body,cone,cloak,0,.48,0,.32,.6,.28);mesh(body,sphere,p.bone,0,1.12,.02,.21,.23,.18);mesh(body,sphere,p.wood,0,1.22,-.05,.26,.25,.22);mesh(body,sphere,p.bone,0,1.1,.14,.15,.14,.05);
    for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.065,1.13,.193,.035,.023,.008);const arm=mesh(body,capsule,p.wood,side*.29,.69,.1,.7,.9,.7);arm.rotation.x=-.8;mesh(body,capsule,p.wood,side*.12,.2,0,.7,.7,.7);curveMesh(body,[[side*.16,1.35,0],[side*.29,1.58,-.06],[side*.48,1.66,-.03]],.035,p.wood);}
    if(caster){mesh(body,cylinder,p.wood,.4,.85,.1,.025,1.65,.025);mesh(body,crystal,p.poison,.4,1.82,.1,.15,.25,.15);mesh(body,cone,p.poison,0,1.56,-.04,.27,.34,.24);}
    else if(stalker){for(const side of [-1,1]){const blade=mesh(body,cone,p.metal,side*.3,.65,.39,.055,.55,.035);blade.rotation.x=Math.PI/2;}mesh(body,cone,p.poison,0,1.49,-.08,.25,.4,.25);}
    else{curveMesh(body,[[-.4,.45,.24],[-.59,.8,.3],[-.4,1.15,.24]],.025,p.wood);curveMesh(body,[[-.4,.45,.24],[-.4,1.15,.24]],.006,p.bone);}
   }else if(e.kind==='boar'){
    mesh(body,sphere,p.leather,0,.42,0,.37,.32,.58);mesh(body,sphere,p.wood,0,.48,.4,.29,.28,.27);mesh(body,sphere,p.skin,0,.33,.67,.24,.14,.15);
    for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.15,.55,.59,.027,.023,.012);const tusk=mesh(body,cone,p.bone,side*.24,.37,.66,.06,.32,.05);tusk.rotation.z=-side*.4;const ear=mesh(body,cone,p.leather,side*.22,.81,.31,.11,.27,.085);ear.rotation.z=side*.4;for(const z of [-.32,.32])mesh(body,capsule,p.boot,side*.25,.15,z,.8,.65,.8);}
    for(let i=0;i<6;i++)mesh(body,cone,p.wood,0,.76,-.4+i*.13,.065,.22,.065);
   }else if(e.kind==='wisp'){
    mesh(body,sphere,p.ice,0,.78,0,.22,.29,.22);mesh(body,cone,p.ice,0,.42,0,.17,.48,.17).rotation.z=Math.PI;for(const side of [-1,1])mesh(body,sphere,p.eye,side*.075,.82,.2,.026,.028,.012);for(let i=0;i<5;i++){const a=i*Math.PI*2/5;mesh(body,crystal,p.ice,Math.cos(a)*.32,.8,Math.sin(a)*.32,.05,.18,.05);}
   }else if(e.kind==='bomber'){
    mesh(body,sphere,p.leather,0,.5,0,.28,.36,.26);mesh(body,sphere,p.moss,0,.78,-.04,.35,.16,.3);mesh(body,sphere,p.bone,0,.64,.2,.16,.14,.12);for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.065,.69,.3,.022,.018,.01);mesh(body,capsule,p.boot,side*.15,.15,0,.65,.65,.65);}mesh(body,sphere,p.fire,.31,.7,.25,.17,.17,.17);curveMesh(body,[[.31,.85,.25],[.35,1.02,.25],[.3,1.08,.25]],.015,p.gold);mesh(body,crystal,p.fire,.3,1.1,.25,.04,.09,.04);
   }else if(e.kind==='boss'){
    if(e.tier===1){
     mesh(body,sphere,p.wood,0,1.2,0,.7,.9,.48);mesh(body,sphere,p.moss,0,1.9,.06,.46,.37,.35);for(const side of [-1,1]){mesh(body,capsule,p.wood,side*.74,1.2,0,2,2.1,2);mesh(body,sphere,p.moss,side*.77,1.65,-.04,.33,.2,.3);mesh(body,sphere,p.wood,side*.32,.28,0,.28,.33,.36);mesh(body,sphere,p.eye,side*.13,1.98,.37,.05,.035,.015);curveMesh(body,[[side*.27,2.12,0],[side*.42,2.62,-.02],[side*.7,2.83,-.08]],.065,p.wood);curveMesh(body,[[side*.4,2.5,-.01],[side*.72,2.57,0]],.04,p.wood);mesh(body,cone,p.gold,side*.7,2.9,-.08,.08,.21,.08);}
    }else if(e.tier===2){
     mesh(body,crystal,p.ice,0,1.3,0,.57,1,.5);mesh(body,sphere,p.black,0,1.82,.1,.27,.24,.2);for(const side of [-1,1])mesh(body,sphere,p.eye,side*.085,1.86,.28,.035,.03,.015);for(let i=0;i<7;i++){const a=i*Math.PI*2/7;mesh(body,crystal,p.ice,Math.cos(a)*.64,1.62,Math.sin(a)*.64,.12,.4,.12);mesh(body,crystal,p.metal,Math.cos(a)*.26,2.43,Math.sin(a)*.26,.06,.33,.06);}const halo=mesh(body,geo(new T.TorusGeometry(.65,.045,6,32)),p.ice,0,.55,0);halo.rotation.x=Math.PI/2;
    }else if(e.tier===3){
     mesh(body,cone,p.poison,0,1.02,0,.83,1.7,.65);mesh(body,sphere,p.black,0,2.1,.05,.35,.38,.3);for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.11,2.14,.33,.04,.03,.015);mesh(body,crystal,p.poison,side*.72,1.5,0,.21,.45,.21);}for(let i=0;i<5;i++){const a=i*Math.PI*2/5;mesh(body,cone,p.gold,Math.cos(a)*.3,2.75,Math.sin(a)*.3,.075,.5,.075);}mesh(body,crystal,p.poison,0,2.95,0,.1,.25,.1);
    }else{
     mesh(body,box,p.leather,0,1.2,0,1.15,1.6,.7);mesh(body,box,p.gold,0,2.23,0,.57,.44,.48);for(const side of [-1,1]){mesh(body,sphere,p.metal,side*.75,1.7,0,.4,.4,.4);mesh(body,box,p.leather,side*.77,1.08,0,.34,.9,.4);mesh(body,box,p.metal,side*.32,.25,.06,.39,.45,.51);mesh(body,sphere,p.eye,side*.12,2.3,.25,.05,.03,.015);}const gear=mesh(body,geo(new T.TorusGeometry(.3,.09,8,24)),p.gold,0,1.35,.4);for(let i=0;i<10;i++){const a=i*Math.PI/5;const tooth=mesh(body,box,p.gold,Math.cos(a)*.39,1.35+Math.sin(a)*.39,.4,.13,.13,.12);tooth.rotation.z=a;}mesh(body,cylinder,p.gold,0,2.72,0,.22,.45,.22);mesh(body,crystal,p.fire,0,3.01,0,.1,.22,.1);
    }
   }else{
    mesh(body,sphere,p.wood,0,.38,0,.36,.28,.4);mesh(body,sphere,p.moss,0,.51,-.04,.4,.19,.34);mesh(body,sphere,p.bone,0,.3,.31,.22,.15,.17);for(const side of [-1,1]){mesh(body,sphere,p.eye,side*.15,.42,.342,.035,.025,.012);for(const z of [-.18,.2]){const leg=mesh(body,capsule,p.wood,side*.36,.17,z,.62,.65,.62);leg.rotation.z=-side*.65;}const horn=mesh(body,cone,p.bone,side*.22,.57,.24,.055,.23,.055);horn.rotation.z=-side*.65;}
   }
   if(e.elite){const crownY=({brute:1.9,juggernaut:1.9,archer:1.55,shaman:1.9,stalker:1.7,boar:.9,wisp:1.1,bomber:1.12}[e.kind]||.8)+.1;for(const side of [-1,1])mesh(body,cone,p.gold,side*.18,crownY,-.05,.06,.26,.06);}
   // Bake each silhouette into a few shared material meshes. A horde does not
   // allocate a separate geometry or draw call for every toe and leaf.
   root.updateMatrixWorld(true);const batches=new Map();body.traverse(o=>{if(!o.isMesh)return;const g=(o.geometry.index?o.geometry.toNonIndexed():o.geometry.clone()).applyMatrix4(o.matrixWorld);for(const name of Object.keys(g.attributes))if(!['position','normal'].includes(name))g.deleteAttribute(name);if(!batches.has(o.material))batches.set(o.material,[]);batches.get(o.material).push(g);});body.clear();body.position.set(0,0,0);body.quaternion.identity();body.scale.setScalar(1);
   for(const [m,list] of batches){const merged=geo(mergeGeometries(list,false));for(const g of list)g.dispose();mesh(body,merged,m);}
   templates.set(key,root);
  }
  const result=templates.get(key).clone(true);result.userData.body=result.getObjectByName('body');return result;
 }
 function animateArcher(root,p,time,interval,hitFlash=false){
  const r=root.userData.rig,walk=p.moving?Math.sin(time*11):0,draw=1-Math.min(1,p.fireTimer/Math.max(.1,interval));
  r.body.position.y=.8+Math.abs(walk)*.025+Math.sin(time*2)*.009;r.body.rotation.z=walk*.025;r.head.rotation.z=-walk*.025;
  r.legs.forEach(({leg,knee},i)=>{leg.rotation.x=walk*(i?1:-1)*.55;knee.rotation.x=Math.max(0,-walk*(i?1:-1))*.65;});
  r.left.rotation.set(-1.36,0,-.62);r.right.rotation.set(-1.25,.12,-.45);r.forearms[1].rotation.x=1.3+draw*.35;r.bow.quaternion.copy(r.left.quaternion).invert();r.stringGeo.attributes.position.setXYZ(1,0,0,-.19*draw);r.stringGeo.attributes.position.needsUpdate=true;r.nocked.visible=p.fireTimer<interval*.8;r.point.material=shared[p.element]||shared.physical;
  const cloak=root.userData.cloak,a=cloak.mesh.geometry.attributes.position;for(let i=0;i<a.count;i++){const x=cloak.base[i*3],y=cloak.base[i*3+1],tail=(.455-y)/.91;a.setXYZ(i,x*(1+tail*.3),y,Math.sin(time*4+x*5)*tail*.035+tail*tail*(p.moving?.16:.04));}a.needsUpdate=true;cloak.mesh.geometry.computeVertexNormals();
  for(const entry of root.userData.hitMaterials){entry.material.emissive.copy(entry.emissive);entry.material.emissiveIntensity=entry.intensity;if(hitFlash){entry.material.emissive.set('#efb4a0');entry.material.emissiveIntensity=.3;}}
 }
 const foxFur=material('#c78e54'),wolfFur=material('#7c9398'),wolfLight=material('#b6c8c5'),beetleShell=material('#65917b',{metalness:.4,roughness:.34});
 const petTemplates=new Map();
 function makePet(pet){
  if(petTemplates.has(pet.kind)){const root=petTemplates.get(pet.kind).clone(true);root.userData.legs=[];root.traverse(o=>{if(o.name==='pet-leg')root.userData.legs.push(o);if(o.name==='pet-tail')root.userData.tail=o;});return root;}
  const root=new T.Group(),legs=[];
  if(pet.kind==='collector'){
   mesh(root,sphere,beetleShell,0,.25,0,.23,.17,.31);mesh(root,box,shared.gold,0,.32,0,.025,.16,.54);mesh(root,sphere,shared.black,0,.28,.27,.12,.1,.12);mesh(root,crystal,shared.physical,0,.49,-.08,.12,.16,.12);
   for(const side of [-1,1]){for(const z of [-.17,0,.17]){const leg=group(root,side*.2,.18,z);curveMesh(leg,[[0,0,0],[side*.12,-.02,.015],[side*.16,-.15,.04]],.02,shared.leather);legs.push(leg);}mesh(root,sphere,shared.eye,side*.065,.31,.36,.027,.025,.012);curveMesh(root,[[side*.06,.35,.28],[side*.1,.5,.31]],.012,shared.gold);}
  }else{
   const wolf=pet.kind==='wolf',fur=wolf?wolfFur:foxFur,light=wolf?wolfLight:shared.bone;
   mesh(root,sphere,fur,0,.32,0,wolf?.3:.25,wolf?.25:.2,wolf?.51:.43);mesh(root,sphere,light,0,.3,.26,.17,.17,.21);mesh(root,sphere,fur,0,.52,.35,wolf?.22:.19,.2,.2);mesh(root,sphere,light,0,.46,.53,.13,.1,.15);mesh(root,sphere,shared.black,0,.48,.65,.045,.03,.025);
   for(const side of [-1,1]){const ear=mesh(root,cone,fur,side*.12,.77,.31,.085,.25,.075);ear.rotation.z=-side*.18;mesh(root,cone,light,side*.12,.77,.35,.047,.15,.025);mesh(root,sphere,wolf?shared.ice:shared.black,side*.105,.56,.51,.023,.023,.015);for(const z of [-.25,.25]){const leg=group(root,side*.15,.23,z);mesh(leg,capsule,fur,0,-.08,0,.65,.6,.65);mesh(leg,sphere,shared.boot,0,-.18,.025,.065,.055,.09);legs.push(leg);}}
   const tail=mesh(root,cone,fur,0,.38,-.52,wolf?.13:.16,.57,.15);tail.rotation.x=-.8;const tip=mesh(root,cone,light,0,.57,-.71,.1,.25,.1);tip.rotation.x=-.8;
   const collar=mesh(root,geo(new T.TorusGeometry(.16,.025,5,18)),shared.gold,0,.43,.28);root.userData.tail=tail;
  }
  for(const leg of legs)leg.name='pet-leg';if(root.userData.tail)root.userData.tail.name='pet-tail';root.userData={};petTemplates.set(pet.kind,root);return makePet(pet);
 }
 function animatePet(root,pet,time){root.userData.legs.forEach((leg,i)=>{leg.rotation.x=Math.sin(time*(pet.kind==='collector'?15:10)+i*Math.PI)*.28;});if(root.userData.tail)root.userData.tail.rotation.z=Math.sin(time*5)*.14;}
 return{makeArcher,makeEnemy,animateArcher,makePet,animatePet};
}
