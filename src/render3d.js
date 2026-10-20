import * as THREE from 'three';

// The simulation stays on a flat arena; all geometry and lighting are real 3D.
export function create3DRenderer(canvas, game) {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#13251f');
  scene.fog = new THREE.Fog('#13251f', 16, 30);
  const camera = new THREE.OrthographicCamera(-6, 6, 4, -4, .1, 60);
  camera.position.set(0, 13, 10);
  camera.lookAt(0, 0, 0);
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
  const crystal = geometry(new THREE.OctahedronGeometry(1));
  const ringGeo = geometry(new THREE.RingGeometry(.89, 1, 48));
  const colors = {
    grass: mat('#354d34'), soil: mat('#3e3d2b'), stone: mat('#697566'), trunk: mat('#675039'),
    pine: [mat('#264b36'), mat('#386044'), mat('#4c7150')],
    cape: mat('#97af68'), hood: mat('#c2ce91'), dark: mat('#243627'), skin: mat('#e4bc83'),
    gold: glowing('#ffcb69'), xp: glowing('#b4a0f2'), heal: glowing('#9be39a'), bolt: glowing('#ffdd94'),
    hostile: glowing('#bd9eeb'), wood: mat('#675639'), leaf: mat('#a0b26d'), frost: mat('#96d9e7'),
    void: mat('#6b427c'), eyes: glowing('#ffe6a1'), edge: mat('#6b7047'),
    mushroom: mat('#ca9869'), water: mat('#507f72', { metalness: .3, roughness: .25 })
  };
  const mesh = (parent, geo, material, x, y, z, sx = 1, sy = sx, sz = sx, shadow = true) => {
    const m = new THREE.Mesh(geo, material); m.position.set(x, y, z); m.scale.set(sx, sy, sz); m.castShadow = shadow; m.receiveShadow = true; parent.add(m); return m;
  };
  const flatRing = (parent, material, radius, y = .015) => {
    const m = mesh(parent, ringGeo, material, 0, y, 0, radius, radius, radius, false); m.rotation.x = -Math.PI / 2; return m;
  };
  let seed = 47382;
  const random = () => { seed = seed * 16807 % 2147483647; return (seed - 1) / 2147483646; };
  // A floating forest floor, with its playable boundaries marked by old stones.
  mesh(scene, box, colors.soil, 0, -.3, 0, 11.8, .55, 8.5);
  mesh(scene, box, colors.grass, 0, -.025, 0, 11.8, .08, 8.5);
  const boundaryMat = mat('#7f9460', { transparent: true, opacity: .35 });
  for (const z of [-3.3, 3.3]) mesh(scene, box, boundaryMat, 0, .012, z, 10, .015, .025, false);
  for (const x of [-5, 5]) mesh(scene, box, boundaryMat, x, .012, 0, .025, .015, 6.6, false);
  // Patches and path stones add detail without blocking movement.
  for (let i = 0; i < 100; i++) {
    const x = (random() - .5) * 10, z = (random() - .5) * 6.6;
    const patch = mesh(scene, cylinder, i % 3 ? colors.pine[0] : colors.soil, x, .012, z, .1 + random() * .28, .018, .1 + random() * .22, false);
    patch.rotation.y = random() * 6;
  }
  for (let i = 0; i < 17; i++) {
    const z = -3.25 + i * .4, x = Math.sin(z * 1.3) * .55;
    const m = mesh(scene, cylinder, colors.stone, x, .025, z, .18, .04, .12); m.rotation.y = random() * 5;
  }
  const rune = mat('#bad091', { emissive: '#a5c788', emissiveIntensity: .25 });
  flatRing(scene, rune, .92);
  for (let i = 0; i < 8; i++) {
    const a = i * Math.PI / 4;
    const m = mesh(scene, box, rune, Math.cos(a) * 1.04, .035, Math.sin(a) * 1.04, .07, .035, .13); m.rotation.y = -a;
  }
  function tree(x, z, s = 1) {
    const group = new THREE.Group(); group.position.set(x, 0, z); scene.add(group);
    mesh(group, cylinder, colors.trunk, 0, .36 * s, 0, .09 * s, .72 * s, .09 * s);
    for (let i = 0; i < 3; i++) mesh(group, cone, colors.pine[i], 0, (.7 + i * .42) * s, 0, (.62 - i * .13) * s, 1.05 * s, (.62 - i * .13) * s);
  }
  for (let i = 0; i < 19; i++) tree(-5.6 + i * .62, -3.85 - random() * .25, .75 + random() * .48);
  for (let i = 0; i < 11; i++) {
    tree(-5.55 - random() * .2, -3.1 + i * .65, .75 + random() * .3);
    tree(5.55 + random() * .2, -3.1 + i * .65, .75 + random() * .3);
  }
  // Short foreground shrubs keep the player visible at the near edge.
  for (let i = 0; i < 17; i++) mesh(scene, sphere, colors.pine[1], -5.5 + i * .68, .17, 3.9, .3, .22, .3);
  for (let i = 0; i < 20; i++) {
    const x = (random() - .5) * 9.6, z = (random() - .5) * 6.2;
    if (Math.hypot(x, z) < 1.2) continue;
    const m = mesh(scene, sphere, colors.stone, x, .07, z, .1 + random() * .12, .12 + random() * .08, .09 + random() * .08); m.rotation.y = random() * 6;
  }
  for (let i = 0; i < 35; i++) {
    const x = (random() - .5) * 10.4, z = (random() - .5) * 7;
    if (i % 3 === 0) {
      mesh(scene, cylinder, colors.skin, x, .055, z, .018, .11, .018);
      mesh(scene, sphere, colors.mushroom, x, .115, z, .07, .04, .07);
    } else {
      for (let j = 0; j < 3; j++) {
        const blade = mesh(scene, cone, colors.pine[2], x + j * .025, .075, z, .022, .15, .022, false); blade.rotation.z = (j - 1) * .3;
      }
    }
  }
  for (const [x, z] of [[-3.8, -2.2], [3.9, 2.3]]) {
    mesh(scene, box, colors.wood, x, .33, z, .06, .66, .06);
    mesh(scene, box, colors.gold, x, .72, z, .15, .2, .15);
    mesh(scene, cone, colors.wood, x, .88, z, .16, .1, .16);
    const lamp = new THREE.PointLight('#ffc370', 1.3, 2.3); lamp.position.set(x, .8, z); scene.add(lamp);
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
  function makeWayfarer() {
    const g = new THREE.Group();
    for (const x of [-.065, .065]) mesh(g, box, colors.wood, x, .07, 0, .07, .14, .12);
    mesh(g, cone, colors.cape, 0, .25, 0, .21, .38, .17);
    mesh(g, sphere, colors.hood, 0, .51, 0, .14, .15, .14);
    mesh(g, sphere, colors.dark, 0, .5, .095, .095, .085, .045);
    for (const x of [-.037, .037]) mesh(g, sphere, colors.eyes, x, .51, .133, .014);
    mesh(g, cylinder, colors.wood, .23, .33, .04, .018, .66, .018);
    mesh(g, crystal, colors.gold, .23, .72, .04, .06, .09, .06);
    const light = new THREE.PointLight('#ffe2a0', 1.1, 1.8); light.position.set(.23, .65, 0); g.add(light);
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
    return group;
  }
  // Object-keyed meshes survive frames, and share reusable geometry/materials.
  const enemyMeshes = new Map(), pickupMeshes = new Map(), boltMeshes = new Map(), effectMeshes = new Map();
  function sync(map, objects, create, update) {
    const alive = new Set(objects);
    for (const [object, m] of map) if (!alive.has(object)) { scene.remove(m); map.delete(object); }
    for (const object of objects) {
      let m = map.get(object);
      if (!m) { m = create(object); scene.add(m); map.set(object, m); }
      m.position.x = (object.x - 500) / 100; m.position.z = (object.y - 330) / 100;
      update(m, object);
    }
  }
  // Instanced fireflies use one draw call.
  const flies = new THREE.InstancedMesh(sphere, colors.gold, 24); scene.add(flies);
  const transform = new THREE.Object3D();
  let width = 0, height = 0, facing = 0;
  function render(time) {
    const w = Math.max(1, Math.round(canvas.clientWidth)), h = Math.max(1, Math.round(canvas.clientHeight));
    if (w !== width || h !== height) {
      width = w; height = h; renderer.setSize(w, h, false);
      const aspect = w / h, horizontal = Math.max(11.8, 8 * aspect), vertical = horizontal / aspect;
      camera.left = -horizontal / 2; camera.right = horizontal / 2; camera.top = vertical / 2; camera.bottom = -vertical / 2; camera.updateProjectionMatrix();
    }
    const p = game.player;
    player.position.set((p.x - 500) / 100, .025 + Math.sin(time * 6) * .009, (p.y - 330) / 100);
    const targetAngle = Math.atan2(p.dx, p.dy);
    facing += Math.atan2(Math.sin(targetAngle - facing), Math.cos(targetAngle - facing)) * .16;
    player.rotation.y = facing; player.visible = !(p.invincible > 0 && Math.floor(time * 16) % 2);
    playerHalo.position.set(player.position.x, .025, player.position.z);
    playerHalo.scale.setScalar(p.dashTime > 0 ? .32 : .24);
    sync(enemyMeshes, game.enemies, makeEnemy, (m, e) => {
      m.rotation.y = Math.atan2(p.x - e.x, p.y - e.y);
      m.userData.body.position.y = Math.sin(time * (e.kind === 'wisp' ? 4 : 7) + e.x) * (e.kind === 'wisp' ? .08 : .015);
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
    sync(boltMeshes, [...game.bullets, ...game.hostile], b => {
      const hostile = game.hostile.includes(b);
      return new THREE.Mesh(hostile ? crystal : sphere, hostile ? colors.hostile : colors.bolt);
    }, (m, b) => { m.position.y = .3; m.scale.set(.055, .055, .1); m.rotation.y = Math.atan2(b.vx, b.vy); });
    sync(effectMeshes, game.effects, e => {
      const material = e.type === 'nova' ? colors.xp : e.type === 'warning' ? colors.gold : colors.heal;
      const g = new THREE.Group();
      if (e.type === 'nova' || e.type === 'warning') flatRing(g, material, 1, .04);
      else for (let i = 0; i < 5; i++) mesh(g, sphere, material, Math.cos(i * 1.256), .3, Math.sin(i * 1.256), .06, .06, .06, false);
      return g;
    }, (m, e) => {
      const progress = 1 - e.life / e.maxLife;
      m.scale.setScalar(Math.max(.015, e.r / 100 * progress)); m.position.y = e.type === 'trail' ? .1 : progress * .15;
    });
    for (let i = 0; i < 24; i++) {
      transform.position.set(Math.sin(i * 9.8 + time * .13) * 5, .2 + Math.sin(time * .6 + i) * .1 + (i % 3) * .3, Math.cos(i * 6.3 + time * .1) * 3.3);
      transform.scale.setScalar(.01 + (Math.sin(time * 2 + i) + 1) * .005); transform.updateMatrix(); flies.setMatrixAt(i, transform.matrix);
    }
    flies.instanceMatrix.needsUpdate = true;
    sun.color.set(game.wave % 3 === 0 ? '#e3c4ff' : '#ffe2ae');
    renderer.render(scene, camera);
  }
  return { render, dispose() { scene.traverse(o => { if (o.isInstancedMesh) o.dispose(); }); sun.shadow.map?.dispose(); geometries.forEach(g => g.dispose()); materials.forEach(m => m.dispose()); renderer.dispose(); } };
}
