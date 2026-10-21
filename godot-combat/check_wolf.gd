extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok and message not in failures:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var lab = load("res://motion-lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab.view_mode = "Pet"
	lab.set_mode("Pet")
	for pattern in [[.008],[.016],[.033],[.1],[.016,.1,.025,.08,.008]]:
		lab.select_companion("wolf")
		var elapsed := 0.0
		var frame := 0
		var changes := 0
		var completed_bites := 0
		var completed_howls := 0
		var previous_clip := ""
		var previous_time := 0.0
		var previous_bites := 0
		var previous_howls := 0
		var since_bite := 100.0
		var since_howl := 100.0
		while elapsed<30.0:
			var dt: float = pattern[frame%pattern.size()]
			var position: Vector3 = lab.fox.position
			var yaw: float = lab.fox.rotation.y
			var poses: Array[Transform3D] = []
			for i in lab.fox_skeleton.get_bone_count():poses.append(lab.fox_skeleton.get_bone_pose(i))
			lab.advance_simulation(dt)
			elapsed += dt
			since_bite += dt
			since_howl += dt
			check(lab.fox.position.distance_to(position)<=lab.WOLF_SPEED*dt+.00001,"Wolf movement stays bounded at varying frame rates")
			check(absf(angle_difference(yaw,lab.fox.rotation.y))<=lab.WOLF_TURN_SPEED*dt+.00001,"Wolf facing never snaps or oscillates faster than its turn limit")
			check(is_zero_approx(lab.fox.position.y),"Wolf root stays on the ground")
			if previous_clip!=lab.fox_clip:changes += 1
			if previous_clip=="Bite" and (lab.fox_clip!="Bite" or lab.fox_time<previous_time):
				check(previous_time+dt>=lab.fox_player.get_animation("Bite").length-.00001,"Bite completes recovery before being restarted or interrupted")
				completed_bites += 1
			if previous_clip=="Howl" and lab.fox_clip!="Howl":
				check(previous_time+dt>=lab.fox_player.get_animation("Howl").length-.00001,"Howl completes before moving again")
				completed_howls += 1
			if lab.wolf_state in ["Bite","Howl"] and previous_clip==lab.fox_clip:
				check(lab.fox.position.distance_to(position)<.00001,"Wolf remains planted during attacks")
			if lab.bites!=previous_bites:
				check(lab.bites==previous_bites+1 and lab.wolf_state=="Bite","One damage event per bite")
				check(since_bite>=float(lab.fox_metadata.biteCooldown)-.00001,"Wolf bites respect cooldown")
				since_bite = 0
			if lab.howls!=previous_howls:
				check(lab.howls==previous_howls+1 and lab.wolf_state=="Howl","One pulse per howl")
				check(since_howl>=float(lab.fox_metadata.howlCooldown)-.00001,"Wolf howls respect cooldown")
				since_howl = 0
			if lab.wolf_state=="Roam":check(lab.fox_clip in ["Idle","Trot"],"Arriving at a roaming destination never starts a bite")
			for i in poses.size():
				var pose: Transform3D = lab.fox_skeleton.get_bone_pose(i)
				check(pose.is_finite(),"Wolf bone transforms remain finite")
				if previous_clip!=lab.fox_clip and not previous_clip.is_empty():
					var before := poses[i].basis.get_rotation_quaternion()
					var after := pose.basis.get_rotation_quaternion()
					check(before.angle_to(after)<=1.0,"Wolf transition blends bound sudden bone rotation")
			previous_clip = lab.fox_clip
			previous_time = lab.fox_time
			previous_bites = lab.bites
			previous_howls = lab.howls
			frame += 1
		check(changes<=40,"Wolf does not chatter between movement and attack states")
		check(completed_bites>=6 and completed_howls>=2,"Wolf continues to perform full bite/howl cycles")
		print("WOLF_STABILITY_CHECK ",pattern," · ",changes," clip changes in 30s · ",completed_bites," full bites · ",completed_howls," full howls")
	# Leaving pet view freezes the study; returning must not skip through a clip.
	lab.view_mode = "Archer"
	var pet_time: float = lab.pet_elapsed
	for i in 120:lab.advance_simulation(.016)
	check(is_equal_approx(lab.pet_elapsed,pet_time),"Hidden pet does not accumulate a large time jump")
	lab.view_mode = "Pet"
	lab.paused = true
	lab._process(.5)
	check(is_equal_approx(lab.pet_elapsed,pet_time),"Pause freezes wolf movement and animation")
	lab.paused = false
	for pet in ["beetle","wolf","fox","wolf"]:
		lab.select_companion(pet)
		lab.advance_simulation(.016)
		check(lab.wolf_blend_from.size()<=lab.fox_skeleton.get_bone_count(),"Switching companions clears old blend bones")
	lab.free()
	if failures.is_empty():print("WOLF_STABILITY_OK: stable movement, bounded turns, complete clips, pose blends and single attack events")
	else:print("WOLF_STABILITY_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
