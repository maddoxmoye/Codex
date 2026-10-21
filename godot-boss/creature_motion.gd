extends Node3D
## One-enemy animation/contact study. The campaign combat system is not migrated.
var creature_id := "briarling"
var metadata: Dictionary
var actor: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var active := false
var paused := false
var speed := 1.0
var mode := "Demo"
var clip := "Idle"
var phase := 0.0
var clock := 0.0
var hp := 60
var hits := 0
var contacts := 0
var arrows_fired := 0
var arrow: Node3D
var arrow_direction := Vector3.ZERO
var arrow_age := 0.0
var contact_fired := false
var demo_step := 0
var demo_time := 0.0
var flash := 0.0
var flash_materials: Array[ShaderMaterial] = []
var effects: Array[Dictionary] = []
var hp_root: Node3D
var hp_fill: MeshInstance3D
var hp_text: Label3D
var dummy: Node3D
var dummy_material: StandardMaterial3D
var dummy_flash := 0.0
var contact_height := 0.64
var tint_shader: Shader

func mat(color: String, glow := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.8
	if glow>0:
		result.emission_enabled = true
		result.emission = Color(color)
		result.emission_energy_multiplier = glow
	return result

func mesh_part(mesh: Mesh, material: Material, parent: Node3D, location: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = location
	return node

func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _ready() -> void:
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+creature_id+"-motion.json"))
	actor = load("res://"+str(metadata.file)).instantiate()
	add_child(actor)
	player = actor.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = actor.find_children("*","Skeleton3D",true,false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name in player.get_animation_list():player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Run"] else Animation.LOOP_NONE
	tint_shader = Shader.new()
	tint_shader.code = "shader_type spatial; uniform sampler2D palette_tex : source_color; uniform float hit_flash = 0.0; void fragment(){vec3 base = texture(palette_tex, UV).rgb; ALBEDO = mix(base, vec3(1.0,0.88,0.66),hit_flash*0.86); ROUGHNESS=0.68;}"
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and not original.emission_enabled:
				var tinted := ShaderMaterial.new()
				tinted.shader = tint_shader
				tinted.set_shader_parameter("palette_tex",original.albedo_texture)
				mesh.set_surface_override_material(i,tinted)
				flash_materials.append(tinted)
	hp_root = Node3D.new()
	add_child(hp_root)
	mesh_part(box(Vector3(0.65,0.07,0.016)),mat("172b26"),hp_root,Vector3.ZERO)
	hp_fill = mesh_part(box(Vector3(0.59,0.033,0.022)),mat("b2cf8b"),hp_root,Vector3(0,0,0.012))
	hp_text = Label3D.new()
	hp_text.font_size = 28
	hp_text.pixel_size = 0.0025
	hp_text.position.y = 0.095
	hp_text.outline_size = 10
	hp_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_root.add_child(hp_text)
	setup_attack_target()
	setup_extras()
	reset_health()
	set_active(false)

func setup_attack_target() -> void:
	# Place the timing-study post at the actual authored left-claw contact pose.
	player.stop()
	player.play("Attack",0)
	player.advance(0)
	player.seek(float(metadata.attackContact),true)
	actor.position.z = 0.20*smoothstep(0.36,0.57,float(metadata.attackContact))
	var local: Array = metadata.clawSocket.L
	var claw_transform := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("claw.L"))
	var point: Vector3 = global_transform.affine_inverse()*(claw_transform*Vector3(local[0],local[1],local[2]))
	contact_height = point.y
	actor.position = Vector3.ZERO
	player.stop()
	skeleton.reset_bone_poses()
	dummy = Node3D.new()
	add_child(dummy)
	dummy.position = Vector3(point.x,0,point.z+0.035)
	mesh_part(box(Vector3(0.055,contact_height,0.055)),mat("6e6249"),dummy,Vector3(0,contact_height*0.5,0))
	dummy_material = mat("b69d6a")
	dummy_material.emission_enabled = true
	dummy_material.emission = Color("e5c184")
	mesh_part(box(Vector3(0.24,0.22,0.07)),dummy_material,dummy,Vector3(0,contact_height,0))
	mesh_part(box(Vector3(0.025,0.16,0.015)),mat("e3d9b8"),dummy,Vector3(0,contact_height,-0.044))

func play_clip(name: String) -> void:
	clip = name
	phase = 0
	contact_fired = false
	actor.position = Vector3.ZERO
	player.play(name,0.07)
	player.advance(0)
	if is_instance_valid(dummy):dummy.visible = active and name=="Attack"
	on_clip_started(name)

func clear_effects() -> void:
	clear_extra()
	if is_instance_valid(arrow):arrow.queue_free()
	arrow = null
	for item in effects:item.node.queue_free()
	effects.clear()

func reset_health() -> void:
	clear_effects()
	hp = int(metadata.health)
	flash = 0
	for material in flash_materials:material.set_shader_parameter("hit_flash",0.0)
	dummy_flash = 0
	dummy_material.emission_energy_multiplier = 0
	play_clip("Idle")
	update_health()
	reset_extra()

func set_active(enabled: bool) -> void:
	active = enabled
	paused = false
	reset_health()
	hp_root.visible = enabled
	dummy.visible = enabled
	if enabled:command("Demo")
	else:
		player.stop()
		skeleton.reset_bone_poses()

func command(request: String) -> bool:
	if request=="Reset":
		reset_health()
		mode = "Idle"
		return true
	if hp<=0 and request!="Demo":return false
	if request=="Hold":
		mode = "Attack"
		clear_effects()
		play_clip("Attack")
		phase = float(metadata.get("windupTime",0.30))
		player.stop()
		player.play("Attack",0)
		player.advance(0)
		player.seek(phase,true)
		update_attack_motion(0.0,phase)
		update_extra(0.0)
		paused = true
		return true
	if request=="Arrow":
		if is_instance_valid(arrow) or clip=="Hit":return false
		mode = "Idle"
		play_clip("Idle")
		shoot_arrow()
		return true
	if request not in ["Demo","Idle","Run","Attack"]:return false
	mode = request
	clear_effects()
	if request=="Demo":
		reset_health()
		demo_step = 0
		demo_time = 0
	play_clip("Idle" if request=="Demo" else request)
	return true

func shoot_arrow() -> void:
	arrow = Node3D.new()
	add_child(arrow)
	arrow.position = actor.position+Vector3(-0.72,float(metadata.get("hitCenter",0.69))+0.13,2.4)
	arrow_direction = (actor.position+Vector3(0,float(metadata.get("hitCenter",0.69)),0)-arrow.position).normalized()
	arrow.look_at(arrow.position+arrow_direction,Vector3.UP,true)
	mesh_part(box(Vector3(0.012,0.012,0.43)),mat("c4b57c"),arrow,Vector3.ZERO)
	mesh_part(box(Vector3(0.04,0.016,0.07)),mat("b6ddd0",0.3),arrow,Vector3(0,0,0.23))
	for s in [-1,1]:mesh_part(box(Vector3(0.045,0.008,0.08)),mat("d7e5ca"),arrow,Vector3(s*0.02,0,-0.16))
	arrow_age = 0
	arrows_fired += 1

func number(text: String, point: Vector3, tint := Color("ffe3a1")) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.0019
	label.outline_size = 12
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	label.position = point
	effects.append({"node":label,"life":0.85,"duration":0.85,"velocity":Vector3(0,0.45,0),"label":true})

func chips(point: Vector3, count := 7, leaves := false) -> void:
	for i in count:
		var shard := mesh_part(chip_mesh(leaves),mat(chip_tint(leaves)),self,point)
		shard.rotation = Vector3(i*0.7,i*1.4,i*0.9)
		effects.append({"node":shard,"life":0.55,"duration":0.55,"velocity":Vector3(sin(i*2.4)*0.55,0.5+(i%3)*0.13,cos(i*2.4)*0.5),"label":false})

func take_damage(amount: int) -> bool:
	if hp<=0:return false
	hp = maxi(0,hp-amount)
	hits += 1
	flash = 0.12
	number("−"+str(amount),actor.position+Vector3(0.10,float(metadata.get("hitCenter",0.69))+0.34,0))
	chips(actor.position+Vector3(0,float(metadata.get("hitCenter",0.69))+0.03,0.1))
	play_clip("Death" if hp==0 else "Hit")
	if hp==0:chips(actor.position+Vector3(0,1.1,0),10,true)
	update_health()
	return true

func update_health() -> void:
	var fraction := float(hp)/float(metadata.health)
	hp_fill.scale.x = maxf(0.001,fraction)
	hp_fill.position.x = -0.295*(1-fraction)
	hp_text.text = str(hp)+" / "+str(int(metadata.health))

func advance_demo(dt: float) -> void:
	demo_time += dt
	var limits := [1.3,2.7,float(metadata.clips.Attack)+0.4,float(metadata.clips.Hit)+0.65,float(metadata.clips.Hit)+0.65,float(metadata.clips.Death)+1.6]
	if demo_time<float(limits[demo_step]):return
	demo_time = 0
	demo_step += 1
	match demo_step:
		1:play_clip("Run")
		2:play_clip("Attack")
		3,4,5:
			play_clip("Idle")
			shoot_arrow()
		6:
			reset_health()
			demo_step = 0

func advance_simulation(dt: float) -> void:
	if not active or paused:return
	clock += dt
	var old := phase
	phase += dt
	player.advance(dt)
	if clip=="Run":update_run_motion(dt)
	elif clip=="Attack":update_attack_motion(dt,old)
	elif clip=="Hit":actor.position.z = -sin(minf(1.0,phase/float(metadata.clips.Hit))*PI)*0.11
	if clip in ["Attack","Hit"] and phase>=float(metadata.clips[clip]):play_clip("Idle")
	if is_instance_valid(arrow):
		var previous := arrow.position+arrow_direction*0.26
		arrow.position += arrow_direction*dt*9
		arrow_age += dt
		var next := arrow.position+arrow_direction*0.26
		var center := actor.position+Vector3(0,float(metadata.get("hitCenter",0.69)),0)
		var closest := Geometry3D.get_closest_points_between_segments(previous,next,center-Vector3(0,0.2,0),center+Vector3(0,0.2,0))
		if closest[0].distance_to(closest[1])<float(metadata.get("hitRadius",0.22)):
			arrow.queue_free()
			arrow = null
			take_damage(int(metadata.arrowDamage))
		elif arrow_age>1.0:
			arrow.queue_free()
			arrow = null
	flash = maxf(0,flash-dt)
	for material in flash_materials:material.set_shader_parameter("hit_flash",flash/0.12)
	dummy_flash = maxf(0,dummy_flash-dt)
	dummy_material.emission_energy_multiplier = dummy_flash*4
	for i in range(effects.size()-1,-1,-1):
		var item := effects[i]
		item.life -= dt
		if not item.label:item.velocity.y -= dt*2
		item.node.position += item.velocity*dt
		if item.label:item.node.modulate.a = clampf(item.life/0.25,0,1)
		else:item.node.scale = Vector3.ONE*maxf(0.01,item.life/item.duration)
		if item.life<=0:
			item.node.queue_free()
			effects.remove_at(i)
	var head := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(str(metadata.get("healthBone","head"))))
	hp_root.position = global_transform.affine_inverse()*head.origin+Vector3.UP*float(metadata.get("healthOffset",0.49))
	update_extra(dt)
	if mode=="Demo":advance_demo(dt)

func update_view(camera: Camera3D) -> void:
	if active:
		hp_root.look_at(camera.global_position,Vector3.UP,true)

func phase_label() -> String:
	if clip=="Attack":return "WINDUP" if phase<0.40 else "CLAW CONTACT" if phase<0.73 else "RECOVERY"
	if clip=="Hit":return "HIT · RECOIL"
	if clip=="Death":return "FALL · DEFEATED"
	return "SCURRY" if clip=="Run" else "IDLE · BREATHING"

func state() -> Dictionary:
	return {"mode":mode,"clip":clip,"phase":phase_label(),"time":snappedf(phase,0.01),"hp":hp,"maxHp":int(metadata.health),"hits":hits,"contacts":contacts,"arrows":arrows_fired,"flying":is_instance_valid(arrow),"paused":paused,"speed":speed,"effects":effects.size()}

func update_attack_motion(_dt: float, old: float) -> void:
	actor.position.z = 0.20*smoothstep(0.36,0.57,phase)*(1-smoothstep(0.75,1.14,phase))
	if not contact_fired and old<float(metadata.attackContact) and phase>=float(metadata.attackContact):
		contact_fired = true
		contacts += 1
		dummy_flash = 0.18
		chips(dummy.position+Vector3(0,contact_height,-0.04),5)
		number(str(int(metadata.dummyDamage)),dummy.position+Vector3(0.08,contact_height+0.18,-0.04),Color("dbe9c0"))

func update_run_motion(_dt: float) -> void:
	actor.position.x = sin(phase*TAU/2.7)*0.20

func chip_mesh(leaves: bool) -> Mesh:
	return box(Vector3(0.045,0.012,0.025) if leaves else Vector3(0.025,0.025,0.025))

func chip_tint(leaves: bool) -> String:
	return "9cba71" if leaves else "bc9a65"

func setup_extras() -> void:pass
func update_extra(_dt: float) -> void:pass
func clear_extra() -> void:pass
func reset_extra() -> void:pass
func on_clip_started(_name: String) -> void:pass
