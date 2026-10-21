import {drawCombatFeedback} from './combat-feedback.js';
import * as THREE from 'three';
import { WORLD, REGIONS, CHARACTERS, ELEMENT_COLORS, isBossWave } from './game.js';
import { SCENERY, SOLIDS } from './world.js';

// A perspective camera follows the ranger through a continuous, explorable world.
export function create3DRenderer(canvas, game) {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: 'high-performance' });
  const feedbackCanvas=document.createElement('canvas');feedbackCanvas.className='combat-feedback';feedbackCanvas.setAttribute('aria-hidden','true');canvas.after(feedbackCanvas);
  const feedback=feedbackCanvas.getContext('2d'),labelPoint=new THREE.Vector3();
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.25));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#8caeab');
  scene.fog = new THREE.Fog('#8caeab', 10, 30);
  const camera = new THREE.PerspectiveCamera(58, 1.5, .1, 75);
  let cameraYaw = 0, cameraLift = 2.5;
  const cameraFocus = new THREE.Vector3(0, .65, 0);
  camera.position.set(0, 3.15, 5.3); camera.lookAt(cameraFocus);
  scene.add(new THREE.HemisphereLight('#d7ecda', '#374637', 2.1));
  const sun = new THREE.DirectionalLight('#ffe2ae', 3.1);
  sun.position.set(-4, 10, -5); sun.castShadow = true;
  sun.shadow.mapSize.set(512, 512);
  Object.assign(sun.shadow.camera, { left: -7, right: 7, top: 6, bottom: -6, near: .1, far: 24 });
  sun.shadow.normalBias = .04; sun.shadow.bias = -.0002;
  scene.add(sun);
  const rim = new THREE.DirectionalLight('#9ccdc8', 1.1); rim.position.set(4, 5, 5); scene.add(rim);
  const geometries = [], materials = [], dynamicMaterials=new Set();
  const geometry = g => { geometries.push(g); return g; };
  const mat = (color, extra = {}) => { const m = new THREE.MeshStandardMaterial({ color, roughness: .86, flatShading: true, ...extra }); materials.push(m); return m; };
  const glowing = color => mat(color, { emissive: color, emissiveIntensity: 1.4 });
  const sphere = geometry(new THREE.IcosahedronGeometry(1, 0));
  const disc=geometry(new THREE.CircleGeometry(1,48));
  const crescent=geometry(new THREE.TorusGeometry(.3,.045,5,28,Math.PI*1.55));
  const box = geometry(new THREE.BoxGeometry(1, 1, 1));
  const cone = geometry(new THREE.ConeGeometry(1, 1, 7));
  const cylinder = geometry(new THREE.CylinderGeometry(1, 1, 1, 8));
  const bowGeo = geometry(new THREE.TorusGeometry(.27, .024, 5, 16, Math.PI));
  const crystal = geometry(new THREE.OctahedronGeometry(1));
  const ringGeo = geometry(new THREE.RingGeometry(.89, 1, 48));
  const colors = {
    grass: mat('#354d34'), soil: mat('#3e3d2b'), stone: mat('#697566'), trunk: mat('#675039'),
    pine: [mat('#264b36'), mat('#386044'), mat('#4c7150')],
    cape: mat('#97af68'), hood: mat('#c2ce91'), dark: mat('#243627'), skin: mat('#e4bc83'),
    gold: glowing('#ffcb69'), xp: glowing('#b4a0f2'), heal: glowing('#9be39a'), bolt: glowing('#ffdd94'),
    hostile: glowing('#bd9eeb'), wood: mat('#675639'), leaf: mat('#a0b26d'), frost: mat('#96d9e7'),
    void: mat('#6b427c'), eyes: glowing('#ffe6a1'), edge: mat('#6b7047'),
    fire: mat(ELEMENT_COLORS.fire,{emissive:ELEMENT_COLORS.fire,emissiveIntensity:.35}), poison: mat(ELEMENT_COLORS.poison,{emissive:ELEMENT_COLORS.poison,emissiveIntensity:.35}), ice: mat(ELEMENT_COLORS.ice,{emissive:ELEMENT_COLORS.ice,emissiveIntensity:.35}), leather: mat('#775039'), feather: mat('#e8dfb9'), mushroom: mat('#ca9869'), water: mat('#507f72', { metalness: .3, roughness: .25 })
  };
  const mesh = (parent, geo, material, x, y, z, sx = 1, sy = sx, sz = sx, shadow = true) => {
    const m = new THREE.Mesh(geo, material); m.position.set(x, y, z); m.scale.set(sx, sy, sz); m.castShadow = shadow; m.receiveShadow = true; parent.add(m); return m;
  };
  const flatRing = (parent, material, radius, y = .015) => {
    const m = mesh(parent, ringGeo, material, 0, y, 0, radius, radius, radius, false); m.rotation.x = -Math.PI / 2; return m;
  };
  let seed = 47382;
  const random = () => { seed = seed * 16807 % 2147483647; return (seed - 1) / 2147483646; };
  const wx=x=>(x-WORLD.width/2)/100, wz=y=>(y-WORLD.height/2)/100;
  mesh(scene, box, colors.soil, 0, -.3, 0, WORLD.width/100+2, .55, WORLD.height/100+2);
  mesh(scene, box, colors.grass, 0, -.025, 0, WORLD.width/100+2, .08, WORLD.height/100+2);
  for (const r of REGIONS.slice(1)) {
    const material=mat(r.color);mesh(scene,cylinder,material,wx(r.x),.008,wz(r.y),r.r/100,.035,r.r/100);
  }
  // Visible trails lead from the central camp toward the three distant biomes.
  for(const region of REGIONS.slice(1)) {
    const x=wx(region.x),z=wz(region.y),length=Math.hypot(x,z);
    const path=mesh(scene,box,colors.soil,x/2,.035,z/2,2.5,.025,length,false);path.rotation.y=Math.atan2(x,z);
  }
  const boundaryMat=mat('#91aa7a',{emissive:'#526b50'});
  for(const z of [-WORLD.height/200,WORLD.height/200])mesh(scene,box,boundaryMat,0,.12,z,WORLD.width/100,.25,.1);
  for(const x of [-WORLD.width/200,WORLD.width/200])mesh(scene,box,boundaryMat,x,.12,0,.1,.25,WORLD.height/100);
  function tree(x,z,s=1,ice=false) {
    const group=new THREE.Group();group.position.set(x,0,z);scene.add(group);
    mesh(group,cylinder,colors.trunk,0,.45*s,0,.09*s,.9*s,.09*s);
    for(let i=0;i<3;i++)mesh(group,cone,ice?colors.frost:colors.pine[i],0,(.9+i*.5)*s,0,(.72-i*.14)*s,1.3*s,(.72-i*.14)*s);
  }
  for(const o of SCENERY){
    const x=wx(o.x),z=wz(o.y),s=o.scale;
    if(o.type==='tree')tree(x,z,s,Math.hypot(o.x-1000,o.y-1000)<760);
    else mesh(scene,sphere,colors.stone,x,.26*s,z,.3*s,.26*s,.3*s);
  }
  const rune=mat('#bad091',{emissive:'#a5c788',emissiveIntensity:.25});
  flatRing(scene,rune,1.05,.055);
  // The starting camp, with its watch fire and canvas shelter.
  mesh(scene,cone,colors.cape,-1.4,.6,-1.3,.9,1.2,.7).rotation.y=.5;
  for(let i=0;i<5;i++){const a=i*Math.PI*2/5;mesh(scene,sphere,colors.stone,Math.cos(a)*.3,.1,Math.sin(a)*.3-1.1,.14,.12,.14);}
  const campFlame=mesh(scene,crystal,colors.fire,0,.35,-1.1,.18,.4,.18);
  const firelight=new THREE.PointLight('#ffb463',3,4);firelight.position.set(0,.8,-1.1);scene.add(firelight);
  for(const [index,r] of REGIONS.slice(1).entries()) {
    const g=new THREE.Group();g.position.set(wx(r.x),0,wz(r.y));scene.add(g);
    const material=[colors.frost,colors.fire,colors.poison][index];flatRing(g,material,1.7,.065);
    if(index===0) {
      for(const x of [-1,1])mesh(g,box,colors.stone,x,1,0,.35,2,.4);
      mesh(g,box,colors.frost,0,2.1,0,2.6,.3,.45);

    }else if(index===1) {
      mesh(g,cone,colors.wood,0,.6,0,1.4,1.2,1.4);mesh(g,crystal,colors.fire,0,1.4,0,.45,.9,.45);
    }else {
      mesh(g,cylinder,colors.water,0,.07,0,1.5,.04,1.5);
      for(let i=0;i<4;i++){const a=i*Math.PI/2;mesh(g,sphere,colors.poison,Math.cos(a),.25,Math.sin(a),.2,.35,.2);}
    }
  }
  // Batch repeated scenery into instances so trees and grass stay inexpensive.
  scene.updateMatrixWorld(true);
  const batches = new Map();
  scene.traverse(object => {
    if (!object.isMesh) return;
    const key = object.geometry.uuid + object.material.uuid + object.castShadow;
    if (!batches.has(key)) batches.set(key, []);
    batches.get(key).push(object);
  });
  for (const objects of batches.values()) {
    if (objects.length < 2) continue;
    const first = objects[0];
    const instances = new THREE.InstancedMesh(first.geometry, first.material, objects.length);
    instances.castShadow = first.castShadow; instances.receiveShadow = true;
    objects.forEach((object, i) => { instances.setMatrixAt(i, object.matrixWorld); object.removeFromParent(); });
    scene.add(instances);
  }
  const chargeMaterial = mat('#f5ae68', { emissive: '#d47838', transparent: true, opacity: .4, depthWrite: false });
  function makeWayfarer(character) {
    const g=new THREE.Group(),cape=mat(character.color),hood=mat(character.hood);
    const hips=new THREE.Group();g.add(hips);
    const legs=[];
    for(const x of [-.09,.09]) {
      const leg=new THREE.Group();leg.position.set(x,.35,0);hips.add(leg);
      mesh(leg,box,colors.leather,0,-.13,0,.105,.27,.12);
      mesh(leg,box,colors.dark,0,-.3,.04,.13,.12,.22);legs.push(leg);
    }
    mesh(hips,box,cape,0,.55,0,.35,.4,.22);
    mesh(hips,cone,cape,0,.4,-.08,.27,.45,.22);
    mesh(hips,box,colors.leather,0,.39,0,.37,.07,.25);
    mesh(hips,sphere,colors.skin,0,.9,0,.145,.17,.14);
    mesh(hips,sphere,hood,0,.98,-.035,.18,.16,.17);
    mesh(hips,box,colors.dark,0,.89,.115,.17,.04,.04);
    // Quiver and spare arrows on the back.
    mesh(hips,cylinder,colors.leather,.14,.58,-.19,.07,.4,.07).rotation.z=-.2;
    for(let i=0;i<3;i++) {
      mesh(hips,cylinder,colors.wood,.1+i*.035,.9,-.2,.008,.4,.008);
      mesh(hips,box,colors.feather,.1+i*.035,1.08,-.2,.04,.07,.015);
    }
    const bowArm=new THREE.Group();bowArm.position.set(-.21,.7,0);hips.add(bowArm);
    mesh(bowArm,box,cape,0,-.09,.12,.11,.12,.3);
    mesh(bowArm,sphere,colors.skin,0,-.09,.28,.065);
    const bow=new THREE.Group();bow.position.set(0,-.09,.35);bow.rotation.y=Math.PI/2;bowArm.add(bow);
    const bowMesh=mesh(bow,bowGeo,colors.wood,0,0,0);bowMesh.rotation.z=-Math.PI/2;
    const string=mesh(bow,box,colors.feather,0,0,0,.009,.54,.009);
    const drawArm=new THREE.Group();drawArm.position.set(.2,.7,0);hips.add(drawArm);
    mesh(drawArm,box,cape,0,-.06,.12,.1,.13,.29);mesh(drawArm,sphere,colors.skin,0,-.06,.28,.06);
    const readyArrow=makeArrow('physical');readyArrow.position.set(-.2,.61,.28);readyArrow.rotation.y=0;hips.add(readyArrow);
    // Each archer has a different silhouette as well as their own materials.
    if(character.id==='ranger'){for(const x of [-.15,.15])mesh(hips,cone,cape,x,.84,-.16,.11,.38,.06).rotation.z=x*3;mesh(hips,cone,hood,-.1,1.13,-.1,.09,.3,.08).rotation.z=.7;}
    if(character.id==='scout'){mesh(hips,box,hood,0,.79,0,.42,.09,.3);for(const x of [-.13,.13]){const scarf=mesh(hips,box,cape,x,.65,-.3,.1,.5,.04);scarf.rotation.x=-.5;}mesh(hips,cone,hood,.12,1.12,-.08,.035,.36,.035).rotation.z=-.5;}
    if(character.id==='warden'){for(const x of [-.26,.26]){mesh(hips,box,hood,x,.74,0,.23,.2,.33);mesh(hips,cone,colors.gold,x,1.13,0,.045,.32,.045).rotation.z=-x*2;}mesh(hips,box,hood,0,.56,.13,.3,.29,.07);mesh(hips,cylinder,cape,0,.61,-.28,.29,.08,.29).rotation.x=Math.PI/2;mesh(hips,box,hood,0,1.02,.1,.33,.12,.12);}
    if(character.id==='hex'){mesh(hips,cone,cape,0,.32,-.04,.35,.63,.27);mesh(hips,crescent,colors.xp,0,1.35,0,.55,.55,.55);for(const x of [-.2,.2])mesh(hips,crystal,hood,x,.8,-.13,.055,.3,.055);mesh(bow,crystal,colors.xp,0,.28,0,.06,.16,.06);}
    if(character.id==='tinker'){mesh(hips,cylinder,cape,0,1.15,-.025,.18,.27,.18);mesh(hips,cylinder,hood,0,1.04,-.025,.25,.045,.25);for(const x of [-.08,.08])mesh(hips,sphere,colors.gold,x,.96,.14,.06,.055,.035);mesh(hips,box,hood,0,.62,-.26,.31,.36,.17);const gear=flatRing(hips,colors.gold,.21,.62);gear.rotation.x=0;gear.position.z=-.37;for(let i=0;i<8;i++){const a=i*Math.PI/4;mesh(hips,box,hood,Math.cos(a)*.23,.62+Math.sin(a)*.23,-.37,.07,.07,.06);}for(const z of [-.18,.18])mesh(bow,crystal,cape,0,z,0,.06,.1,.06);}
    g.userData={hips,legs,bowArm,drawArm,string,readyArrow};return g;
  }
  function makeArrow(element='physical',pet=false) {
    const g=new THREE.Group(), tip=element==='fire'?colors.fire:element==='ice'?colors.ice:element==='poison'?colors.poison:colors.feather;
    if(pet){mesh(g,crystal,tip,0,0,0,.09,.09,.22);return g;}
    // Arrow points along local +Z; shaft, broadhead, and fletching stay visible in flight.
    const shaft=mesh(g,cylinder,colors.wood,0,0,0,.012,.48,.012,false);shaft.rotation.x=Math.PI/2;
    const head=mesh(g,cone,tip,0,0,.3,.045,.14,.045,false);head.rotation.x=Math.PI/2;
    for(const x of [-.025,.025])mesh(g,box,colors.feather,x,0,-.19,.015,.07,.12,false);
    if(element!=='physical')mesh(g,sphere,tip,0,0,-.06,.035,.035,.19,false);
    return g;
  }
  const effectMaterial=(color,extra={})=>{const m=new THREE.MeshBasicMaterial({color,toneMapped:false,...extra});materials.push(m);return m;};
  const fxColors=Object.fromEntries(Object.entries({mythic:'#ff405a',wind:'#70dcff',hare:'#9aeb84',shell:'#ffd06e',bramble:'#85da59',worldroot:'#ff405a',rapid:'#ffca55',moon:'#c79aff',flock:'#8fdefa',thunder:'#72cfff',lightning:'#ff405a',phoenix:'#ff405a',harvest:'#85e38b',howl:'#a7dcff',claw:'#fff0cd',echo:'#d19cff',clock:'#52ddd2',gears:'#f4c65b',embers: ELEMENT_COLORS.fire,'enemy-blast':'#ff526b','hex-blast':'#de5fff'}).map(([key,color])=>[key,effectMaterial(color)]));
  const heroes=new Map(CHARACTERS.map(c=>{const model=makeWayfarer(c);model.visible=false;scene.add(model);return [c.id,model];}));let player=heroes.get('ranger');
  const clockAura=new THREE.Group();scene.add(clockAura);for(const r of [2.25,2.4])flatRing(clockAura,fxColors.clock,r,.11);for(let i=0;i<12;i++){const a=i*Math.PI/6;mesh(clockAura,box,fxColors.shell,Math.cos(a)*2.3,.12,Math.sin(a)*2.3,.045,.02,.15,false).rotation.y=-a;}
  const skillShell=mesh(scene,sphere,effectMaterial('#ffd06e',{transparent:true,opacity:.4,wireframe:true,depthWrite:false}),0,0,0,.6,.75,.6,false);
  const thornAura=new THREE.Group();scene.add(thornAura);
  for(let i=0;i<12;i++){const a=i*Math.PI/6;const thorn=mesh(thornAura,cone,fxColors.bramble,Math.cos(a)*.53,.15,Math.sin(a)*.53,.055,.35,.055,false);thorn.rotation.z=Math.cos(a)*.4;}
  const sprintAura=new THREE.Group();scene.add(sprintAura);
  for(const x of [-.22,0,.22]){const ribbon=mesh(sprintAura,cone,fxColors.hare,x,.16,-.35,.045,.8,.045,false);ribbon.rotation.x=-Math.PI/2;}
  const rapidAura=new THREE.Group();scene.add(rapidAura);
  for(let i=0;i<6;i++){const a=i*Math.PI/3,arrow=makeArrow('physical');arrow.position.set(Math.cos(a)*.65,.65+Math.sin(a)*.15,Math.sin(a)*.65);arrow.rotation.y=-a;rapidAura.add(arrow);}
  const moonAura=mesh(scene,crescent,fxColors.moon,0,0,0,.9,.9,.9,false);
  const dawnAura=new THREE.Group();scene.add(dawnAura);
  for(let i=0;i<3;i++){const sun=mesh(dawnAura,sphere,fxColors.mythic,0,.55,0,.14,.14,.14,false);flatRing(sun,fxColors.mythic,1.4,.025);}
  const dangerMaterial=effectMaterial('#ff3d51',{transparent:true,opacity:.95,depthWrite:false});
  const dangerFill=effectMaterial('#ff3d51',{transparent:true,opacity:.3,depthWrite:false});
  function makeEffect(e){
    const g=new THREE.Group(),material=fxColors[e.type]||(e.element==='fire'?colors.fire:e.element==='ice'?colors.ice:e.element==='poison'?colors.poison:colors.gold);
    if(['clock','gears'].includes(e.type)){for(const r of [.5,1])flatRing(g,material,r,.1);for(let i=0;i<12;i++){const a=i*Math.PI/6;mesh(g,box,material,Math.cos(a),.14,Math.sin(a),.15,.06,.15,false);}}else if(['lightning','thunder'].includes(e.type)){
      flatRing(g,material,1,.035);
      for(let i=0;i<6;i++){const bolt=mesh(g,box,material,(i%2?.12:-.12),i*.55,0,.08,.75,.07,false);bolt.rotation.z=i%2?.4:-.4;}
    }else if(['bramble','worldroot'].includes(e.type)){
      flatRing(g,material,1,.025);for(let i=0;i<12;i++){const a=i*Math.PI/6,thorn=mesh(g,cone,material,Math.cos(a)*.75,.18,Math.sin(a)*.75,.07,.6,.07,false);thorn.rotation.z=Math.cos(a)*.55;const root=mesh(g,box,colors.wood,Math.cos(a)*.45,.02,Math.sin(a)*.45,.04,.04,.8,false);root.rotation.y=-a+Math.PI/2;}
    }else if(e.type==='quake'){
      for(const r of [.35,.65,1])flatRing(g,material,r,.025);for(let i=0;i<12;i++){const a=i*Math.PI/6;mesh(g,crystal,material,Math.cos(a)*.85,.2,Math.sin(a)*.85,.1,.5,.1,false);}
    }else if(e.type==='moon'){
      mesh(g,crescent,material,0,1.5,0,1.3,1.3,1.3,false);for(let i=0;i<8;i++)mesh(g,crystal,material,Math.cos(i)*.9,.4,Math.sin(i)*.9,.04,.07,.04,false);
    }else if(e.type==='phoenix'){
      flatRing(g,material,1,.035);for(let i=0;i<14;i++){const a=i/13*Math.PI,wing=mesh(g,cone,i%2?fxColors.mythic:colors.fire,Math.cos(a)*.6,.5+Math.sin(a)*.5,0,.08,.7,.08,false);wing.rotation.z=a-Math.PI/2;}
    }else if(['flock','rapid'].includes(e.type)){
      for(let i=0;i<8;i++){const a=i*Math.PI/4;for(const side of [-1,1]){const wing=mesh(g,box,material,Math.cos(a)*.7+side*.09,.25,Math.sin(a)*.7,.2,.035,.04,false);wing.rotation.z=side*.6;}}
    }else if(e.type==='claw'){
      for(const x of [-.25,0,.25]){const claw=mesh(g,box,material,x,.25,0,.05,.05,1.2,false);claw.rotation.y=.6;}
    }else if(['wind','hare','echo'].includes(e.type)){
      for(let i=0;i<5;i++){const streak=mesh(g,cone,material,Math.cos(i*1.2)*.4,.1,Math.sin(i*1.2)*.4,.055,.7,.055,false);streak.rotation.x=Math.PI/2;streak.rotation.z=i*.6;}
    }else if(['nova','shell','howl','enemy-blast','hex-blast','harvest'].includes(e.type)){
      for(const r of [.55,1])flatRing(g,material,r,.035);
      if(e.type==='enemy-blast'||e.type==='hex-blast')for(let i=0;i<8;i++)mesh(g,crystal,material,Math.cos(i)*.7,.25,Math.sin(i)*.7,.07,.4,.07,false);
      if(e.type==='shell')mesh(g,sphere,material,0,.3,0,.35,.35,.35,false);
    }else for(let i=0;i<7;i++)mesh(g,e.element==='ice'?crystal:sphere,material,Math.cos(i)*.65,.3+(i%3)*.15,Math.sin(i)*.65,.08,.08,.08,false);
    return g;
  }
  const pickupHalo=flatRing(scene,effectMaterial('#b4d994',{transparent:true,opacity:.25,depthWrite:false}),.75,.08);
  const playerHalo = flatRing(scene, mat('#d2e89b', { transparent: true, opacity: .55 }), .24, .025);
  function makeEnemy(e) {
    const group = new THREE.Group(), body = new THREE.Group(); group.add(body); group.userData.body = body;
    const boss = e.kind === 'boss';
    const material = boss ? [colors.wood, colors.frost, colors.void, colors.leather][e.tier - 1] : e.kind === 'brute' ? colors.wood : e.kind === 'wisp' ? colors.frost : colors.leaf;
    if (boss && e.tier === 1) {
      mesh(body, sphere, material, 0, .53, 0, .5, .63, .36);
      mesh(body, sphere, colors.leaf, 0, .96, .07, .3, .3, .25);
      for (const x of [-.22, .22]) {
        mesh(body, cylinder, colors.wood, x, 1.36, 0, .04, .48, .04).rotation.z = -x * 1.2;
        mesh(body, cone, colors.gold, x, 1.63, 0, .07, .18, .07);
        mesh(body, box, material, x * 2.4, .58, 0, .19, .55, .22).rotation.z = x;
      }
      for (const x of [-.23, .23]) mesh(body, box, material, x, .13, 0, .22, .26, .26);
    } else if (boss && e.tier === 2) {
      mesh(body, crystal, material, 0, .7, 0, .42, .8, .4);
      for (let i = 0; i < 6; i++) {
        const a = i * Math.PI / 3;
        mesh(body, crystal, colors.frost, Math.cos(a) * .52, .9, Math.sin(a) * .52, .1, .27, .1);
      }
      flatRing(body, colors.xp, .5, .55);
    } else if(boss&&e.tier===4){mesh(body,box,colors.leather,0,.65,0,.85,1.05,.55);mesh(body,box,colors.gold,0,1.28,0,.4,.35,.4);for(const x of [-.62,.62]){mesh(body,sphere,colors.gold,x,.95,0,.3);mesh(body,box,colors.wood,x,.5,0,.25,.65,.3);}flatRing(body,colors.gold,.7,.1);for(const x of [-.25,.25])mesh(body,box,colors.wood,x,.13,0,.3,.3,.38);
    } else if (boss) {
      mesh(body, cone, colors.void, 0, .5, 0, .6, .95, .48);
      mesh(body, sphere, colors.dark, 0, 1.05, .04, .29, .31, .25);
      for (let i = 0; i < 5; i++) {
        const a = i * Math.PI * 2 / 5;
        mesh(body, cone, colors.gold, Math.cos(a) * .25, 1.47, Math.sin(a) * .25, .075, .4, .075);
      }
      for (const x of [-.5, .5]) mesh(body, crystal, colors.xp, x, .75, 0, .12, .23, .12);
    } else if(e.kind==='juggernaut'){mesh(body,box,colors.stone,0,.4,0,.55,.7,.45);for(const x of [-.35,.35])mesh(body,box,colors.wood,x,.6,0,.22,.22,.32);mesh(body,box,colors.gold,0,.8,.1,.28,.14,.14);
    } else if(e.kind==='stalker'){mesh(body,cone,colors.void,0,.35,0,.22,.65,.2);for(const x of [-.22,.22])mesh(body,cone,colors.feather,x,.2,.2,.035,.45,.035).rotation.x=.7;
    } else if(e.kind==='boar'){
      mesh(body,sphere,colors.wood,0,.24,0,.3,.23,.4);mesh(body,box,colors.mushroom,0,.24,.37,.24,.17,.2);
      for(const x of [-.14,.14]){mesh(body,cone,colors.feather,x,.23,.46,.045,.22,.045);mesh(body,cone,colors.wood,x,.5,.15,.08,.16,.08);}
      for(const x of [-.2,.2])for(const z of [-.2,.2])mesh(body,box,colors.dark,x,.08,z,.08,.15,.08);
    } else if(e.kind==='archer'){
      mesh(body,box,colors.leather,0,.26,0,.22,.4,.18);mesh(body,sphere,colors.feather,0,.54,0,.13);
      mesh(body,cone,colors.void,0,.7,0,.2,.25,.2);const bow=mesh(body,bowGeo,colors.gold,.27,.32,.1);bow.rotation.z=-Math.PI/2;
      for(const x of [-.1,.1])mesh(body,box,colors.dark,x,.07,0,.08,.18,.1);
    } else if(e.kind==='shaman'){
      mesh(body,cone,colors.void,0,.3,0,.3,.65,.25);mesh(body,sphere,colors.poison,0,.66,0,.12);mesh(body,cylinder,colors.wood,.28,.4,0,.025,.8,.025);mesh(body,crystal,colors.poison,.28,.9,0,.12);
      flatRing(body,colors.poison,.32,.025);
    } else if(e.kind==='bomber'){
      mesh(body,sphere,colors.hostile,0,.25,0,.25,.3,.25);mesh(body,sphere,colors.fire,.22,.42,.15,.13);mesh(body,cone,colors.gold,.22,.62,.15,.025,.16,.025);
      for(const x of [-.15,.15])mesh(body,box,colors.dark,x,.06,0,.1,.13,.15);
    } else if (e.kind === 'wisp') {
      mesh(body, sphere, material, 0, .31, 0, .13, .17, .13);
      mesh(body, cone, material, 0, .1, 0, .1, .25, .1).rotation.z = Math.PI;
    } else {
      const r = e.kind === 'brute' ? .22 : .15;
      mesh(body, sphere, material, 0, r, 0, r, r, r);
      for (const x of [-r, r]) {
        mesh(body, box, material, x, r * .5, .05, .065, .1, .22).rotation.z = x;
      }
    }
    const eyeY = boss ? (e.tier === 1 ? 1.02 : e.tier === 2 ? .9 : 1.1) : ['archer','shaman'].includes(e.kind)?.58:e.kind==='boar'?.29:e.kind==='bomber'?.36:e.kind === 'wisp' ? .35 : e.kind === 'brute' ? .28 : .19;
    for (const x of [-1, 1]) mesh(body, sphere, colors.eyes, x * (boss ? .09 : .04), eyeY, boss ? .26 : e.kind === 'brute' ? .18 : .12, boss ? .035 : .018);
    if (boss) {
      const ground = flatRing(group, [colors.gold, colors.xp, colors.hostile,colors.gold][e.tier - 1], .62, .035); group.userData.halo = ground;
      // Charge lane is visible during the Briar King's wind-up.
      const lane = mesh(group, box, chargeMaterial, 0, .035, 0, .48, .02, 2.3, false); lane.visible = false; group.userData.lane = lane;
    }
    if(e.elite){for(const x of [-.24,.24])mesh(body,cone,colors.gold,x,.5,-.1,.05,.32,.05);}
    const clones=new Map();body.traverse(o=>{if(!o.isMesh)return;const original=o.material;if(!clones.has(original)){const clone=original.clone();dynamicMaterials.add(clone);clones.set(original,{material:clone,color:original.color.clone(),emissive:original.emissive.clone()});}o.material=clones.get(original).material;});
    group.userData.tints=[...clones.values()];group.userData.release=()=>{for(const {material} of clones.values()){dynamicMaterials.delete(material);material.dispose();}};
    const status=new THREE.Group();group.add(status);group.userData.status=status;
    for(const material of [colors.fire,colors.ice,colors.poison,colors.gold])flatRing(status,material,boss?.48:.17,.04);
    return group;
  }
  // Object-keyed meshes survive frames, and share reusable geometry/materials.
  const enemyMeshes = new Map(), pickupMeshes = new Map(), boltMeshes = new Map(), effectMeshes = new Map(), petMeshes=new Map(), chestMeshes=new Map(),hazardMeshes=new Map();
  function sync(map, objects, create, update) {
    const alive = new Set(objects);
    for (const [object, m] of map) if (!alive.has(object)) { scene.remove(m);m.userData.release?.(); map.delete(object); }
    for (const object of objects) {
      let m = map.get(object);
      if (!m) { m = create(object); scene.add(m); map.set(object, m); }
      m.position.x = (object.x - WORLD.width/2) / 100; m.position.z = (object.y - WORLD.height/2) / 100;
      update(m, object);
    }
  }
  // Instanced fireflies use one draw call.
  const flies = new THREE.InstancedMesh(sphere, colors.gold, 24); scene.add(flies);
  const transform = new THREE.Object3D();
  let width = 0, height = 0, facing = 0, lastTime=0,characterId=null;
  function render(time) {
    const w = Math.max(1, Math.round(canvas.clientWidth)), h = Math.max(1, Math.round(canvas.clientHeight));
    if (w !== width || h !== height) {
      width = w; height = h; renderer.setSize(w, h, false);feedbackCanvas.width=w;feedbackCanvas.height=h;
      camera.aspect=w/h;camera.updateProjectionMatrix();
    }
    const p=game.player, dt=Math.min(.25,lastTime?time-lastTime:.016);lastTime=time;
    const px=(p.x-WORLD.width/2)/100,pz=(p.y-WORLD.height/2)/100;
    if(characterId!==game.character){player.visible=false;characterId=game.character;player=heroes.get(characterId)||heroes.get('ranger');}
    player.position.set(px,.02,pz);
    const targetAngle=p.shotTime>0?Math.atan2(p.aimX,p.aimY):Math.atan2(p.dx,p.dy);
    facing+=Math.atan2(Math.sin(targetAngle-facing),Math.cos(targetAngle-facing))*(1-Math.exp(-dt*14));
    player.rotation.y=facing;player.visible=!(p.invincible>0&&p.spaceTime<=0&&Math.floor(time*16)%2);
    clockAura.visible=p.spaceTime>0&&game.loadout.space==='clock';clockAura.position.set(px,0,pz);clockAura.rotation.y=-time*.4;
    skillShell.visible=p.spaceTime>0&&game.loadout.space==='shield';skillShell.position.set(px,.6,pz);skillShell.rotation.y=time*.9;skillShell.scale.setScalar(.65+Math.sin(time*6)*.025);
    thornAura.visible=p.spaceTime>0&&game.loadout.space==='repel';thornAura.position.set(px,0,pz);thornAura.rotation.y=time;
    sprintAura.visible=p.spaceTime>0&&game.loadout.space==='sprint';sprintAura.position.set(px,0,pz);sprintAura.rotation.y=facing;
    rapidAura.visible=p.rapidTime>0;rapidAura.position.set(px,0,pz);rapidAura.rotation.y=time*5;
    moonAura.visible=p.furyTime>0;moonAura.position.set(px,1.65,pz);moonAura.lookAt(camera.position);moonAura.rotation.z-=.6;
    dawnAura.visible=!!p.orbit;dawnAura.position.set(px,0,pz);dawnAura.children.forEach((sun,i)=>{sun.position.x=Math.cos(time*2+i*Math.PI*2/3);sun.position.z=Math.sin(time*2+i*Math.PI*2/3);});
    const step=p.moving?Math.sin(game.time*13)*.55:0;
    player.userData.legs[0].rotation.x=step;player.userData.legs[1].rotation.x=-step;
    player.userData.hips.position.y=p.moving?Math.abs(Math.sin(game.time*13))*.025:0;
    player.userData.drawArm.rotation.y=p.shotTime>0?-.7*(p.shotTime/.3):0;
    player.userData.bowArm.rotation.x=p.shotTime>0?-.08:0;
    player.userData.string.position.x=p.shotTime>0?-.08*p.shotTime/.3:0;
    player.userData.readyArrow.visible=p.shotTime<=0;
    pickupHalo.position.set(px,.08,pz);pickupHalo.scale.setScalar(p.magnet/100);pickupHalo.visible=['playing','paused'].includes(game.state);
    playerHalo.position.set(px,.035,pz);playerHalo.scale.setScalar(p.dashTime>0?.32:.24);
    const focusTarget=new THREE.Vector3(px,.65,pz);
    // Snap only across a restart/teleport; ordinary movement follows smoothly.
    if(cameraFocus.distanceTo(focusTarget)>8)cameraFocus.copy(focusTarget);
    else cameraFocus.lerp(focusTarget,1-Math.exp(-dt*9));
    const distance=canvas.clientWidth<500?6.4:5.3;
    camera.position.set(cameraFocus.x+Math.sin(cameraYaw)*distance,cameraFocus.y+cameraLift,cameraFocus.z+Math.cos(cameraYaw)*distance);
    camera.lookAt(cameraFocus);
    // Opaque scenery stays present. Pull the camera in before it enters a solid object.
    const dx=camera.position.x-px,dz=camera.position.z-pz,length2=dx*dx+dz*dz;
    let fraction=1;
    for(const o of SOLIDS){
      const x=(o.x-p.x)/100,z=(o.y-p.y)/100,r=(o.cameraR||o.r)/100;
      const dot=dx*x+dz*z,discriminant=dot*dot-length2*(x*x+z*z-r*r);
      if(discriminant<0)continue;
      const entry=(dot-Math.sqrt(discriminant))/length2;
      if(entry>0&&entry<fraction&&cameraFocus.y+(camera.position.y-cameraFocus.y)*entry<o.height/100+.1)fraction=Math.max(.12,entry-.04);
    }
    if(fraction<1)camera.position.lerpVectors(cameraFocus,camera.position.clone(),fraction);
    camera.lookAt(cameraFocus);
    sun.position.set(px-4,10,pz-5);sun.target.position.set(px,0,pz);sun.target.updateMatrixWorld();
    campFlame.scale.y=.4+Math.sin(time*7)*.05;
    sync(enemyMeshes, game.enemies, makeEnemy, (m, e) => {
      m.scale.setScalar(e.kind==='boss'?1:e.elite?2.15:1.8);
      const tint=e.poison>0?ELEMENT_COLORS.poison:e.burn>0?ELEMENT_COLORS.fire:e.slow>0?ELEMENT_COLORS.ice:null;for(const entry of m.userData.tints){entry.material.color.copy(entry.color);entry.material.emissive.copy(entry.emissive);if(tint){entry.material.color.lerp(new THREE.Color(tint),.8);entry.material.emissive.set(tint);}}
      m.rotation.y = e.charge>0?Math.atan2(e.cx,e.cy):Math.atan2(p.x - e.x, p.y - e.y);
      m.userData.body.position.y = Math.sin(time * (e.kind === 'wisp' ? 4 : 7) + e.x) * (e.kind === 'wisp' ? .08 : .015);
      m.userData.status.children.forEach((a,i)=>{a.visible=i===0?e.burn>0:i===1?e.slow>0:i===2?e.poison>0:e.guard>0;});
      if (e.slow > 0) m.userData.body.scale.setScalar(.94 + Math.sin(time * 8) * .03); else m.userData.body.scale.setScalar(1);
      if (m.userData.halo) m.userData.halo.scale.setScalar(.6 + Math.sin(time * 2) * .04);
      if (m.userData.lane) {
        const lane = m.userData.lane; lane.visible = e.charge > .7;
        // Lane is in world space relative to the root rotation.
        lane.rotation.y = Math.atan2(e.cx || 0, e.cy || 1) - m.rotation.y;
        const a = lane.rotation.y; lane.position.x = Math.sin(a) * 1.15; lane.position.z = Math.cos(a) * 1.15;
      }
    });
    sync(pickupMeshes, game.pickups, i => {
      const g = new THREE.Group();
      const m = mesh(g, i.kind === 'coin' ? cylinder : crystal, i.kind === 'coin' ? colors.gold : i.kind === 'heal' ? colors.heal : colors.xp, 0, 0, 0, .065, i.kind === 'coin' ? .025 : .1, .065, false);
      if (i.kind === 'coin') m.rotation.x = Math.PI / 2;
      return g;
    }, (m, i) => { m.position.y = .16 + Math.sin(time * 3 + i.x) * .045; m.rotation.y = time * 1.8; });
    sync(boltMeshes,[...game.bullets,...game.hostile],b=>{
      if(game.hostile.includes(b)){
        if(b.style==='arrow'){const g=makeArrow('fire');g.scale.setScalar(1.3);return g;}
        const g=new THREE.Group();mesh(g,crystal,colors.hostile,0,0,0,.09);for(let i=1;i<4;i++)mesh(g,sphere,colors.hostile,0,0,-i*.07,.055/i);return g;
      }
      if(b.style==='flock'){
        const g=new THREE.Group();mesh(g,cone,colors[b.element]||fxColors.flock,0,0,.12,.035,.2,.035,false).rotation.x=Math.PI/2;
        for(const side of [-1,1]){const wing=mesh(g,box,colors.feather,side*.12,0,0,.25,.025,.09,false);wing.rotation.z=side*.5;}
        return g;
      }
      const g=makeArrow(b.element,b.kind==='pet');if(b.style==='gear'){flatRing(g,fxColors.gears,.14,0).rotation.x=0;mesh(g,crystal,fxColors.clock,0,0,.22,.05,.05,.12,false);}
      if(b.style==='moon'||b.style==='rapid'||b.pierceLeft){const trail=mesh(g,box,b.pierceLeft?fxColors.wind:b.style==='moon'?fxColors.moon:fxColors.rapid,0,0,-.35,.025,.025,.5,false);g.userData.trail=trail;}
      return g;
    },(m,b)=>{m.position.y=b.kind==='pet'?.4:.57;m.rotation.y=Math.atan2(b.vx,b.vy);if(b.style==='flock')for(const [i,wing] of m.children.entries())if(i)wing.rotation.z=(i===1?-1:1)*Math.sin(time*24)*.7;});
    sync(petMeshes,game.pets,p=>{
      const g=new THREE.Group(),material=p.kind==='fox'?colors.mushroom:colors.stone;
      if(p.kind==='collector'){
        mesh(g,sphere,colors.gold,0,.23,0,.22,.16,.28);mesh(g,sphere,colors.dark,0,.27,.24,.12);
        mesh(g,crystal,colors.xp,0,.45,-.08,.12,.18,.12);
        for(const x of [-.22,.22])for(const z of [-.15,0,.15])mesh(g,box,colors.dark,x,.09,z,.22,.04,.035);
        for(const x of [-.08,.08])mesh(g,sphere,colors.heal,x,.32,.33,.035);
        return g;
      }
      mesh(g,box,material,0,.22,0,.22,.25,.4);mesh(g,sphere,material,0,.4,.22,.17,.16,.15);
      for(const x of [-.09,.09]){mesh(g,cone,material,x,.58,.2,.07,.2,.07);for(const z of [-.12,.12])mesh(g,box,colors.dark,x,.07,z,.05,.16,.07);}
      const tail=mesh(g,cone,material,0,.32,-.34,.11,.4,.11);tail.rotation.x=-.8;
      g.userData.orb=mesh(g,crystal,colors.feather,0,.39,.37,.04);
      return g;
    },(m,p)=>{m.rotation.y=Math.atan2(p.aimX||0,p.aimY||1);m.position.y=Math.sin(time*(p.kind==='collector'?12:9))*.025;if(m.userData.orb)m.userData.orb.material=p.kind==='fox'?colors.gold:colors.ice;});
    sync(chestMeshes,game.chests,c=>{
      const g=new THREE.Group(),material=c.tier==='mythical'?fxColors.mythic:colors.gold;
      mesh(g,box,colors.wood,0,.17,0,.44,.3,.32);mesh(g,box,material,0,.34,0,.46,.09,.34);mesh(g,box,material,0,.2,.18,.09,.12,.025);flatRing(g,material,.35,.025);
      if(c.tier==='mythical')for(let i=0;i<5;i++)mesh(g,crystal,material,Math.cos(i*1.26)*.19,.56,Math.sin(i*1.26)*.19,.05,.14,.05);return g;
    },(m,c)=>{m.position.y=.04+Math.sin(time*3+c.x)*.035;m.rotation.y=Math.sin(time*.5)*.15;});
    sync(hazardMeshes,game.hazards,h=>{
      const g=new THREE.Group();
      if(h.shape==='line'){const base=mesh(g,box,dangerFill,0,.035,0,1,.015,1,false),fill=mesh(g,box,dangerMaterial,0,.045,0,1,.015,1,false);g.userData={base,fill};}
      else{flatRing(g,dangerMaterial,1,.025);const fill=mesh(g,disc,dangerFill,0,.018,0,1,1,1,false);fill.rotation.x=-Math.PI/2;g.userData.fill=fill;}
      return g;
    },(m,h)=>{
      const progress=1-h.delay/h.maxDelay;m.position.y=.09;
      if(h.shape==='line'){const length=Math.hypot(h.tx-h.x,h.ty-h.y)/100;m.rotation.y=Math.atan2(h.tx-h.x,h.ty-h.y);m.userData.base.scale.set(h.width/100,.015,length);m.userData.base.position.z=length/2;m.userData.fill.scale.set(h.width/100,.015,Math.max(.01,length*progress));m.userData.fill.position.z=length*progress/2;}
      else{m.scale.setScalar(h.r/100);m.userData.fill.scale.setScalar(Math.max(.02,progress));}
    });
    sync(effectMeshes,game.effects,makeEffect,(m,e)=>{
      const progress=1-e.life/e.maxLife;m.scale.setScalar(Math.max(.015,e.r/100*(.2+progress*.8)));m.position.y=.09+progress*.1;
      if(['wind','hare','echo','moon','flock'].includes(e.type))m.rotation.y=progress*2;
    });
    for (let i = 0; i < 24; i++) {
      transform.position.set(px+Math.sin(i * 9.8 + time * .13) * 5, .2 + Math.sin(time * .6 + i) * .1 + (i % 3) * .3, pz+Math.cos(i * 6.3 + time * .1) * 3.3);
      transform.scale.setScalar(.01 + (Math.sin(time * 2 + i) + 1) * .005); transform.updateMatrix(); flies.setMatrixAt(i, transform.matrix);
    }
    flies.instanceMatrix.needsUpdate = true;
    sun.color.set(isBossWave(game.wave) ? '#e3c4ff' : '#ffe2ae');
    renderer.render(scene, camera);
    feedback.clearRect(0,0,width,height);drawCombatFeedback(feedback,game,(x,y,h)=>{labelPoint.set((x-WORLD.width/2)/100,h,(y-WORLD.height/2)/100).project(camera);if(labelPoint.z< -1||labelPoint.z>1)return null;return {x:(labelPoint.x+1)*width/2,y:(1-labelPoint.y)*height/2};},width,height);
  }
  return { render, setQuality(quality) { renderer.shadowMap.enabled=quality==='high';renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,quality==='high'?1.25:1)); }, look(dx,dy) { cameraYaw+=dx*.006;cameraLift=THREE.MathUtils.clamp(cameraLift+dy*.012,.85,5.5); }, orbit(delta) { cameraYaw+=delta; }, movement(x,y) { return {moveX:x*Math.cos(cameraYaw)+y*Math.sin(cameraYaw),moveY:y*Math.cos(cameraYaw)-x*Math.sin(cameraYaw)}; }, dispose() { feedbackCanvas.remove();scene.traverse(o => { if (o.isInstancedMesh) o.dispose(); }); sun.shadow.map?.dispose(); geometries.forEach(g => g.dispose()); materials.forEach(m => m.dispose());dynamicMaterials.forEach(m=>m.dispose());dynamicMaterials.clear(); renderer.dispose(); } };
}
