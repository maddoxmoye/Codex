extends SceneTree
var failures: Array[String]=[]
var assertions := 0
func check(ok: bool, message: String) -> void:
	assertions+=1
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false);game.manual_test=true
	for wave in [5,10,15,20]:
		game.start_run(false);game.clear_combat();game.wave=wave;game.stage="boss";game.spawn_boss();game.invulnerable=100
		var boss: HuntUnit=game.enemies[0]
		check(boss.kind==game.Campaign.BOSSES[wave],"Approved guardian at wave "+str(wave))
		for action in (["Melee","Ranged","Summon"] if wave==20 else ["Melee","Ranged"]):
			game.bosses.begin(boss,action)
			check(boss.clip==action and is_instance_valid(boss.warning),boss.kind+" animates and telegraphs "+action)
			for i in 300:
				game.bosses.update(boss,1.0/60)
				game.update_projectiles(1.0/60);game.update_effects(1.0/60)
			if action=="Summon":check(game.bosses.brood_count()==6,"Colossus emits six bounded brood from its hatch")
		game.clear_combat()
		check(game.enemies.is_empty() and game.projectiles.is_empty(),"Guardian cleanup removes attacks and adds")
	game.start_run(false);game.clear_combat();game.stage="skirmish"
	game.rewards.spawn(Vector3(12,0,0));game.rewards.spawn(Vector3(-12,0,0))
	check(game.rewards.ground.size()==2,"Two earned chests remain on ground")
	game.rewards.spawn(game.player_unit.position);game.rewards.update(.016)
	check(game.rewards.queue.size()==1,"Nearby earned chest collects manually")
	game.gain_xp(60);game.wave_left=0;game.update_encounter(.016)
	check(game.stage=="chest" and game.rewards.ground.is_empty() and game.rewards.queue.size()==2,"Wave auto-collects every chest and opens queue before levels")
	game.native_hud.refresh()
	var reveal=game.native_hud.modal_panel.find_child("ChestReveal",true,false)
	check(reveal!=null and not reveal.finished,"Dedicated native reveal starts before claim buttons")
	if reveal:
		reveal.set_process(false);reveal.advance(2.1)
		check(reveal.finished and reveal.lid.rotation.x< -1.8 and reveal.treasure.visible,"Native chest opens and reward rises before completion")
	for i in 3:
		var token: int=game.rewards.current.token
		check(game.rewards.resolve("take",token),"Sequential chest can be claimed")
		check(not game.rewards.resolve("take",token),"Stale chest claim cannot duplicate reward")
	check(game.stage=="training","Level rewards follow the complete chest queue")
	for killed_boss in [false,true]:
		for wave in [5,10,15,20]:
			game.start_run(false);game.clear_combat();game.wave=wave;game.stage="boss";game.spawn_boss()
			var boss: HuntUnit=game.enemies[0]
			if killed_boss:game.damage_enemy(boss,boss.hp,"physical")
			check(game.rewards.ground.size()==(1 if killed_boss else 0),"Only actual boss death earns a Mythic chest at wave "+str(wave))
			game.wave_left=0;game.update_encounter(.016)
			if killed_boss:
				check(game.stage=="chest" and game.rewards.current.mythic and game.rewards.ground.is_empty(),"Earned Mythic auto-collects at wave end")
				check(game.rewards.current.item.rarity=="mythic","Guardian chest uses premium Mythic table")
				game.rewards.resolve("take",game.rewards.current.token)
			else:check(game.rewards.current.is_empty() and game.rewards.queue.is_empty(),"Timer survival awards no Mythic chest")
			if wave==20:check(game.victory==killed_boss and game.ended,"Final victory requires actual kill and resolves final rewards first")
			else:check(not game.ended and game.stage in ["shop","training"],"Living or defeated guardian permits campaign progression")
	# Pet choreography and collection run independently of player arrows.
	game.start_run(false);game.clear_combat();game.stage="test";game.player_unit.position=Vector3.ZERO;game.obstacles.clear()
	game.build.record({"id":"pet-test","effects":{"wolf":1,"beetle":1}},"shop");game.refresh_build()
	var target: HuntUnit=game.spawn_enemy("thornback",Vector3(2,0,0));target.maximum=10000;target.hp=10000
	game.spawn_pickup(Vector3(3,0,2))
	for frame in 720:
		game.pets.update(1.0/60)
		for actor in game.pets.actors:check(actor.position.is_finite() and actor.position.distance_to(game.player_unit.position)<12,"Pet motion stays finite and leashed")
	check(game.pets.states[0].bites>0 and game.pets.states[0].howls>0 and target.hp<10000,"Wolf bites and howls using its independent physical kit")
	check(game.pets.states[1].collected==1 and game.pickups.is_empty() and game.gold==2 and game.experience==12,"Beetle collection credits real loot exactly once")
	for i in 100:
		var reward: Dictionary=game.rewards.draw(false)
		check(not reward.has("arrow_type") and not reward.effects.has("fox") and not reward.effects.has("wolf") and not reward.effects.has("beetle"),"Arrow types and pet recruitment remain trader acquisitions")
	# Entire 20-wave state machine, including alternating boss-survival outcomes.
	game.start_run(false)
	for wave in range(1,21):
		check(game.wave==wave and game.wave_left==game.Campaign.duration(wave),"Correct timer at campaign wave "+str(wave))
		var guardians: Array=game.enemies.filter(func(unit):return game.Campaign.is_boss(unit.kind))
		check(guardians.size()==(1 if wave%5==0 else 0),"Boss schedule exact at wave "+str(wave))
		if wave in [5,15,20]:game.damage_enemy(guardians[0],1000000,"physical")
		game.wave_left=0;game.update_encounter(.016)
		var limit := 0
		while game.stage in ["chest","training"] and limit<30:
			if game.stage=="chest":game.rewards.resolve("take",game.rewards.current.token)
			else:game.choose_training(game.build.draft[0].id,game.build.draft_revision)
			limit+=1
		check(limit<30,"Reward queue terminates at wave "+str(wave))
		if wave<20:check(game.continue_run(),"Can enter next wave "+str(wave+1))
	check(game.ended and game.victory and game.boss_kills==[5,15,20],"Full campaign records actual kills, survives Oracle, and wins only after Colossus")
	# Closed-form price checks protect the current trader formula at late waves.
	game.build.reset();game.build.character_base={}
	for wave in [1,5,10,20,25]:
		game.build.shop_wave=wave
		for rarity in ["common","uncommon","rare","mythic"]:
			var item := {"id":"price-probe","price":20,"rarity":rarity}
			game.build.ranks[item.id]=2
			game.build.history.clear();game.build.history.append({"status":"active","effects":{"economy":60}})
			var expected := ceili((20+wave+20*.1*wave)*float(game.build.SHOP_RARITY_PRICE_MULTIPLIERS[rarity])*1.2*.6-1e-9)
			check(game.build.price(item)==expected,"Exact rarity / copy / capped Economy price "+rarity+" wave "+str(wave))
	# Defensive investment matters without flattening late damage.
	game.start_run(false);game.clear_combat();game.stage="test";game.invulnerable=0
	var strike: float=24*game.Campaign.damage_scale(20)
	game.hurt_player(strike,"Late thornback")
	check(game.ended,"Unarmored base build dies to a late heavy attack")
	game.start_run(false);game.clear_combat();game.stage="test";game.invulnerable=0
	game.build.record({"id":"defense-test","effects":{"max_hp":100,"armor":16}},"shop");game.refresh_build();game.player_unit.hp=game.player_unit.maximum
	game.hurt_player(strike,"Late thornback")
	check(not game.ended and game.player_unit.hp>130,"Health and armor investment survives the same late attack")
	game.free();await create_timer(.15).timeout
	if failures.is_empty():print("EMBERWOOD_CAMPAIGN_OK: ",assertions," guardian choreography, release and cleanup assertions")
	else:print("EMBERWOOD_CAMPAIGN_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
