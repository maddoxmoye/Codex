extends SceneTree
var failures: Array[String] = []
var boss: Node3D
func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func advance(seconds: float, dt := .016) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var step := minf(dt,seconds-elapsed)
		boss.advance_simulation(step)
		elapsed += step
func run() -> void:
	var stage = load("res://boss.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	for id in ["frost-oracle","hollow-monarch","gilded-colossus"]:
		stage.select_boss(id)
		boss = stage.boss
		check(boss.skeleton.get_bone_count()==23,id+" bounded skeleton")
		for clip in boss.metadata.clips:
			check(boss.player.has_animation(clip),id+" clip "+clip)
		for dt in [.016,.1]:
			boss.command("Reset")
			boss.command("Melee")
			var hits: int = boss.slam_hits
			var damage: int = boss.close_damage
			advance(.8,dt)
			check(boss.melee_warning.visible and boss.slam_hits==hits,id+" warning before contact")
			advance(2.65,dt)
			check(boss.slam_hits==hits+2,id+" exactly two distinct close contacts")
			check(boss.close_damage-damage==int(boss.metadata.melee.damage*1.5),id+" escalating contact damage")
			boss.command("Ranged")
			var impacts: int = boss.thorn_hits
			var splits: int = boss.split_events
			var frost: int = boss.hazard_hits
			advance(.8,dt)
			check(boss.ranged_warning.visible,id+" ranged telegraph")
			advance(2.9,dt)
			var expected := 15 if id=="frost-oracle" else 20 if id=="hollow-monarch" else 21
			check(boss.thorn_hits-impacts==expected,id+" complete projectile pattern dt="+str(dt))
			if id=="hollow-monarch":check(boss.split_events-splits==10,"Ten orbs split once into twenty shards")
			if id=="frost-oracle":check(boss.hazard_hits-frost==15,"Each frost impact leaves a delayed damage tick")
		boss.command("HoldMelee")
		var hits: int = boss.slam_hits
		advance(5)
		check(boss.paused and boss.slam_hits==hits,id+" held pose has no damage")
		for size in [Vector2i(1280,900),Vector2i(390,844)]:
			root.size = size
			stage.view_mode = "Arena"
			stage.update_camera(1)
			for point in stage.bounds_points(boss.actor):
				var screen: Vector2 = stage.camera.unproject_position(point)
				check(screen.x>0 and screen.x<size.x and screen.y>0 and screen.y<size.y*.79,id+" model fits "+str(size))
		if id=="gilded-colossus":
			boss.command("Reset")
			boss.command("HoldSummon")
			advance(3)
			check(boss.living_minions()==0 and boss.summon_warning.visible,"Held furnace telegraphs without spawning")
			boss.command("Summon")
			advance(2.8)
			check(boss.living_minions()==6,"Six real skinned enemies emerge")
			var position: Vector3 = boss.minions[0].node.position
			boss.paused = true
			advance(5)
			check(boss.minions[0].node.position==position,"Pause freezes summoned enemies")
			boss.paused = false
			advance(8)
			check(boss.summon_hits>0,"Brood approaches and attacks independently")
			check(boss.peak_minions==6,"Repeated summon respects six living enemy cap")
			boss.command("BroodHit")
			boss.command("BroodHit")
			check(boss.living_minions()==5 and boss.summon_kills==1,"Summons can take damage and die")
			advance(2)
			boss.command("Summon")
			advance(2.8)
			check(boss.living_minions()==6,"Furnace replenishes defeated enemies without exceeding cap")
			boss.command("Defeat")
			var attacks: int = boss.summon_hits
			advance(3.2)
			check(boss.living_minions()==0 and boss.minions.is_empty() and boss.summon_hits==attacks,"Boss defeat cleans brood and stops their damage")
		boss.command("Demo")
		advance(90,.1)
		check(boss.outgoing.size()<50 and boss.effects.size()<180 and boss.hazards.size()<=30,id+" repeated effects bounded")
		boss.command("Reset")
		check(boss.minions.is_empty() and boss.hazards.is_empty() and boss.outgoing.is_empty(),id+" reset clears all attacks")
	stage.select_boss("briar-king")
	check(stage.boss.study_id=="briar-king","Original King retained after selection")
	stage.select_boss("invalid")
	check(stage.boss.study_id=="briar-king","Invalid selection ignored")
	stage.free()
	if failures.is_empty():print("GUARDIANS_VALIDATION_OK: three rigs, escalating patterns, lingering frost, split shots, bounded autonomous brood, pause, death, reset and camera")
	else:print("GUARDIANS_VALIDATION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
