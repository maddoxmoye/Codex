extends SceneTree
## Verify the native locomotion layer independently of the camera or frame rate.
var failures: Array[String] = []

func check(ok: bool, description: String) -> void:
	if not ok:failures.append(description);push_error(description)

func _initialize() -> void:call_deferred("run")

func make_actor(id: String) -> HuntUnit:
	var unit := HuntUnit.new()
	root.add_child(unit)
	unit.configure(id)
	return unit

func bones(unit: HuntUnit) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i in unit.skeleton.get_bone_count():result.append(unit.skeleton.get_bone_pose(i))
	return result

func difference(a: Array[Transform3D], b: Array[Transform3D]) -> float:
	var total := 0.0
	for i in a.size():total+=a[i].origin.distance_to(b[i].origin)+a[i].basis.x.distance_to(b[i].basis.x)+a[i].basis.y.distance_to(b[i].basis.y)+a[i].basis.z.distance_to(b[i].basis.z)
	return total

func bow_direction(unit: HuntUnit) -> Vector3:
	return (unit.socket("bow")-unit.socket("bowstring")).normalized()

func run() -> void:
	var rowan := make_actor("rowan")
	var authored := make_actor("rowan")
	rowan.configure_motion(Vector3(3,0,3),1.0/60)
	rowan.motion_velocity=rowan.motion_target
	rowan.gait_weight=1
	rowan.play("Shoot",true);authored.play("Shoot",true)
	var previous := bones(rowan)
	var leg_motion := 0.0
	var worst_aim_error := 0.0
	# Aim and release sockets remain on the approved attack while hips/feet strafe.
	for frame in 180:
		rowan.pose(1.0/60);authored.pose(1.0/60)
		if frame>5:
			worst_aim_error=maxf(worst_aim_error,bow_direction(rowan).distance_to(bow_direction(authored)))
		var current := bones(rowan)
		for bone in rowan.gait_bones:leg_motion+=previous[bone].basis.y.distance_to(current[bone].basis.y)+previous[bone].basis.z.distance_to(current[bone].basis.z)
		previous=current
	check(worst_aim_error<.001,"Moving upper-body bow aim stays aligned with the authored attack: "+str(worst_aim_error))
	check(leg_motion>10,"Feet keep running throughout the independent shooting animation")
	var clock_before := rowan.gait_time
	rowan.play("RunShoot",true);rowan.pose(.016)
	check(rowan.gait_time>clock_before,"Restarting a shot never restarts the stride phase")
	var frozen := bones(rowan)
	for i in 5:rowan.pose(0)
	check(difference(frozen,bones(rowan))<.0001,"Paused layered running and shooting hold exactly still: "+str(difference(frozen,bones(rowan))))
	# Deceleration settles into the authored idle, with no drifting rig origin.
	rowan.configure_motion(Vector3.ZERO,.016);rowan.play("Idle",true)
	for i in 120:rowan.pose(1.0/60)
	check(rowan.motion_velocity.length()<.001 and rowan.gait_weight<.001,"Stopping settles the gait without continued foot cycling")
	check(rowan.position==Vector3.ZERO,"Presentation layer never moves the collision body")
	rowan.reset_motion()
	check(rowan.motion_velocity==Vector3.ZERO and rowan.gait_time==0 and rowan.turning_lean==0,"A new run clears momentum, gait phase and turn lean")
	# Fixed-step versus slower frames must cover nearly the same animation distance.
	var phases: Array[float]=[]
	for dt in [1.0/60,.1]:
		rowan.reset_motion();rowan.configure_motion(Vector3(0,0,5),dt);rowan.play("Run",true)
		for i in int(round(2/dt)):rowan.pose(dt)
		phases.append(rowan.gait_time)
	check(absf(phases[0]-phases[1])<.09,"Distance-driven gait stays consistent at 10 and 60 simulation steps per second")
	# The fox retains its authored trot and only adds bounded tail follow-through.
	var fox := make_actor("fox")
	fox.configure_motion(Vector3(0,0,4.5),1.0/60);fox.play("Trot",true)
	var fox_start := bones(fox)
	var peak_lean := 0.0
	for i in 180:
		fox.rotation.y+=.08*sin(float(i)*.06)
		fox.pose(1.0/60)
		peak_lean=maxf(peak_lean,absf(fox.turning_lean))
	check(difference(fox_start,bones(fox))>.5,"Fox trot moves the rig during travel")
	check(peak_lean<=.11001 and peak_lean>.02,"Fox turn follow-through remains small and bounded")
	check(fox.position==Vector3.ZERO,"Fox secondary motion cannot pull or launch the pet body")
	var frozen_fox := bones(fox)
	for i in 5:fox.pose(0)
	check(difference(frozen_fox,bones(fox))<.0001,"Paused fox trot and tail hold still")
	fox.configure_motion(Vector3.ZERO,.016);fox.play("Attack",true)
	for i in 50:fox.pose(1.0/60)
	check(fox.motion_velocity.length()<.001,"Fox attack settles travel before its next movement")
	rowan.free();authored.free();fox.free()
	if failures.is_empty():print("EMBERWOOD_MOTION_OK: independent aim/gait, continuous shots, pause, stop, cadence, stable fox and attack transitions")
	else:print("EMBERWOOD_MOTION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
