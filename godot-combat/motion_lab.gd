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
	for i in 12:
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
	add_child(load("res://assets/woodland.glb").instantiate())
	setup_effects()
	camera.current = true
	var dpr := 1.0
	if OS.has_feature("web"):
		dpr = float(JavaScriptBridge.eval("window.devicePixelRatio || 1",true))
	get_viewport().scaling_3d_scale = minf(1.0,1.5/dpr)
	select_character("ash")
	update_camera(1.0)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.combatReady=true",true)
	print("COMBAT_ATELIER_READY: five kits and independent companion motion")

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
	for i in 12:
		var marker := salvo_targets[i]
		marker.position = launch+direction*4.2+right*(float(i)-3.5)*0.53
		marker.look_at(launch,Vector3.UP,true)
		marker.visible = clip=="Salvo" and not fan_mode
	target.visible = clip!="Salvo"
	target_post.visible = target.visible
	pet_target.position = base_origin+Vector3(-1.2,0.58,0.3)+direction*3.0
	pet_target.look_at(base_origin+Vector3(-1.2,0.58,0.3),Vector3.UP,true)

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

# Dedicated combat review: the game simulation and saved progression are untouched.
const ROSTER := ["rowan","ash","briar","nyx","pip"]
const COMPANIONS := ["fox","wolf","beetle"]
var character := "ash"
var companion := "wolf"
var action_kind := "Idle"
var pet_mode := "Auto"
var review_stage := 0
var release_index := 0
var normal_speed := 2.0
var pet_elapsed := 0.0
var pet_event := false
var pet_cycle := -1
var collected := 0
var wolf_state := ""
var wolf_state_time := 0.0
var wolf_roam_goal := Vector3.ZERO
var wolf_lap := 0
var wolf_bite_count := 0
var wolf_next_bite_time := 0.0
var wolf_blend_from: Array[Transform3D] = []
var wolf_blend_time := 0.0
const WOLF_SPEED := 0.30/(0.72*0.55)
const WOLF_TURN_SPEED := 4.0
const WOLF_BLEND_DURATION := 0.14
var bites := 0
var howls := 0
var blocks := 0
var damage_total := 0.0
var effects: Array[Dictionary] = []
var tokens: Array[Node3D] = []
var token_origins: Array[Vector3] = []
var health_nodes: Array[Node3D] = []
var target_hp: Array[float] = []
var target_rest: Array[Vector3] = []
var target_pulses: Array[float] = []
var shell_frame: Node3D
var ward: Node3D
var shield: MeshInstance3D
var aura: Node3D
var moon: Node3D
var clock_face: Node3D
var pet_ring: Node3D
var hostile_clock := 0.0
var hostile: Array[Dictionary] = []
var bite_target: Node3D
var defense_contact := false
var status_text := ""

func setup_effects() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.02
	sphere.height = 2.22
	sphere.radial_segments = 24
	sphere.rings = 12
	var glass := material("shell_glass","f4d58a",0.2,0.15)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.13
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield = part(sphere,glass,Vector3(0,1.0,0))
	shield.visible = false
	shell_frame = Node3D.new()
	add_child(shell_frame)
	for i in 3:
		var rim := TorusMesh.new()
		rim.inner_radius = .98
		rim.outer_radius = 1.0
		rim.rings = 8
		rim.ring_segments = 4
		var node := part(rim,material("shield_rim","edca7d",.6,.4),Vector3.ZERO,shell_frame)
		if i==0:node.rotation.x = PI/2
		elif i==1:node.rotation.z = PI/2
	ward = Node3D.new()
	add_child(ward)
	for i in 10:
		var angle := i*TAU/10
		var thorn := cylinder(0,.07,.45,5)
		var node := part(thorn,material("ward_thorn","b29cd5",.3,.3),Vector3(sin(angle)*1.05,.2,cos(angle)*1.05),ward)
		node.rotation.z = sin(angle)*-.6
		node.rotation.x = cos(angle)*.6
	aura = Node3D.new()
	add_child(aura)
	for i in 12:
		var angle := i*TAU/12
		var rune := BoxMesh.new()
		rune.size = Vector3(0.045,0.025,0.17)
		part(rune,material("runes","c4b8e8",0.3,0.6),Vector3(sin(angle)*0.95,0.035,cos(angle)*0.95),aura).rotation.y = angle
	moon = Node3D.new()
	add_child(moon)
	for i in 16:
		var a := -PI*0.70+i*PI*1.4/15
		var bead := SphereMesh.new()
		bead.radius = 0.025+0.025*sin(i*PI/15)
		bead.height = bead.radius*2
		bead.radial_segments = 6
		bead.rings = 3
		part(bead,material("moon_glow","d4c3f3",0.1,0.7),Vector3(sin(a)*0.32,cos(a)*0.32,0),moon)
	clock_face = Node3D.new()
	add_child(clock_face)
	for i in 12:
		var mark := BoxMesh.new()
		mark.size = Vector3(0.04,0.025,0.17 if i%3==0 else 0.08)
		var a := i*TAU/12
		part(mark,material("clock_brass","e8c57f",0.6,0.3),Vector3(sin(a)*1.5,0.03,cos(a)*1.5),clock_face).rotation.y = a
	for i in 2:
		var hand := BoxMesh.new()
		hand.size = Vector3(0.04,0.035,0.8 if i==0 else 1.1)
		var pivot := Node3D.new()
		clock_face.add_child(pivot)
		part(hand,palette.clock_brass,Vector3(0,0.04,hand.size.z/2),pivot)
	pet_ring = Node3D.new()
	add_child(pet_ring)
	for i in 8:
		var coin := cylinder(0.065,0.065,0.025,12)
		var token := part(coin,material("coin" if i%2==0 else "xp","f1ce73" if i%2==0 else "99dfbf",0.4,0.25),Vector3(-1.8+cos(i*TAU/8)*0.65,0.18,1.1+sin(i*TAU/8)*0.65))
		token.rotation.x = PI/2
		tokens.append(token)
		token_origins.append(token.position)
	bite_target = Node3D.new()
	add_child(bite_target)
	part(cylinder(0.24,0.30,0.65,8),material("bite_target","976d51"),Vector3(0,0.33,0),bite_target)
	part(cylinder(0.26,0.26,0.05,12),material("bite_band","b7c6af",0.2),Vector3(0,0.53,0),bite_target)
	for marker in salvo_targets:
		var bar := Node3D.new()
		marker.add_child(bar)
		bar.position = Vector3(0,0.39,0)
		var back := BoxMesh.new()
		back.size = Vector3(0.49,0.035,0.025)
		part(back,material("hp_back","25383b"),Vector3.ZERO,bar)
		var front := BoxMesh.new()
		front.size = Vector3(0.45,0.025,0.03)
		var fill := part(front,material("hp_front","a7c49a"),Vector3(0,0,0.015),bar)
		health_nodes.append(fill)
		target_hp.append(100.0)
		target_rest.append(Vector3.ZERO)
		target_pulses.append(0.0)

func select_character(id: String) -> void:
	if id not in ROSTER:return
	character = id
	if is_instance_valid(actor):actor.free()
	actor = load("res://assets/"+id+"-motion.glb").instantiate()
	add_child(actor)
	player = actor.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = actor.find_children("*","Skeleton3D",true,false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+("motion" if id=="rowan" else id)+".json"))
	if id=="rowan":
		metadata.merge({"id":"rowan","name":"Rowan","role":"Wayfarer","space":"Windskip","attack":"Salvo","spaceName":"Windskip","attackName":"Flock & Awe","spaceDuration":0.65,"attackDuration":0.0,"spaceCooldown":2.6,"attackCooldown":11.0,"color":"c4d994","damage":18.0,"description":"The approved archer, wind dash and eight-arrow salvo.","spaceDetail":"0.19s dash; 0.30s invulnerability.","attackDetail":"Eight arrows at 1.4× damage. Preview adds a short draw."},true)
	for name in player.get_animation_list():player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Run"] else Animation.LOOP_NONE
	player.play("Shoot",0)
	player.advance(0)
	player.seek(float(metadata.anchorTime),true)
	anchor_string = actor.global_transform.affine_inverse()*bone_point("bowstring")
	anchor_direction = (bone_point("bow")+Vector3.UP*0.08-bone_point("bowstring")).normalized()
	wind_cooldown = 0
	salvo_cooldown = 0
	shots = 0
	hits = 0
	damage_total = 0
	set_mode("Demo")

func select_companion(id: String) -> void:
	if id not in COMPANIONS:return
	companion = id
	if is_instance_valid(fox):fox.free()
	fox = load("res://assets/"+id+"-motion.glb").instantiate()
	add_child(fox)
	fox_player = fox.find_children("*","AnimationPlayer",true,false)[0]
	fox_skeleton = fox.find_children("*","Skeleton3D",true,false)[0]
	fox_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	fox_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+("fox-motion" if id=="fox" else id)+".json"))
	fox_metadata["id"] = id
	for name in fox_player.get_animation_list():fox_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Trot","Crawl","Fly"] else Animation.LOOP_NONE
	fox.position = Vector3(-1.45,0,0.65)
	fox_clip = ""
	wolf_state = ""
	wolf_state_time = 0
	wolf_lap = 0
	wolf_next_bite_time = 0
	wolf_blend_from.clear()
	wolf_blend_time = 0
	pet_elapsed = 0
	pet_cycle = -1
	pet_event = false
	fox_time = 0
	pet_shots = 0
	pet_hits = 0
	collected = 0
	bites = 0
	howls = 0

func set_mode(requested: String) -> void:
	if requested not in ["Demo","Shoot","Run","Space","Attack","Pet","Idle"]:return
	mode = requested
	review_stage = 0
	clear_arrows()
	clear_effects()
	base_origin = Vector3.ZERO
	actor.position = Vector3.ZERO
	actor.rotation.y = 0
	if health_nodes.size()>0:
		for i in 12:target_hp[i] = 100.0
	start_clip("Idle" if mode=="Demo" or mode=="Pet" else mode)

func start_clip(kind: String) -> void:
	action_kind = kind
	phase_time = 0
	release_index = 0
	release_fired = false
	defense_contact = false
	actor.position = Vector3.ZERO
	actor.rotation.y = 0
	if kind=="Space":
		clip = str(metadata.space)
		duration = float(metadata.spaceDuration)+1.2
		wind_cooldown = float(metadata.spaceCooldown)
	elif kind=="Attack":
		clip = str(metadata.attack)
		duration = maxf(float(metadata.clips[clip]),float(metadata.attackDuration))+1.2
		salvo_cooldown = float(metadata.attackCooldown)
	else:
		clip = "Run" if kind=="Run" else "Shoot" if kind=="Shoot" else "Idle"
		duration = 3.2/normal_speed+0.35 if clip=="Shoot" else 3.2 if clip=="Run" else 8.0 if mode=="Pet" else 1.2
	player.stop()
	player.play(clip,0)
	player.advance(0)
	align_combat_targets()
	status_text = ""

func align_combat_targets() -> void:
	if salvo_targets.is_empty():return
	var launch := anchor_string
	var direction := anchor_direction
	var right := Vector3.UP.cross(direction).normalized()
	target.visible = false
	target_post.visible = false
	for i in 12:
		var marker := salvo_targets[i]
		marker.visible = view_mode!="Pet"
		if character=="briar" and action_kind=="Attack":
			marker.position = Vector3(sin(i*TAU/12)*3.3,1.0,cos(i*TAU/12)*3.3)
		else:marker.position = launch+direction*(3.9+absf(i-5.5)*0.08)+right*(float(i)-5.0)*0.48
		marker.look_at(launch if not (character=="briar" and action_kind=="Attack") else Vector3(0,1,0),Vector3.UP,true)
		if target_rest.size()>i:target_rest[i] = marker.position
	bite_target.position = Vector3(-1.45,0,1.8)
	pet_target.position = Vector3(-1.45,0.65,3.6)
	pet_target.look_at(Vector3(-1.45,0.65,0.5),Vector3.UP,true)

func trigger_ability(slot: String) -> bool:
	if paused or slot not in ["Space","Attack"]:return false
	if (wind_cooldown if slot=="Space" else salvo_cooldown)>0:return false
	mode = "Idle"
	clear_arrows()
	clear_effects()
	start_clip(slot)
	return true

func emit_arrow(point: Vector3, direction: Vector3, empowered: bool, multiplier := 1.0, family := "normal") -> void:
	spawn_projectile(point,direction,false,empowered)
	var shot := projectiles[-1]
	shot["damage"] = float(metadata.damage)*multiplier
	shot["family"] = family
	if empowered:
		for child in shot.node.get_children():child.material_override = material("arrow_"+character,str(metadata.color),0.3,0.7)
		if character=="pip":
			var gear := TorusMesh.new()
			gear.inner_radius = 0.065
			gear.outer_radius = 0.09
			gear.rings = 10
			gear.ring_segments = 4
			part(gear,material("gold_gear","efd092",0.6,0.4),Vector3(0,0,-0.1),shot.node).rotation.x = PI/2
		if character=="nyx":shot.node.scale *= 1.2

func release_combat_arrow(index := 0) -> void:
	var restore := player.current_animation_position
	var sample := float(metadata.anchorTime)
	if action_kind=="Attack" and character=="rowan":sample = float(metadata.salvoAnchorTime)
	elif action_kind=="Attack" and character in ["ash","nyx","pip"]:sample = index*float(metadata.attackCycle)+float(metadata.attackCycle)*1.75/3.2
	player.seek(sample,true)
	var point := bone_point("bowstring")
	var aim := (bone_point("bow")+Vector3.UP*0.08-point).normalized()
	if action_kind=="Attack" and character=="rowan":
		for i in 8:emit_arrow(point,(salvo_targets[i+2].position-point).normalized(),true,1.4,"salvo")
	elif action_kind=="Attack" and character=="pip":
		for i in 3:emit_arrow(point,(salvo_targets[4+i].position-point).normalized(),true,1.0,"gear")
	elif action_kind=="Attack" and character=="briar":
		point = Vector3(0,1,0)
		for i in 12:emit_arrow(point,(salvo_targets[i].position-point).normalized(),true,0.8,"burst")
		pulse_ring(Vector3(0,0.08,0),Color("b5e6e5"),3.5,0.65)
	else:
		emit_arrow(point,aim,action_kind=="Attack",2.0 if character=="nyx" and action_kind=="Attack" else 1.0)
	player.seek(restore,true)

func advance_simulation(dt: float) -> void:
	wind_cooldown = maxf(0,wind_cooldown-dt)
	salvo_cooldown = maxf(0,salvo_cooldown-dt)
	phase_time += dt
	var anim_time := minf(phase_time*normal_speed,float(metadata.clips.Shoot)) if action_kind=="Shoot" else minf(phase_time,float(metadata.clips[clip]))
	if action_kind=="Run":anim_time = fmod(phase_time,0.8)
	if action_kind=="Idle":anim_time = fmod(phase_time,3.2)
	player.seek(anim_time,true)
	if action_kind=="Shoot" and phase_time>=float(metadata.releaseTime)/normal_speed and not release_fired:
		release_fired = true
		release_combat_arrow()
	if action_kind=="Attack":
		if character in ["rowan","briar"]:
			var release := float(metadata.salvoReleaseTime) if character=="rowan" else float(metadata.burstReleaseTime)
			if phase_time>=release and not release_fired:
				release_fired = true
				release_combat_arrow()
		elif character in ["ash","nyx","pip"]:
			var cycle: float = metadata.attackCycle
			while phase_time>=release_index*cycle+cycle*1.82/3.2 and release_index*cycle+cycle*1.82/3.2<float(metadata.attackDuration):
				release_combat_arrow(release_index)
				release_index += 1
	if action_kind=="Run":
		var a := phase_time/3.2*TAU
		actor.position = Vector3(cos(a)*0.65-0.65,0,sin(a)*0.65)
		actor.rotation.y = -a
	if action_kind=="Space" and character=="rowan":actor.position.z = 2.5*clampf(phase_time/0.19,0,1)
	if action_kind=="Space" and character=="ash" and phase_time<4:
		# Match the sped-up stride and keep the route within the practice stage.
		var a := phase_time/4*TAU
		actor.position = Vector3(cos(a)*0.95-0.95,0,sin(a)*0.95)
		actor.rotation.y = -a
	update_defense(dt)
	update_fox(dt)
	update_nocked()
	update_projectiles(dt)
	update_effects(dt)
	for i in target_pulses.size():
		target_pulses[i] = maxf(0,target_pulses[i]-dt)
		var pulse := target_pulses[i]
		var pushed := 0.0
		if action_kind=="Space" and character=="nyx":pushed = 1.1*smoothstep(0.2,0.7,phase_time)*(1-smoothstep(1.5,2.4,phase_time))
		var direction := target_rest[i].normalized()
		salvo_targets[i].position = target_rest[i]+direction*(pushed+pulse*0.12)
		health_nodes[i].scale.x = maxf(.01,target_hp[i]/100)
	if phase_time>=duration:
		clear_effects()
		if mode=="Demo":
			review_stage = (review_stage+1)%4
			start_clip(["Idle","Shoot","Space","Attack"][review_stage])
		elif mode in ["Idle","Pet"]:start_clip("Idle")
		else:start_clip(mode)

func update_nocked() -> void:
	var anim_t := phase_time*normal_speed if action_kind=="Shoot" else phase_time
	var release := float(metadata.releaseTime)
	var nock_time := 0.7
	if action_kind=="Attack" and character in ["ash","nyx","pip"]:
		var cycle: float = metadata.attackCycle
		anim_t = fmod(phase_time,cycle)*3.2/cycle
		if phase_time>=float(metadata.attackDuration):anim_t = 3.2
	elif action_kind=="Attack" and character=="rowan":anim_t = phase_time*3.2/1.1
	nocked.visible = view_mode!="Pet" and (action_kind=="Shoot" or (action_kind=="Attack" and character!="briar")) and anim_t>=nock_time and anim_t<release
	if nocked.visible:
		var point := bone_point("bowstring")
		var direction := (bone_point("bow")+Vector3.UP*0.08-point).normalized()
		nocked.position = point+direction*0.30
		nocked.look_at(nocked.position+direction,Vector3.UP,true)

func update_defense(dt: float) -> void:
	var active := action_kind=="Space" and phase_time<float(metadata.spaceDuration)
	invulnerable = active and phase_time<(0.3 if character=="rowan" else 0.8 if character=="ash" else 1.0 if character=="pip" else float(metadata.spaceDuration))
	shield.visible = active and character=="briar"
	shield.position = actor.position+Vector3(0,1.0,0)
	shell_frame.visible = shield.visible
	shell_frame.position = shield.position
	shell_frame.rotation.y = phase_time*.25
	ward.visible = active and character=="nyx"
	ward.position = actor.position
	ward.rotation.y = phase_time*.25
	ward.scale = Vector3.ONE*maxf(.01,smoothstep(0,.3,phase_time))
	aura.visible = active and character in ["briar","nyx"]
	aura.position = actor.position
	aura.rotation.y += dt*0.3
	clock_face.visible = active and character=="pip"
	clock_face.position = actor.position
	if clock_face.visible:
		clock_face.get_child(12).rotation.y = -phase_time*0.7
		clock_face.get_child(13).rotation.y = -phase_time*2.4
	moon.visible = action_kind=="Attack" and character=="nyx" and phase_time<4
	moon.position = actor.position+Vector3(0,2.40,0)
	moon.rotation.y += dt*.4
	if active and not defense_contact:
		defense_contact = true
		if character=="nyx":pulse_ring(actor.position+Vector3(0,0.15,0),Color("b7a2e2"),4.8,0.7)
		if character=="pip":pulse_ring(actor.position+Vector3(0,0.08,0),Color("e6c482"),2.0,0.7)
	if active and character in ["ash","rowan"]:
		effect_clock += dt
		if effect_clock>0.10:
			effect_clock = 0
			pulse_ring(actor.position+Vector3(0,0.08,0),Color(str(metadata.color)),0.55,0.3)
	if active and character in ["briar","nyx","pip"]:
		hostile_clock -= dt
		if hostile_clock<=0:
			hostile_clock = 0.6
			var orb := SphereMesh.new()
			orb.radius = 0.07
			orb.height = 0.14
			orb.radial_segments = 8
			orb.rings = 4
			var node := part(orb,material("hostile","d89d8e",0.1,0.5),actor.position+Vector3(0,1.0,2.6))
			hostile.append({"node":node,"life":5.0})
	for i in range(hostile.size()-1,-1,-1):
		var item := hostile[i]
		item.life -= dt
		var slow := 0.35 if active and character=="pip" and item.node.position.distance_to(actor.position+Vector3.UP)<2.0 else 1.0
		item.node.position = item.node.position.move_toward(actor.position+Vector3.UP,dt*3.5*slow)
		var distance: float = item.node.position.distance_to(actor.position+Vector3.UP)
		if (distance<1.05 and active and character in ["briar","nyx"]) or distance<0.15 or item.life<=0:
			if invulnerable or (active and character=="nyx"):
				blocks += 1
				pulse_ring(item.node.position,Color("f7dba5"),0.3,0.25,true)
			item.node.queue_free()
			hostile.remove_at(i)

func pet_play(next: String, restart := false) -> void:
	if fox_clip==next and not restart:return
	if companion=="wolf":
		wolf_blend_from.clear()
		if not fox_clip.is_empty():
			for i in fox_skeleton.get_bone_count():wolf_blend_from.append(fox_skeleton.get_bone_pose(i))
		wolf_blend_time = 0
	fox_clip = next
	fox_time = 0
	pet_event = false
	fox_player.stop()
	fox_player.play(next,0)
	fox_player.advance(0)

func update_fox(dt: float) -> void:
	if fox_metadata.get("id","")!=companion:
		select_companion(companion)
	if view_mode in ["Archer","Bow"]:
		return
	pet_elapsed += dt
	var detail := view_mode=="Pet" or mode=="Pet"
	var home := Vector3(-1.45,0,0.65) if detail else actor.position+Vector3(-1.45,0,0.65)
	bite_target.visible = companion=="wolf"
	pet_target.visible = companion=="fox"
	for token in tokens:token.visible = companion=="beetle"
	if companion=="beetle":
		var cycle := int(pet_elapsed/6.0)
		var t := fmod(pet_elapsed,6.0)
		var index := cycle%tokens.size()
		if cycle!=pet_cycle:
			pet_cycle = cycle
			for i in tokens.size():tokens[i].position = token_origins[i]
		var goal: Vector3 = token_origins[index]
		if t<1.0:
			pet_play("Crawl")
			fox.position = fox.position.move_toward(home,dt*0.5)
		elif t<2.5:
			pet_play("Fly")
			fox.position = fox.position.move_toward(goal+Vector3(0,.45,0),dt*1.2)
		elif t<3.5:
			pet_play("Collect")
			fox.position = fox.position.move_toward(goal,dt*1.5)
			if fox_time>=float(fox_metadata.collectTime) and not pet_event:
				pet_event = true
				collected += 1
				pulse_ring(goal,Color("f3d185"),0.45,0.4)
			if pet_event:tokens[index].position = fox.position+Vector3(0,.50,0)
		elif t<5.0:
			pet_play("Fly")
			fox.position = fox.position.move_toward(home+Vector3(0,.45,0),dt*1.2)
			tokens[index].position = fox.position+Vector3(0,.50,0)
		else:
			pet_play("Deliver")
			fox.position = fox.position.move_toward(home,dt)
			var u := smoothstep(5.0,5.6,t)
			tokens[index].position = (fox.position+Vector3(0,.5,0)).lerp(actor.position+Vector3(0,0.9,0),u)
			if t>5.6:tokens[index].visible = false
		var face: Vector3 = (goal if t<3.5 else home)-fox.position
		if face.length()>0.05:fox.rotation.y = lerp_angle(fox.rotation.y,atan2(face.x,face.z),minf(1,dt*8))
	elif companion=="wolf":
		update_wolf(dt,home)
	else:
		fox_cooldown -= dt
		if fox.position.distance_to(home)>0.1:
			pet_play("Trot")
			var direction := home-fox.position
			fox.position = fox.position.move_toward(home,dt*1.7)
			fox.rotation.y = lerp_angle(fox.rotation.y,atan2(direction.x,direction.z),minf(1,dt*10))
		else:
			fox.rotation.y = lerp_angle(fox.rotation.y,0,minf(1,dt*10))
			if fox_cooldown<=0:fox_clip = "";pet_play("Attack");fox_cooldown = 1.1
			if fox_clip=="Attack" and fox_time>=.32 and not pet_event:
				pet_event = true
				var local: Array = fox_metadata.muzzleLocal
				var head: Transform3D = fox_skeleton.global_transform*fox_skeleton.get_bone_global_pose(fox_skeleton.find_bone("head"))
				var point: Vector3 = head*Vector3(local[0],local[1],local[2])
				for spread in [-.12,0,.12]:spawn_projectile(point,(pet_target.position-point).normalized().rotated(Vector3.UP,spread),true)
			if fox_time>.85:pet_play("Idle")
	fox_time += dt
	var length := fox_player.get_animation(fox_clip).length
	fox_player.seek(fmod(fox_time,length) if fox_clip in ["Idle","Trot","Fly","Crawl"] else minf(fox_time,length),true)
	if companion=="wolf" and not wolf_blend_from.is_empty():
		wolf_blend_time += dt
		var weight := smoothstep(0,WOLF_BLEND_DURATION,wolf_blend_time)
		for i in wolf_blend_from.size():
			fox_skeleton.set_bone_pose(i,wolf_blend_from[i].interpolate_with(fox_skeleton.get_bone_pose(i),weight))
		if weight>=1:wolf_blend_from.clear()


func wolf_enter(next: String, home := Vector3.ZERO) -> void:
	wolf_state = next
	wolf_state_time = 0
	match next:
		"Roam":
			# Pick one destination per patrol, rather than chasing a new point every frame.
			wolf_roam_goal = home+Vector3(-0.40 if wolf_lap%2==0 else 0.30,0,-0.22)
			wolf_lap += 1
			wolf_bite_count = 0
			pet_play("Trot")
		"Approach":pet_play("Trot")
		"Face", "Rest":pet_play("Idle")
		"Bite":pet_play("Bite",true)
		"Howl":pet_play("Howl")

func wolf_turn(direction: Vector3, dt: float) -> void:
	if direction.length_squared()<0.0001:return
	fox.rotation.y = rotate_toward(fox.rotation.y,atan2(direction.x,direction.z),WOLF_TURN_SPEED*dt)

func update_wolf(dt: float, home: Vector3) -> void:
	if wolf_state.is_empty():wolf_enter("Roam",home)
	wolf_state_time += dt
	match wolf_state:
		"Roam":
			var direction := wolf_roam_goal-fox.position
			if direction.length()>0.025:
				pet_play("Trot")
				fox.position = fox.position.move_toward(wolf_roam_goal,WOLF_SPEED*dt)
				wolf_turn(direction,dt)
			else:pet_play("Idle")
			if wolf_state_time>=1.4:wolf_enter("Approach")
		"Approach":
			var goal := bite_target.position+Vector3(0,0,-0.73)
			var direction := goal-fox.position
			fox.position = fox.position.move_toward(goal,WOLF_SPEED*dt)
			wolf_turn(direction,dt)
			if fox.position.distance_to(goal)<0.015:wolf_enter("Face")
		"Face":
			var direction := bite_target.position-fox.position
			wolf_turn(direction,dt)
			if absf(angle_difference(fox.rotation.y,atan2(direction.x,direction.z)))<0.04:wolf_enter("Bite")
		"Bite":
			# Body and facing stay planted through the entire authored bite and recovery.
			if fox_time>=float(fox_metadata.biteContact) and pet_elapsed>=wolf_next_bite_time and not pet_event:
				pet_event = true
				wolf_next_bite_time = pet_elapsed+float(fox_metadata.biteCooldown)
				bites += 1
				pet_hits += 1
				pulse_ring(bite_target.position+Vector3(0,.55,-.25),Color("e8c996"),.25,.25,true)
				floating_number(bite_target.position+Vector3(0,.9,0),str(roundi(float(metadata.damage)*1.3)),Color("f1d8a6"))
			if fox_time>=fox_player.get_animation("Bite").length:
				wolf_bite_count += 1
				wolf_enter("Howl" if wolf_bite_count>=3 else "Bite")
		"Howl":
			if fox_time>=.55 and not pet_event:
				pet_event = true
				howls += 1
				pulse_ring(fox.position+Vector3(0,.06,0),Color("bad7e9"),1.75,.7)
			if fox_time>=fox_player.get_animation("Howl").length:wolf_enter("Rest")
		"Rest":
			if wolf_state_time>=.35:wolf_enter("Roam",home)

func pulse_ring(point: Vector3, tint: Color, radius: float, life: float, upright := false) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = .93
	torus.outer_radius = 1.0
	torus.rings = 36
	torus.ring_segments = 4
	var node := part(torus,material("pulse_"+tint.to_html(),tint.to_html(),0.2,.6),point)
	if upright:node.rotation.x = PI/2
	effects.append({"node":node,"age":0.0,"duration":life,"radius":radius,"number":false})

func floating_number(point: Vector3, value: String, tint: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.font_size = 48
	label.pixel_size = .004
	label.modulate = tint
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	label.position = point
	effects.append({"node":label,"age":0.0,"duration":.75,"radius":1.0,"number":true})

func update_effects(dt: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var fx := effects[i]
		fx.age += dt
		var u: float = fx.age/fx.duration
		if fx.number:
			fx.node.position.y += dt*.6
			fx.node.modulate.a = 1-u
		else:fx.node.scale = Vector3.ONE*maxf(.01,fx.radius*(.08+.92*u))
		if u>=1:
			fx.node.queue_free()
			effects.remove_at(i)

func clear_effects() -> void:
	for fx in effects:fx.node.queue_free()
	effects.clear()
	for item in hostile:item.node.queue_free()
	hostile.clear()
	hostile_clock = 0.3

func update_projectiles(dt: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var item := projectiles[i]
		var arrow: Node3D = item.node
		var dir: Vector3 = item.direction
		var previous := arrow.position+dir*.38
		arrow.position += dir*dt*11
		item.age += dt
		var next := arrow.position+dir*.38
		var candidates: Array = [pet_target] if item.pet else salvo_targets
		var hit_index := -1
		var contact: Variant = null
		for j in candidates.size():
			var candidate: Node3D = candidates[j]
			var normal: Vector3 = candidate.global_basis.z.normalized()
			contact = Plane(normal,normal.dot(candidate.position)).intersects_segment(previous,next)
			if contact!=null and Vector3(contact).distance_to(candidate.position)<(.48 if item.pet else .27):
				hit_index = j
				break
		if hit_index>=0:
			arrow.position = Vector3(contact)-dir*.28
			stuck.append(arrow)
			if stuck.size()>24:stuck.pop_front().queue_free()
			if item.pet:pet_hits += 1
			else:
				hits += 1
				var damage: float = item.get("damage",metadata.damage)
				damage_total += damage
				target_hp[hit_index] = maxf(0,target_hp[hit_index]-damage)
				target_pulses[hit_index] = .3
				floating_number(Vector3(contact)+Vector3(0,.35,0),str(roundi(damage)),Color(str(metadata.color)))
				if target_hp[hit_index]<=0:target_hp[hit_index] = 100.0
			pulse_ring(contact,Color("f1d495"),.22,.25,true)
			projectiles.remove_at(i)
		elif item.age>1.5:
			arrow.queue_free()
			projectiles.remove_at(i)

func update_camera(dt: float) -> void:
	actor.visible = view_mode!="Pet"
	fox.visible = view_mode in ["Range","Pet"]
	bite_target.visible = fox.visible and companion=="wolf"
	pet_target.visible = fox.visible and companion=="fox"
	for token in tokens:token.visible = token.visible and fox.visible
	aura.visible = aura.visible and actor.visible
	moon.visible = moon.visible and actor.visible
	shield.visible = shield.visible and actor.visible
	shell_frame.visible = shell_frame.visible and actor.visible
	ward.visible = ward.visible and actor.visible
	clock_face.visible = clock_face.visible and actor.visible
	for marker in salvo_targets:marker.visible = view_mode!="Pet"
	var focus := actor.position+Vector3(0,1.0,0)
	var offset := Vector3(-3.2,1.25,4.1)
	if view_mode=="Bow":
		focus = actor.position+Vector3(0,1.45,0)
		offset = Vector3(-1.8,.65,2.25)
	elif view_mode=="Range":
		focus = Vector3(0,1.0,1.25)
		offset = Vector3(-5.8,4.2,7.7)
	elif view_mode=="Pet":
		focus = fox.position+Vector3(0,.4 if companion!="beetle" else .2,0)
		offset = Vector3(-2.5,.8,1.7) if companion=="wolf" else Vector3(-1.4,.75,1.7)
	var size := get_viewport().get_visible_rect().size
	if size.x<size.y and view_mode=="Range":offset *= 1.8
	if size.x<size.y and view_mode=="Bow":offset *= 1.65
	offset = offset.rotated(Vector3.UP,view_turn)
	offset.y += view_pitch
	# Raise the composition above the compact bottom review controls.
	focus.y -= .12 if view_mode=="Pet" else .1
	if view_mode in ["Archer","Pet"]:
		offset = offset.normalized()*fit_subject(fox if view_mode=="Pet" else actor,focus,offset.normalized(),offset.length(),size.x/maxf(1,size.y))
	camera.position = camera.position.lerp(focus+offset,minf(1,dt*8))
	camera.look_at(focus)

func fit_subject(subject: Node3D, focus: Vector3, back: Vector3, minimum: float, aspect: float) -> float:
	var right := Vector3.UP.cross(back).normalized()
	var up := back.cross(right).normalized()
	var tangent := tan(deg_to_rad(camera.fov)*.5)
	var distance := minimum
	for mesh in subject.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin:continue
		var bounds: AABB = mesh.mesh.get_aabb()
		for i in 8:
			var point: Vector3 = mesh.global_transform*bounds.get_endpoint(i)-focus
			var near := point.dot(back)
			distance = maxf(distance,near+absf(point.dot(right))/(tangent*aspect*.78))
			var vertical := point.dot(up)
			distance = maxf(distance,near+absf(vertical)/(tangent*(.78 if vertical>0 else .55)))
	return distance*1.02

func phase_label() -> String:
	if view_mode=="Pet":return str(fox_metadata.name)+" · "+fox_clip
	if action_kind=="Space":return str(metadata.spaceName)+(" · BLOCKING" if invulnerable else " · ACTIVE" if phase_time<float(metadata.spaceDuration) else " · RECOVER")
	if action_kind=="Attack":return str(metadata.attackName)+(" · RECOVER" if phase_time>float(metadata.clips[clip]) else " · ACTIVE")
	return "DRAW · RELEASE · IMPACT" if action_kind=="Shoot" else "LOCOMOTION" if action_kind=="Run" else "COMBAT STUDY"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging = event.pressed
	if event is InputEventMouseMotion and dragging:
		view_turn -= event.relative.x*.007
		view_pitch = clampf(view_pitch+event.relative.y*.004,-.3,1.5)
	if event is InputEventScreenDrag:
		view_turn -= event.relative.x*.007
		view_pitch = clampf(view_pitch+event.relative.y*.004,-.3,1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:trigger_ability("Space")
		if event.keycode==KEY_E:trigger_ability("Attack")
		if event.keycode==KEY_P:paused = not paused

func _process(delta: float) -> void:
	if not paused:advance_simulation(minf(delta,.1)*speed)
	update_camera(delta)
	poll += delta
	if poll<.12 or not OS.has_feature("web"):return
	poll = 0
	var request = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.combatRequest || {})",true))
	if request:
		if request.get("character",character)!=character:select_character(str(request.character))
		if request.get("companion",companion)!=companion:select_companion(str(request.companion))
		if request.get("mode",mode)!=mode:set_mode(str(request.mode))
		paused = bool(request.get("paused",false))
		speed = clampf(float(request.get("speed",1)),.25,1)
		view_mode = str(request.get("view","Archer"))
		if request.has("cast"):
			if trigger_ability(str(request.cast)):JavaScriptBridge.eval("window.combatRequest.mode='Idle'",true)
			JavaScriptBridge.eval("delete window.combatRequest.cast",true)
		if bool(request.get("reset",false)):
			view_turn = 0
			view_pitch = 0
			JavaScriptBridge.eval("window.combatRequest.reset=false",true)
		if request.has("seek"):
			phase_time = float(request.seek)
			player.seek(phase_time*normal_speed if action_kind=="Shoot" else phase_time,true)
			clear_arrows()
			update_nocked()
			JavaScriptBridge.eval("delete window.combatRequest.seek",true)
	var state := {"character":character,"companion":companion,"mode":mode,"clip":clip,"action":action_kind,"phase":phase_label(),"time":phase_time,"shots":shots,"hits":hits,"damage":damage_total,"flying":projectiles.size(),"paused":paused,"speed":speed,"fps":Engine.get_frames_per_second(),"bones":skeleton.get_bone_count(),"nocked":nocked.visible,"view":view_mode,"petClip":fox_clip,"petShots":pet_shots,"petHits":pet_hits,"collected":collected,"bites":bites,"howls":howls,"blocks":blocks,"windCooldown":wind_cooldown,"salvoCooldown":salvo_cooldown,"invulnerable":invulnerable,"effects":effects.size(),"petBones":fox_skeleton.get_bone_count()}
	JavaScriptBridge.eval("window.combatState="+JSON.stringify(state),true)
