extends Node3D
## Isolated animation study. All body/bow deformation is baked in Blender;
## projectile flight and impact are synchronized here against the release timestamp.
const STUDY := preload("res://assets/rowan-motion.glb")
const FOX := preload("res://assets/fox-motion.glb")
const SHOWCASE := [["Idle",1.6],["Run",3.2],["Shoot",3.2],["Windskip",2.6],["Salvo",3.0],["Fox",5.0],["RunShoot",3.2]]
var fox: Node3D
var fox_player: AnimationPlayer
var fox_skeleton: Skeleton3D
var fox_metadata: Dictionary
var fox_clip := "Idle"
var fox_time := 0.0
var fox_cooldown := 0.0
var fox_fired := false
var pet_shots := 0
var pet_hits := 0
var pet_target: Node3D
var salvo_targets: Array[Node3D] = []
var wind_cooldown := 0.0
var salvo_cooldown := 0.0
var invulnerable := false
var fan_mode := false
var effect_clock := 0.0
var wind_rings: Array[Dictionary] = []
var metadata: Dictionary
var actor: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var camera: Camera3D
var target: Node3D
var target_post: MeshInstance3D
var target_material: StandardMaterial3D
var nocked: Node3D
var mode := "Showcase"
var clip := "Idle"
var view_mode := "Archer"
var paused := false
var speed := 1.0
var phase_time := 0.0
var duration := 1.6
var segment := 0
var release_fired := false
var shots := 0
var hits := 0
var base_origin := Vector3.ZERO
var dodge_direction := 1.0
var anchor_string := Vector3.ZERO
var anchor_direction := Vector3.FORWARD
var projectiles: Array[Dictionary] = []
var stuck: Array[Node3D] = []
var sparks: Array[Dictionary] = []
var poll := 0.0
var flash := 0.0
var dragging := false
var view_turn := 0.0
var view_pitch := 0.0
var palette: Dictionary = {}

func material(id: String, tint: String, metallic := 0.0, glow := 0.0) -> StandardMaterial3D:
	if palette.has(id):
		return palette[id]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint)
	m.roughness = 0.65
	m.metallic = metallic
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(tint)
		m.emission_energy_multiplier = glow
	palette[id] = m
	return m

func part(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func cylinder(top: float, bottom: float, height: float, sides := 16) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = sides
	return m

func _ready() -> void:
	Engine.max_fps = 60
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion.json"))
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("14262e")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b9cbd4")
	world.environment.ambient_light_energy = 0.35
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	for info in [[Vector3(-42,-25,0),Color("ffe0b8"),0.65,true],[Vector3(-25,140,0),Color("9dc2df"),0.25,false]]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = info[0]
		sun.light_color = info[1]
		sun.light_energy = info[2]
		sun.shadow_enabled = info[3]
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = 18
		add_child(sun)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(35,35)
	part(floor_mesh,material("floor","243e43"),Vector3(0,-0.045,0))
	part(cylinder(2.05,2.1,0.08,64),material("stone","586b67"),Vector3(0,-0.025,0))
	for i in 24:
		var angle := i * TAU / 24
		var box := BoxMesh.new()
		box.size = Vector3(0.20,0.025,0.045)
		var mark := part(box,material("marks","a89b72"),Vector3(sin(angle)*1.9,0.02,cos(angle)*1.9))
		mark.rotation.y = angle
	# Low-cost boundary stones leave the action unobstructed.
	for i in 14:
		var a := i * TAU / 14
		part(cylinder(0.20,0.28,0.28,6),material("rock","365357"),Vector3(sin(a)*6.6,0.07,cos(a)*6.6))
	actor = STUDY.instantiate()
	add_child(actor)
	player = actor.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = actor.find_children("*","Skeleton3D",true,false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name in player.get_animation_list():
		player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Run"] else Animation.LOOP_NONE
	# Read the actual exported full-draw bone positions to lay out the target.
	player.play("Shoot",0)
	player.seek(float(metadata.anchorTime),true)
	anchor_string = actor.global_transform.affine_inverse() * bone_point("bowstring")
	var grip := actor.global_transform.affine_inverse() * (bone_point("bow")+Vector3.UP*0.08)
	anchor_direction = (grip-anchor_string).normalized()
	target = Node3D.new()
	add_child(target)
	part(cylinder(0.52,0.52,0.09,48),material("wood","826546"),Vector3.ZERO,target).rotation.x = PI/2
	for ring in [[0.43,"outer","c6c3a0"],[0.29,"middle","526a59"],[0.13,"center","d4a960"]]:
		var disk := part(cylinder(ring[0],ring[0],0.012,48),material(ring[1],ring[2]),Vector3(0,0,0.052+palette.size()*0.0003),target)
		disk.rotation.x = PI/2
	target_material = palette.center
	target_material.emission_enabled = true
	target_material.emission = Color("e5b96d")
	target_post = part(cylinder(0.05,0.065,1.0,8),material("post","5d4b3c"),Vector3.ZERO)
	for i in 8:
		var marker := Node3D.new()
		add_child(marker)
		part(cylinder(0.24,0.24,0.07,24),material("salvo_target","d6aa61",0.2,0.1),Vector3.ZERO,marker).rotation.x = PI/2
		part(cylinder(0.075,0.075,0.085,16),material("salvo_bull","f5e4ba"),Vector3(0,0,0.04),marker).rotation.x = PI/2
		salvo_targets.append(marker)
	fox_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/fox-motion.json"))
	fox = FOX.instantiate()
	add_child(fox)
	fox_player = fox.find_children("*","AnimationPlayer",true,false)[0]
	fox_skeleton = fox.find_children("*","Skeleton3D",true,false)[0]
	fox_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name in fox_player.get_animation_list():
		fox_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Trot"] else Animation.LOOP_NONE
	pet_target = Node3D.new()
	add_child(pet_target)
	part(cylinder(0.48,0.48,0.06,24),material("pet_target","b77745"),Vector3.ZERO,pet_target).rotation.x = PI/2
	part(cylinder(0.13,0.13,0.075,16),material("pet_bull","f1ca8a"),Vector3(0,0,0.04),pet_target).rotation.x = PI/2
	nocked = make_arrow()
	add_child(nocked)
	nocked.visible = false
	camera = Camera3D.new()
	camera.fov = 40
	camera.near = 0.05
	camera.far = 50
	add_child(camera)
	camera.current = true
	var dpr := 1.0
	if OS.has_feature("web"):
		dpr = float(JavaScriptBridge.eval("window.devicePixelRatio || 1",true))
	get_viewport().scaling_3d_scale = minf(1.0,1.5/dpr)
	set_mode("Showcase")
	update_camera(1.0)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.motionReady=true",true)
	print("MOTION_LAB_READY: baked Blender clips and synchronized Godot arrows")

func bone_point(name: String) -> Vector3:
	return (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(name))).origin

func align_target() -> void:
	var launch := actor.global_transform * anchor_string
	var direction := actor.global_basis * anchor_direction
	target.global_position = launch + direction * 4.2
	target.look_at(launch,Vector3.UP,true)
	target_post.position = Vector3(target.position.x,target.position.y*0.5,target.position.z)
	target_post.scale.y = target.position.y
	var right := Vector3.UP.cross(direction).normalized()
	for i in 8:
		var marker := salvo_targets[i]
		marker.position = launch+direction*4.2+right*(float(i)-3.5)*0.53
		marker.look_at(launch,Vector3.UP,true)
		marker.visible = clip=="Salvo" and not fan_mode
	target.visible = clip!="Salvo"
	target_post.visible = target.visible
	pet_target.position = base_origin+Vector3(-1.2,0.58,0.3)+direction*3.0
	pet_target.look_at(base_origin+Vector3(-1.2,0.58,0.3),Vector3.UP,true)

func set_mode(requested: String) -> void:
	if requested not in ["Showcase","Idle","Run","Shoot","RunShoot","Dodge","Windskip","Salvo","Fox"]:
		return
	mode = requested
	segment = 0
	base_origin = Vector3.ZERO
	actor.position = Vector3.ZERO
	actor.rotation.y = 0
	dodge_direction = 1
	wind_cooldown = 0
	salvo_cooldown = 0
	fox.position = Vector3(-1.25,0,0.65)
	fox_cooldown = 0
	fox_time = 0
	fox_clip = "Idle"
	fox_player.play("Idle",0)
	clear_arrows()
	start_clip(SHOWCASE[0][0] if mode == "Showcase" else mode)

func start_clip(name: String) -> void:
	clip = name
	phase_time = 0
	release_fired = false
	duration = float(SHOWCASE[segment][1]) if mode == "Showcase" else 3.2 if clip == "Run" else 5.0 if clip=="Fox" else maxf(float(metadata.clips[clip]),2.6 if clip=="Windskip" else 11.0 if clip=="Salvo" else 0.0)
	actor.position = base_origin
	actor.rotation.y = 0
	player.play("Idle" if clip=="Fox" else clip,0.10)
	if clip=="Windskip":wind_cooldown = float(metadata.windskipCooldown)
	if clip=="Salvo":salvo_cooldown = float(metadata.salvoCooldown)
	player.advance(0)
	align_target()

func clear_arrows() -> void:
	for item in projectiles:
		item.node.queue_free()
	projectiles.clear()
	for arrow in stuck:
		arrow.queue_free()
	stuck.clear()
	for item in sparks:
		item.node.queue_free()
	sparks.clear()
	for item in wind_rings:item.node.queue_free()
	wind_rings.clear()

func make_arrow() -> Node3D:
	var arrow := Node3D.new()
	part(cylinder(0.009,0.009,0.60,6),material("shaft","c3a875"),Vector3.ZERO,arrow).rotation.x = PI/2
	part(cylinder(0,0.026,0.085,6),material("tip","97dbd2",0.3,0.3),Vector3(0,0,0.34),arrow).rotation.x = PI/2
	for a in [0,PI/2]:
		var feather := BoxMesh.new()
		feather.size = Vector3(0.095,0.006,0.12)
		part(feather,material("feather","a0d3be"),Vector3(0,0,-0.23),arrow).rotation.z = a
	return arrow

func spawn_projectile(point: Vector3, direction: Vector3, pet := false, empowered := false) -> void:
	var arrow := make_arrow()
	if pet:
		arrow.scale = Vector3.ONE*0.42
		for child in arrow.get_children():child.material_override = material("fox_dart","edb76c",0.15,0.5)
	elif empowered:
		for child in arrow.get_children():child.material_override = material("flock_arrow","f3d487",0.15,0.7)
		for side in [-1,1]:
			var wing := BoxMesh.new()
			wing.size = Vector3(0.20,0.009,0.07)
			part(wing,material("flock_wings","f5e4b5",0.1,0.25),Vector3(side*0.10,0,-0.11),arrow).rotation.y = side*0.5
	add_child(arrow)
	arrow.position = point+direction*(0.13 if pet else 0.3)
	arrow.look_at(arrow.position+direction,Vector3.UP,true)
	projectiles.append({"node":arrow,"direction":direction,"age":0.0,"pet":pet,"empowered":empowered})
	if pet:pet_shots += 1
	else:shots += 1

func release_arrow() -> void:
	var restore := phase_time
	player.seek(float(metadata.salvoAnchorTime if clip=="Salvo" else metadata.anchorTime),true)
	var string := bone_point("bowstring")
	var direction := (bone_point("bow")+Vector3.UP*0.08-string).normalized()
	if clip=="Salvo":
		for i in 8:
			var aim := direction.rotated(Vector3.UP,(float(i)-3.5)*0.12) if fan_mode else (salvo_targets[i].position-string).normalized()
			spawn_projectile(string,aim,false,true)
	else:spawn_projectile(string,direction)
	player.seek(restore,true)

func trigger_ability(name: String) -> bool:
	if paused or name not in ["Windskip","Salvo"]:return false
	if (wind_cooldown if name=="Windskip" else salvo_cooldown)>0:return false
	# Manual casts return to idle; study tabs replay the chosen motion automatically.
	mode = "Idle"
	base_origin = actor.position
	start_clip(name)
	return true

func update_fox(dt: float) -> void:
	fox_cooldown = maxf(0,fox_cooldown-dt)
	var goal := actor.position+Vector3(-1.25,0,0.45)
	var distance := fox.position.distance_to(goal)
	var next_clip := "Trot" if distance>0.12 else "Attack" if fox_cooldown<=0 or (fox_clip=="Attack" and fox_time<0.85) else "Idle"
	if clip=="Fox" and fmod(phase_time,5.0)<1.4:
		goal += Vector3(sin(phase_time*1.8)*0.65,0,cos(phase_time*1.8)*0.45)
		if fox.position.distance_to(goal)>0.12:next_clip = "Trot"
	if next_clip!=fox_clip:
		fox_clip = next_clip
		fox_time = 0
		fox_fired = false
		fox_player.play(fox_clip,0.1)
		if fox_clip=="Attack":fox_cooldown = float(fox_metadata.attackInterval)
	if fox_clip=="Trot":
		var direction := goal-fox.position
		var velocity := 3.4 if distance>1.5 else 0.85
		fox.position = fox.position.move_toward(goal,dt*velocity)
		if direction.length()>0.01:fox.rotation.y = lerp_angle(fox.rotation.y,atan2(direction.x,direction.z),minf(1,dt*10))
	else:
		var direction := pet_target.position-fox.position
		fox.rotation.y = lerp_angle(fox.rotation.y,atan2(direction.x,direction.z),minf(1,dt*10))
	var anim_dt := dt*(1.3 if fox_clip=="Trot" else 1.0)
	fox_time += anim_dt
	fox_player.advance(anim_dt)
	if fox_clip=="Attack" and fox_time>=float(fox_metadata.releaseTime) and not fox_fired:
		fox_fired = true
		var local: Array = fox_metadata.muzzleLocal
		var head := fox_skeleton.global_transform*fox_skeleton.get_bone_global_pose(fox_skeleton.find_bone("head"))
		var point: Vector3 = head*Vector3(local[0],local[1],local[2])
		var direction := (pet_target.position-point).normalized()
		for spread in fox_metadata.spread:spawn_projectile(point,direction.rotated(Vector3.UP,float(spread)),true)

func update_wind(dt: float) -> void:
	invulnerable = clip=="Windskip" and phase_time<float(metadata.windskipInvulnerability)
	effect_clock += dt
	if invulnerable and effect_clock>=0.035:
		effect_clock = 0
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.35
		mesh.outer_radius = 0.39
		mesh.rings = 16
		mesh.ring_segments = 6
		var ring := part(mesh,material("wind","b7ece1",0,0.7),actor.position+Vector3(0,0.75,0))
		ring.rotation.x = PI/2
		wind_rings.append({"node":ring,"life":0.38})
	for i in range(wind_rings.size()-1,-1,-1):
		var item := wind_rings[i]
		item.life -= dt
		item.node.scale = Vector3.ONE*maxf(0.01,item.life/0.38)
		if item.life<=0:
			item.node.queue_free()
			wind_rings.remove_at(i)

func advance_simulation(dt: float) -> void:
	wind_cooldown = maxf(0,wind_cooldown-dt)
	salvo_cooldown = maxf(0,salvo_cooldown-dt)
	var old := phase_time
	phase_time = minf(phase_time+dt,duration)
	if clip == "Run":
		var angle := phase_time/3.2*TAU
		actor.position = base_origin + Vector3(-0.70+cos(angle)*0.70,0,sin(angle)*0.70)
		actor.rotation.y = -angle
	elif clip == "Dodge":
		actor.position = base_origin + Vector3(dodge_direction*0.9*smoothstep(0.08,0.32,phase_time),0,0)
	elif clip=="Windskip":
		actor.position = base_origin+Vector3(0,0,2.5*clampf(phase_time/float(metadata.windskipDuration),0,1))
	player.advance(phase_time-old)
	if clip in ["Shoot","RunShoot","Salvo"] and not release_fired and phase_time >= float(metadata.salvoReleaseTime if clip=="Salvo" else metadata.releaseTime):
		release_fired = true
		release_arrow()
	update_nocked()
	update_fox(dt)
	update_wind(dt)
	update_projectiles(dt)
	flash = maxf(0,flash-dt)
	target_material.emission_energy_multiplier = flash*3
	if phase_time >= duration-0.0001:
		if clip == "Dodge":
			base_origin = actor.position
			dodge_direction *= -1
		if mode == "Showcase":
			segment = (segment+1)%SHOWCASE.size()
			if segment==0:base_origin = Vector3.ZERO
			elif clip=="Windskip":base_origin = actor.position
			start_clip(SHOWCASE[segment][0])
		else:
			if clip=="Windskip":base_origin = actor.position if mode=="Idle" else Vector3.ZERO
			start_clip(mode if mode=="Idle" else clip)

func update_nocked() -> void:
	nocked.visible = view_mode!="Fox" and clip in ["Shoot","RunShoot","Salvo"] and phase_time >= (0.24 if clip=="Salvo" else 0.70) and phase_time < float(metadata.salvoReleaseTime if clip=="Salvo" else metadata.releaseTime)
	if nocked.visible:
		var point := bone_point("bowstring")
		var dir := (bone_point("bow")+Vector3.UP*0.08-point).normalized()
		nocked.position = point+dir*0.3
		nocked.look_at(nocked.position+dir,Vector3.UP,true)

func update_projectiles(dt: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var item := projectiles[i]
		var arrow: Node3D = item.node
		var dir: Vector3 = item.direction
		var previous := arrow.position+dir*0.38
		arrow.position += dir*dt*11
		item.age += dt
		var next := arrow.position+dir*0.38
		var hit = null
		var candidates: Array = [pet_target] if item.pet else salvo_targets if item.empowered else [target]
		if item.empowered and fan_mode:candidates = []
		for candidate in candidates:
			var normal: Vector3 = candidate.global_basis.z.normalized()
			var plane := Plane(normal,normal.dot(candidate.global_position))
			var intersection = plane.intersects_segment(previous,next)
			if intersection != null and Vector3(intersection).distance_to(candidate.global_position)<(0.25 if item.empowered else 0.49):
				hit = intersection
				break
		if hit != null:
			arrow.position = Vector3(hit)-dir*0.28
			stuck.append(arrow)
			if stuck.size()>18:
				stuck.pop_front().queue_free()
			if item.pet:pet_hits += 1
			else:hits += 1
			flash = 0.35
			for k in (3 if item.pet else 6):
				var spark_mesh := SphereMesh.new()
				spark_mesh.radius = 0.018
				spark_mesh.height = 0.036
				spark_mesh.radial_segments = 6
				spark_mesh.rings = 3
				var spark := part(spark_mesh,material("spark","e6c784",0,0.5),hit)
				sparks.append({"node":spark,"velocity":Vector3(cos(k*2.4)*0.7,0.5+(k%3)*0.15,sin(k*2.4)*0.7),"life":0.40})
			projectiles.remove_at(i)
		elif item.age>2:
			arrow.queue_free()
			projectiles.remove_at(i)
	for i in range(sparks.size()-1,-1,-1):
		var spark := sparks[i]
		spark.life -= dt
		spark.velocity.y -= dt*2
		spark.node.position += spark.velocity*dt
		if spark.life<=0:
			spark.node.queue_free()
			sparks.remove_at(i)

func update_camera(dt: float) -> void:
	# Isolate the small companion so Rowan cannot obscure its detail camera.
	actor.visible = view_mode!="Fox"
	update_nocked()
	var focus := actor.position+Vector3(0,1.1,0)
	var offset := Vector3(-2.8,1.0,3.3)
	if view_mode == "Bow":
		focus = actor.position+Vector3(0,1.46,0)
		offset = Vector3(-1.7,0.55,1.9)
	elif view_mode == "Fox":
		focus = fox.position+Vector3(0,0.4,0)
		offset = fox.global_basis*Vector3(-1.8,0.7,2.2)
	elif view_mode == "Range":
		focus = (base_origin+target.position)*0.5
		focus.y = 1.0
		offset = Vector3(-5.3,3.3,6.4)
	var size := get_viewport().get_visible_rect().size
	if size.x<size.y:
		offset *= 1.6 if view_mode == "Range" else 1.45 if view_mode=="Fox" else 1.15
	offset = offset.rotated(Vector3.UP,view_turn)
	offset.y += view_pitch
	camera.position = camera.position.lerp(focus+offset,minf(1,dt*7))
	camera.look_at(focus)

func phase_label() -> String:
	if clip=="Windskip":return "WINDSKIP · INVULNERABLE" if invulnerable else "WINDSKIP · RECOVER"
	if clip=="Salvo":return "FLOCK & AWE · DRAW" if phase_time<float(metadata.salvoReleaseTime) else "EIGHT EMPOWERED ARROWS"
	if clip=="Fox":return "FOREST FOX · "+fox_clip.to_upper()
	if clip == "Run":return "RUN · FOOT PLACEMENT"
	if clip == "Dodge":return "SIDESTEP · RECOVER"
	if clip == "Idle":return "IDLE · BREATHING"
	if phase_time<0.45:return "RAISE THE BOW"
	if phase_time<0.75:return "NOCK THE ARROW"
	if phase_time<1.5:return "DRAW THE STRING"
	if phase_time<float(metadata.releaseTime):return "ANCHOR · AIM"
	if phase_time<2.2:return "RELEASE · FOLLOW THROUGH"
	return "LOWER · RECOVER"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	if event is InputEventMouseMotion and dragging:
		view_turn -= event.relative.x*0.007
		view_pitch = clampf(view_pitch+event.relative.y*0.004,-0.3,1.5)
	if event is InputEventScreenDrag:
		view_turn -= event.relative.x*0.007
		view_pitch = clampf(view_pitch+event.relative.y*0.004,-0.3,1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		var modes := [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]
		if event.keycode in modes:set_mode(["Showcase","Run","Shoot","RunShoot","Dodge"][modes.find(event.keycode)])
		if event.keycode==KEY_SPACE:trigger_ability("Windskip")
		if event.keycode==KEY_E:trigger_ability("Salvo")
		if event.keycode==KEY_P:paused = not paused
		if event.keycode==KEY_TAB:view_mode = "Range" if view_mode=="Archer" else "Archer"

func _process(delta: float) -> void:
	if not paused:advance_simulation(minf(delta,0.10)*speed)
	update_camera(delta)
	poll += delta
	if poll<0.15 or not OS.has_feature("web"):return
	poll = 0
	var request = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.motionRequest || {})",true))
	if request:
		if request.get("mode",mode)!=mode:set_mode(request.mode)
		paused = bool(request.get("paused",false))
		var new_fan := bool(request.get("fan",false))
		if new_fan!=fan_mode:
			fan_mode = new_fan
			align_target()
		if request.has("cast"):
			if trigger_ability(str(request.cast)):
				JavaScriptBridge.eval("window.motionRequest.mode='Idle'",true)
			JavaScriptBridge.eval("delete window.motionRequest.cast",true)
		speed = clampf(float(request.get("speed",1)),0.25,1.5)
		view_mode = str(request.get("view","Archer"))
		if request.has("seek"):
			phase_time = clampf(float(request.seek),0,duration)
			player.stop()
			player.play(clip,0)
			player.advance(0)
			player.seek(phase_time,true)
			release_fired = phase_time>=float(metadata.releaseTime)
			clear_arrows()
			update_nocked()
			JavaScriptBridge.eval("delete window.motionRequest.seek",true)
		if bool(request.get("reset",false)):
			view_turn = 0
			view_pitch = 0
			JavaScriptBridge.eval("window.motionRequest.reset=false",true)
	var state := {"mode":mode,"clip":clip,"phase":phase_label(),"time":snappedf(phase_time,0.01),"shots":shots,"hits":hits,"flying":projectiles.size(),"paused":paused,"speed":speed,"fps":Engine.get_frames_per_second(),"bones":skeleton.get_bone_count(),"nocked":nocked.visible,"view":view_mode,"petClip":fox_clip,"petShots":pet_shots,"petHits":pet_hits,"windCooldown":snappedf(wind_cooldown,0.1),"salvoCooldown":snappedf(salvo_cooldown,0.1),"invulnerable":invulnerable,"petDistance":fox.position.distance_to(actor.position),"petBones":fox_skeleton.get_bone_count()}
	JavaScriptBridge.eval("window.motionState="+JSON.stringify(state),true)
