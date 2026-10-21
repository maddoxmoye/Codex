extends "res://creature_motion.gd"
## One original boss, two authored attacks. No campaign migration or production AI.
var melee_warning: Node3D
var ranged_warning: Node3D
var melee_center := Vector3.ZERO
var targets: Array[Node3D] = []
var target_points: Array[Vector3] = []
var release_index := 0
var volleys := 0
var thorn_shots := 0
var thorn_hits := 0
var slam_hits := 0
var outgoing: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var embedded: Array[Node3D] = []
var glow_materials: Array[StandardMaterial3D] = []
var target_flash: Array[float] = [0.0,0.0,0.0]
var target_materials: Array[StandardMaterial3D] = []
var target_damage: Array[int] = [0,0,0]
var close_damage := 0

func _ready() -> void:
	creature_id = "briar-king"
	super._ready()
	hp_root.scale = Vector3.ONE*1.8
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.emission_enabled:
				var glow: StandardMaterial3D = original.duplicate()
				mesh.set_surface_override_material(i,glow)
				glow_materials.append(glow)

func sphere(radius: float) -> SphereMesh:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius*2
	shape.radial_segments = 12
	shape.rings = 6
	return shape

func ring(inner: float, outer: float) -> TorusMesh:
	var shape := TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = 48
	shape.ring_segments = 5
	return shape

func transparent(tint: String, alpha: float) -> StandardMaterial3D:
	var material := mat(tint,.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = alpha
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func socket(id: String) -> Vector3:
	var info: Dictionary = metadata.sockets[id]
	var point: Array = info.local
	var transform: Transform3D = skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(str(info.bone)))
	return global_transform.affine_inverse()*(transform*Vector3(point[0],point[1],point[2]))

func sample_socket(id: String, animation: String, time: float) -> Vector3:
	var restore := player.current_animation_position
	player.seek(time,true)
	var point := socket(id)
	player.seek(restore,true)
	return point

func make_dummy(position: Vector3, large := false) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = position
	mesh_part(box(Vector3(.10,1.2,.10)),mat("7c6049"),node,Vector3(0,.6,0))
	var target_mat := mat("b9bf9b")
	target_mat.emission_enabled = true
	target_mat.emission = Color("f5d39d")
	target_mat.emission_energy_multiplier = 0
	var disk := CylinderMesh.new()
	disk.top_radius = .36 if large else .28
	disk.bottom_radius = disk.top_radius
	disk.height = .07
	disk.radial_segments = 24
	mesh_part(disk,target_mat,node,Vector3(0,1.15,0)).rotation.x = PI/2
	mesh_part(sphere(.07),mat("6a4c36"),node,Vector3(0,1.15,.06))
	target_materials.append(target_mat)
	return node

func setup_attack_target() -> void:
	player.play("Melee",0)
	player.advance(0)
	player.seek(float(metadata.melee.contact),true)
	melee_center = socket("knuckle")
	melee_center.y = .035
	player.stop()
	skeleton.reset_bone_poses()
	dummy = make_dummy(melee_center+Vector3(0,-.035,1.35),true)
	dummy_material = target_materials.pop_back()
	contact_height = 1.15
	for i in 3:
		var position := Vector3(-.65+i*1.40,0,6.0)
		targets.append(make_dummy(position))
		target_points.append(position+Vector3.UP*1.15)

func setup_extras() -> void:
	melee_warning = Node3D.new()
	add_child(melee_warning)
	melee_warning.position = melee_center
	var area := CylinderMesh.new()
	area.top_radius = float(metadata.melee.radius)
	area.bottom_radius = area.top_radius
	area.height = .006
	area.radial_segments = 64
	mesh_part(area,transparent("c46c55",.13),melee_warning,Vector3.ZERO)
	mesh_part(ring(area.top_radius-.035,area.top_radius),transparent("e5a273",.8),melee_warning,Vector3(0,.012,0))
	for i in 12:
		var a := i*TAU/12
		var mark := mesh_part(box(Vector3(.045,.02,.18)),mat("edc392",.3),melee_warning,Vector3(sin(a)*(area.top_radius-.14),.02,cos(a)*(area.top_radius-.14)))
		mark.rotation.y = a
	ranged_warning = Node3D.new()
	add_child(ranged_warning)
	var origin := Vector3(.72,.035,1.15)
	for point in target_points:
		var end := Vector3(point.x,.035,point.z)
		var direction := (end-origin).normalized()
		var line := mesh_part(box(Vector3(.09,.008,origin.distance_to(end))),transparent("d3b56d",.35),ranged_warning,(origin+end)*.5)
		line.rotation.y = atan2(direction.x,direction.z)
		for j in 5:
			var mark := mesh_part(box(Vector3(.12,.015,.30)),mat("e8c884",.25),ranged_warning,origin.lerp(end,.24+j*.16))
			mark.rotation.y = line.rotation.y
		mesh_part(ring(.25,.28),transparent("e8c884",.7),ranged_warning,Vector3(point.x,.04,point.z))
	melee_warning.visible = false
	ranged_warning.visible = false

func on_clip_started(name: String) -> void:
	release_index = 0
	contact_fired = false
	if is_instance_valid(melee_warning):melee_warning.visible = false
	if is_instance_valid(ranged_warning):ranged_warning.visible = false
	if is_instance_valid(dummy):dummy.visible = name=="Melee"
	for node in targets:node.visible = name=="Ranged" or not outgoing.is_empty() or not embedded.is_empty()

func command(request: String) -> bool:
	if request=="Reset":
		mode = "Idle"
		reset_health()
		return true
	if hp<=0 and request!="Demo":return false
	if request=="Arrow":
		clear_extra()
		return super.command("Arrow")
	if request=="Defeat":
		mode = "Idle"
		clear_effects()
		return take_damage(hp)
	if request in ["HoldMelee","HoldRanged"]:
		var name := "Melee" if request=="HoldMelee" else "Ranged"
		mode = name
		clear_effects()
		play_clip(name)
		phase = 1.0 if name=="Melee" else .95
		player.stop()
		player.play(name,0)
		player.advance(0)
		player.seek(phase,true)
		update_extra(0)
		paused = true
		return true
	if request not in ["Demo","Idle","Run","Melee","Ranged"]:return false
	paused = false
	clear_effects()
	mode = request
	if mode=="Demo":
		reset_health()
		demo_step = 0
		demo_time = 0
	play_clip("Idle" if mode=="Demo" else mode)
	return true

func take_damage(amount: int) -> bool:
	clear_extra()
	return super.take_damage(amount)

func advance_demo(dt: float) -> void:
	demo_time += dt
	var sequence := [["Idle",1.8],["Melee",4.4],["Ranged",5.0],["Run",2.4],["Hit",1.3],["Idle",1.0]]
	if demo_time<float(sequence[demo_step][1]):return
	demo_time = 0
	demo_step = (demo_step+1)%sequence.size()
	if demo_step==0:reset_health()
	if sequence[demo_step][0]=="Hit":
		shoot_arrow()
		play_clip("Idle")
	else:play_clip(sequence[demo_step][0])

func advance_simulation(dt: float) -> void:
	super.advance_simulation(dt)
	if not active or paused:return
	if clip in ["Melee","Ranged"] and phase>=float(metadata.clips[clip]):play_clip("Idle")
	elif mode in ["Melee","Ranged"] and clip=="Idle" and phase>=.9:play_clip(mode)

func update_run_motion(_dt: float) -> void:
	# A short practice lap, matched to the heavy baked gait, without teleporting at a loop seam.
	var a := phase/2.4*TAU
	actor.position = Vector3(cos(a)*.22-.22,0,sin(a)*.22)

func launch_volley(at: float) -> void:
	var point := sample_socket("muzzle","Ranged",at)
	volleys += 1
	for i in target_points.size():
		var aim := (target_points[i]-point).normalized()
		var thorn := Node3D.new()
		add_child(thorn)
		thorn.position = point
		thorn.look_at(point+aim,Vector3.UP,true)
		var shaft := CylinderMesh.new()
		shaft.top_radius = .025
		shaft.bottom_radius = .035
		shaft.height = .60
		shaft.radial_segments = 7
		mesh_part(shaft,mat("a38a58"),thorn,Vector3.ZERO).rotation.x = PI/2
		var tip := CylinderMesh.new()
		tip.top_radius = 0
		tip.bottom_radius = .09
		tip.height = .25
		tip.radial_segments = 6
		mesh_part(tip,mat("d8be7c",.3),thorn,Vector3(0,0,.40)).rotation.x = PI/2
		for side in [-1,1]:
			var fin := mesh_part(box(Vector3(.12,.025,.18)),mat("647b52"),thorn,Vector3(side*.05,0,-.20))
			fin.rotation.y = side*.5
		outgoing.append({"node":thorn,"direction":aim,"age":0.0})
		thorn_shots += 1

func update_extra(dt: float) -> void:
	melee_warning.visible = clip=="Melee" and phase>=float(metadata.melee.warningStart) and phase<float(metadata.melee.contact)
	ranged_warning.visible = clip=="Ranged" and phase>=float(metadata.ranged.warningStart) and phase<=float(metadata.ranged.releases[-1])+.10
	if clip=="Melee" and not contact_fired and phase>=float(metadata.melee.contact):
		contact_fired = true
		var point := sample_socket("knuckle","Melee",float(metadata.melee.contact))
		chips(point,14)
		var wave := mesh_part(ring(.93,1.0),transparent("e6b47f",.8),self,Vector3(point.x,.055,point.z))
		waves.append({"node":wave,"age":0.0,"duration":float(metadata.melee.waveDuration),"hit":false})
	if clip=="Ranged":
		while release_index<metadata.ranged.releases.size() and phase>=float(metadata.ranged.releases[release_index]):
			launch_volley(float(metadata.ranged.releases[release_index]))
			release_index += 1
	for i in range(waves.size()-1,-1,-1):
		var wave := waves[i]
		wave.age += dt
		var u: float = clampf(wave.age/wave.duration,0,1)
		var radius := float(metadata.melee.radius)*u
		wave.node.scale = Vector3.ONE*maxf(.01,radius)
		wave.node.material_override.albedo_color.a = .8*(1-u)
		var horizontal := Vector2(dummy.position.x-wave.node.position.x,dummy.position.z-wave.node.position.z).length()
		if not wave.hit and horizontal<=radius:
			wave.hit = true
			slam_hits += 1
			contacts += 1
			close_damage += int(metadata.melee.damage)
			dummy_flash = .20
			chips(dummy.position+Vector3.UP*1.15,6)
			number(str(int(metadata.melee.damage)),dummy.position+Vector3.UP*1.7,Color("f3bc9d"))
		if wave.age>=wave.duration:
			wave.node.queue_free()
			waves.remove_at(i)
	for i in range(outgoing.size()-1,-1,-1):
		var item := outgoing[i]
		var direction: Vector3 = item.direction
		var previous: Vector3 = item.node.position+direction*.52
		item.node.position += direction*float(metadata.ranged.speed)*dt
		item.age += dt
		var end: Vector3 = item.node.position+direction*.52
		var hit_index := -1
		var nearest := INF
		var contact := Vector3.ZERO
		for j in target_points.size():
			var closest := Geometry3D.get_closest_point_to_segment(target_points[j],previous,end)
			if closest.distance_to(target_points[j])<.25 and previous.distance_to(closest)<nearest:
				hit_index = j
				nearest = previous.distance_to(closest)
				contact = closest
		if hit_index>=0:
			thorn_hits += 1
			contacts += 1
			target_damage[hit_index] += int(metadata.ranged.damage)
			target_flash[hit_index] = .2
			item.node.position = contact-direction*.40
			embedded.append(item.node)
			if embedded.size()>18:embedded.pop_front().queue_free()
			chips(contact,4)
			number(str(int(metadata.ranged.damage)),contact+Vector3.UP*.35,Color("ead39e"))
			outgoing.remove_at(i)
		elif item.age>2:
			item.node.queue_free()
			outgoing.remove_at(i)
	for i in 3:
		target_flash[i] = maxf(0,target_flash[i]-dt)
		target_materials[i].emission_energy_multiplier = target_flash[i]*3
	var charge := 0.0
	if clip=="Ranged":charge = smoothstep(.2,1.1,phase)*(1-smoothstep(1.95,3.3,phase))
	elif clip=="Melee":charge = smoothstep(.2,1.4,phase)*(1-smoothstep(1.55,2.7,phase))*.6
	var life := 1.0-.95*smoothstep(.20,2.5,phase) if hp<=0 else 1.0
	for material in glow_materials:
		material.emission_energy_multiplier = (1.0+charge*1.8+.04*sin(clock*3))*life
		material.albedo_color = Color(life,life,life,1.0)

func clear_extra() -> void:
	for item in outgoing:item.node.queue_free()
	outgoing.clear()
	for wave in waves:wave.node.queue_free()
	waves.clear()
	for node in embedded:node.queue_free()
	embedded.clear()
	if is_instance_valid(melee_warning):melee_warning.visible = false
	if is_instance_valid(ranged_warning):ranged_warning.visible = false

func phase_label() -> String:
	if clip=="Melee":return "THRONEBREAKER · RAISE" if phase<float(metadata.melee.contact) else "THRONEBREAKER · IMPACT" if phase<2.1 else "THRONEBREAKER · RECOVER"
	if clip=="Ranged":return "BRIAR DECREE · CHARGE" if phase<1.2 else "BRIAR DECREE · THREE SALVOS" if phase<2.25 else "BRIAR DECREE · RECOVER"
	if clip=="Run":return "IRONWOOD STRIDE"
	if clip=="Death":return "THE CROWN FALLS SILENT"
	if clip=="Hit":return "AMBER HEART · RECOIL"
	return "SOVEREIGN OF THE OVERGROWTH"

func state() -> Dictionary:
	var result := super.state()
	result.merge({"volleys":volleys,"thornShots":thorn_shots,"thornHits":thorn_hits,"slamHits":slam_hits,"closeDamage":close_damage,"targetDamage":target_damage,"outgoing":outgoing.size(),"waves":waves.size(),"meleeWarning":melee_warning.visible,"rangedWarning":ranged_warning.visible,"bones":skeleton.get_bone_count()},true)
	return result
