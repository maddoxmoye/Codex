extends RefCounted
## Earned chests are a ledger independent of combat cleanup and opening presentation.
const NORMAL_DROP := .035
const NORMAL_WEIGHTS := {"common":48.0,"uncommon":36.0,"rare":15.0,"mythic":1.0}
const MYTHIC_WEIGHTS := {"mythic":1.0}
var game: Node3D
var ground: Array[Dictionary]=[]
var queue: Array[Dictionary]=[]
var current: Dictionary={}
var serial := 0
var revision := 0
func setup(target: Node3D) -> void:game=target
func reset() -> void:
	for entry in ground:entry.node.queue_free()
	ground.clear();queue.clear();current.clear();revision+=1
func spawn(point: Vector3, mythic := false) -> void:
	var chest := Node3D.new();game.add_child(chest);chest.position=point
	var color := "ba4631" if mythic else "4e8062"
	game.mesh_part(game.box(Vector3(.65,.4,.45)),game.material(color,.15),chest,Vector3(0,.22,0))
	game.mesh_part(game.box(Vector3(.7,.15,.48)),game.material(color,.2),chest,Vector3(0,.49,0))
	for x in [-.22,.22]:game.mesh_part(game.box(Vector3(.06,.51,.48)),game.material("e9bf72",.4),chest,Vector3(x,.3,0))
	serial+=1;ground.append({"node":chest,"mythic":mythic,"token":serial})
func collect(index: int) -> void:
	var entry := ground[index];queue.append({"mythic":entry.mythic,"token":entry.token});entry.node.queue_free();ground.remove_at(index);revision+=1
func collect_all() -> void:
	while not ground.is_empty():collect(0)
	queue.sort_custom(func(a,b):return not a.mythic and b.mythic)
func update(dt: float) -> void:
	for i in range(ground.size()-1,-1,-1):
		var entry := ground[i];entry.node.rotation.y+=dt*.4
		if entry.node.position.distance_to(game.player_unit.position)<float(game.run_stats.pickup_radius):collect(i)
func draw(mythic: bool) -> Dictionary:
	var pool: Array=[]
	var weights: Dictionary=MYTHIC_WEIGHTS if mythic else NORMAL_WEIGHTS
	for item in game.build.catalog:
		if item.has("arrow_type") or item.effects.has("fox") or item.effects.has("wolf") or item.effects.has("beetle"):continue
		if game.build.eligible(item,game.equipped) and weights.has(item.rarity):pool.append(item)
	# A completed Mythic collection falls back to premium rare gear, never a duplicate.
	if pool.is_empty() and mythic:
		for item in game.build.catalog:
			if item.rarity=="rare" and game.build.eligible(item,game.equipped):pool.append(item)
	if pool.is_empty():return {"id":"treasure-gold","name":"Trader's Gold","rarity":"rare","description":"A purse of 20 gold.","effects":{"gold":20},"price":20,"icon":"coin","element":"","cap":999}
	var total := 0.0
	for item in pool:total+=float(weights.get(item.rarity,1))
	var ticket: float=game.rng.randf()*total
	for item in pool:
		ticket-=float(weights.get(item.rarity,1))
		if ticket<=0:return item.duplicate(true)
	return pool.back().duplicate(true)
func open_next() -> bool:
	if queue.is_empty():current.clear();return false
	current=queue.pop_front();current.item=draw(bool(current.mythic));current.rerolls=0;revision+=1
	return true
func reroll_price() -> int:
	return maxi(1,ceili((4+game.wave*2+int(current.get("rerolls",0))*5)*(1-float(game.run_stats.economy)/100)))
func sell_price() -> int:
	return maxi(3,int(game.build.price(current.item)*.30)) if not current.is_empty() else 0
func resolve(action: String, token: int) -> bool:
	if game.stage!="chest" or current.is_empty() or token!=int(current.token):return false
	if action=="reroll":
		var cost := reroll_price()
		if game.gold<cost:return false
		game.gold-=cost;current.rerolls+=1;current.item=draw(bool(current.mythic));revision+=1;return true
	if action=="take":
		var item: Dictionary=current.item
		if item.effects.has("gold"):game.earn_gold(float(item.effects.gold))
		else:
			var before: float=game.player_unit.maximum
			game.build.record(item,"chest")
			if item.has("arrow_type"):game.set_element(item.arrow_type)
			game.refresh_build();game.player_unit.hp=minf(game.player_unit.maximum,game.player_unit.hp+maxf(0,game.player_unit.maximum-before))
	elif action=="sell":game.earn_gold(sell_price())
	else:return false
	current.clear();revision+=1;game.advance_rewards();return true
func view() -> Dictionary:
	return {"current":current,"queued":queue.size(),"ground":ground.size(),"revision":revision,"rerollCost":reroll_price(),"sellPrice":sell_price()}
