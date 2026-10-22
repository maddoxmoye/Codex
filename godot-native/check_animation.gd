extends SceneTree
var failures: Array[String] = []
func check(ok: bool, description: String) -> void:
	if not ok:failures.append(description);push_error(description)
func _initialize() -> void:call_deferred("run")
func capture(unit: HuntUnit) -> Array[Transform3D]:
	var pose: Array[Transform3D] = []
	for i in unit.skeleton.get_bone_count():pose.append(unit.skeleton.get_bone_pose(i))
	return pose
func difference(a: Array[Transform3D], b: Array[Transform3D]) -> float:
	var distance := 0.0
	for i in a.size():distance+=a[i].origin.distance_to(b[i].origin)+a[i].basis.x.distance_to(b[i].basis.x)+a[i].basis.y.distance_to(b[i].basis.y)+a[i].basis.z.distance_to(b[i].basis.z)
	return distance
func advance(unit: HuntUnit, seconds: float, dt: float) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var step := minf(dt,seconds-elapsed)
		unit.pose(step);elapsed+=step
func run() -> void:
	var game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false);game.manual_test=true
	for id in ["rowan","fox","briarling","sporecaller","thornback","briar-king"]:
		var unit: HuntUnit=game.make_unit(id,Vector3.ZERO)
		for dt in [.016,.1]:
			for clip in unit.animation.get_animation_list():
				unit.play("Idle",true);advance(unit,.2,dt)
				unit.play(clip,true);advance(unit,.18,dt)
				var first := capture(unit)
				advance(unit,.32,dt)
				var second := capture(unit)
				var motion := difference(first,second)
				check(motion>.005,id+" / "+clip+" visibly changes bone transforms dt="+str(dt)+" motion="+str(motion))
				var held := capture(unit)
				for i in 5:unit.pose(0)
				check(difference(held,capture(unit))<.0001,id+" / "+clip+" stays frozen when paused")
		# A transition must blend toward the authored clip and finish on that clip.
		unit.play("Idle",true);advance(unit,.2,.016)
		var before_switch := capture(unit)
		unit.play("Run" if id!="fox" else "Trot",true)
		check(difference(before_switch,capture(unit))<.0001,id+" clip switch preserves the outgoing pose until the blend advances")
		unit.pose(.016)
		check(unit.blend_elapsed>0 and unit.blend_elapsed<unit.BLEND_DURATION,id+" transition clock advances")
		advance(unit,.1,.016)
		check(is_equal_approx(unit.blend_elapsed,unit.BLEND_DURATION),id+" transition completes")
		var actual := capture(unit)
		unit.animation.seek(unit.anim_time,true)
		check(difference(actual,capture(unit))<.0001,id+" final pose matches authored animation")
		unit.free()
	# Check real gameplay paths too, rather than only individual animation clips.
	game.start_run(true);game.auto_fire=false;game.stage="test";game.request={"move":[1,0]}
	for i in 12:game.simulate(.016)
	var moving := capture(game.player_unit)
	for i in 12:game.simulate(.016)
	check(difference(moving,capture(game.player_unit))>.1,"Gameplay movement animates Rowan's running limbs")
	game.request={"fire":true}
	for i in 12:game.simulate(.016)
	var draw := capture(game.player_unit)
	for i in 12:game.simulate(.016)
	check(difference(draw,capture(game.player_unit))>.1,"Gameplay shooting animates Rowan's bow draw")
	game.free()
	# Let the audio mix thread finish its scheduled stop/fade before engine exit.
	await create_timer(.15).timeout
	if failures.is_empty():print("FIRST_HUNT_ANIMATION_OK: every actor and clip moves, real run/shoot paths animate, transitions complete, pause holds poses")
	else:print("FIRST_HUNT_ANIMATION_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
