extends Node3D
const BOSS := preload("res://boss_motion.gd")
var boss: Node3D
var camera: Camera3D
var scenery: Node3D
var scale_archer: Node3D
var scale_player: AnimationPlayer
var view_mode := "Auto"
var scale_visible := false
var woodland := true
var turn := -.42
var pitch := .21
var zoom := 1.0
var dragging := false
var poll := 0.0
var world: WorldEnvironment

func _ready() -> void:
	Engine.max_fps = 60
	world = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("172a29")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b6cbbf")
	world.environment.ambient_light_energy = .40
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	for info in [[Vector3(-42,-28,0),Color("ffe0b3"),.65,true],[Vector3(-24,130,0),Color("abcadd"),.25,false],[Vector3(-40,180,0),Color("cae4b3"),.22,false]]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = info[0]
		sun.light_color = info[1]
		sun.light_energy = info[2]
		sun.shadow_enabled = info[3]
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = 30
		add_child(sun)
	scenery = load("res://assets/woodland.glb").instantiate()
	add_child(scenery)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80,80)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("283b35")
	material.roughness = 1
	ground.material_override = material
	ground.position.y = -.06
	add_child(ground)
	boss = Node3D.new()
	boss.set_script(BOSS)
	add_child(boss)
	boss.set_active(true)
	scale_archer = load("res://assets/rowan.glb").instantiate()
	add_child(scale_archer)
	scale_archer.position = Vector3(2.8,0,-.2)
	scale_player = scale_archer.find_children("*","AnimationPlayer",true,false)[0]
	scale_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	scale_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	scale_player.play("Idle",0)
	scale_archer.visible = false
	camera = Camera3D.new()
	camera.fov = 40
	camera.near = .05
	camera.far = 100
	add_child(camera)
	camera.current = true
	var dpr := 1.0
	if OS.has_feature("web"):dpr = float(JavaScriptBridge.eval("window.devicePixelRatio || 1",true))
	get_viewport().scaling_3d_scale = minf(1,1.5/dpr)
	update_camera(1)
	if OS.has_feature("web"):JavaScriptBridge.eval("window.bossReady=true",true)
	print("BRIAR_KING_READY: original boss, authored close and ranged attacks")

func arena_view() -> bool:
	return view_mode=="Arena" or (view_mode=="Auto" and boss.clip in ["Melee","Ranged"])

func bounds_points(subject: Node3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for mesh in subject.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin:continue
		var bounds: AABB = mesh.mesh.get_aabb()
		for i in 8:result.append(mesh.global_transform*bounds.get_endpoint(i))
	return result

func update_camera(dt: float) -> void:
	var arena := arena_view()
	var focus := Vector3(0,1.55,0)
	var ranged: bool = boss.clip=="Ranged" or boss.mode=="Ranged"
	if arena:focus = Vector3(.1,.55,2.0) if ranged else Vector3(-.45,.75,.60)
	elif view_mode=="Heart":focus = Vector3(0,2.15,0)
	if scale_visible and not arena:focus.x = .7
	var tilt: float = pitch+(.18 if arena else 0)
	var back := Vector3(sin(turn)*cos(tilt),sin(tilt),cos(turn)*cos(tilt))
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x/maxf(1,size.y)
	var tangent := tan(deg_to_rad(camera.fov)*.5)
	var right := Vector3.UP.cross(back).normalized()
	var up := back.cross(right).normalized()
	var distance := 9.0 if arena else 7.5
	var points := bounds_points(boss.actor)
	if not OS.has_feature("web"):points.append(Vector3(0,4.35,0))
	elif boss.clip=="Melee":points.append(Vector3(-.6,4.05,.3))
	if scale_visible and not arena:points.append_array(bounds_points(scale_archer))
	if arena:
		if ranged:
			for x in [-1.2,2.65]:
				for z in [1.0,6.35]:points.append(Vector3(x,.04,z))
			for point in boss.target_points:points.append(point+Vector3.UP*.35)
		else:
			var center: Vector3 = boss.melee_center
			var radius: float = boss.metadata.melee.radius
			for x in [center.x-radius,center.x+radius]:
				for z in [center.z-radius,center.z+radius]:points.append(Vector3(x,.04,z))
	for point in points:
		var delta := point-focus
		var near := delta.dot(back)
		distance = maxf(distance,near+absf(delta.dot(right))/(tangent*aspect*.82))
		var vertical := delta.dot(up)
		distance = maxf(distance,near+absf(vertical)/(tangent*(.79 if vertical>=0 else .55)))
	if view_mode=="Heart":distance = 4.8 if aspect>1 else 6.5
	camera.position = camera.position.lerp(focus+back*distance*zoom,minf(1,dt*6))
	camera.look_at(focus)
	scale_archer.visible = scale_visible and not arena and view_mode!="Heart"
	boss.hp_root.visible = view_mode!="Heart" and not OS.has_feature("web")
	boss.update_view(camera)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:zoom = clampf(zoom+(-.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .08),.65,1.6)
	if event is InputEventMouseMotion and dragging:
		turn -= event.relative.x*.007
		pitch = clampf(pitch+event.relative.y*.004,-.02,.65)
	if event is InputEventScreenDrag:
		turn -= event.relative.x*.007
		pitch = clampf(pitch+event.relative.y*.004,-.02,.65)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_1:boss.command("Melee")
		if event.keycode==KEY_2:boss.command("Ranged")
		if event.keycode==KEY_P:boss.paused = not boss.paused

func _process(delta: float) -> void:
	var remaining: float = minf(delta,.1)*boss.speed
	while remaining>.000001:
		var step := minf(remaining,1.0/60.0)
		boss.advance_simulation(step)
		if not boss.paused:scale_player.advance(step)
		remaining -= step
	update_camera(delta)
	poll += delta
	if poll<.15 or not OS.has_feature("web"):return
	poll = 0
	var request = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.bossRequest || {})",true))
	if request:
		if request.has("motion"):
			boss.command(str(request.motion))
			if str(request.motion).begins_with("Hold"):JavaScriptBridge.eval("window.bossRequest.paused=true",true)
			JavaScriptBridge.eval("delete window.bossRequest.motion",true)
		boss.paused = bool(request.get("paused",false))
		boss.speed = clampf(float(request.get("speed",1)),.25,1)
		view_mode = str(request.get("view","Auto"))
		scale_visible = bool(request.get("scale",false))
		woodland = bool(request.get("woodland",true))
		scenery.visible = woodland
		world.environment.background_color = Color("172a29") if woodland else Color("162329")
		if bool(request.get("reset",false)):
			turn = -.42
			pitch = .21
			zoom = 1
			JavaScriptBridge.eval("window.bossRequest.reset=false",true)
	var state: Dictionary = boss.state()
	state.merge({"fps":Engine.get_frames_per_second(),"view":view_mode,"arena":arena_view(),"scale":scale_visible,"woodland":woodland},true)
	JavaScriptBridge.eval("window.bossState="+JSON.stringify(state),true)
