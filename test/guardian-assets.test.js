import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {BOSSES} from '../src/game.js';
const root=new URL('../godot-boss/',import.meta.url);
const registry=JSON.parse(readFileSync(new URL('assets/guardians.json',root)));
function parse(file){const b=readFileSync(new URL(file,root));assert.equal(b.toString('ascii',0,4),'glTF');assert.equal(b.readUInt32LE(4),2);assert.equal(b.readUInt32LE(8),b.length);const n=b.readUInt32LE(12);return {g:JSON.parse(b.toString('utf8',20,20+n)),bin:b.subarray(28+n)};}
function rows(d,index){const a=d.g.accessors[index],v=d.g.bufferViews[a.bufferView],width={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16}[a.type],bytes={5121:1,5123:2,5125:4,5126:4}[a.componentType],read={5121:'readUInt8',5123:'readUInt16LE',5125:'readUInt32LE',5126:'readFloatLE'}[a.componentType];return Array.from({length:a.count},(_,i)=>Array.from({length:width},(_,j)=>d.bin[read]((v.byteOffset||0)+(a.byteOffset||0)+i*(v.byteStride||width*bytes)+j*bytes)));}

test('guardian progression matches the four campaign bosses and increases pressure',()=>{
 const all=Object.entries(registry);assert.equal(all.length,4);
 for(let i=0;i<4;i++){const [id,m]=all[i];assert.equal(m.name,BOSSES[i]);assert.equal(m.wave,(i+1)*5);assert.equal(m.tier,i+1);
 if(i){const previous=all[i-1][1];assert(m.health>previous.health);assert(m.melee.damage>previous.melee.damage);assert(m.ranged.damage>previous.ranged.damage);assert.deepEqual(m,JSON.parse(readFileSync(new URL('assets/'+id+'-motion.json',root))));}
 assert.equal(!!m.summon,i===3);}
 const summon=registry['gilded-colossus'].summon;assert.equal(summon.maxAlive,6);assert.equal(summon.releases.length*summon.perRelease,6);assert(summon.contact<summon.attackInterval);assert(summon.health>0&&summon.damage>0);
});
const hashes=[];
for(const id of ['frost-oracle','hollow-monarch','gilded-colossus'])test(id+' has a distinct complete skinned model, clips, sockets and editable source',()=>{
 const m=registry[id],d=parse(m.file),g=d.g;hashes.push(createHash('sha256').update(readFileSync(new URL(m.file,root))).digest('hex'));assert.equal(new Set(hashes).size,hashes.length);
 assert.equal(g.skins.length,1);assert.equal(g.skins[0].joints.length,23);assert.equal(g.materials.length,3);assert(m.triangles<10000);assert(m.heightMeters>3.5&&m.heightMeters<5.5);
 let triangles=0;for(const mesh of g.meshes)for(const p of mesh.primitives){const pos=rows(d,p.attributes.POSITION),w=rows(d,p.attributes.WEIGHTS_0),j=rows(d,p.attributes.JOINTS_0),indices=rows(d,p.indices).flat();triangles+=indices.length/3;assert(pos.every(r=>r.every(Number.isFinite)));assert(indices.every(i=>i>=0&&i<pos.length));assert(rows(d,p.attributes.TEXCOORD_0).every(r=>r.every(x=>x>0&&x<1)));w.forEach((r,i)=>{assert(Math.abs(r.reduce((a,b)=>a+b,0)-1)<1e-4);r.forEach((v,k)=>{if(v>0)assert(j[i][k]<23)});});}assert.equal(triangles,m.triangles);
 assert.deepEqual(g.animations.map(a=>a.name).sort(),Object.keys(m.clips).sort());const motions=[];for(const a of g.animations){assert(Math.abs(rows(d,a.samplers[0].input).at(-1)[0]-m.clips[a.name])<.04);const data=a.samplers.map(s=>rows(d,s.output));assert(data.some(v=>v.some(r=>JSON.stringify(r)!==JSON.stringify(v[0]))));motions.push(JSON.stringify(data));}assert.equal(new Set(motions).size,g.animations.length);
 for(const socket of Object.values(m.sockets)){assert(g.nodes.some(n=>n.name===socket.bone));assert(socket.local.every(Number.isFinite));}
 assert.equal(m.melee.events.length,2);assert(m.melee.events.every(t=>t>m.melee.warningStart&&t<m.clips.Melee));assert(m.ranged.releases.every(t=>t>m.ranged.warningStart&&t<m.clips.Ranged));
 assert(readFileSync(new URL('../art/blender/'+id+'.blend',root)).length>100000);assert(readFileSync(new URL('../art/blender/renders/'+id+'.png',root)).length>100000);
});
