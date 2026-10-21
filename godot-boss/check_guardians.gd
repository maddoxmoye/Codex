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
			var bursts: int = boss.giant_bursts
			var returns: int = boss.return_hits
			var ticks: int = boss.beam_ticks
			var shots: int = boss.thorn_shots
			advance(.8,dt)
			check(boss.ranged_warning.visible,id+" ranged telegraph")
			advance(2.9,dt)
			if id=="frost-oracle":
				check(boss.giant_bursts-bursts==1 and boss.thorn_shots-shots==9,"One enormous ice heart bursts once into eight shards")
				check(boss.thorn_hits>impacts and boss.outgoing.is_empty(),"Ice heart and fragments impact and expire")
			elif id=="hollow-monarch":
				check(boss.thorn_shots-shots==1 and boss.return_hits>returns,"One curved scythe deals separate outbound and return contacts")
				check(boss.thorn_hits-impacts<=10 and boss.outgoing.is_empty(),"Returning blade cannot repeatedly damage a post in one pass")
			else:
				check(boss.thorn_shots==shots and boss.beam_ticks-ticks>=7,"Sweeping beam crosses target line without spawning projectile volleys")
				check(not boss.beam.visible,"Beam stops after its active window")
		boss.command("Melee")
		advance(1.6)
		if id!="frost-oracle":check(boss.actor.position.z>2.0,id+" close attack actually moves through the corridor")
		else:
			check(boss.hazards.size()==1,"Ice cage remains in the world after eruption")
			check(boss.hazards[0].node.position.distance_to(boss.melee_center)<.01 and boss.hazards[0].node.scale.y>.95,"Ice prison holds full height at its target, without drifting or shrinking toward the boss")
		boss.command("Reset")
		var saved: Vector3 = boss.dummy.position
		boss.dummy.position.x = 5
		var safe_hits: int = boss.slam_hits
		boss.command("Melee")
		advance(3.45)
		check(boss.slam_hits==safe_hits,id+" dodging outside attack geometry avoids damage")
		boss.dummy.position = saved
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
	if failures.is_empty():print("GUARDIANS_VALIDATION_OK: three rigs, escalating patterns, giant ice heart, returning scythe, sweeping beam, bounded autonomous brood, pause, death, reset and camera")
	else:print("GUARDIANS_VALIDATION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
