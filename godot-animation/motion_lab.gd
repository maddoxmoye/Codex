extends Node3D
## Isolated animation study. All body/bow deformation is baked in Blender;
## projectile flight and impact are synchronized here against the release timestamp.
const STUDY := preload("res://assets/rowan-motion.glb")
const SHOWCASE := [["Idle",1.6],["Run",3.2],["Shoot",3.2],["RunShoot",3.2],["Dodge",0.9],["Idle",1.2]]
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

func set_mode(requested: String) -> void:
	if requested not in ["Showcase","Idle","Run","Shoot","RunShoot","Dodge"]:
		return
	mode = requested
	segment = 0
	base_origin = Vector3.ZERO
	actor.position = Vector3.ZERO
	actor.rotation.y = 0
	dodge_direction = 1
	clear_arrows()
	start_clip(SHOWCASE[0][0] if mode == "Showcase" else mode)

func start_clip(name: String) -> void:
	clip = name
	phase_time = 0
	release_fired = false
	duration = float(SHOWCASE[segment][1]) if mode == "Showcase" else 3.2 if clip == "Run" else float(metadata.clips[clip])
	actor.position = base_origin
	actor.rotation.y = 0
	player.play(clip,0.16)
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

func make_arrow() -> Node3D:
	var arrow := Node3D.new()
	part(cylinder(0.009,0.009,0.60,6),material("shaft","c3a875"),Vector3.ZERO,arrow).rotation.x = PI/2
	part(cylinder(0,0.026,0.085,6),material("tip","97dbd2",0.3,0.3),Vector3(0,0,0.34),arrow).rotation.x = PI/2
	for a in [0,PI/2]:
		var feather := BoxMesh.new()
		feather.size = Vector3(0.095,0.006,0.12)
		part(feather,material("feather","a0d3be"),Vector3(0,0,-0.23),arrow).rotation.z = a
	return arrow

func release_arrow() -> void:
	# Sample just before the snap even if a slow frame crosses the release marker.
	var restore := phase_time
	player.seek(float(metadata.anchorTime),true)
	var string := bone_point("bowstring")
	var direction := (bone_point("bow")+Vector3.UP*0.08-string).normalized()
	var arrow := make_arrow()
	add_child(arrow)
	arrow.position = string + direction*0.3
	arrow.look_at(arrow.position+direction,Vector3.UP,true)
	projectiles.append({"node":arrow,"direction":direction,"age":0.0})
	shots += 1
	player.seek(restore,true)
	print("ARROW_RELEASE: ",clip," #",shots)

func advance_simulation(dt: float) -> void:
	var old := phase_time
	phase_time = minf(phase_time+dt,duration)
	if clip == "Run":
		var angle := phase_time/3.2*TAU
		actor.position = base_origin + Vector3(-0.70+cos(angle)*0.70,0,sin(angle)*0.70)
		actor.rotation.y = -angle
	elif clip == "Dodge":
		actor.position = base_origin + Vector3(dodge_direction*0.9*smoothstep(0.08,0.32,phase_time),0,0)
	player.advance(phase_time-old)
	if clip in ["Shoot","RunShoot"] and not release_fired and phase_time >= float(metadata.releaseTime):
		release_fired = true
		release_arrow()
	update_nocked()
	update_projectiles(dt)
	flash = maxf(0,flash-dt)
	target_material.emission_energy_multiplier = flash*3
	if phase_time >= duration-0.0001:
		if clip == "Dodge":
			base_origin = actor.position
			dodge_direction *= -1
		if mode == "Showcase":
			segment = (segment+1)%SHOWCASE.size()
			start_clip(SHOWCASE[segment][0])
		else:
			start_clip(clip)

func update_nocked() -> void:
	nocked.visible = clip in ["Shoot","RunShoot"] and phase_time >= 0.70 and phase_time < float(metadata.releaseTime)
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
		var normal := target.global_basis.z.normalized()
		var plane := Plane(normal,normal.dot(target.global_position))
		var hit = plane.intersects_segment(previous,next)
		if hit != null and Vector3(hit).distance_to(target.global_position)<0.49:
			arrow.position = Vector3(hit)-dir*0.28
			stuck.append(arrow)
			if stuck.size()>6:
				stuck.pop_front().queue_free()
			hits += 1
			flash = 0.35
			for k in 10:
				var spark_mesh := SphereMesh.new()
				spark_mesh.radius = 0.018
				spark_mesh.height = 0.036
				spark_mesh.radial_segments = 6
				spark_mesh.rings = 3
				var spark := part(spark_mesh,material("spark","e6c784",0,0.5),hit)
				sparks.append({"node":spark,"velocity":Vector3(cos(k*2.4)*0.7,0.5+(k%3)*0.15,sin(k*2.4)*0.7),"life":0.40})
			projectiles.remove_at(i)
			print("TARGET_HIT: ",hits)
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
	var focus := actor.position+Vector3(0,1.1,0)
	var offset := Vector3(-2.8,1.0,3.3)
	if view_mode == "Bow":
		focus = actor.position+Vector3(0,1.46,0)
		offset = Vector3(-1.7,0.55,1.9)
	elif view_mode == "Range":
		focus = (base_origin+target.position)*0.5
		focus.y = 1.0
		offset = Vector3(-5.3,3.3,6.4)
	var size := get_viewport().get_visible_rect().size
	if size.x<size.y:
		offset *= 1.6 if view_mode == "Range" else 1.15
	offset = offset.rotated(Vector3.UP,view_turn)
	offset.y += view_pitch
	camera.position = camera.position.lerp(focus+offset,minf(1,dt*7))
	camera.look_at(focus)

func phase_label() -> String:
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
		if event.keycode==KEY_SPACE:paused = not paused
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
	var state := {"mode":mode,"clip":clip,"phase":phase_label(),"time":snappedf(phase_time,0.01),"shots":shots,"hits":hits,"flying":projectiles.size(),"paused":paused,"speed":speed,"fps":Engine.get_frames_per_second(),"bones":skeleton.get_bone_count(),"nocked":nocked.visible,"view":view_mode}
	JavaScriptBridge.eval("window.motionState="+JSON.stringify(state),true)
