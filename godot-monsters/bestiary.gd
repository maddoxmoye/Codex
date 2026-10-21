extends Node3D
## Isolated monster design review with one Blender-authored enemy motion prototype.
const BRIAR_MOTION := preload("res://briarling_motion.gd")
var briar: Node3D
var manifest: Dictionary
var models: Dictionary = {}
var environment: Node3D
var studio: MeshInstance3D
var camera: Camera3D
var current := "lineup"
var woodland := true
var auto_rotate := false
var turn := 0.12
var pitch := 0.18
var zoom := 1.0
var dragging := false
var poll := 0.0
var light_world: WorldEnvironment

func data(id: String) -> Dictionary:
	for item in manifest.assets:
		if item.id==id:return item
	return {}

func _ready() -> void:
	Engine.max_fps = 60
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	light_world = WorldEnvironment.new()
	light_world.environment = Environment.new()
	light_world.environment.background_mode = Environment.BG_COLOR
	light_world.environment.background_color = Color("182d2b")
	light_world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light_world.environment.ambient_light_color = Color("bacfc1")
	light_world.environment.ambient_light_energy = 0.42
	light_world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(light_world)
	for info in [[Vector3(-43,-26,0),Color("ffe1b0"),0.64,true],[Vector3(-28,130,0),Color("a5c9df"),0.27,false],[Vector3(-35,180,0),Color("bddec0"),0.23,false]]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = info[0]
		sun.light_color = info[1]
		sun.light_energy = info[2]
		sun.shadow_enabled = info[3]
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = 28
		add_child(sun)
	environment = load("res://"+manifest.environment.file).instantiate()
	add_child(environment)
	var plane := PlaneMesh.new()
	plane.size = Vector2(120,120)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("263634")
	floor_mat.roughness = 0.9
	studio = MeshInstance3D.new()
	studio.mesh = plane
	studio.material_override = floor_mat
	studio.position.y = -0.045
	add_child(studio)
	for item in manifest.assets:
		var model: Node3D
		if item.id=="briarling":
			model = Node3D.new()
			model.set_script(BRIAR_MOTION)
			briar = model
		else:model = load("res://"+item.file).instantiate()
		add_child(model)
		models[item.id] = model
	camera = Camera3D.new()
	camera.fov = 38
	camera.near = 0.04
	camera.far = 180
	add_child(camera)
	camera.current = true
	var dpr := 1.0
	if OS.has_feature("web"):dpr = float(JavaScriptBridge.eval("window.devicePixelRatio || 1",true))
	get_viewport().scaling_3d_scale = minf(1.0,1.5/dpr)
	select_model("lineup")
	set_environment(true)
	update_camera(1.0)
	if OS.has_feature("web"):JavaScriptBridge.eval("window.bestiaryReady=true",true)
	print("BESTIARY_READY: first Briarling motion study and three static designs")

func select_model(id: String) -> void:
	if id!="lineup" and not models.has(id):return
	current = id
	for item in manifest.assets:
		var model: Node3D = models[item.id]
		model.visible = id=="lineup" or id==item.id
		model.position = Vector3(float(item.slot) if id=="lineup" else 0.0,0,0)
	turn = 0.12
	pitch = 0.18
	zoom = 1
	auto_rotate = false
	if is_instance_valid(briar):briar.set_active(id=="briarling")

func set_environment(enabled: bool) -> void:
	woodland = enabled
	environment.visible = enabled
	light_world.environment.background_color = Color("182d2b") if enabled else Color("182326")

func update_camera(dt: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := maxf(0.25,viewport_size.x/viewport_size.y)
	var focus := Vector3(0,1.15,0)
	var distance := maxf(19.5,7.0/(tan(deg_to_rad(camera.fov)*0.5)*aspect)*1.15)
	if current!="lineup":
		var item := data(current)
		var height := float(item.heightMeters)
		focus.y = height*(0.39 if current=="briarling" else 0.52)
		var sphere_radius := sqrt(pow(float(item.radius),2)+pow(height*0.52,2))
		var limiting_half_fov := atan(tan(deg_to_rad(camera.fov)*0.5)*minf(1.0,aspect))
		distance = maxf(height*2.6,sphere_radius/sin(limiting_half_fov)*1.15)
		distance = maxf(distance,2.5)
		if current=="briarling":distance *= 1.08
	distance *= zoom
	var offset := Vector3(sin(turn)*cos(pitch),sin(pitch),cos(turn)*cos(pitch))*distance
	camera.position = camera.position.lerp(focus+offset,minf(1.0,dt*9))
	camera.look_at(focus)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom+(-0.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.08),0.55,1.8)
	if event is InputEventMouseMotion and dragging:
		turn -= event.relative.x*0.007
		pitch = clampf(pitch+event.relative.y*0.004,0.02,0.65)
		auto_rotate = false
	if event is InputEventScreenDrag:
		turn -= event.relative.x*0.007
		pitch = clampf(pitch+event.relative.y*0.004,0.02,0.65)
		auto_rotate = false
	if event is InputEventKey and event.pressed and not event.echo:
		var keys := [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]
		if event.keycode in keys:select_model(["lineup","briarling","sporecaller","thornback","hollowhart"][keys.find(event.keycode)])

func _process(delta: float) -> void:
	if is_instance_valid(briar):
		var remaining: float = minf(delta,0.10)*briar.speed
		while remaining>0.000001:
			var step := minf(remaining,1.0/60.0)
			briar.advance_simulation(step)
			remaining -= step
		briar.update_view(camera)
	if auto_rotate and not dragging:turn += minf(delta,0.1)*0.25
	update_camera(delta)
	poll += delta
	if poll<0.15 or not OS.has_feature("web"):return
	poll = 0
	var request = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.bestiaryRequest || {})",true))
	if request:
		var id := str(request.get("id",current))
		if id!=current:select_model(id)
		if request.has("motion"):
			if current=="briarling":briar.command(str(request.motion))
			JavaScriptBridge.eval("delete window.bestiaryRequest.motion",true)
		briar.paused = bool(request.get("paused",false))
		briar.speed = clampf(float(request.get("speed",1.0)),0.25,1.0)
		if request.has("woodland") and bool(request.woodland)!=woodland:set_environment(bool(request.woodland))
		if request.has("rotate"):
			auto_rotate = bool(request.rotate)
			JavaScriptBridge.eval("delete window.bestiaryRequest.rotate",true)
		if request.has("zoom"):
			zoom = clampf(zoom+float(request.zoom),0.55,1.8)
			JavaScriptBridge.eval("delete window.bestiaryRequest.zoom",true)
		if bool(request.get("reset",false)):
			turn = 0.12
			pitch = 0.18
			zoom = 1
			JavaScriptBridge.eval("window.bestiaryRequest.reset=false",true)
	var state := {"id":current,"woodland":woodland,"rotate":auto_rotate,"fps":Engine.get_frames_per_second(),"animated":current=="briarling","motion":briar.state(),"zoom":snappedf(zoom,0.01),"visibleModels":4 if current=="lineup" else 1}
	JavaScriptBridge.eval("window.bestiaryState="+JSON.stringify(state),true)
