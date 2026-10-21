extends SceneTree
var game: Node3D
var failures: Array[String] = []
func check(ok: bool, description: String) -> void:
	if not ok:failures.append(description);push_error(description)
func _initialize() -> void:call_deferred("run")
func advance(seconds: float, dt := .016) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var step := minf(dt,seconds-elapsed)
		game.simulate(step);elapsed+=step
func empty_arena() -> void:
	game.start_run(false)
	for enemy in game.enemies:enemy.free()
	game.enemies.clear();game.auto_fire=false;game.stage="test";game.request={};game.invulnerable=0
	game.player_unit.position=Vector3.ZERO;game.fox.position=Vector3(-4,0,0);game.fox_cooldown=100
func run() -> void:
	game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false)
	check(game.player_unit.animation.has_animation("RunShoot") and game.player_unit.animation.has_animation("Salvo"),"Approved Rowan clips loaded")
	check(absf(game.player_unit.base_aim)<PI*2,"Finite actual bow direction")
	check(absf(game.segment_time(Vector3.ZERO,Vector3(0,0,10),Vector3(0,0,3),1)-.2)<.0001,"Projectile collision finds the first surface, rather than nearest center")
	check(game.segment_time(Vector3.ZERO,Vector3(0,0,10),Vector3(3,0,3),1)==INF,"Off-path actors do not absorb arrows")
	for step in [.016,.1]:
		empty_arena()
		game.set_element("physical")
		var near=game.spawn_enemy("briarling",Vector3(0,0,3));var far=game.spawn_enemy("briarling",Vector3(0,0,5))
		near.cooldown=100;far.cooldown=100
		game.fire_arrow(Vector3(0,.73,0),Vector3.BACK,"player",1,false)
		# Only projectile advancement: targets stay at their initial positions.
		for i in int(1.0/step):game.update_projectiles(step)
		check(is_equal_approx(near.hp,48) and is_equal_approx(far.hp,70),"Physical arrow stops at the first actor dt="+str(step))
		empty_arena();game.set_element("fire")
		var fire=game.spawn_enemy("thornback",Vector3(0,0,4))
		game.damage_enemy(fire,0,"fire")
		for i in int(ceil(3.0/step)):game.update_status(fire,step)
		check(absf(fire.hp-(145-18))<.1,"Fire burn applies six 3-damage ticks dt="+str(step))
		empty_arena();game.set_element("poison")
		var poison=game.spawn_enemy("thornback",Vector3(0,0,4))
		for i in 6:game.damage_enemy(poison,0,"poison")
		check(poison.poison_stacks==4,"Poison has a four-stack cap")
		for i in int(ceil(1.0/step)):game.update_status(poison,step)
		check(absf(poison.hp-133)<.1,"Four poison stacks tick for six damage each half-second")
		var power: float=game.elemental_power
		game.set_element("ice")
		check(poison.poison_time==0 and poison.poison_stacks==0 and game.elemental_power==power,"Swap clears previous element benefits and preserves base elemental power")
		game.damage_enemy(poison,0,"ice")
		check(poison.ice_time>0 and poison.fire_time==0,"Ice alone applies after swap")
		empty_arena();game.request={"move":[1,0]}
		var start: Vector3=game.player_unit.position
		advance(.5,step)
		check(game.player_unit.position.distance_to(start)>2,"Movement advances through the map dt="+str(step))
		check(game.cast_dash(),"Dash is available")
		check(not game.cast_dash(),"Dash cooldown prevents spam")
		var hp: float=game.player_unit.hp
		check(not game.hurt_player(36,"test") and game.player_unit.hp==hp,"Dash invulnerability blocks boss damage")
		advance(.35,step)
		check(game.hurt_player(36,"test") and game.player_unit.hp==hp-36,"Damage resumes after dash invulnerability")
		check(not game.hurt_player(36,"test"),"Post-hit invulnerability prevents repeated instant hits")
		empty_arena();game.set_element("fire")
		game.spawn_enemy("briar-king",Vector3(0,0,8))
		check(game.cast_salvo() and not game.cast_salvo(),"Salvo can cast once per cooldown")
		advance(.7,step)
		check(game.shots==8,"Flock & Awe releases eight physical arrow meshes at authored release")
		game.paused=true
		var before: Dictionary=game.snapshot();advance(3,step)
		check(game.snapshot()==before,"Pause freezes combat, status timers and cooldowns")
		check(not game.cast_dash() and not game.cast_salvo(),"Paused casts are blocked")
	# Body/environment collision and movement limits.
	empty_arena()
	var rock: Dictionary=game.obstacles[22]
	var clipped: Vector3=game.clamp_position(rock.p,.4)
	check(clipped.distance_to(rock.p)>=float(rock.r)+.39,"Solid rock pushes player outside its collision radius")
	check(game.clamp_position(Vector3(40,0,0),.4).length()<=17.61,"Arena boundary contains player")
	for i in 60:
		var angle: float=i*TAU/60
		check(game.clamp_position(Vector3(sin(angle),0,cos(angle))*30,.4).length()<=17.61,"Obstacle pushback cannot move player beyond boundary")
	# Boss has real targeting and authored releases; slam can be avoided by leaving the warning.
	empty_arena();game.player_unit.position=Vector3(0,0,2.5)
	var king=game.spawn_enemy("briar-king",Vector3.ZERO)
	game.begin_attack(king)
	check(king.clip=="Melee" and is_instance_valid(king.warning),"King selects melee nearby and creates warning")
	game.player_unit.position=Vector3(8,0,8)
	for i in 220:game.update_enemy(king,.016)
	check(game.taken==0,"Leaving the marked slam avoids damage")
	king.cooldown=0;game.begin_attack(king)
	check(king.clip=="Ranged","King selects ranged at distance")
	for i in 130:game.update_enemy(king,.016)
	check(game.projectiles.size()==9,"Three real three-thorn salvos release from the cannon")
	# Ranged hazard and pet do damage independently of chosen element.
	empty_arena();game.add_spores(Vector3.ZERO)
	check(game.taken==10 and game.hazards.size()==1,"Spore burst damages inside its splash radius")
	game.player_unit.position=Vector3(5,0,5);game.invulnerable=0
	game.update_hazards(.8)
	check(game.taken==10,"Moving out of spore pool avoids its ticks")
	empty_arena();game.fox_cooldown=0;game.set_element("poison")
	var target=game.spawn_enemy("thornback",Vector3(0,0,4));target.cooldown=100
	game.fox.position=Vector3(-1,0,1)
	for i in 200:
		game.update_fox(.016);game.update_projectiles(.016)
	check(game.pet_hits>0 and target.hp<145 and target.poison_stacks==0,"Fox attacks physically and independently of player's element")
	# Encounter progression, pickup radius, defeat and clean restart.
	empty_arena();game.stage="skirmish";game.wave_left=.01
	advance(.1);check(game.stage=="shop","Timed wave opens camp shop")
	check(game.continue_run() and game.wave==2,"Camp continues to stronger second wave")
	game.wave_left=.01;advance(.1)
	check(game.stage=="shop" and game.continue_run() and game.wave==3 and game.boss_spawned,"Second camp starts the King wave")
	game.start_run(true);check(game.enemies.size()==1 and game.enemies[0].kind=="briar-king","Boss practice starts directly at King")
	game.invulnerable=0;game.hurt_player(200,"test")
	check(game.ended and not game.victory and game.player_unit.hp==0,"Player defeat ends the encounter")
	game.start_run(true)
	check(not game.ended and game.player_unit.hp==140 and game.player_unit.actor.rotation.z==0,"Restart restores health and actor pose")
	game.damage_enemy(game.enemies[0],1200,"physical")
	check(game.ended and game.victory,"Killing King ends in victory")
	empty_arena();game.spawn_pickup(Vector3(5,0,0));game.update_pickups(.1)
	check(game.gold==0,"Distant pickups are not collected")
	game.player_unit.position=Vector3(5,0,0)
	for i in 30:game.update_pickups(.016)
	check(game.gold==6 and game.experience==12,"Pickup radius collects nearby gold and XP")
	game.free()
	if failures.is_empty():print("FIRST_HUNT_VALIDATION_OK: movement, first-hit arrows, elements, status swaps, ability cooldowns, invulnerability, pause, collision, boss AI, pet, pickups, victory/defeat and restart")
	else:print("FIRST_HUNT_VALIDATION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
