extends SceneTree
func _init() -> void:
	call_deferred("validate")
func validate() -> void:
	var stage = load("res://bestiary.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	stage.select_model("briarling")
	var enemy = stage.briar
	var failures: Array[String] = []
	if enemy.skeleton.get_bone_count()!=13:failures.append("Briarling motion rig must have 13 bones")
	for name in ["Idle","Run","Attack","Hit","Death"]:
		if not enemy.player.has_animation(name):failures.append("Missing "+name)
		enemy.player.stop()
		enemy.player.play(name,0)
		enemy.player.advance(0)
		enemy.player.seek(0,true)
		var before: Array = []
		for i in enemy.skeleton.get_bone_count():before.append(enemy.skeleton.get_bone_pose(i))
		enemy.player.seek(float(enemy.metadata.clips[name])*0.4,true)
		var changed := false
		for i in enemy.skeleton.get_bone_count():
			if not enemy.skeleton.get_bone_pose(i).is_equal_approx(before[i]):changed = true
		if not changed:failures.append(name+" has no authored movement")
	enemy.player.stop()
	enemy.player.play("Attack",0)
	enemy.player.advance(0)
	enemy.player.seek(0.30,true)
	var socket: Array = enemy.metadata.clawSocket.L
	var transform: Transform3D = enemy.skeleton.global_transform*enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("claw.L"))
	var raised: Vector3 = transform*Vector3(socket[0],socket[1],socket[2])
	enemy.player.seek(float(enemy.metadata.attackContact),true)
	transform = enemy.skeleton.global_transform*enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("claw.L"))
	var strike: Vector3 = transform*Vector3(socket[0],socket[1],socket[2])
	if strike.z-raised.z<0.20:failures.append("Claws do not travel forward from windup to strike")
	for dt in [0.016,0.1]:
		enemy.command("Reset")
		enemy.command("Attack")
		var contacts: int = enemy.contacts
		for i in range(int(1.6/dt)):enemy.advance_simulation(dt)
		if enemy.contacts-contacts!=1:failures.append("Attack contact must fire once at timestep "+str(dt))
		if enemy.clip!="Idle":failures.append("Attack fails to recover to idle")
		enemy.command("Reset")
		enemy.command("Attack")
		enemy.advance_simulation(0.2)
		contacts = enemy.contacts
		enemy.take_damage(20)
		for i in range(int(1.3/dt)):enemy.advance_simulation(dt)
		if enemy.contacts!=contacts:failures.append("Interrupted windup still inflicts its contact event")
		enemy.command("Reset")
		var hits: int = enemy.hits
		for n in 3:
			if not enemy.command("Arrow"):failures.append("Ready arrow test rejected")
			if enemy.command("Arrow"):failures.append("Duplicate in-flight arrow accepted")
			for i in range(int(0.95/dt)):enemy.advance_simulation(dt)
			if enemy.hp!=60-(n+1)*20:failures.append("Arrow damage not synchronized to swept capsule hit at timestep "+str(dt))
		if enemy.hits-hits!=3 or enemy.hp!=0 or enemy.clip!="Death":failures.append("Three arrows must defeat the 60 HP target exactly once")
		if enemy.command("Arrow"):failures.append("Dead target accepts another arrow")
		if not enemy.command("Reset") or enemy.hp!=60:failures.append("Reset fails to restore target")
	enemy.command("Run")
	enemy.paused = true
	var time: float = enemy.phase
	enemy.advance_simulation(0.1)
	if enemy.phase!=time:failures.append("Pause does not freeze animation")
	enemy.paused = false
	enemy.command("Demo")
	var arrows: int = enemy.arrows_fired
	for i in 2400:enemy.advance_simulation(0.016)
	if enemy.arrows_fired-arrows<6:failures.append("Demo does not run multiple attack/hit/defeat cycles")
	if enemy.effects.size()>40:failures.append("Effects accumulate without bounds")
	stage.select_model("sporecaller")
	if enemy.active or enemy.hp_root.visible or enemy.dummy.visible:failures.append("Motion study leaks into the other monster design views")
	for error in failures:push_error(error)
	print("BRIARLING_MOTION_VALIDATION: ","PASS" if failures.is_empty() else "FAIL")
	stage.free()
	quit(0 if failures.is_empty() else 1)
