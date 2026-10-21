extends Node3D
## Procedural, original art. An automatically animated scene, not a game benchmark.

var clock := 0.0
var stats_clock := 0.0
var camera: Camera3D
var sun: DirectionalLight3D
var ranger: Node3D
var cape: MeshInstance3D
var bow_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var familiar: Node3D
var crystal: Node3D
var rings: Array[MeshInstance3D] = []
var motes: Array[MeshInstance3D] = []
var arrows: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}
var batch_meshes: Dictionary = {}
var batches: Dictionary = {}
var quality := "balanced"
var run_time := 0.0
var sample_seconds := 0.0
var sample_frames := 0
var last_tick := 0.0

func mat(id: String, tint: String, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	if materials.has(id):
		return materials[id]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint)
	m.metallic = metal
	m.roughness = 0.68 if metal < 0.5 else 0.3
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(tint)
		m.emission_energy_multiplier = glow
	materials[id] = m
	return m

func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func sphere(radius: float, height := -1.0) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2 if height < 0 else height
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh

func cylinder(top: float, bottom: float, height: float, sides := 12) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	return mesh

func mesh_at(mesh: Mesh, material: Material, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = pos
	return node

func static_at(key: String, mesh: Mesh, material: Material, pos: Vector3, size := Vector3.ONE, turn := 0.0) -> void:
	if not batches.has(key):
		batches[key] = []
		batch_meshes[key] = [mesh, material]
	var basis := Basis(Vector3.UP, turn).scaled(size)
	batches[key].append(Transform3D(basis, pos))

func flush_static() -> void:
	for key in batches:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = batch_meshes[key][0]
		mm.instance_count = batches[key].size()
		for i in mm.instance_count:
			mm.set_instance_transform(i, batches[key][i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = mm
		node.material_override = batch_meshes[key][1]
		add_child(node)
	batches.clear()
	batch_meshes.clear()

func branch(a: Vector3, b: Vector3, radius: float, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var part := mesh_at(cylinder(radius * 0.8, radius, a.distance_to(b), 8), material, (a + b) * 0.5, parent)
	var direction := (b - a).normalized()
	if absf(direction.dot(Vector3.UP)) < 0.999:
		part.quaternion = Quaternion(Vector3.UP, direction)
	return part

func make_ring(radius: float, material: Material, y: float, parent: Node3D = self) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.035
	mesh.outer_radius = radius + 0.035
	mesh.rings = 48
	mesh.ring_segments = 6
	return mesh_at(mesh, material, Vector3(0, y, 0), parent)

func _ready() -> void:
	rng.seed = 87219
	Engine.max_fps = 60
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("10242d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("98bdd4")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffe0af")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = 46
	camera.near = 0.1
	camera.far = 95
	add_child(camera)
	camera.current = true
	build_grove()
	build_ranger()
	build_familiar()
	flush_static()
	set_quality("balanced")
	animate_scene(0.0)
	last_tick = Time.get_ticks_usec() / 1000000.0
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.godotDemoReady = true;", true)
	print("MOONWELL_READY: Godot scene initialized")

func build_grove() -> void:
	var stone := mat("stone", "626c70")
	var stone_light := mat("stone_light", "9bada6")
	var stone_dark := mat("stone_dark", "344c54")
	var moss := mat("moss", "5e8170")
	var earth := mat("earth", "263d49")
	var grass := mat("grass", "407b73")
	var gold := mat("gold", "bd9557", 0.65)
	var magic := mat("magic", "62e2d3", 0.3, 1.0)
	var lilac := mat("lilac", "bba2f6", 0.1, 0.7)
	# A floating, terraced clearing; low sided primitives create a hand-cut silhouette.
	mesh_at(cylinder(9.3, 8.2, 1.0, 18), earth, Vector3(0, -0.75, 0))
	mesh_at(cylinder(8.7, 9.2, 0.35, 24), moss, Vector3(0, -0.12, 0))
	mesh_at(cylinder(3.7, 3.85, 0.22, 48), stone_dark, Vector3(0, 0.08, 0))
	for i in 30:
		var angle := i * TAU / 30
		static_at("walkway", box(Vector3(0.64, 0.22, 0.86)), stone_light, Vector3(sin(angle) * 3.2, 0.22, cos(angle) * 3.2), Vector3.ONE, angle)
	# The raised moonwell, water surface, gold inset and animated magical rings.
	mesh_at(cylinder(2.05, 2.25, 0.44, 32), stone, Vector3(0, 0.32, 0))
	mesh_at(cylinder(1.8, 1.8, 0.12, 48), mat("water", "235a70", 0.45, 0.15), Vector3(0, 0.57, 0))
	make_ring(1.96, gold, 0.57)
	for i in 16:
		var angle := i * TAU / 16
		static_at("well_runes", box(Vector3(0.07, 0.025, 0.20)), magic, Vector3(sin(angle) * 1.95, 0.63, cos(angle) * 1.95), Vector3.ONE, angle)
	for i in 3:
		var ring := make_ring(0.6 + i * 0.25, magic if i != 1 else gold, 1.65 + i * 0.34)
		rings.append(ring)
	crystal = Node3D.new()
	add_child(crystal)
	mesh_at(cylinder(0.0, 0.43, 0.85, 6), magic, Vector3(0, 0.425, 0), crystal)
	mesh_at(cylinder(0.43, 0.0, 0.85, 6), magic, Vector3(0, -0.425, 0), crystal)
	# Ruined gate frames the central crystal without hiding it from the orbiting camera.
	for side in [-1, 1]:
		for step in 5:
			var pos := Vector3(side * 2.2, 0.45 + step * 0.68, -3.5)
			static_at("gate_blocks", box(Vector3(0.76, 0.64, 0.8)), stone_light, pos, Vector3.ONE, step * side * 0.015)
		static_at("gate_bases", box(Vector3(1.12, 0.28, 1.12)), stone_dark, Vector3(side * 2.2, 0.18, -3.5))
		static_at("gate_caps", box(Vector3(1.0, 0.24, 1.0)), gold, Vector3(side * 2.2, 3.57, -3.5))
	for i in 9:
		var a := PI * i / 8
		static_at("arch", box(Vector3(0.78, 0.67, 0.83)), stone_light, Vector3(cos(a) * 2.2, 3.72 + sin(a) * 1.7, -3.5), Vector3.ONE, a - PI * 0.5)
	make_tree(Vector3(-5.0, 0, -1.8), 1.25, -0.25)
	make_tree(Vector3(5.1, 0, -2.6), 1.05, 0.45)
	make_tree(Vector3(-7.0, 0, 3.6), 0.9, -1.3)
	make_tree(Vector3(7.0, 0, 3.6), 0.86, 2.0)
	make_tree(Vector3(1.0, 0, -6.6), 1.18, -0.6)
	# Broadleaf clusters and fern-like grass are instanced by material, not individual draws.
	for i in 130:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(4.2, 8.4)
		var pos := Vector3(sin(angle) * radius, 0.16, cos(angle) * radius)
		var scale_y := rng.randf_range(0.5, 1.4)
		static_at("grass", cylinder(0, 0.14, 0.55, 3), grass, pos, Vector3(1, scale_y, 1), angle)
		if i % 3 == 0:
			static_at("flowers", sphere(0.075), lilac, pos + Vector3(0, 0.3 * scale_y, 0))
	for i in 38:
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.2, 8.1)
		var s := rng.randf_range(0.3, 0.85)
		static_at("rocks", sphere(0.7), stone_dark, Vector3(sin(a) * r, 0.03, cos(a) * r), Vector3(s, s * 0.6, s * 0.8), a)
	# Suspended debris sells the floating-island silhouette.
	for i in 18:
		var a := i * TAU / 18
		static_at("island_shards", cylinder(0.9, 0.0, 2.8, 5), earth, Vector3(sin(a) * 7.3, -1.8, cos(a) * 7.3), Vector3.ONE, a)
	for pos in [Vector3(-3.8, 0, 1.8), Vector3(3.8, 0, -0.8)]:
		mesh_at(cylinder(0.27, 0.42, 0.85, 8), stone, pos + Vector3(0, 0.5, 0))
		mesh_at(sphere(0.19), mat("flame", "ffd487", 0.0, 1.2), pos + Vector3(0, 1.14, 0))
	for i in 22:
		var node := mesh_at(sphere(0.028), magic if i % 2 == 0 else lilac, Vector3.ZERO)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		motes.append(node)
	# A soft halo around the moonwell is a single alpha-blended billboard.
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var distance := Vector2(x - 31.5, y - 31.5).length() / 31.5
			image.set_pixel(x, y, Color(0.2, 0.9, 0.82, pow(maxf(0, 1 - distance), 3) * 0.3))
	var halo_mat := StandardMaterial3D.new()
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_mat.albedo_texture = ImageTexture.create_from_image(image)
	var quad := QuadMesh.new()
	quad.size = Vector2(4, 4)
	mesh_at(quad, halo_mat, Vector3(0, 2, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func make_tree(pos: Vector3, size: float, turn: float) -> void:
	var trunk := mat("bark", "51434b")
	var leaves := [mat("leaves0", "2e655d"), mat("leaves1", "50867a"), mat("leaves2", "75a38b")]
	static_at("trunks", cylinder(0.19, 0.45, 3.4, 7), trunk, pos + Vector3(0, 1.7 * size, 0), Vector3.ONE * size, turn)
	for i in 3:
		var angle := turn + i * TAU / 3
		var offset := Vector3(sin(angle) * 0.85, 3.4 + i * 0.3, cos(angle) * 0.85) * size
		static_at("canopy" + str(i), sphere(1.25), leaves[i], pos + offset, Vector3(1.15, 0.65, 1.0) * size, angle)
		var b := Transform3D(Basis(Vector3.UP, turn), pos)
		var base := b * (Vector3(sin(angle) * 0.2, 1.8, cos(angle) * 0.2) * size)
		var tip := pos + offset
		var direction := (tip - base).normalized()
		var basis := Basis(Quaternion(Vector3.UP, direction))
		if not batches.has("branches"):
			batches["branches"] = []
			batch_meshes["branches"] = [cylinder(0.07, 0.16, 1, 6), trunk]
		batches["branches"].append(Transform3D(basis.scaled(Vector3(size, base.distance_to(tip), size)), (base + tip) * 0.5))

func build_ranger() -> void:
	ranger = Node3D.new()
	add_child(ranger)
	var teal := mat("cloak", "368d8e")
	var cloth := mat("cloth", "204b61")
	var leather := mat("leather", "684e47")
	var skin := mat("skin", "e3b58f")
	var hair := mat("hair", "3c3038")
	var gold := mat("gold", "bd9557", 0.65)
	mesh_at(cylinder(0.3, 0.39, 0.75, 8), cloth, Vector3(0, 1.06, 0), ranger)
	mesh_at(cylinder(0.325, 0.335, 0.13, 8), leather, Vector3(0, 0.89, 0), ranger)
	mesh_at(box(Vector3(0.14, 0.15, 0.04)), gold, Vector3(0, 0.89, 0.33), ranger)
	mesh_at(sphere(0.31), teal, Vector3(0, 1.65, 0), ranger)
	mesh_at(sphere(0.25, 0.48), skin, Vector3(0, 1.64, 0.12), ranger)
	mesh_at(sphere(0.255, 0.20), hair, Vector3(0, 1.84, 0.13), ranger)
	for side in [-1, 1]:
		mesh_at(sphere(0.024), hair, Vector3(side * 0.09, 1.69, 0.354), ranger)
		mesh_at(sphere(0.009), mat("eyes", "d0eef0", 0, 0.2), Vector3(side * 0.09, 1.697, 0.374), ranger)
	cape = mesh_at(box(Vector3(0.65, 0.91, 0.065)), teal, Vector3(0, 0.98, -0.32), ranger)
	cape.rotation.x = -0.17
	mesh_at(cylinder(0.12, 0.13, 0.66, 8), leather, Vector3(0.24, 1.22, -0.4), ranger)
	for i in 4:
		branch(Vector3(0.18 + i * 0.04, 1.35, -0.4), Vector3(0.18 + i * 0.04, 1.75, -0.4), 0.012, gold, ranger)
	for side in [-1, 1]:
		var leg := Node3D.new()
		ranger.add_child(leg)
		leg.position = Vector3(side * 0.17, 0.73, 0)
		mesh_at(cylinder(0.12, 0.1, 0.49, 8), cloth, Vector3(0, -0.22, 0), leg)
		mesh_at(box(Vector3(0.24, 0.26, 0.36)), leather, Vector3(0, -0.49, 0.055), leg)
		if side == -1:
			left_leg = leg
		else:
			right_leg = leg
	bow_arm = Node3D.new()
	ranger.add_child(bow_arm)
	bow_arm.position = Vector3(-0.30, 1.36, 0)
	branch(Vector3.ZERO, Vector3(-0.2, -0.16, 0.43), 0.1, teal, bow_arm)
	mesh_at(sphere(0.085), skin, Vector3(-0.2, -0.16, 0.47), bow_arm)
	branch(Vector3(0.3, 1.35, 0), Vector3(0.12, 1.2, 0.44), 0.1, teal, ranger)
	mesh_at(sphere(0.085), skin, Vector3(0.12, 1.2, 0.44), ranger)
	# Curved wooden bow and visible string, with a blue arrow nocked.
	var bow_mat := mat("bow", "b5875b")
	var previous := Vector3.ZERO
	for i in 9:
		var t := i / 8.0
		var point := Vector3(-0.2, -0.78 + t * 1.22, 0.47 + sin(t * PI) * 0.25)
		if i > 0:
			branch(previous, point, 0.025, bow_mat, bow_arm)
		previous = point
	branch(Vector3(-0.2, -0.78, 0.47), Vector3(-0.2, 0.44, 0.47), 0.005, gold, bow_arm)
	branch(Vector3(-0.2, -0.16, 0.37), Vector3(-0.2, -0.16, 0.94), 0.013, mat("arrow", "9bffff", 0.2, 1.0), bow_arm)
	for i in 4:
		var arrow := Node3D.new()
		add_child(arrow)
		branch(Vector3(0, 0, -0.30), Vector3(0, 0, 0.30), 0.018, materials["arrow"], arrow)
		mesh_at(sphere(0.05), materials["arrow"], Vector3(0, 0, 0.3), arrow)
		arrows.append(arrow)

func build_familiar() -> void:
	familiar = Node3D.new()
	add_child(familiar)
	var amber := mat("fox", "e4aa66")
	var cream := mat("fox_cream", "fff0cc")
	mesh_at(sphere(0.16, 0.24), amber, Vector3.ZERO, familiar)
	mesh_at(sphere(0.17), amber, Vector3(0, 0.15, 0.12), familiar)
	mesh_at(sphere(0.1), cream, Vector3(0, 0.09, 0.24), familiar)
	for side in [-1, 1]:
		mesh_at(cylinder(0, 0.09, 0.20, 3), amber, Vector3(side * 0.1, 0.33, 0.12), familiar)
		mesh_at(sphere(0.018), materials["hair"], Vector3(side * 0.07, 0.19, 0.26), familiar)
	mesh_at(sphere(0.11, 0.4), cream, Vector3(0, 0.02, -0.25), familiar).rotation.x = 1.1

func set_quality(value: String) -> void:
	quality = value
	var viewport := get_viewport()
	var base_scale := 1.0 if quality == "high" else 0.6 if quality == "light" else 0.75
	var pixel_ratio := 1.0
	if OS.has_feature("web"):
		pixel_ratio = float(JavaScriptBridge.eval("window.devicePixelRatio || 1", true))
	# Cap 3D pixel density on Retina phones; HTML labels remain native resolution.
	viewport.scaling_3d_scale = base_scale * minf(1.0, 1.5 / maxf(1, pixel_ratio))
	viewport.msaa_3d = Viewport.MSAA_DISABLED if quality == "light" else Viewport.MSAA_2X
	sun.shadow_enabled = quality != "light"
	# Reset the rolling measurement when the workload changes.
	run_time = 0
	sample_frames = 0
	sample_seconds = 0

func animate_scene(delta: float) -> void:
	clock += delta
	var orbit := clock * 0.13 + 0.3
	var portrait := get_viewport().get_visible_rect().size.x < get_viewport().get_visible_rect().size.y
	var distance := 23.0 if portrait else 16.2
	camera.position = Vector3(sin(orbit) * distance, 8.3 if portrait else 7.5, cos(orbit) * distance)
	camera.look_at(Vector3(0, 1.4, 0))
	crystal.position.y = 2.15 + sin(clock * 1.7) * 0.15
	crystal.rotation.y = clock * 0.55
	for i in rings.size():
		rings[i].rotation = Vector3(sin(clock * 0.7 + i) * 0.25, clock * 0.3, cos(clock * 0.8 + i) * 0.2)
	for i in motes.size():
		var angle := clock * (0.13 + i * 0.002) + i * 2.4
		var radius := 1.3 + (i % 5) * 1.1
		motes[i].position = Vector3(sin(angle) * radius, 0.8 + (i % 4) * 0.6 + sin(clock + i) * 0.25, cos(angle) * radius)
	# The archer patrols the well, stops, draws and fires four visible magic arrows.
	var cycle := fmod(clock, 10.0)
	var moving := cycle < 5.0
	var path_angle := floorf(clock / 10.0) * 1.8 + minf(cycle, 5.0) * 0.36 + 1.3
	ranger.position = Vector3(sin(path_angle) * 3.35, 0.32, cos(path_angle) * 3.35)
	ranger.rotation.y = path_angle + PI * 0.5 if moving else path_angle + PI
	var stride := sin(clock * 8) * 0.42 if moving else 0.0
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	cape.rotation.x = -0.18 + sin(clock * 4) * 0.1
	bow_arm.rotation.y = sin(cycle * PI) * 0.1 if not moving else 0.0
	familiar.position = ranger.position + Vector3(sin(clock * 1.3) * 0.8, 0.7 + sin(clock * 3) * 0.13, cos(clock * 1.3) * 0.8)
	familiar.rotation.y = -clock * 1.3
	for i in arrows.size():
		var phase := cycle - (5.6 + i * 0.8)
		arrows[i].visible = phase >= 0 and phase < 0.6
		if arrows[i].visible:
			var start := ranger.position + Vector3(0, 1.25, 0)
			var target := Vector3(0, 2.2, 0)
			arrows[i].position = start.lerp(target, phase / 0.6)
			arrows[i].look_at(target + (target - start).normalized(), Vector3.UP, true)

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec() / 1000000.0
	var real_delta := maxf(0, now - last_tick)
	last_tick = now
	var suspended := false
	if OS.has_feature("web"):
		suspended = bool(JavaScriptBridge.eval("window.demoPaused === true || document.hidden", true))
	if not suspended:
		animate_scene(minf(delta, 0.1))
		run_time += real_delta
		# Exclude the first five seconds of loading and shader warmup from the average.
		if run_time > 5:
			sample_seconds += real_delta
			sample_frames += 1
	stats_clock += delta
	if stats_clock < 0.5:
		return
	stats_clock = 0
	if OS.has_feature("web"):
		var requested = JavaScriptBridge.eval("window.demoQuality || 'balanced'", true)
		if requested is String and requested in ["light", "balanced", "high"] and requested != quality:
			set_quality(requested)
		var fps := Engine.get_frames_per_second()
		var avg := sample_frames / sample_seconds if sample_seconds > 0 else 0.0
		var payload := JSON.stringify({"fps": fps, "average": snappedf(avg, 0.1), "warmup": run_time < 5, "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "quality": quality, "paused": suspended, "seconds": snappedf(sample_seconds, 0.1), "resolution": get_viewport().get_visible_rect().size * get_viewport().scaling_3d_scale})
		JavaScriptBridge.eval("window.godotDemoStats = " + payload + ";", true)
