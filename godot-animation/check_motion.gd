extends SceneTree
func _init() -> void:
	call_deferred("validate")

func validate() -> void:
	var lab = load("res://motion-lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	var failures: Array[String] = []
	for name in ["Idle","Run","Shoot","RunShoot","Dodge","Windskip","Salvo"]:
		if not lab.player.has_animation(name):failures.append("Missing clip: "+name)
	if lab.skeleton.get_bone_count()!=22:failures.append("Wrong joint count")
	lab.set_mode("Shoot")
	for i in 30:lab.advance_simulation(0.025)
	var relaxed = lab.bone_point("bowstring")-lab.bone_point("bow")
	for i in 40:lab.advance_simulation(0.025)
	var drawn = lab.bone_point("bowstring")-lab.bone_point("bow")
	if drawn.distance_to(relaxed)<0.20:failures.append("String does not visibly draw")
	if not lab.nocked.visible:failures.append("No nocked arrow before release")
	for step in [0.016,0.1]:
		for name in ["Shoot","RunShoot"]:
			lab.set_mode(name)
			var shots = lab.shots
			var hits = lab.hits
			var elapsed := 0.0
			while elapsed<2.9:
				lab.advance_simulation(step)
				elapsed+=step
			if lab.shots-shots!=1:failures.append(name+" release is not exactly once at step "+str(step))
			if lab.hits-hits!=1:failures.append(name+" projectile did not physically cross the target at step "+str(step))
			if lab.nocked.visible:failures.append(name+" nocked arrow remains after release")
	lab.set_mode("Run")
	for i in 200:lab.advance_simulation(0.016)
	if lab.actor.position.distance_to(Vector3.ZERO)>0.05:failures.append("Run path does not return to its start")
	lab.set_mode("Dodge")
	for i in 30:lab.advance_simulation(0.016)
	if lab.actor.position.x<0.8:failures.append("Sidestep has no root movement")
	if lab.fox_skeleton.get_bone_count()!=21:failures.append("Fox paw rig has incorrect joint count")
	for name in ["Idle","Trot","Attack"]:
		if not lab.fox_player.has_animation(name):failures.append("Missing fox clip "+name)
	lab.fox_player.play("Trot",0)
	lab.fox_player.seek(0.0,true)
	var paw = lab.fox_skeleton.get_bone_global_pose(lab.fox_skeleton.find_bone("front_paw.L")).origin
	lab.fox_player.seek(0.40,true)
	var swing = lab.fox_skeleton.get_bone_global_pose(lab.fox_skeleton.find_bone("front_paw.L")).origin
	if paw.distance_to(swing)<0.05:failures.append("Fox paws do not move")
	for step in [0.016,0.1]:
		lab.fan_mode = false
		lab.set_mode("Salvo")
		var before = lab.shots
		var hit_before = lab.hits
		for i in range(int(1.5/step)):lab.advance_simulation(step)
		if lab.shots-before!=8:failures.append("Salvo must release exactly 8 arrows")
		if lab.hits-hit_before!=8:failures.append("Salvo must physically hit all 8 markers")
		if lab.trigger_ability("Salvo"):failures.append("Salvo cooldown allows an early recast")
	lab.fan_mode = true
	lab.set_mode("Salvo")
	for i in 40:lab.advance_simulation(0.016)
	var directions: Array[Vector3] = []
	for item in lab.projectiles:
		if item.empowered:directions.append(item.direction)
	if directions.size()!=8 or directions[0].distance_to(directions[7])<0.7:failures.append("No-target salvo has no eight-arrow fan")
	lab.fan_mode = false
	lab.set_mode("Windskip")
	lab.advance_simulation(0.1)
	if not lab.invulnerable:failures.append("Windskip invulnerability missing during burst")
	lab.advance_simulation(0.1)
	if absf(lab.actor.position.z-2.5)>0.01:failures.append("Windskip burst not completed within 0.19s")
	lab.advance_simulation(0.11)
	if lab.invulnerable:failures.append("Windskip invulnerability outlasts 0.30s")
	if lab.trigger_ability("Windskip"):failures.append("Windskip cooldown allows early recast")
	lab.set_mode("Idle")
	if not lab.trigger_ability("Windskip"):failures.append("Ready Windskip cannot be cast")
	for i in 180:lab.advance_simulation(0.016)
	if not lab.trigger_ability("Windskip"):failures.append("Windskip cooldown never recovers")
	lab.set_mode("Fox")
	var pet_before = lab.pet_shots
	var pet_hit_before = lab.pet_hits
	for i in 220:lab.advance_simulation(0.016)
	if lab.pet_shots-pet_before<3 or (lab.pet_shots-pet_before)%3!=0:failures.append("Fox must release three physical darts per attack")
	if lab.pet_hits-pet_hit_before<3:failures.append("Fox darts do not physically reach their target")
	lab.set_mode("Idle")
	lab.trigger_ability("Windskip")
	for i in 180:lab.advance_simulation(0.016)
	if lab.fox.position.distance_to(lab.actor.position)>1.8:failures.append("Fox does not catch up after dash")
	for i in 1800:lab.advance_simulation(0.016)
	if lab.projectiles.size()>30 or lab.stuck.size()>18 or lab.sparks.size()>150:failures.append("Preview effects grow without bounds")
	lab.view_mode = "Fox"
	lab.update_camera(1.0)
	if lab.actor.visible:failures.append("Rowan can obscure the fox detail camera")
	lab.view_mode = "Archer"
	lab.update_camera(1.0)
	if not lab.actor.visible:failures.append("Rowan stays hidden when leaving fox detail")
	for failure in failures:push_error(failure)
	print("MOTION_VALIDATION: ","PASS" if failures.is_empty() else "FAIL"," / string draw ",drawn.distance_to(relaxed)," / ",lab.shots," arrows / ",lab.hits," hits")
	lab.free()
	quit(0 if failures.is_empty() else 1)
