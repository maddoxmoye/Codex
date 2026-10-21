extends SceneTree
var failures: Array[String] = []
var lab: Node3D
func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:
	call_deferred("run")
func advance(seconds: float, dt := 0.016) -> void:
	var elapsed := 0.0
	while elapsed<seconds:
		var step := minf(dt,seconds-elapsed)
		lab.advance_simulation(step)
		elapsed += step
func sample(clip: String, time: float) -> void:
	lab.player.stop()
	lab.player.play(clip,0)
	lab.player.advance(0)
	lab.player.seek(time,true)
func run() -> void:
	lab = load("res://motion-lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab.select_companion("wolf")
	for id in ["rowan","ash","briar","nyx","pip"]:
		lab.select_character(id)
		check(lab.skeleton.get_bone_count()==22,id+" skeleton budget")
		for name in ["Idle","Run","Shoot",str(lab.metadata.space),str(lab.metadata.attack)]:
			check(lab.player.has_animation(name),id+" missing "+name)
			check(absf(lab.player.get_animation(name).length-float(lab.metadata.clips[name]))<.075,id+" duration "+name+": "+str(lab.player.get_animation(name).length))
		sample("Shoot",.75)
		var rest: Vector3 = lab.bone_point("bowstring")-lab.bone_point("bow")
		sample("Shoot",1.75)
		var draw: Vector3 = lab.bone_point("bowstring")-lab.bone_point("bow")
		check(rest.distance_to(draw)>.20,id+" actual string draw")
		for step in [.016,.1]:
			lab.set_mode("Shoot")
			var shots: int = lab.shots
			var hits: int = lab.hits
			var damage: float = lab.damage_total
			advance(1.5,step)
			check(lab.shots-shots==1,id+" normal arrow count dt="+str(step))
			check(lab.hits-hits==1,id+" normal target hit dt="+str(step))
			check(is_equal_approx(lab.damage_total-damage,float(lab.metadata.damage)),id+" normal damage")
			lab.set_mode("Attack")
			shots = lab.shots
			hits = lab.hits
			damage = lab.damage_total
			advance(lab.duration-.05,step)
			var expected: int = {"rowan":8,"ash":6,"briar":12,"nyx":2,"pip":21}[id]
			check(lab.shots-shots==expected,id+" special projectile count: "+str(lab.shots-shots)+" expected "+str(expected))
			check(lab.hits-hits==expected,id+" special hit count: "+str(lab.hits-hits)+" expected "+str(expected))
			if id=="nyx":check(is_equal_approx(lab.damage_total-damage,60.),"Nyx doubles impact damage")
		lab.set_mode("Space")
		advance(.1)
		check(lab.invulnerable,id+" starts invulnerable")
		advance(.4)
		if id=="rowan":check(not lab.invulnerable and lab.actor.position.z>2.49,"Rowan dash window and displacement")
		if id=="briar":check(lab.shield.visible,"Briar shell visible")
		if id=="nyx":check(lab.salvo_targets[0].position.distance_to(lab.target_rest[0])>.4,"Nyx actual pushback")
		if id=="pip":check(lab.clock_face.visible,"Pip clock field")
		advance(float(lab.metadata.spaceDuration)-.5+.1)
		check(not lab.invulnerable,id+" defense expires")
		lab.paused = false
		lab.wind_cooldown = 0
		check(lab.trigger_ability("Space"),id+" manual defense cast")
		check(not lab.trigger_ability("Space"),id+" prevents cooldown bypass")
		lab.paused = true
		check(not lab.trigger_ability("Attack"),id+" paused cast rejected")
		lab.paused = false
		print("CHARACTER_CHECKED ",id," · bones ",lab.skeleton.get_bone_count())
	lab.set_mode("Pet")
	lab.view_mode = "Pet"
	for pet in ["fox","wolf","beetle"]:
		lab.select_companion(pet)
		var seen: Dictionary = {}
		for i in 750:
			lab.advance_simulation(.016)
			seen[lab.fox_clip] = true
		check(lab.fox.position.distance_to(lab.actor.position)<4.0,pet+" stays nearby")
		if pet=="fox":check(lab.pet_shots>=3 and lab.pet_hits>=1,"Fox physical dart fan")
		if pet=="wolf":
			check(lab.bites>=2 and lab.howls>=1,"Wolf bite and howl events")
			check(seen.has("Trot") and seen.has("Howl") and seen.has("Bite"),"Wolf distinct motion styles")
			check(lab.fox_skeleton.find_bone("jaw")>=0,"Wolf articulated jaw")
		if pet=="beetle":
			check(lab.collected>=2,"Beetle actual pickup events")
			for clip in ["Crawl","Fly","Collect","Deliver"]:check(seen.has(clip),"Beetle "+clip+" demonstrated")
		print("COMPANION_CHECKED ",pet," · clips ",seen.keys())
	# Repeated casts must leave bounded live transient objects.
	lab.select_character("pip")
	lab.set_mode("Attack")
	advance(90.0,.1)
	check(lab.projectiles.size()<25 and lab.effects.size()<60 and lab.stuck.size()<=24,"Transient object budgets")
	lab.view_mode = "Pet"
	lab.update_camera(1)
	check(not lab.actor.visible,"Pet close-up unobstructed")
	lab.view_mode = "Archer"
	lab.update_camera(1)
	check(lab.actor.visible,"Character close-up restored")
	lab.free()
	if failures.is_empty():print("COMBAT_CHECK_OK: five character kits, real impacts, three companions, cooldowns and bounded effects")
	else:print("COMBAT_CHECK_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
