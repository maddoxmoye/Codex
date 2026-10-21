import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const root=new URL('../',import.meta.url);
const read=name=>readFileSync(new URL(name,root));
const assets=[['rowan-motion.glb','godot-combat',['Idle','Run','Shoot','RunShoot','Windskip','Salvo']],['fox-motion.glb','godot-combat',['Idle','Trot','Attack']],['briarling-motion.glb','godot-monsters',['Idle','Run','Attack','Hit','Death']],['sporecaller-motion.glb','godot-monsters',['Idle','Run','Attack','Death']],['thornback-motion.glb','godot-monsters',['Idle','Run','Attack','Death']],['briar-king.glb','godot-boss',['Idle','Run','Melee','Ranged','Hit','Death']]];
for(const [file,source,clips] of assets)test('First Hunt uses the approved '+file+' with its real animation clips',()=>{
 const b=read('godot-arena/assets/'+file);assert.deepEqual(b,read(source+'/assets/'+file));assert.equal(b.toString('ascii',0,4),'glTF');const n=b.readUInt32LE(12),g=JSON.parse(b.toString('utf8',20,20+n));assert.equal(g.skins.length,1);assert(g.skins[0].joints.length<=23);for(const clip of clips)assert(g.animations.some(a=>a.name===clip),clip);
});
test('playable demo is isolated from campaign saving and uses its own Godot project',()=>{
 const project=read('godot-arena/project.godot').toString();assert(project.includes('res://arena.tscn'));const shell=read('godot-arena/web-shell.html').toString();assert(!shell.includes('localStorage'));assert(!shell.includes('sessionStorage'));assert(shell.includes('first-hunt-source.zip'));assert(read('godot-arena/check_hunt.gd').toString().includes('FIRST_HUNT_VALIDATION_OK'));
});
