import test from 'node:test';
import assert from 'node:assert/strict';
import * as T from 'three';
import {createEnemyBatch,createPickupBatch} from '../src/instance-batch.js';

const camera=()=>{const c=new T.PerspectiveCamera(60,1,.1,100);c.position.set(0,2,8);c.lookAt(0,1,0);c.updateMatrixWorld();return c;};
const makeRoot=(geometry,material,x=0)=>{const root=new T.Group(),body=new T.Group();body.add(new T.Mesh(geometry,material));root.add(body);root.position.x=x;root.userData.body=body;return root;};
test('enemy instances share draws while preserving transforms and independent elemental tints',()=>{
 const scene=new T.Scene(),geometry=new T.BoxGeometry(),material=new T.MeshStandardMaterial({color:'white'}),batch=createEnemyBatch(scene),a=makeRoot(geometry,material,-1),b=makeRoot(geometry,material,1),burning={burn:1},ordinary={};
 batch.register(a);batch.register(b);batch.update(new Map([[burning,a],[ordinary,b]]),camera());const draws=scene.children.filter(o=>o.isInstancedMesh);assert.equal(draws.length,1);const draw=draws[0];assert.equal(draw.count,2);assert.equal(a.userData.body.visible,false);
 const matrix=new T.Matrix4(),color=new T.Color();draw.getMatrixAt(1,matrix);assert.equal(matrix.elements[12],1);draw.getColorAt(0,color);assert.ok(color.r>color.g);draw.getColorAt(1,color);assert.equal(color.r,color.g);assert.equal(material.color.getHexString(),'ffffff');
 burning.burn=0;batch.update(new Map([[burning,a],[ordinary,b]]),camera());draw.getColorAt(0,color);assert.equal(color.r,color.g);batch.dispose();geometry.dispose();material.dispose();
});
test('batching omits distant enemies and removes stale instances after despawn',()=>{
 const scene=new T.Scene(),geo=new T.BoxGeometry(),mat=new T.MeshStandardMaterial(),batch=createEnemyBatch(scene),near=makeRoot(geo,mat),far=makeRoot(geo,mat,1000);batch.register(near);batch.register(far);batch.update(new Map([[{},near],[{},far]]),camera());const draw=scene.children[0];assert.equal(draw.count,1);batch.update(new Map(),camera());assert.equal(draw.count,0);assert.equal(draw.visible,false);let disposed=false;draw.addEventListener('dispose',()=>disposed=true);batch.dispose();assert.ok(disposed);assert.equal(scene.children.length,0);geo.dispose();mat.dispose();
});
test('pickup instances grow for large loot piles and reset counts without stale gold',()=>{
 const scene=new T.Scene(),coin=new T.CylinderGeometry(),gem=new T.OctahedronGeometry(),mat=new T.MeshStandardMaterial(),batch=createPickupBatch(scene,{coin,gem},{coin:mat,xp:mat,heal:mat});
 batch.update(Array.from({length:600},()=>({kind:'coin',x:2400,y:2000})),0);const draw=scene.children.find(o=>o.geometry===coin);assert.equal(draw.count,600);assert.ok(draw.instanceMatrix.count>=600);const matrix=new T.Matrix4();draw.getMatrixAt(0,matrix);assert.equal(matrix.elements[12],0);assert.equal(matrix.elements[14],0);batch.update([],1);assert.equal(draw.count,0);batch.dispose();assert.equal(scene.children.length,0);coin.dispose();gem.dispose();mat.dispose();
});
