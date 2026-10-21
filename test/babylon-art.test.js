import test from 'node:test';
import assert from 'node:assert/strict';
import {NullEngine,Scene} from '@babylonjs/core';
import {createArt,mergeStaticMeshes} from '../src/emberwild/art.js';
import {createActors} from '../src/emberwild/actors.js';
import {createTerrain,groundHeight} from '../src/emberwild/world.js';
import {CHARACTERS} from '../src/content.js';
const setup=()=>{const engine=new NullEngine(),scene=new Scene(engine),art=createArt(scene);art.texture=()=>null;return {engine,scene,actors:createActors(art)};};
test('Babylon edition builds and animates all five distinct archer rigs',()=>{
 const {engine,scene,actors}=setup();try{const colors=new Set();for(const c of CHARACTERS){const root=actors.archer(c),rig=root.metadata.rig;assert.equal(root.metadata.character,c.id);colors.add(rig.body.getChildMeshes()[0].material.albedoColor.toHexString());const original=Array.from(rig.cape.getVerticesData('position'));actors.animateArcher(root,{moving:true,shotTime:.2},2,.42);assert.notDeepEqual(Array.from(rig.cape.getVerticesData('position')),original);root.computeWorldMatrix(true);for(const mesh of root.getChildMeshes()){mesh.computeWorldMatrix(true);assert.ok(Array.from(mesh.getWorldMatrix().m).every(Number.isFinite));}assert.ok(rig.arms.every(a=>a.arm.rotationQuaternion&&a.elbow.rotationQuaternion));root.dispose();}assert.equal(colors.size,5);}finally{scene.dispose();engine.dispose();}
});
test('Babylon enemy elemental hues stay independent and reset after the effect expires',()=>{
 const {engine,scene,actors}=setup();try{const a=actors.enemy({kind:'crawler'}),b=actors.enemy({kind:'crawler'}),original=b.metadata.tints[0].m.albedoColor.toHexString();actors.animateEnemy(a,{kind:'crawler',x:0,poison:4},1);assert.notEqual(a.metadata.tints[0].m.albedoColor.toHexString(),original);assert.equal(b.metadata.tints[0].m.albedoColor.toHexString(),original);actors.animateEnemy(a,{kind:'crawler',x:0},2);assert.equal(a.metadata.tints[0].m.albedoColor.toHexString(),original);for(const root of [a,b]){root.metadata.release();root.dispose();}}finally{scene.dispose();engine.dispose();}
});
test('Babylon bestiary covers every enemy, all four guardians and independent pets',()=>{
 const {engine,scene,actors}=setup();try{for(const kind of ['crawler','wisp','brute','archer','boar','shaman','bomber','stalker','juggernaut']){const root=actors.enemy({kind});actors.animateEnemy(root,{kind,x:5},1);assert.ok(root.getChildMeshes().length>5);root.metadata.release();root.dispose();}for(const tier of [1,2,3,4]){const root=actors.enemy({kind:'boss',tier});assert.ok(root.getHierarchyBoundingVectors().max.y>2.5);root.metadata.release();root.dispose();}for(const kind of ['fox','wolf','collector']){const root=actors.pet({kind});actors.animatePet(root,1);assert.ok(root.metadata.legs.length>=4);root.dispose();}}finally{scene.dispose();engine.dispose();}
});

test('rolling terrain keeps upward lighting normals in Babylon right-handed camera space',()=>{
 const engine=new NullEngine(),scene=new Scene(engine);scene.useRightHandedSystem=true;try{const ground=createTerrain(scene,null),normals=ground.getVerticesData('normal'),positions=ground.getVerticesData('position');for(let i=0;i<normals.length;i+=3)assert.ok(normals[i+1]>.9);for(let i=0;i<positions.length;i+=3)assert.ok(Math.abs(positions[i+1]-groundHeight(positions[i],positions[i+2]))<1e-6);}finally{scene.dispose();engine.dispose();}
});

test('static batching never corrupts primitive indices shared by later characters',()=>{
 const engine=new NullEngine(),scene=new Scene(engine),art=createArt(scene);try{const rock=art.part('ico',null,art.palette.stone,30,0,0,4,8,4),block=art.part('box',null,art.palette.stone,-20,3,0,4,4,4),originalIndices=Array.from(rock.getIndices()),originalPositions=Array.from(rock.getVerticesData('position'));const merged=mergeStaticMeshes([rock,block]);assert.ok(merged);assert.ok(rock.isDisposed());const actorPart=art.part('ico',null,art.palette.bone);assert.deepEqual(Array.from(actorPart.getIndices()),originalIndices);assert.deepEqual(Array.from(actorPart.getVerticesData('position')),originalPositions);assert.ok(Array.from(actorPart.getIndices()).every(i=>i<actorPart.getTotalVertices()));}finally{scene.dispose();engine.dispose();}
});
