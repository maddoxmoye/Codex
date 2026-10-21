import test from 'node:test';
import assert from 'node:assert/strict';
import {clearProgressStorage} from '../src/progress-storage.js';
import {formatDamage} from '../src/combat-feedback.js';
const storage=()=>{const map=new Map([['wildfall-run','checkpoint'],['wildfall-unlocks','unlocks'],['wildfall-best','321'],['wildfall-quality','low'],['wildfall-camera-mode','free']]);return {map,getItem:key=>map.get(key)??null,setItem:(key,value)=>map.set(key,value),removeItem:key=>map.delete(key)};};
test('deleting a saved run preserves unlocks, best score and display preferences',()=>{
 const s=storage();assert.equal(clearProgressStorage(s,'run'),true);assert.equal(s.getItem('wildfall-run'),null);assert.equal(s.getItem('wildfall-unlocks'),'unlocks');assert.equal(s.getItem('wildfall-best'),'321');assert.equal(s.getItem('wildfall-camera-mode'),'free');
});
test('full reset removes only game progress and preserves preferences',()=>{
 const s=storage();assert.equal(clearProgressStorage(s,'all'),true);assert.equal(s.getItem('wildfall-run'),null);assert.equal(s.getItem('wildfall-unlocks'),null);assert.equal(s.getItem('wildfall-best'),null);assert.equal(s.getItem('wildfall-quality'),'low');assert.equal(s.getItem('wildfall-camera-mode'),'free');
});
test('storage failure restores previous progress rather than claiming a successful reset',()=>{
 const s=storage(),before=[...s.map];let failed=false;const remove=s.removeItem;s.removeItem=key=>{if(key==='wildfall-unlocks'&&!failed){failed=true;throw new Error('storage unavailable');}remove(key);};assert.equal(clearProgressStorage(s,'all'),false);assert.deepEqual([...s.map].sort(),before.sort());assert.equal(clearProgressStorage(s,'unknown'),false);
});
test('damage labels retain fractional ticks and never round positive damage to zero',()=>{
 assert.equal(formatDamage(18),'18');assert.equal(formatDamage(2.375),'2.4');assert.equal(formatDamage(.04),'0.04');assert.equal(formatDamage(.001),'<0.01');
});
