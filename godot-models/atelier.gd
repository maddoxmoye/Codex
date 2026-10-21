extends Node3D
## Small inspection stage for the actual Blender GLBs. No gameplay is migrated here.
const IDS := ["rowan", "ash", "briar", "nyx", "pip", "fox", "wolf", "beetle"]
var manifest: Dictionary
var current := ""
var model: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var camera: Camera3D
var turn := 0.22
var pitch := 0.13
var auto_rotate := true
var dragging := false
var zoom := 1.0
var motion := "Idle"
var poll := 0.0
var clock := 0.0
var platform: MeshInstance3D
var native_label: Label

func _ready() -> void:
	Engine.max_fps = 60
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("17242c")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c2d2dc")
	world.environment.ambient_light_energy = 0.35
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	for light_info in [[Vector3(-38,-25,0),Color("ffe4c1"),0.6,true],[Vector3(-20,140,0),Color("97b8d2"),0.2,false],[Vector3(-50,175,0),Color("9fd5bc"),0.3,false]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = light_info[0]
		light.light_color = light_info[1]
		light.light_energy = light_info[2]
		light.shadow_enabled = light_info[3]
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		light.directional_shadow_max_distance = 12
		add_child(light)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("26333a")
	mat.roughness = 0.8
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.95
	cylinder.bottom_radius = 1.0
	cylinder.height = 0.12
	cylinder.radial_segments = 64
	platform = MeshInstance3D.new()
	platform.mesh = cylinder
	platform.material_override = mat
	platform.position.y = -0.07
	add_child(platform)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.93
	ring_mesh.outer_radius = 0.946
	ring_mesh.rings = 64
	ring_mesh.ring_segments = 6
	var rim := MeshInstance3D.new()
	rim.mesh = ring_mesh
	rim.position.y = -0.015
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("b7a26d")
	brass.metallic = 0.6
	brass.roughness = 0.4
	rim.material_override = brass
	add_child(rim)
	camera = Camera3D.new()
	camera.fov = 40
	camera.near = 0.05
	camera.far = 30
	add_child(camera)
	camera.current = true
	var ratio := 1.0
	if OS.has_feature("web"):
		ratio = float(JavaScriptBridge.eval("window.devicePixelRatio || 1", true))
	get_viewport().scaling_3d_scale = minf(1, 1.5 / ratio)
	select_model("rowan")
	if not OS.has_feature("web"):
		var layer := CanvasLayer.new()
		add_child(layer)
		native_label = Label.new()
		native_label.position = Vector2(20,20)
		layer.add_child(native_label)
		update_native_label()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.atelierReady=true",true)
	print("ATELIER_READY: Blender models loaded in Godot")

func info(id: String) -> Dictionary:
	for asset in manifest.assets:
		if asset.id == id:
			return asset
	return {}

func descendant(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for child in node.get_children():
		var found := descendant(child,type)
		if found:
			return found
	return null

func select_model(id: String) -> void:
	if id not in IDS or current == id:
		return
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	var data := info(id)
	var scene := load("res://" + data.file) as PackedScene
	model = scene.instantiate() as Node3D
	add_child(model)
	current = id
	animation = descendant(model,"AnimationPlayer") as AnimationPlayer
	skeleton = descendant(model,"Skeleton3D") as Skeleton3D
	turn = 0.22
	zoom = 1
	for node in model.find_children("*","MeshInstance3D",true,false):
		# Import-generated palette materials retain their authored values.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if animation:
		for name in animation.get_animation_list():
			animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	play_motion(motion)
	update_camera()
	update_native_label()
	print("MODEL_SELECTED: ",id," bones=",skeleton.get_bone_count() if skeleton else 0," animations=",animation.get_animation_list() if animation else [])

func play_motion(requested: String) -> void:
	motion = requested
	if not animation:
		return
	if motion == "Rest":
		animation.stop()
		if skeleton:
			skeleton.reset_bone_poses()
		return
	var data := info(current)
	var desired: String = data.clips[1] if motion == "Move" else "Idle"
	for name in animation.get_animation_list():
		if name == desired or name.ends_with("/" + desired):
			animation.play(name,0.15)
			return

func update_camera() -> void:
	var pet := current in ["fox","wolf","beetle"]
	var height := float(info(current).heightMeters)
	var target := Vector3(0,height * 0.51,0)
	var size := get_viewport().get_visible_rect().size
	var aspect := maxf(0.25,size.x / size.y)
	# Fit the full horizontal silhouette at every turntable angle, including long pet tails.
	var radius := 1.05 if current == "wolf" else 0.92 if current == "fox" else 0.55 if current == "beetle" else 0.72
	var distance := maxf(height * 1.95,radius / (tan(deg_to_rad(camera.fov) * 0.5) * aspect) * 1.12) * zoom
	if pet:
		distance = maxf(distance,2.1 * zoom)
	camera.position = target + Vector3(sin(turn)*distance,sin(pitch)*distance,cos(turn)*distance)
	camera.look_at(target)

func update_native_label() -> void:
	if native_label:
		var data := info(current)
		native_label.text = data.name + " / " + data.role + "\nLeft / Right: models · Space: idle/move · R: rest pose\nDrag to orbit · Wheel to zoom · A: auto turntable"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom + (-0.08 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.08),0.45,1.7)
	if event is InputEventMouseMotion and dragging:
		turn -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.005,-0.12,0.6)
		auto_rotate = false
	if event is InputEventScreenDrag:
		turn -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.005,-0.12,0.6)
		auto_rotate = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:
			var i := IDS.find(current)
			select_model(IDS[posmod(i + (1 if event.keycode == KEY_RIGHT else -1),IDS.size())])
		if event.keycode == KEY_SPACE:
			play_motion("Idle" if motion == "Move" else "Move")
		if event.keycode == KEY_R:
			play_motion("Rest")
		if event.keycode == KEY_A:
			auto_rotate = not auto_rotate

func _process(delta: float) -> void:
	clock += delta
	if auto_rotate and not dragging:
		turn += delta * 0.22
	update_camera()
	poll += delta
	if poll < 0.2 or not OS.has_feature("web"):
		return
	poll = 0
	var request = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.atelierRequest || {})",true))
	if request:
		var id = request.id
		if id is String and id in IDS and id != current:
			select_model(id)
		var clip = request.motion
		if clip is String and clip in ["Idle","Move","Rest"] and clip != motion:
			play_motion(clip)
		if request.has("zoom"):
			zoom = clampf(zoom + float(request.zoom),0.45,1.7)
			JavaScriptBridge.eval("delete window.atelierRequest.zoom",true)
		if bool(request.reset):
			turn = 0.22
			pitch = 0.13
			zoom = 1
			auto_rotate = true
			JavaScriptBridge.eval("window.atelierRequest.reset=false",true)
	var state := {"id":current,"motion":motion,"fps":Engine.get_frames_per_second(),"bones":skeleton.get_bone_count() if skeleton else 0,"clip":animation.current_animation if animation else "","auto":auto_rotate}
	JavaScriptBridge.eval("window.atelierState=" + JSON.stringify(state),true)
