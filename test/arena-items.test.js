import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const root = new URL('../', import.meta.url);
const read = name => readFileSync(new URL(name, root), 'utf8');
const items = JSON.parse(read('godot-arena/assets/items.json'));
const effects = new Set([
  'damage', 'damage_bonus', 'max_hp', 'armor', 'speed_bonus', 'pickup_radius',
  'economy', 'salvage', 'gold_bonus', 'heal', 'attack_speed', 'pet_damage',
  'elemental_power', 'crit', 'heal_kill', 'regen', 'haste', 'revive',
  'burn_bonus', 'venom_bonus', 'duration', 'element_bonus', 'slow_bonus', 'stacks',
]);
const rarities = new Set(['common', 'uncommon', 'rare', 'mythic']);

test('Godot item catalog has unique identifiers and complete purchasable item data', () => {
  assert(Array.isArray(items) && items.length > 0);
  assert.equal(new Set(items.map(item => item.id)).size, items.length);
  assert.equal(new Set(items.map(item => item.name)).size, items.length);
  for (const item of items) {
    assert.match(item.id, /^[a-z][a-z0-9-]*$/, item.name);
    for (const field of ['name', 'description', 'icon']) {
      assert.equal(typeof item[field], 'string', `${item.id}.${field}`);
      assert(item[field].trim().length > 0, `${item.id}.${field}`);
    }
    assert(Number.isInteger(item.price) && item.price > 0, `${item.id} price`);
    assert(Number.isInteger(item.cap) && item.cap > 0, `${item.id} cap`);
    assert(rarities.has(item.rarity), `${item.id} rarity`);
    assert(['gear', 'utility', 'element'].includes(item.category), `${item.id} category`);
    assert(['', 'fire', 'ice', 'poison'].includes(item.element), `${item.id} element`);
    assert.equal(item.category === 'element', item.element !== '', `${item.id} element category`);
    assert(item.effects && !Array.isArray(item.effects), `${item.id} effects`);
    assert(Object.keys(item.effects).length > 0, `${item.id} has a gameplay effect`);
    for (const [effect, value] of Object.entries(item.effects)) {
      assert(effects.has(effect), `${item.id} unknown effect ${effect}`);
      assert(Number.isFinite(value) && value > 0, `${item.id}.${effect} positive numeric effect`);
    }
  }
});

test('every catalog item has an actual SVG design rather than relying on the fallback icon', () => {
  const shell = read('godot-arena/web-shell.html');
  const registry = shell.match(/const iconPaths=\{([\s\S]*?)\};/);
  assert(registry, 'item icon registry');
  const icons = new Set([...registry[1].matchAll(/(?:^|\n)([a-z]+):'/g)].map(match => match[1]));
  for (const item of items) assert(icons.has(item.icon), `${item.id}: missing ${item.icon} design`);
});

test('each element has damage and duration options while shared power and economy remain element independent', () => {
  for (const [element, damageEffects] of [
    ['fire', ['burn_bonus', 'element_bonus']],
    ['ice', ['element_bonus']],
    ['poison', ['venom_bonus']],
  ]) {
    const gear = items.filter(item => item.element === element);
    assert(gear.some(item => damageEffects.some(key => key in item.effects)), `${element} damage gear`);
    assert(gear.some(item => 'duration' in item.effects), `${element} duration gear`);
  }
  for (const effect of ['elemental_power', 'economy', 'pickup_radius', 'salvage']) {
    assert(items.some(item => item.element === '' && effect in item.effects), `shared ${effect} equipment`);
  }
  for (const item of items.filter(item => item.rarity === 'mythic')) {
    assert.equal(item.cap, 1, `${item.id} mythic cannot be stacked`);
  }
  assert(items.some(item => item.rarity === 'mythic' && item.effects.revive === 1));
});
