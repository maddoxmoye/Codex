extends RefCounted
## Run inventory and offers; the arena validates the current gameplay phase.
const RARITY_WEIGHTS := {"common":50.0,"uncommon":30.0,"rare":12.0,"mythic":1.0}
const BASE := {"max_hp":140.0,"damage":22.0,"damage_bonus":0.0,"elemental_power":8.0,"armor":0.0,"speed_bonus":0.0,"pickup_radius":2.0,"economy":0.0,"salvage":.5,"gold_bonus":0.0,"attack_speed":0.0,"pet_damage":1.0,"crit":0.0,"heal_kill":0.0,"regen":0.0,"haste":0.0,"revive":0.0,"burn_bonus":0.0,"venom_bonus":0.0,"duration":0.0,"element_bonus":0.0,"slow_bonus":0.0,"stacks":4.0}
const TRAINING := [
	{"id":"vitality","name":"Vitality","icon":"heart","description":"+18 maximum health and heal 18.","effects":{"max_hp":18}},
	{"id":"power","name":"Marksmanship","icon":"arrow","description":"+3 base arrow damage.","effects":{"damage":3}},
	{"id":"arcana","name":"Elemental mastery","icon":"gem","description":"+3 shared elemental power for any element.","effects":{"elemental_power":3}},
	{"id":"guard","name":"Resilience","icon":"shield","description":"+1 armor. Reduce damage from every attack.","effects":{"armor":1}},
	{"id":"stride","name":"Footwork","icon":"boots","description":"+5% movement speed.","effects":{"speed_bonus":.05}}
]
var catalog: Array = []
var history: Array[Dictionary] = []
var ranks := {}
var offers: Array[Dictionary] = []
var element_slots := {}
var draft: Array[Dictionary] = []
var rerolls := 0
var shop_wave := 1
var revision := 0
var draft_revision := 0
var revive_used := false
var rng := RandomNumberGenerator.new()

func _init() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items.json"))
	rng.randomize()

func reset() -> void:
	history.clear();ranks.clear();offers.clear();element_slots.clear();draft.clear();rerolls=0;shop_wave=1;revive_used=false;revision+=1;draft_revision+=1

func stats() -> Dictionary:
	var result := BASE.duplicate()
	for entry in history:
		if entry.status!="active":continue
		for key in entry.effects:
			if result.has(key):result[key]+=float(entry.effects[key])
	result.economy=minf(50,result.economy)
	result.haste=minf(.45,result.haste)
	result.crit=minf(.6,result.crit)
	result.salvage=minf(.75,result.salvage)
	return result

func eligible(item: Dictionary, element: String) -> bool:
	if item.element!="" and item.element!=element:return false
	if int(ranks.get(item.id,0))>=int(item.cap):return false
	var s := stats()
	if item.id=="seal" and s.economy>=50:return false
	if item.id=="watch" and s.haste>=.45:return false
	return true

func sample(pool: Array, count: int) -> Array[Dictionary]:
	var available := pool.duplicate()
	var chosen: Array[Dictionary] = []
	while not available.is_empty() and chosen.size()<count:
		var total := 0.0
		for item in available:total+=float(RARITY_WEIGHTS.get(item.get("rarity","common"),50))
		var ticket := rng.randf()*total
		var index := 0
		while index<available.size()-1 and ticket>=float(RARITY_WEIGHTS.get(available[index].get("rarity","common"),50)):
			ticket-=float(RARITY_WEIGHTS.get(available[index].get("rarity","common"),50));index+=1
		chosen.append(available.pop_at(index).duplicate(true))
	return chosen

func roll(element: String, varied := false) -> void:
	var pool: Array = []
	for item in catalog:
		if eligible(item,element):pool.append(item)
	offers.clear();element_slots.clear()
	if varied:
		for category in ["utility","element","gear"]:
			var group: Array = []
			for item in pool:
				if item.category==category:group.append(item)
			var chosen := sample(group,1)
			if not chosen.is_empty():offers.append(chosen[0]);pool=pool.filter(func(item):return item.id!=chosen[0].id)
	offers.append_array(sample(pool,4-offers.size()))
	for offer in offers:offer.sold=false
	for i in offers.size():
		if offers[i].element!="":element_slots[i]={element:offers[i].duplicate(true)}
	revision+=1

func open_shop(wave: int, element: String) -> void:
	shop_wave=wave;rerolls=0;roll(element,true)

func price(item: Dictionary) -> int:
	var base := float(item.price)*(1+.15*int(ranks.get(item.id,0)))
	return maxi(1,int(ceil(base*(1-float(stats().economy)/100)-1e-9)))

func reroll_price() -> int:
	return maxi(1,int(ceil((5+(shop_wave-1)*2+rerolls*5)*(1-float(stats().economy)/100)-1e-9)))

func record(item: Dictionary, source: String) -> void:
	var entry := item.duplicate(true)
	entry.source=source;entry.status="used" if item.effects.has("heal") else "active"
	history.append(entry)
	if source=="shop":ranks[item.id]=int(ranks.get(item.id,0))+1
	revision+=1

func buy(id: String, coins: int, element: String) -> Dictionary:
	for offer in offers:
		if offer.id!=id or offer.sold:continue
		if not eligible(offer,element):return {}
		var cost := price(offer)
		if coins<cost:return {}
		offer.sold=true
		record(offer,"shop")
		return {"cost":cost,"item":offer.duplicate(true)}
	return {}

func reroll(coins: int, element: String) -> int:
	var cost := reroll_price()
	if coins<cost:return -1
	rerolls+=1;roll(element)
	return cost

func prepare_training() -> void:
	draft=sample(TRAINING,4);draft_revision+=1

func choose_training(id: String, token: int) -> Dictionary:
	if token!=draft_revision:return {}
	for item in draft:
		if item.id==id:
			record(item,"level");draft.clear();draft_revision+=1
			return item
	return {}

func discard_element(element: String, next: String) -> void:
	for entry in history:
		if entry.get("element","")==element and entry.status=="active":
			entry.status="discarded";ranks.erase(entry.id)
	# Keep the same slots and cache each variant until a paid reroll/new camp.
	# Plain arrows (or exhausted elemental stock) receive a general-item fallback.
	var used: Array = []
	for i in offers.size():
		if not element_slots.has(i) and offers[i].element!="":element_slots[i]={element:offers[i].duplicate(true)}
		if not element_slots.has(i) or offers[i].sold:used.append(offers[i].id)
	for i in offers.size():
		if not element_slots.has(i) or offers[i].sold:continue
		var pool: Array = []
		for item in catalog:
			if item.category=="element" and eligible(item,next) and item.id not in used:pool.append(item)
		if pool.is_empty():
			for item in catalog:
				if item.element=="" and eligible(item,next) and item.id not in used:pool.append(item)
		var cached: Dictionary=element_slots[i].get(next,{})
		if not cached.is_empty() and eligible(cached,next) and cached.id not in used:
			offers[i]=cached.duplicate(true)
		else:
			var chosen := sample(pool,1)
			if not chosen.is_empty():
				offers[i]=chosen[0];element_slots[i][next]=offers[i].duplicate(true)
		offers[i].sold=false;used.append(offers[i].id)
	revision+=1

func view(coins: int, element := "fire") -> Dictionary:
	var stock: Array = []
	for offer in offers:
		var card := offer.duplicate(true)
		card.cost=price(offer);card.owned=int(ranks.get(offer.id,0));card.eligible=eligible(offer,element);card.affordable=coins>=card.cost
		stock.append(card)
	return {"offers":stock,"rerolls":rerolls,"rerollCost":reroll_price(),"revision":revision,"draft":draft,"draftRevision":draft_revision,"history":history,"stats":stats(),"reviveUsed":revive_used}
