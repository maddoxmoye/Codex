extends SceneTree
var failures: Array[String] = []
var stage: Node3D
var boss: Node3D
func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func sample(name: String, at: float) -> void:
	boss.player.stop()
	boss.player.play(name,0)
	boss.player.advance(0)
	boss.player.seek(at,true)
func advance(seconds: float, dt := .016) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var step := minf(dt,seconds-elapsed)
		boss.advance_simulation(step)
		elapsed += step
func run() -> void:
	stage = load("res://boss.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	boss = stage.boss
	check(boss.skeleton.get_bone_count()==23,"Boss uses bounded 23-bone skin")
	for clip in ["Idle","Run","Melee","Ranged","Hit","Death"]:
		check(boss.player.has_animation(clip),"Boss clip exists: "+clip)
		check(absf(boss.player.get_animation(clip).length-float(boss.metadata.clips[clip]))<.04,"Clip duration: "+clip)
	sample("Melee",1.0)
	var raised: Vector3 = boss.socket("knuckle")
	sample("Melee",float(boss.metadata.melee.contact))
	var strike: Vector3 = boss.socket("knuckle")
	print("MELEE_SOCKETS raised=",raised," impact=",strike)
	check(raised.y>2.75,"Heavy fist visibly rises above the shoulders")
	check(strike.y>=-.05 and strike.y<=.20,"Fist contacts the ground without sinking below it")
	check(raised.distance_to(strike)>2.0,"Melee has a distinct overhead-to-ground strike")
	for side in [".L",".R"]:
		var foot: Transform3D = boss.skeleton.global_transform*boss.skeleton.get_bone_global_pose(boss.skeleton.find_bone("foot"+side))
		check(absf(foot.origin.y-.17)<.04,"Stance foot stays planted during slam "+side)
	for step in [.016,.1,.6]:
		boss.command("Reset")
		boss.command("Melee")
		var slams: int = boss.slam_hits
		advance(1.0,step)
		check(boss.melee_warning.visible and boss.slam_hits==slams,"Melee warning precedes contact at dt="+str(step))
		advance(2.25,step)
		check(boss.slam_hits==slams+1,"Exactly one slam hit at dt="+str(step))
		check(not boss.melee_warning.visible,"Melee warning ends on impact")
		boss.command("Ranged")
		var shots: int = boss.thorn_shots
		var volleys: int = boss.volleys
		var impacts: int = boss.thorn_hits
		advance(1.0,step)
		check(boss.ranged_warning.visible and boss.thorn_shots==shots,"Ranged charge and warnings precede firing")
		advance(2.7,step)
		check(boss.volleys==volleys+3,"Exactly three salvos even with a skipped release frame")
		check(boss.thorn_shots==shots+9,"Three visible thorns per salvo")
		check(boss.thorn_hits==impacts+9,"All thorns follow fixed paths and hit the three target posts")
		check(boss.outgoing.is_empty(),"Thorns stop on target instead of passing through")
	# Pause/held charge must not create attacks, and reset/interruption remove warnings and projectiles.
	boss.command("HoldMelee")
	var slams: int = boss.slam_hits
	advance(5.0)
	check(boss.paused and boss.melee_warning.visible and boss.slam_hits==slams,"Held melee windup is safe to inspect")
	boss.command("HoldRanged")
	var shots: int = boss.thorn_shots
	advance(5.0)
	check(boss.paused and boss.ranged_warning.visible and boss.thorn_shots==shots,"Held ranged charge does not release thorns")
	boss.command("Ranged")
	advance(1.3)
	check(not boss.outgoing.is_empty(),"Ranged projectiles exist before interruption")
	boss.command("Arrow")
	advance(.7)
	check(boss.hp==1080 and boss.clip=="Hit","Actual arrow impact triggers boss health/recoil")
	check(boss.outgoing.is_empty() and not boss.melee_warning.visible and not boss.ranged_warning.visible,"Interrupted attack clears its effects")
	boss.command("Defeat")
	advance(3.2)
	check(boss.hp==0 and boss.clip=="Death","Defeat holds the authored collapse")
	for material in boss.glow_materials:check(material.albedo_color.r<.10,"Defeated heart, eyes and muzzle visibly darken")
	check(boss.outgoing.is_empty() and boss.waves.is_empty(),"Defeated boss leaves no damaging projectiles")
	boss.command("Demo")
	advance(90.0,.1)
	check(boss.outgoing.size()<=9 and boss.embedded.size()<=18 and boss.effects.size()<90,"Repeated demo effects stay bounded")
	check(boss.slam_hits>slams and boss.thorn_shots>shots,"Demo repeatedly demonstrates both attacks")
	# Fit the full body and the relevant warning/target area above the review controls.
	boss.command("Reset")
	for size in [Vector2i(1280,900),Vector2i(390,844)]:
		root.size = size
		for attack in ["Melee","Ranged"]:
			boss.command("Hold"+attack)
			stage.view_mode = "Arena"
			stage.update_camera(1)
			var points: Array[Vector3] = stage.bounds_points(boss.actor)
			if attack=="Melee":
				var radius: float = boss.metadata.melee.radius
				for x in [-radius,radius]:
					for z in [-radius,radius]:points.append(boss.melee_center+Vector3(x,0,z))
			else:
				for point in boss.target_points:points.append(point)
			for point in points:
				var screen: Vector2 = stage.camera.unproject_position(point)
				check(screen.x>0 and screen.x<size.x and screen.y>0 and screen.y<float(size.y)*.79,"Body and attack fit review frame: "+attack+" "+str(size))
	stage.free()
	if failures.is_empty():print("BOSS_VALIDATION_OK: grounded slam, nine-thorn ranged attack, warnings, hits, pause, interruption and defeat")
	else:print("BOSS_VALIDATION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
