import * as THREE from 'three';
import { WORLD, REGIONS } from './game.js';

// A perspective camera follows the ranger through a continuous, explorable world.
export function create3DRenderer(canvas, game) {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#8caeab');
  scene.fog = new THREE.Fog('#8caeab', 10, 30);
  const camera = new THREE.PerspectiveCamera(58, 1.5, .1, 75);
  let cameraYaw = 0;
  const cameraFocus = new THREE.Vector3(0, .65, 0);
  camera.position.set(0, 3.15, 5.3); camera.lookAt(cameraFocus);
  scene.add(new THREE.HemisphereLight('#d7ecda', '#374637', 2.1));
  const sun = new THREE.DirectionalLight('#ffe2ae', 3.1);
  sun.position.set(-4, 10, -5); sun.castShadow = true;
  sun.shadow.mapSize.set(1024, 1024);
  Object.assign(sun.shadow.camera, { left: -7, right: 7, top: 6, bottom: -6, near: .1, far: 24 });
  sun.shadow.normalBias = .04; sun.shadow.bias = -.0002;
  scene.add(sun);
  const rim = new THREE.DirectionalLight('#9ccdc8', 1.1); rim.position.set(4, 5, 5); scene.add(rim);
  const geometries = [], materials = [];
  const geometry = g => { geometries.push(g); return g; };
  const mat = (color, extra = {}) => { const m = new THREE.MeshStandardMaterial({ color, roughness: .86, flatShading: true, ...extra }); materials.push(m); return m; };
  const glowing = color => mat(color, { emissive: color, emissiveIntensity: 1.4 });
  const sphere = geometry(new THREE.IcosahedronGeometry(1, 0));
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
    fire: glowing('#ff8e42'), poison: glowing('#8ce454'), ice: glowing('#79e5ff'), leather: mat('#775039'), feather: mat('#e8dfb9'), mushroom: mat('#ca9869'), water: mat('#507f72', { metalness: .3, roughness: .25 })
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
    const path=mesh(scene,box,colors.soil,x/2,.035,z/2,.85,.025,length,false);path.rotation.y=Math.atan2(x,z);
  }
  const boundaryMat=mat('#91aa7a',{emissive:'#526b50',transparent:true,opacity:.5});
  for(const z of [-WORLD.height/200,WORLD.height/200])mesh(scene,box,boundaryMat,0,.12,z,WORLD.width/100,.25,.1);
  for(const x of [-WORLD.width/200,WORLD.width/200])mesh(scene,box,boundaryMat,x,.12,0,.1,.25,WORLD.height/100);
  function tree(x,z,s=1,ice=false) {
    const group=new THREE.Group();group.position.set(x,0,z);scene.add(group);
    mesh(group,cylinder,colors.trunk,0,.45*s,0,.09*s,.9*s,.09*s);
    for(let i=0;i<3;i++)mesh(group,cone,ice?colors.frost:colors.pine[i],0,(.9+i*.5)*s,0,(.72-i*.14)*s,1.3*s,(.72-i*.14)*s);
  }
  for(let i=0;i<520;i++) {
    const x=(random()-.5)*WORLD.width/100,z=(random()-.5)*WORLD.height/100;
    if(Math.hypot(x,z)<2.6)continue;
    // Leave the three trails and their landmarks clear.
    if(REGIONS.slice(1).some(r=>Math.hypot(x-wx(r.x),z-wz(r.y))<2))continue;
    if(Math.abs(x)<1 || Math.abs(z)<.75)continue;
    const frozen=Math.hypot(x-wx(1000),z-wz(1000))<7.6;
    tree(x,z,.7+random()*.75,frozen);
  }
  for(let i=0;i<180;i++) {
    const x=(random()-.5)*WORLD.width/100,z=(random()-.5)*WORLD.height/100;
    const m=mesh(scene,sphere,colors.stone,x,.08,z,.12+random()*.25,.12+random()*.2,.13+random()*.2);m.rotation.y=random()*6;
    if(i%2===0){mesh(scene,cylinder,colors.skin,x+.4,.07,z,.025,.14,.025);mesh(scene,sphere,colors.mushroom,x+.4,.16,z,.08,.05,.08);}
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
      for(let i=0;i<5;i++)mesh(g,crystal,colors.ice,(random()-.5)*3,.3,(random()-.5)*2,.15,.6,.15);
    }else if(index===1) {
      mesh(g,cone,colors.wood,0,.6,0,1.4,1.2,1.4);mesh(g,crystal,colors.fire,0,1.4,0,.45,.9,.45);
    }else {
      mesh(g,cylinder,colors.water,0,.07,0,1.5,.04,1.5);
      for(let i=0;i<4;i++){const a=i*Math.PI/2;mesh(g,sphere,colors.poison,Math.cos(a),.25,Math.sin(a),.2,.35,.2);}
    }
  }
  // Batch repeated scenery into instances so trees and grass stay inexpensive.
  scene.updateMatrixWorld(true);
  const batches = new Map(), foliageBatches=[];
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
    if(first.geometry===cone && [...colors.pine,colors.frost].includes(first.material)) {
      foliageBatches.push({mesh:instances,matrices:objects.map(o=>o.matrixWorld.clone()),hidden:objects.map(()=>false)});
    }
  }
  const chargeMaterial = mat('#f5ae68', { emissive: '#d47838', transparent: true, opacity: .4, depthWrite: false });
  function makeWayfarer() {
    const g=new THREE.Group();
    const hips=new THREE.Group();g.add(hips);
    const legs=[];
    for(const x of [-.09,.09]) {
      const leg=new THREE.Group();leg.position.set(x,.35,0);hips.add(leg);
      mesh(leg,box,colors.leather,0,-.13,0,.105,.27,.12);
      mesh(leg,box,colors.dark,0,-.3,.04,.13,.12,.22);legs.push(leg);
    }
    mesh(hips,box,colors.cape,0,.55,0,.35,.4,.22);
    mesh(hips,cone,colors.cape,0,.4,-.08,.27,.45,.22);
    mesh(hips,box,colors.leather,0,.39,0,.37,.07,.25);
    mesh(hips,sphere,colors.skin,0,.9,0,.145,.17,.14);
    mesh(hips,sphere,colors.hood,0,.98,-.035,.18,.16,.17);
    mesh(hips,box,colors.dark,0,.89,.115,.17,.04,.04);
    // Quiver and spare arrows on the back.
    mesh(hips,cylinder,colors.leather,.14,.58,-.19,.07,.4,.07).rotation.z=-.2;
    for(let i=0;i<3;i++) {
      mesh(hips,cylinder,colors.wood,.1+i*.035,.9,-.2,.008,.4,.008);
      mesh(hips,box,colors.feather,.1+i*.035,1.08,-.2,.04,.07,.015);
    }
    const bowArm=new THREE.Group();bowArm.position.set(-.21,.7,0);hips.add(bowArm);
    mesh(bowArm,box,colors.cape,0,-.09,.12,.11,.12,.3);
    mesh(bowArm,sphere,colors.skin,0,-.09,.28,.065);
    const bow=new THREE.Group();bow.position.set(0,-.09,.35);bow.rotation.y=Math.PI/2;bowArm.add(bow);
    const bowMesh=mesh(bow,bowGeo,colors.wood,0,0,0);bowMesh.rotation.z=-Math.PI/2;
    const string=mesh(bow,box,colors.feather,0,0,0,.009,.54,.009);
    const drawArm=new THREE.Group();drawArm.position.set(.2,.7,0);hips.add(drawArm);
    mesh(drawArm,box,colors.cape,0,-.06,.12,.1,.13,.29);mesh(drawArm,sphere,colors.skin,0,-.06,.28,.06);
    const readyArrow=makeArrow('physical');readyArrow.position.set(-.2,.61,.28);readyArrow.rotation.y=0;hips.add(readyArrow);
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
  const player = makeWayfarer(); scene.add(player);
  const playerHalo = flatRing(scene, mat('#d2e89b', { transparent: true, opacity: .55 }), .24, .025);
  function makeEnemy(e) {
    const group = new THREE.Group(), body = new THREE.Group(); group.add(body); group.userData.body = body;
    const boss = e.kind === 'boss';
    const material = boss ? [colors.wood, colors.frost, colors.void][e.tier - 1] : e.kind === 'brute' ? colors.wood : e.kind === 'wisp' ? colors.frost : colors.leaf;
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
    } else if (boss) {
      mesh(body, cone, colors.void, 0, .5, 0, .6, .95, .48);
      mesh(body, sphere, colors.dark, 0, 1.05, .04, .29, .31, .25);
      for (let i = 0; i < 5; i++) {
        const a = i * Math.PI * 2 / 5;
        mesh(body, cone, colors.gold, Math.cos(a) * .25, 1.47, Math.sin(a) * .25, .075, .4, .075);
      }
      for (const x of [-.5, .5]) mesh(body, crystal, colors.xp, x, .75, 0, .12, .23, .12);
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
    const eyeY = boss ? (e.tier === 1 ? 1.02 : e.tier === 2 ? .9 : 1.1) : e.kind === 'wisp' ? .35 : e.kind === 'brute' ? .28 : .19;
    for (const x of [-1, 1]) mesh(body, sphere, colors.eyes, x * (boss ? .09 : .04), eyeY, boss ? .26 : e.kind === 'brute' ? .18 : .12, boss ? .035 : .018);
    if (boss) {
      const ground = flatRing(group, [colors.gold, colors.xp, colors.hostile][e.tier - 1], .62, .035); group.userData.halo = ground;
      // Charge lane is visible during the Briar King's wind-up.
      const lane = mesh(group, box, chargeMaterial, 0, .035, 0, .48, .02, 2.3, false); lane.visible = false; group.userData.lane = lane;
    }
    const status=new THREE.Group();group.add(status);group.userData.status=status;
    for(const material of [colors.fire,colors.ice,colors.poison])flatRing(status,material,boss?.48:.17,.04);
    return group;
  }
  // Object-keyed meshes survive frames, and share reusable geometry/materials.
  const enemyMeshes = new Map(), pickupMeshes = new Map(), boltMeshes = new Map(), effectMeshes = new Map(), petMeshes=new Map(), chestMeshes=new Map();
  function sync(map, objects, create, update) {
    const alive = new Set(objects);
    for (const [object, m] of map) if (!alive.has(object)) { scene.remove(m); map.delete(object); }
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
  let width = 0, height = 0, facing = 0, lastTime=0;
  function render(time) {
    const w = Math.max(1, Math.round(canvas.clientWidth)), h = Math.max(1, Math.round(canvas.clientHeight));
    if (w !== width || h !== height) {
      width = w; height = h; renderer.setSize(w, h, false);
      camera.aspect=w/h;camera.updateProjectionMatrix();
    }
    const p=game.player, dt=Math.min(.05,lastTime?time-lastTime:.016);lastTime=time;
    const px=(p.x-WORLD.width/2)/100,pz=(p.y-WORLD.height/2)/100;
    player.position.set(px,.02,pz);
    const targetAngle=p.shotTime>0?Math.atan2(p.aimX,p.aimY):Math.atan2(p.dx,p.dy);
    facing+=Math.atan2(Math.sin(targetAngle-facing),Math.cos(targetAngle-facing))*.2;
    player.rotation.y=facing;player.visible=!(p.invincible>0 && Math.floor(time*16)%2);
    const step=p.moving?Math.sin(game.time*13)*.55:0;
    player.userData.legs[0].rotation.x=step;player.userData.legs[1].rotation.x=-step;
    player.userData.hips.position.y=p.moving?Math.abs(Math.sin(game.time*13))*.025:0;
    player.userData.drawArm.rotation.y=p.shotTime>0?-.7*(p.shotTime/.3):0;
    player.userData.bowArm.rotation.x=p.shotTime>0?-.08:0;
    player.userData.string.position.x=p.shotTime>0?-.08*p.shotTime/.3:0;
    player.userData.readyArrow.visible=p.shotTime<=0;
    playerHalo.position.set(px,.035,pz);playerHalo.scale.setScalar(p.dashTime>0?.32:.24);
    const focusTarget=new THREE.Vector3(px,.65,pz);
    // Snap only across a restart/teleport; ordinary movement follows smoothly.
    if(cameraFocus.distanceTo(focusTarget)>8)cameraFocus.copy(focusTarget);
    else cameraFocus.lerp(focusTarget,1-Math.exp(-dt*9));
    const distance=canvas.clientWidth<500?6.4:5.3;
    camera.position.set(cameraFocus.x+Math.sin(cameraYaw)*distance,cameraFocus.y+2.5,cameraFocus.z+Math.cos(cameraYaw)*distance);
    camera.lookAt(cameraFocus);
    // Cut away foliage between camera and ranger so exploration never hides the character.
    const cx=camera.position.x-px,cz=camera.position.z-pz,span=cx*cx+cz*cz;
    for(const batch of foliageBatches)for(let i=0;i<batch.matrices.length;i++) {
      const base=batch.matrices[i],x=base.elements[12]-px,z=base.elements[14]-pz,t=(x*cx+z*cz)/span;
      const hidden=t>-.1&&t<1.1&&Math.hypot(x-cx*t,z-cz*t)<.7;
      if(hidden!==batch.hidden[i]) {
        batch.hidden[i]=hidden;const matrix=base.clone();if(hidden)matrix.scale(new THREE.Vector3(0,0,0));
        batch.mesh.setMatrixAt(i,matrix);batch.mesh.instanceMatrix.needsUpdate=true;
      }
    }
    sun.position.set(px-4,10,pz-5);sun.target.position.set(px,0,pz);sun.target.updateMatrixWorld();
    campFlame.scale.y=.4+Math.sin(time*7)*.05;
    sync(enemyMeshes, game.enemies, makeEnemy, (m, e) => {
      m.scale.setScalar(e.kind==='boss'?1:1.8);
      m.rotation.y = Math.atan2(p.x - e.x, p.y - e.y);
      m.userData.body.position.y = Math.sin(time * (e.kind === 'wisp' ? 4 : 7) + e.x) * (e.kind === 'wisp' ? .08 : .015);
      m.userData.status.children.forEach((a,i)=>{a.visible=i===0?e.burn>0:i===1?e.slow>0:e.poison>0;});
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
    sync(boltMeshes,[...game.bullets,...game.hostile],b=>game.hostile.includes(b)?new THREE.Mesh(crystal,colors.hostile):makeArrow(b.element,b.kind==='pet'),(m,b)=>{
      m.position.y=b.kind==='pet'?.4:.57;m.rotation.y=Math.atan2(b.vx,b.vy);
      if(game.hostile.includes(b)){m.scale.setScalar(.09);m.rotation.z=time*4;}
    });
    sync(petMeshes,game.pets,p=>{
      const g=new THREE.Group(),material=p.kind==='fox'?colors.mushroom:colors.frost;
      mesh(g,box,material,0,.22,0,.22,.25,.4);mesh(g,sphere,material,0,.4,.22,.17,.16,.15);
      for(const x of [-.09,.09]){mesh(g,cone,material,x,.58,.2,.07,.2,.07);for(const z of [-.12,.12])mesh(g,box,colors.dark,x,.07,z,.05,.16,.07);}
      const tail=mesh(g,cone,material,0,.32,-.34,.11,.4,.11);tail.rotation.x=-.8;
      mesh(g,crystal,p.kind==='fox'?colors.fire:colors.ice,0,.39,.37,.04);
      return g;
    },(m,p)=>{m.rotation.y=Math.atan2(game.player.x-p.x,game.player.y-p.y);m.position.y=Math.sin(time*9)*.02;});
    sync(chestMeshes,game.chests,c=>{
      const g=new THREE.Group();mesh(g,box,colors.wood,0,.17,0,.44,.3,.32);const lid=mesh(g,box,colors.gold,0,.34,0,.46,.09,.34);g.userData.lid=lid;return g;
    },(m,c)=>{m.userData.lid.rotation.x=c.opened?-1:0;m.userData.lid.position.y=c.opened?.48:.34;});
    sync(effectMeshes, game.effects, e => {
      const material = e.type === 'nova' ? (game.player.element==='fire'?colors.fire:game.player.element==='ice'?colors.ice:game.player.element==='poison'?colors.poison:colors.xp) : e.type === 'warning' ? colors.gold : e.element==='fire'?colors.fire:e.element==='ice'?colors.ice:e.element==='poison'?colors.poison:colors.heal;
      const g = new THREE.Group();
      if (e.type === 'nova' || e.type === 'warning') flatRing(g, material, 1, .04);
      else for (let i = 0; i < 5; i++) mesh(g, sphere, material, Math.cos(i * 1.256), .3, Math.sin(i * 1.256), .06, .06, .06, false);
      return g;
    }, (m, e) => {
      const progress = 1 - e.life / e.maxLife;
      m.scale.setScalar(Math.max(.015, e.r / 100 * progress)); m.position.y = e.type === 'trail' ? .1 : progress * .15;
    });
    for (let i = 0; i < 24; i++) {
      transform.position.set(px+Math.sin(i * 9.8 + time * .13) * 5, .2 + Math.sin(time * .6 + i) * .1 + (i % 3) * .3, pz+Math.cos(i * 6.3 + time * .1) * 3.3);
      transform.scale.setScalar(.01 + (Math.sin(time * 2 + i) + 1) * .005); transform.updateMatrix(); flies.setMatrixAt(i, transform.matrix);
    }
    flies.instanceMatrix.needsUpdate = true;
    sun.color.set(game.wave % 3 === 0 ? '#e3c4ff' : '#ffe2ae');
    renderer.render(scene, camera);
  }
  return { render, orbit(delta) { cameraYaw+=delta; }, movement(x,y) { return {moveX:x*Math.cos(cameraYaw)+y*Math.sin(cameraYaw),moveY:y*Math.cos(cameraYaw)-x*Math.sin(cameraYaw)}; }, dispose() { scene.traverse(o => { if (o.isInstancedMesh) o.dispose(); }); sun.shadow.map?.dispose(); geometries.forEach(g => g.dispose()); materials.forEach(m => m.dispose()); renderer.dispose(); } };
}
