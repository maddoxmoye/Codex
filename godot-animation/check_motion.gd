extends SceneTree
func _init() -> void:
	call_deferred("validate")

func validate() -> void:
	var lab = load("res://motion-lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	var failures: Array[String] = []
	for name in ["Idle","Run","Shoot","RunShoot","Dodge"]:
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
	for failure in failures:push_error(failure)
	print("MOTION_VALIDATION: ","PASS" if failures.is_empty() else "FAIL"," / string draw ",drawn.distance_to(relaxed)," / ",lab.shots," arrows / ",lab.hits," hits")
	lab.free()
	quit(0 if failures.is_empty() else 1)
