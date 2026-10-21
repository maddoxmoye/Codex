extends "res://briarling_motion.gd"
## Species-specific effects and attack timing; shared target feedback stays in the base.
var warning: Node3D
var warning_material: StandardMaterial3D
var warning_fill: MeshInstance3D
var shockwaves: Array[Dictionary] = []
var blob: Node3D
var blob_age := 0.0
var blob_start := Vector3.ZERO
var blob_target := Vector3.ZERO
var releases := 0
var impacts := 0
var dust_clock := 0.0
var glow_materials: Array[Dictionary] = []
var telegraph_clock := 0.0

func attack_type() -> String:
	return str(metadata.attackType)

func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh

func ring(inner: float, outer: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 40
	mesh.ring_segments = 6
	return mesh

func translucent(color: String, alpha: float) -> StandardMaterial3D:
	var material := mat(color,0.25)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = alpha
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func socket_point(id: String) -> Vector3:
	var info: Dictionary = metadata.sockets[id]
	var values: Array = info.local
	var transform := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(str(info.bone)))
	return global_transform.affine_inverse()*(transform*Vector3(values[0],values[1],values[2]))

func setup_attack_target() -> void:
	dummy = Node3D.new()
	add_child(dummy)
	contact_height = 0.65
	dummy.position = Vector3(0,0,2.5) if attack_type()=="spore" else Vector3(1.0,0,1.0)
	if attack_type()=="charge":
		player.stop()
		player.play("Attack",0)
		player.advance(0)
		player.seek(float(metadata.attackContact),true)
		actor.position.z = float(metadata.chargeDistance)*smoothstep(float(metadata.chargeStart),float(metadata.chargeEnd),float(metadata.attackContact))
		var point := socket_point("nose")
		contact_height = point.y
		dummy.position = Vector3(point.x,0,point.z+0.035)
		actor.position = Vector3.ZERO
		player.stop()
		skeleton.reset_bone_poses()
	dummy_material = mat("a8b88c")
	dummy_material.emission_enabled = true
	dummy_material.emission = Color("e3c98e")
	mesh_part(box(Vector3(0.06,maxf(0.1,contact_height),0.06)),mat("6e6249"),dummy,Vector3(0,contact_height*0.5,0))
	mesh_part(box(Vector3(0.28,0.25,0.07)),dummy_material,dummy,Vector3(0,contact_height,0))

func setup_extras() -> void:
	warning = Node3D.new()
	add_child(warning)
	var color := "bb82db" if attack_type()=="spore" else "e6aa62" if attack_type()=="charge" else "ce6c5b"
	warning_material = translucent(color,0.75)
	if attack_type()=="charge":
		mesh_part(box(Vector3(0.90,0.012,3.2)),translucent(color,0.17),warning,Vector3(0,0.015,1.75))
		for side in [-1,1]:mesh_part(box(Vector3(0.028,0.018,3.2)),warning_material,warning,Vector3(side*0.46,0.025,1.75))
		for z in [0.5,1.15,1.8,2.45,3.1]:
			for side in [-1,1]:
				var chevron := mesh_part(box(Vector3(0.22,0.018,0.028)),warning_material,warning,Vector3(side*0.075,0.03,z))
				chevron.rotation.y = side*0.60
	else:
		var radius := 0.55 if attack_type()=="spore" else 1.45
		warning.position = Vector3(0,0.025,2.5) if attack_type()=="spore" else Vector3(0,0.025,0.90)
		mesh_part(ring(radius-0.025,radius+0.025),warning_material,warning,Vector3.ZERO)
		var disk := CylinderMesh.new()
		disk.top_radius = radius
		disk.bottom_radius = radius
		disk.height = 0.008
		disk.radial_segments = 40
		warning_fill = mesh_part(disk,translucent(color,0.12),warning,Vector3(0,-0.006,0))
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.emission_enabled:
				var material: StandardMaterial3D = original.duplicate()
				mesh.set_surface_override_material(i,material)
				glow_materials.append({"material":material,"energy":material.emission_energy_multiplier})
	warning.visible = false

func on_clip_started(name: String) -> void:
	if is_instance_valid(warning):warning.visible = active and name=="Attack"
	dust_clock = 0

func clear_extra() -> void:
	if is_instance_valid(blob):blob.queue_free()
	blob = null
	for wave in shockwaves:wave.node.queue_free()
	shockwaves.clear()
	if is_instance_valid(warning):warning.visible = false

func reset_extra() -> void:
	for entry in glow_materials:entry.material.emission_energy_multiplier = entry.energy

func update_run_motion(_dt: float) -> void:
	# Small in-place inspection patrol, with the forward gait baked in Blender.
	actor.position.z = sin(phase*TAU/3.0)*0.10

func update_attack_motion(dt: float, old: float) -> void:
	if attack_type()=="charge":
		actor.position.z = float(metadata.chargeDistance)*smoothstep(float(metadata.chargeStart),float(metadata.chargeEnd),phase)*(1-smoothstep(1.65,float(metadata.clips.Attack),phase))
		if phase>=float(metadata.chargeStart) and phase<=1.35:
			dust_clock += dt
			if dust_clock>=0.10:
				dust_clock = 0
				chips(actor.position+Vector3(0,0.12,-0.25),2)
	elif attack_type()=="slam":actor.position.z = 0.22*smoothstep(1.05,1.42,phase)*(1-smoothstep(2.0,3.1,phase))
	if not contact_fired and old<float(metadata.attackContact) and phase>=float(metadata.attackContact):
		contact_fired = true
		if attack_type()=="spore":launch_spore()
		else:
			contacts += 1
			impacts += 1
			dummy_flash = 0.22
			if attack_type()=="charge":
				chips(dummy.position+Vector3(0,contact_height,-0.04),12)
				number(str(int(metadata.dummyDamage)),dummy.position+Vector3(0.22,contact_height+0.30,-0.04),Color("eed8ae"))
			else:
				var palms := (socket_point("handL")+socket_point("handR"))*0.5
				var center := Vector3(palms.x,0.04,palms.z)
				chips(center+Vector3.UP*0.15,14)
				spawn_wave(center,"e1ca8f",1.85,0.65)
				number(str(int(metadata.dummyDamage)),Vector3(0.9,0.95,1.0),Color("c7e3a5"))

func launch_spore() -> void:
	releases += 1
	var restore := phase
	player.seek(float(metadata.attackContact),true)
	blob_start = socket_point("launch")
	player.seek(restore,true)
	blob_target = Vector3(0,0.06,2.5)
	blob = Node3D.new()
	add_child(blob)
	mesh_part(sphere(0.13),mat("bb8bc8",0.55),blob,Vector3.ZERO)
	for i in 3:mesh_part(sphere(0.035),mat("e4cfe5",0.3),blob,Vector3(sin(i*2.1)*0.12,0.02,cos(i*2.1)*0.12))
	blob.position = blob_start
	blob_age = 0

func spawn_wave(point: Vector3, color: String, size: float, lifetime: float) -> void:
	var node := mesh_part(ring(0.95,1.0),translucent(color,0.75),self,point)
	node.scale = Vector3.ONE*0.1
	shockwaves.append({"node":node,"life":lifetime,"duration":lifetime,"size":size})

func update_extra(dt: float) -> void:
	if is_instance_valid(warning):
		warning.visible = active and ((clip=="Attack" and phase<float(metadata.attackRecovery)) or is_instance_valid(blob))
		telegraph_clock += dt
		warning_material.albedo_color.a = 0.60+sin(telegraph_clock*9)*0.18
	if is_instance_valid(blob):
		blob_age += dt
		var u := minf(1.0,blob_age/float(metadata.flightTime))
		blob.position = blob_start.lerp(blob_target,u)+Vector3.UP*(4.0*u*(1.0-u)*0.85)
		blob.rotation.y += dt*3.0
		if u>=1.0:
			blob.queue_free()
			blob = null
			contacts += 1
			impacts += 1
			dummy_flash = 0.20
			chips(blob_target+Vector3.UP*0.12,12)
			spawn_wave(blob_target,"c39bdb",0.70,0.65)
			number(str(int(metadata.dummyDamage)),blob_target+Vector3(0.22,0.55,0),Color("e0c6f1"))
	for i in range(shockwaves.size()-1,-1,-1):
		var wave := shockwaves[i]
		wave.life -= dt
		var u: float = 1.0-wave.life/wave.duration
		wave.node.scale = Vector3.ONE*maxf(0.01,lerpf(0.12,float(wave.size),u))
		wave.node.material_override.albedo_color.a = maxf(0,wave.life/wave.duration)*0.65
		if wave.life<=0:
			wave.node.queue_free()
			shockwaves.remove_at(i)
	var pulse := 0.05*sin(clock*3)
	if clip=="Attack":pulse += 0.75*sin(clampf(phase/float(metadata.attackContact),0.0,1.0)*PI*0.5)
	if clip=="Hit":pulse += flash/0.12
	for entry in glow_materials:
		entry.material.emission_energy_multiplier = maxf(0,float(entry.energy)*(1.0+pulse))*(0.45 if hp<=0 else 1.0)

func chip_tint(leaves: bool) -> String:
	if leaves:return "a7ba7c"
	return "bd95c6" if attack_type()=="spore" else "93a3a0" if attack_type()=="charge" else "c4a174"

func chip_mesh(leaves: bool) -> Mesh:
	if attack_type()=="spore" and not leaves:return sphere(0.035)
	return super.chip_mesh(leaves)

func phase_label() -> String:
	if clip=="Attack":
		if phase<float(metadata.attackContact):return "SPORE · CHARGE THE GILLS" if attack_type()=="spore" else "CHARGE · LOWER THE TUSKS" if attack_type()=="charge" else "SLAM · RAISE THE HAMMERS"
		if phase<float(metadata.attackRecovery):return "SPORE · LOB & LAND" if attack_type()=="spore" else "CHARGE · IMPACT" if attack_type()=="charge" else "SLAM · SHOCKWAVE"
		return "RECOVER · RESET STANCE"
	if clip=="Run":return str(metadata.runLabel).to_upper()
	if clip=="Hit":return "CAP · WOBBLE" if attack_type()=="spore" else "ARMOR · HEAVY RECOIL" if attack_type()=="charge" else "SEED-HEART · STAGGER"
	return super.phase_label()

func state() -> Dictionary:
	var result := super.state()
	result["type"] = attack_type()
	result["releases"] = releases
	result["impacts"] = impacts
	result["outgoing"] = is_instance_valid(blob)
	result["warning"] = is_instance_valid(warning) and warning.visible
	result["waves"] = shockwaves.size()
	return result
