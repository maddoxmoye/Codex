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
	game.free();await create_timer(.15).timeout
	if failures.is_empty():print("EMBERWOOD_CAMPAIGN_OK: ",assertions," guardian choreography, release and cleanup assertions")
	else:print("EMBERWOOD_CAMPAIGN_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
