import test from 'node:test';
import assert from 'node:assert/strict';
import {cameraClearance,resolveFollowCamera} from '../src/follow-camera.js';
import {SOLIDS,WORLD} from '../src/world.js';

test('an unobstructed follow camera preserves its orbit, height and zoom',()=>{
 const focus={x:0,y:.95,z:0},c=resolveFollowCamera(focus,.52,3.1,8.7,[]);assert.equal(c.clearance,8.7);assert.equal(c.offset,0);assert.ok(Math.abs(c.y-4.05)<1e-9);
});
test('a camera can see underneath a high tree canopy without treating it as a ground-level wall',()=>{
 const focus={x:0,y:.95,z:0},camera={x:0,y:1.4,z:8.7},tree={type:'tree',x:.8,z:2,scale:1};assert.equal(cameraClearance(focus,camera,[tree]),1);
});
test('close obstacles cause a safe orbit adjustment instead of a close-up inside the character',()=>{
 const focus={x:0,y:.95,z:0},solids=[{x:0,z:1.5,r:1,height:2}];const c=resolveFollowCamera(focus,0,3.1,8.7,solids);assert.ok(c.clearance>=4.4);assert.notEqual(c.offset,0);assert.ok(cameraClearance(focus,c,solids)>.95);
});
test('camera framing stays playable throughout the campaign biome centers, including the marsh edge',()=>{
 const obstacles=SOLIDS.map(o=>({...o,x:(o.x-WORLD.width/2)/100,z:(o.y-WORLD.height/2)/100,r:(o.cameraR||o.r)/100,height:o.height/100}));
 for(const [x,z] of [[2400,2000],[1000,1250],[3700,1250],[3400,3450]]){const focus={x:(x-2400)/100,y:.95,z:(z-2000)/100},c=resolveFollowCamera(focus,.52,3.1,8.7,obstacles);assert.ok(c.clearance>=4.4,`${x},${z}`);assert.ok([c.x,c.y,c.z].every(Number.isFinite));}
});
