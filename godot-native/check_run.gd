extends SceneTree
var game: Node3D
var failures: Array[String] = []
func check(ok: bool, description: String) -> void:
	if not ok:failures.append(description);push_error(description)
func _initialize() -> void:call_deferred("run")
func stock(ids: Array) -> void:
	game.build.offers.clear();game.build.element_slots.clear()
	for id in ids:
		for item in game.build.catalog:
			if item.id==id:
				var offer: Dictionary=item.duplicate(true);offer.sold=false;game.build.offers.append(offer)
func advance(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var dt := minf(.016,seconds-elapsed);game.simulate(dt);elapsed+=dt
func run() -> void:
	game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false);game.manual_test=true
	game.start_run(false);game.auto_fire=false
	check(game.wave==1 and game.wave_left==45,"Normal run begins at 45 seconds")
	check(not game.buy_item("quiver") and not game.reroll_shop() and not game.continue_run(),"Combat cannot access shop actions")
	game.gold=10;game.player_unit.hp=100
	game.spawn_pickup(Vector3(8,0,8));game.spawn_pickup(Vector3(7,0,8))
	game.gain_xp(48)
	game.wave_left=0;game.update_encounter(.016)
	check(game.stage=="training" and game.level==2 and game.pending_levels.size()==1,"Ground XP is fully absorbed and opens a separate level reward before shop")
	check(game.gold==36 and game.experience==12,"50% of twelve ground gold plus twenty bounty is awarded once")
	check(game.player_unit.hp==125 and game.pickups.is_empty() and game.enemies.is_empty(),"Camp recovery and combat cleanup happen once")
	var previous_gold: int=game.gold;game.finish_wave();check(game.gold==previous_gold,"Wave cannot be settled twice")
	check(game.build.draft.size()==4 and not game.buy_item("quiver") and not game.continue_run(),"Four distinct free training options gate the shop")
	var token: int=game.build.draft_revision
	var id: String=game.build.draft[0].id
	check(not game.choose_training(id,token-1),"Stale training clicks are rejected")
	check(game.choose_training(id,token) and game.stage=="shop","One free pick advances to shop")
	check(not game.choose_training(id,token),"Same training reward cannot be claimed twice")
	check(game.build.offers.size()==4,"Shop opens with exactly four items")
	var time: float=game.clock;var health: float=game.player_unit.hp
	advance(3)
	check(game.clock==time and game.player_unit.hp==health,"Shop freezes combat, regen, timers and abilities")
	check(not game.cast_dash() and not game.cast_salvo(),"Abilities cannot fire through shop menus")
	game.gold=100;stock(["quiver","seal","compass","lodestone"])
	var old_arrow: float=game.run_stats.damage
	check(game.buy_item("quiver") and game.run_stats.damage==old_arrow+3,"Buying an actual quiver updates arrow damage")
	var spent: int=game.gold
	check(not game.buy_item("quiver") and game.gold==spent,"Sold slot cannot be charged again")
	var base_cost: int=game.build.price(game.build.offers[2])
	check(game.buy_item("seal") and game.run_stats.economy==10,"Merchant seal adds dedicated Economy stat")
	check(game.build.price(game.build.offers[2])<base_cost,"Economy reprices remaining items")
	check(game.buy_item("compass") and is_equal_approx(game.run_stats.pickup_radius,2.65),"Gathering Compass expands actual pickup radius")
	check(game.buy_item("lodestone") and game.elemental_power>=12,"Lodestone raises shared elemental power")
	check(game.build.offers.all(func(item):return item.sold),"All four items can be bought in one visit")
	var first: int=game.build.reroll_price();var coins: int=game.gold
	check(game.reroll_shop() and game.gold==coins-first,"Reroll charges current discounted cost")
	check(game.build.reroll_price()>first and game.build.offers.size()==4,"Reroll price increases within visit and produces four fresh items")
	game.gold=0;var revision: int=game.build.revision
	check(not game.reroll_shop() and game.build.revision==revision,"Unaffordable reroll cannot alter inventory")
	# Element-specific purchases are discarded on swap; shared power survives.
	game.set_element("fire");game.gold=100;stock(["ember-vial","cinder","coalglass","heartwood"])
	check(game.buy_item("ember-vial") and game.run_stats.burn_bonus>.3,"Fire vial improves actual burn multiplier")
	var shared: float=game.elemental_power
	game.set_element("ice")
	check(game.run_stats.burn_bonus==0 and game.elemental_power==shared,"Swapping to ice removes fire benefits but preserves shared elemental power")
	game.set_element("fire")
	check(game.run_stats.burn_bonus==0,"Swapping back does not restore discarded elemental gear")
	stock(["quiver","ember-vial","cinder","coalglass"])
	game.set_element("physical")
	var plain_stock: Array=[]
	for offer in game.build.offers:
		check(offer.element=="" and game.build.eligible(offer,"physical"),"Plain arrows replace elemental slots with eligible general items")
		check(offer.id not in plain_stock,"Fallback stock has four distinct items")
		plain_stock.append(offer.id)
	game.set_element("ice");game.set_element("physical")
	for i in game.build.offers.size():
		check(game.build.offers[i].id==plain_stock[i],"Cycling elements cannot reroll general fallback items for free")
	game.set_element("fire")
	for item in game.build.catalog:
		if item.element=="ice":game.build.ranks[item.id]=int(item.cap)
	game.set_element("ice")
	for offer in game.build.offers:
		check(game.build.eligible(offer,"ice"),"Exhausted elemental stock falls back to eligible general items")
	game.set_element("fire")
	# Mythic ownership remains unique after its one-use effect is consumed.
	game.gold=500;stock(["heartwood"])
	check(game.buy_item("heartwood"),"Mythic relic can be bought")
	var mythic: Dictionary={}
	for item in game.build.catalog:
		if item.id=="heartwood":mythic=item
	check(not game.build.eligible(mythic,"fire"),"Owned mythic cannot appear again")
	check(game.continue_run() and game.wave==2 and game.wave_left==45,"Continue starts second timed wave with build intact")
	check(game.run_stats.damage>22 and game.run_stats.pickup_radius>2,"Items carry into actual next-wave stats")
	check(game.enemies[0].maximum>70 or game.enemies[0].kind!="briarling","Second-wave enemies scale up")
	game.invulnerable=0;game.player_unit.hp=1
	var relic_revision: int=game.build.revision
	var taken_before: float=game.taken
	check(game.hurt_player(100,"test") and not game.ended and game.build.revive_used,"Heartwood relic prevents one lethal hit")
	check(game.build.revision>relic_revision,"Consuming relic refreshes inventory presentation")
	check(game.taken>taken_before and game.effects.any(func(item):return item.label),"Relic-triggering hit still reports damage and an incoming number")
	game.invulnerable=0;game.hurt_player(1000,"test")
	check(game.ended,"Relic cannot prevent a second lethal hit")
	game.build.record({"id":"bloodroot","effects":{"heal_kill":1}},"shop");game.refresh_build()
	game.damage_enemy(game.enemies[0],10000,"physical")
	check(game.player_unit.hp==0,"Late hits cannot heal an already defeated player")
	# Independent camp visits reset reroll cost; multiple level rewards are never lost.
	game.start_run(false);game.stage="shop";game.gold=200;game.build.open_shop(1,"fire")
	game.reroll_shop();game.reroll_shop();check(game.build.rerolls==2,"First camp records rerolls")
	game.continue_run();game.gain_xp(180);game.wave_left=0;game.update_encounter(.016)
	check(game.stage=="training" and game.pending_levels.size()==2,"Multiple gained levels each receive their own reward")
	check(game.build.rerolls==0 and game.build.reroll_price()==7,"Second visit resets rerolls to its low wave-adjusted base")
	for i in 2:
		var choice: String=game.build.draft[0].id
		check(game.choose_training(choice,game.build.draft_revision),"Queued level reward can be selected")
	check(game.stage=="shop" and game.pending_levels.is_empty(),"All queued level rewards resolve before shop")
	game.continue_run();check(game.wave==3 and game.wave_left==75,"Boss wave starts at 75 seconds")
	var king: HuntUnit
	for enemy in game.enemies:
		if enemy.kind=="briar-king":king=enemy
	check(is_equal_approx(king.maximum,2592),"Full-run King has the durability to test an upgraded build")
	game.damage_enemy(king,king.hp,"physical")
	check(not game.ended,"Killing King early does not end the timed boss wave")
	game.wave_left=0;game.update_encounter(.016)
	check(game.ended and game.victory and game.stage=="complete","Run ends after both King defeat and timer expiry")
	game.start_run(false);game.wave=2;game.stage="shop";game.build.open_shop(2,"fire");game.continue_run()
	game.wave_left=0;game.update_encounter(.016)
	check(not game.ended and game.stage=="boss","Living King causes overtime rather than disappearing")
	# Seeded offer invariants over many rerolls.
	for element in ["fire","ice","poison","physical"]:
		for i in 50:
			game.build.roll(element)
			var ids: Array=[]
			for offer in game.build.offers:
				check(offer.id not in ids,"Shop never repeats an item within its four slots")
				check(offer.element=="" or offer.element==element,"Shop filters element-specific gear")
				ids.append(offer.id)
	game.start_run(false)
	check(game.build.history.is_empty() and game.gold==0 and game.level==1 and game.pending_levels.is_empty() and game.run_stats.damage==22,"Restart clears run inventory and restores base stats")
	game.free()
	# Let the audio mix thread finish its scheduled stop/fade before engine exit.
	await create_timer(.15).timeout
	if failures.is_empty():print("THREE_WAVE_RUN_OK: timed waves, settlement, level drafts, four-item shop, purchase effects, rerolls, economy, elements, mythic uniqueness, boss timing and reset")
	else:print("THREE_WAVE_RUN_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
