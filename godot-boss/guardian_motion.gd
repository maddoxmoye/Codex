extends "res://boss_motion.gd"
## Distinct second/third/final boss patterns. Summons have bounded, stable animation states.
const BROOD := preload("res://assets/broodling.glb")
var melee_index := 0
var warning_index := -1
var hazard_hits := 0
var split_events := 0
var hazards: Array[Dictionary] = []
var summon_warning: Node3D
var summon_index := 0
var minions: Array[Dictionary] = []
var summon_total := 0
var summon_hits := 0
var summon_kills := 0
var peak_minions := 0
var minion_serial := 0
var melee_events := 0

func setup_attack_target() -> void:
	melee_center = Vector3(-.55,.035,1.35)
	if study_id=="hollow-monarch":melee_center = Vector3(0,.035,0)
	dummy = make_dummy(Vector3(-.55,0,2.65),true)
	dummy_material = target_materials.pop_back()
	contact_height = 1.15
	target_flash.clear()
	target_damage.clear()
	var count: int = metadata.ranged.shotsPerVolley
	for i in count:
		var point := Vector3(.70+(i-(count-1)*.5)*1.0,0,6.0)
		targets.append(make_dummy(point))
		target_points.append(point+Vector3.UP*1.15)
		target_flash.append(0)
		target_damage.append(0)

func sector(radius: float, angle: float, span := 1.7, inner := 0.45) -> ArrayMesh:
	var points := PackedVector3Array()
	for i in 32:
		var a := angle-span*.5+span*i/32
		var b := angle-span*.5+span*(i+1)/32
		var p := Vector3(sin(a)*inner,0,cos(a)*inner)
		var q := Vector3(sin(a)*radius,0,cos(a)*radius)
		var r := Vector3(sin(b)*radius,0,cos(b)*radius)
		var z := Vector3(sin(b)*inner,0,cos(b)*inner)
		points.append_array([p,r,q,p,z,r])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func setup_extras() -> void:
	melee_warning = Node3D.new()
	add_child(melee_warning)
	melee_warning.position = melee_center
	if study_id=="hollow-monarch":
		mesh_part(sector(float(metadata.melee.radius),-.45),transparent("bf9ce5",.18),melee_warning,Vector3(0,.02,0))
	else:
		var area := CylinderMesh.new()
		area.top_radius = float(metadata.melee.radius)
		area.bottom_radius = area.top_radius
		area.height = .006
		area.radial_segments = 48
		mesh_part(area,transparent(str(metadata.color),.13),melee_warning,Vector3.ZERO)
	mesh_part(ring(float(metadata.melee.radius)-.035,float(metadata.melee.radius)),transparent(str(metadata.color),.75),melee_warning,Vector3(0,.012,0))
	ranged_warning = Node3D.new()
	add_child(ranged_warning)
	var origin := Vector3(.76,.035,1.1)
	for point in target_points:
		var end := Vector3(point.x,.035,point.z)
		var direction := (end-origin).normalized()
		var lane := mesh_part(box(Vector3(.10,.012,origin.distance_to(end))),transparent(str(metadata.color),.35),ranged_warning,(origin+end)*.5)
		lane.rotation.y = atan2(direction.x,direction.z)
		mesh_part(ring(.27,.30),transparent(str(metadata.color),.7),ranged_warning,end)
		if study_id=="hollow-monarch":
			for side in [-1,1]:
				var fork := mesh_part(box(Vector3(.035,.016,1.15)),transparent("c7afe6",.65),ranged_warning,end-direction*.58+Vector3(side*.10,.01,0))
				fork.rotation.y = lane.rotation.y+side*.065
	summon_warning = Node3D.new()
	add_child(summon_warning)
	for i in 6:
		var point := Vector3((i%2*2-1)*(1.0+(i/2)*.25),.045,2.1+(i/2)*.30)
		mesh_part(ring(.23,.27),transparent("eab773",.7),summon_warning,point)
	melee_warning.visible = false
	ranged_warning.visible = false
	summon_warning.visible = false

func on_clip_started(name: String) -> void:
	super.on_clip_started(name)
	melee_index = 0
	warning_index = -1
	summon_index = 0
	if is_instance_valid(summon_warning):summon_warning.visible = false
	if name=="Summon":
		for target in targets:target.visible = true

func command(request: String) -> bool:
	if request in ["Reset","Demo"]:clear_minions()
	if request=="BroodHit":
		for minion in minions:
			if minion.hp>0:
				hit_minion(minion,30)
				return true
		return false
	if request in ["Summon","HoldSummon"]:
		if not metadata.has("summon") or hp<=0:return false
		clear_effects()
		mode = "Summon"
		play_clip("Summon")
		paused = request=="HoldSummon"
		if paused:
			phase = .90
			player.stop()
			player.play("Summon",0)
			player.advance(0)
			player.seek(phase,true)
			update_extra(0)
		return true
	return super.command(request)

func take_damage(amount: int) -> bool:
	if amount>=hp:
		for minion in minions:
			if minion.hp>0:hit_minion(minion,int(minion.hp))
	return super.take_damage(amount)

func advance_demo(dt: float) -> void:
	demo_time += dt
	var sequence := [["Idle",1.6],["Melee",4.5],["Ranged",5.2],["Run",2.4],["Idle",1.1]]
	if metadata.has("summon"):sequence = [["Idle",1.6],["Melee",4.5],["Ranged",5.0],["Summon",8.5],["Idle",1.2]]
	if demo_time<float(sequence[demo_step][1]):return
	demo_time = 0
	demo_step = (demo_step+1)%sequence.size()
	if demo_step==0:
		clear_minions()
		reset_health()
	play_clip(sequence[demo_step][0])

func advance_simulation(dt: float) -> void:
	super.advance_simulation(dt)
	if not active or paused:return
	if clip=="Summon" and phase>=float(metadata.clips.Summon):play_clip("Idle")
	elif mode=="Summon" and clip=="Idle" and phase>.9:play_clip("Summon")

func make_bolt(style: String) -> Node3D:
	var node := Node3D.new()
	var color := str(metadata.color)
	if style=="void_orb":
		mesh_part(sphere(.16),mat("6c548f",.5),node,Vector3.ZERO)
		for side in [-1,1]:mesh_part(sphere(.027),mat("dfc5ff",.8),node,Vector3(side*.065,.035,.14))
	else:
		var shard := PrismMesh.new()
		shard.size = Vector3(.11,.11,.67 if style!="solar" else .85)
		mesh_part(shard,mat(color,.65),node,Vector3.ZERO)
		var tip := CylinderMesh.new()
		tip.top_radius = 0
		tip.bottom_radius = .065
		tip.height = .20
		tip.radial_segments = 5
		mesh_part(tip,mat("dbe9f2" if style=="ice" else color,.6),node,Vector3(0,0,.40)).rotation.x = PI/2
		if style=="solar":
			for side in [-1,1]:mesh_part(box(Vector3(.20,.018,.08)),mat("e3c16c",.4),node,Vector3(side*.07,0,-.2))
	return node

func emit_bolt(point: Vector3, direction: Vector3, style: String, split := false) -> void:
	var node := make_bolt(style)
	add_child(node)
	node.position = point
	node.look_at(point+direction,Vector3.UP,true)
	outgoing.append({"node":node,"direction":direction,"age":0.0,"style":style,"split":split})
	thorn_shots += 1

func launch_volley(at: float) -> void:
	var point := sample_socket("muzzle","Ranged",at)
	volleys += 1
	var style: String = metadata.ranged.style
	for target in target_points:
		emit_bolt(point,(target-point).normalized(),"void_orb" if style=="void" else style,style=="void")

func start_melee_event(index: int) -> void:
	melee_events += 1
	var pattern: String = metadata.melee.pattern
	var point := melee_center
	var radius: float = metadata.melee.radius
	var damage := int(float(metadata.melee.damage)*float(metadata.melee.multipliers[index]))
	var mesh: Mesh = ring(.94,1.0)
	var angle := -.45 if index==0 else .45
	if pattern=="sweep":mesh = sector(radius,angle)
	var node := mesh_part(mesh,transparent(str(metadata.color),.8),self,point+Vector3.UP*.035)
	waves.append({"node":node,"age":0.0,"duration":float(metadata.melee.waveDuration),"hit":false,"damage":damage,"pattern":pattern,"angle":angle})
	if index==0:chips(point+Vector3.UP*.15,12,pattern=="frost")
	# Crystal/metal fragments give the aftershock a distinct silhouette, without persistent collision objects.
	for i in 8:
		var a := i*TAU/8
		var shard := mesh_part(sphere(.07) if pattern=="frost" else box(Vector3(.08,.14,.08)),mat(str(metadata.color),.2),self,point+Vector3(sin(a)*.5,.15,cos(a)*.5))
		effects.append({"node":shard,"life":.65,"duration":.65,"velocity":Vector3(sin(a)*1.2,.8,cos(a)*1.2),"label":false})

func update_extra(dt: float) -> void:
	melee_warning.visible = clip=="Melee" and phase>=float(metadata.melee.warningStart) and phase<float(metadata.melee.events[-1])
	ranged_warning.visible = clip=="Ranged" and phase>=float(metadata.ranged.warningStart) and phase<float(metadata.ranged.releases[-1])+.1
	summon_warning.visible = clip=="Summon" and phase>=.15 and phase<2.0
	if clip=="Melee":
		while melee_index<metadata.melee.events.size() and phase>=float(metadata.melee.events[melee_index]):
			start_melee_event(melee_index)
			melee_index += 1
		if study_id=="hollow-monarch" and warning_index!=melee_index:
			warning_index = melee_index
			melee_warning.get_child(0).mesh = sector(float(metadata.melee.radius),-.45 if melee_index==0 else .45)
	if clip=="Ranged":
		while release_index<metadata.ranged.releases.size() and phase>=float(metadata.ranged.releases[release_index]):
			launch_volley(float(metadata.ranged.releases[release_index]))
			release_index += 1
	if clip=="Summon":
		while summon_index<metadata.summon.releases.size() and phase>=float(metadata.summon.releases[summon_index]):
			for i in int(metadata.summon.perRelease):spawn_minion(float(metadata.summon.releases[summon_index]))
			summon_index += 1
	update_waves(dt)
	update_bolts(dt)
	update_hazards(dt)
	update_minions(dt)
	for i in target_flash.size():
		target_flash[i] = maxf(0,target_flash[i]-dt)
		target_materials[i].emission_energy_multiplier = target_flash[i]*3
	var charge := smoothstep(.1,.9,phase)*(1-smoothstep(2,3.3,phase)) if clip in ["Ranged","Melee","Summon"] else 0.0
	var life := 1.0-.95*smoothstep(.2,2.5,phase) if hp<=0 else 1.0
	for material in glow_materials:
		material.emission_energy_multiplier = (1+charge*1.8)*life
		material.albedo_color = Color(life,life,life,1)
	if not minions.is_empty():
		for target in targets:target.visible = true

func update_waves(dt: float) -> void:
	for i in range(waves.size()-1,-1,-1):
		var wave := waves[i]
		wave.age += dt
		var u: float = clampf(wave.age/wave.duration,0,1)
		var radius := float(metadata.melee.radius)*u
		wave.node.scale = Vector3.ONE if wave.pattern=="sweep" else Vector3.ONE*maxf(.01,radius)
		wave.node.material_override.albedo_color.a = .8*(1-u)
		var delta: Vector3 = dummy.position-wave.node.position
		var distance := Vector2(delta.x,delta.z).length()
		var eligible := distance<=radius
		if wave.pattern=="sweep":eligible = distance<float(metadata.melee.radius) and absf(angle_difference(atan2(delta.x,delta.z),wave.angle))<.85
		if not wave.hit and eligible:
			wave.hit = true
			slam_hits += 1
			contacts += 1
			close_damage += int(wave.damage)
			dummy_flash = .2
			number(str(wave.damage),dummy.position+Vector3.UP*1.65,Color(str(metadata.color)))
		if wave.age>=wave.duration:
			wave.node.queue_free()
			waves.remove_at(i)

func update_bolts(dt: float) -> void:
	for i in range(outgoing.size()-1,-1,-1):
		var item := outgoing[i]
		var direction: Vector3 = item.direction
		var previous: Vector3 = item.node.position+direction*.45
		item.node.position += direction*float(metadata.ranged.speed)*dt
		item.age += dt
		if item.split and item.age>=float(metadata.ranged.splitAt):
			for side in [-1,1]:emit_bolt(item.node.position,direction.rotated(Vector3.UP,side*float(metadata.ranged.splitAngle)),"void_shard")
			split_events += 1
			item.node.queue_free()
			outgoing.remove_at(i)
			continue
		var end: Vector3 = item.node.position+direction*.45
		var hit := -1
		var nearest := INF
		var contact := Vector3.ZERO
		for j in target_points.size():
			var point := Geometry3D.get_closest_point_to_segment(target_points[j],previous,end)
			if point.distance_to(target_points[j])<.31 and previous.distance_to(point)<nearest:
				hit = j
				nearest = previous.distance_to(point)
				contact = point
		if hit>=0:
			thorn_hits += 1
			contacts += 1
			target_damage[hit] += int(metadata.ranged.damage)
			target_flash[hit] = .20
			number(str(int(metadata.ranged.damage)),contact+Vector3.UP*.35,Color(str(metadata.color)))
			item.node.position = contact-direction*.35
			embedded.append(item.node)
			if embedded.size()>24:embedded.pop_front().queue_free()
			if item.style=="ice":
				var patch := mesh_part(ring(.35,.42),transparent("9edce9",.6),self,Vector3(target_points[hit].x,.045,target_points[hit].z))
				hazards.append({"node":patch,"age":0.0,"target":hit,"hit":false})
			outgoing.remove_at(i)
		elif item.age>2:
			item.node.queue_free()
			outgoing.remove_at(i)

func update_hazards(dt: float) -> void:
	for i in range(hazards.size()-1,-1,-1):
		var hazard := hazards[i]
		hazard.age += dt
		if not hazard.hit and hazard.age>=float(metadata.ranged.hazardDelay):
			hazard.hit = true
			hazard_hits += 1
			target_damage[int(hazard.target)] += int(metadata.ranged.hazardDamage)
			number(str(int(metadata.ranged.hazardDamage)),target_points[int(hazard.target)]+Vector3.UP*.15,Color("bce8f0"))
		if hazard.age>=float(metadata.ranged.hazardDuration):
			hazard.node.queue_free()
			hazards.remove_at(i)

func living_minions() -> int:
	var count := 0
	for minion in minions:
		if minion.hp>0:count += 1
	return count

func spawn_minion(at: float) -> void:
	if living_minions()>=int(metadata.summon.maxAlive):return
	# Fixed emergence/landing slots stop arrivals from competing for a moving threshold.
	var slot := 0
	var occupied: Array[int] = []
	for minion in minions:
		if minion.hp>0:occupied.append(int(minion.slot))
	while slot in occupied:slot += 1
	var node: Node3D = BROOD.instantiate()
	add_child(node)
	node.scale = Vector3.ONE*.65
	var spawn := sample_socket("hatch","Summon",at)
	node.position = spawn
	var animation: AnimationPlayer = node.find_children("*","AnimationPlayer",true,false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name in animation.get_animation_list():animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR if name in ["Idle","Run"] else Animation.LOOP_NONE
	animation.play("Idle",0)
	animation.advance(0)
	var target_index: int = [1,3,5][slot/2]
	var goal := target_points[target_index]-Vector3(0,1.15,.32)+Vector3((slot%2*2-1)*.22,0,0)
	var landing := Vector3((slot%2*2-1)*(1.0+(slot/2)*.25),0,2.1+(slot/2)*.30)
	var bar := Node3D.new()
	node.add_child(bar)
	bar.position.y = 1.65
	mesh_part(box(Vector3(.54,.075,.025)),mat("243b31"),bar,Vector3.ZERO)
	var fill := mesh_part(box(Vector3(.49,.035,.03)),mat("d9ba72"),bar,Vector3(0,0,.02))
	var materials: Array[ShaderMaterial] = []
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin:continue
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and not original.emission_enabled:
				var hit_mat := ShaderMaterial.new()
				hit_mat.shader = tint_shader
				hit_mat.set_shader_parameter("palette_tex",original.albedo_texture)
				mesh.set_surface_override_material(i,hit_mat)
				materials.append(hit_mat)
	minions.append({"node":node,"player":animation,"hp":int(metadata.summon.health),"slot":slot,"state":"Air","time":0.0,"clip":"Idle","clipTime":0.0,"event":false,"start":spawn,"landing":landing,"goal":goal,"target":target_index,"anchor":landing,"bar":bar,"fill":fill,"flash":0.0,"materials":materials})
	minion_serial += 1
	summon_total += 1
	peak_minions = maxi(peak_minions,living_minions())

func minion_clip(minion: Dictionary, name: String) -> void:
	minion.clip = name
	minion.clipTime = 0
	minion.event = false
	minion.player.stop()
	minion.player.play(name,0)
	minion.player.advance(0)

func hit_minion(minion: Dictionary, damage: int) -> void:
	if minion.hp<=0:return
	minion.hp = maxi(0,int(minion.hp)-damage)
	minion.flash = .12
	number(str(damage),minion.node.position+Vector3.UP*1.05,Color("f0d89b"))
	minion.state = "Dying" if minion.hp<=0 else "Hit"
	minion.time = 0
	minion_clip(minion,"Death" if minion.hp<=0 else "Hit")
	if minion.hp<=0:summon_kills += 1

func update_minions(dt: float) -> void:
	for i in range(minions.size()-1,-1,-1):
		var minion := minions[i]
		minion.time += dt
		minion.clipTime += dt*(2.0 if minion.clip=="Run" else 1.0)
		minion.flash = maxf(0,minion.flash-dt)
		for material in minion.materials:material.set_shader_parameter("hit_flash",minion.flash/.12)
		minion.fill.scale.x = maxf(.01,float(minion.hp)/float(metadata.summon.health))
		match minion.state:
			"Air":
				var u: float = clampf(minion.time/.70,0,1)
				minion.node.position = minion.start.lerp(minion.landing,u)+Vector3.UP*sin(u*PI)*.5
				if u>=1:
					minion.state = "Approach"
					minion_clip(minion,"Run")
			"Approach":
				var delta: Vector3 = minion.goal-minion.node.position
				minion.node.position = minion.node.position.move_toward(minion.goal,dt*.85)
				if delta.length()>.02:minion.node.rotation.y = rotate_toward(minion.node.rotation.y,atan2(delta.x,delta.z),dt*4)
				if minion.node.position.distance_to(minion.goal)<.02:
					minion.state = "Face"
					minion_clip(minion,"Idle")
			"Face":
				var delta: Vector3 = target_points[int(minion.target)]-minion.node.position
				var angle := atan2(delta.x,delta.z)
				minion.node.rotation.y = rotate_toward(minion.node.rotation.y,angle,dt*4)
				if absf(angle_difference(minion.node.rotation.y,angle))<.03:
					minion.state = "Attack"
					minion.anchor = minion.node.position
					minion_clip(minion,"Attack")
			"Attack":
				var lunge := .13*smoothstep(.36,.57,minion.clipTime)*(1-smoothstep(.75,1.14,minion.clipTime))
				minion.node.position = minion.anchor+minion.node.basis.z*lunge
				if not minion.event and minion.clipTime>=float(metadata.summon.contact):
					minion.event = true
					summon_hits += 1
					target_damage[int(minion.target)] += int(metadata.summon.damage)
					target_flash[int(minion.target)] = .2
					number(str(int(metadata.summon.damage)),minion.node.position+Vector3.UP*.85,Color("e8cf96"))
				if minion.clipTime>=float(metadata.summon.attackInterval):minion_clip(minion,"Attack")
			"Hit":
				if minion.clipTime>=.55:
					minion.state = "Approach"
					minion_clip(minion,"Run")
			"Dying":
				if minion.clipTime>=1.45:
					minion.node.queue_free()
					minions.remove_at(i)
					continue
		var animation: Animation = minion.player.get_animation(minion.clip)
		minion.player.seek(fmod(minion.clipTime,animation.length) if minion.clip in ["Idle","Run"] else minf(minion.clipTime,animation.length),true)

func update_view(camera: Camera3D) -> void:
	super.update_view(camera)
	for minion in minions:minion.bar.look_at(camera.global_position,Vector3.UP,true)

func clear_minions() -> void:
	for minion in minions:minion.node.queue_free()
	minions.clear()

func clear_extra() -> void:
	super.clear_extra()
	for hazard in hazards:hazard.node.queue_free()
	hazards.clear()
	if is_instance_valid(summon_warning):summon_warning.visible = false

func phase_label() -> String:
	if clip=="Melee":return str(metadata.melee.name).to_upper()+(" · WINDUP" if phase<float(metadata.melee.events[0]) else " · RETURN SWEEP" if study_id=="hollow-monarch" else " · AFTERSHOCK")
	if clip=="Ranged":return str(metadata.ranged.name).to_upper()+(" · CHARGE" if phase<float(metadata.ranged.releases[0]) else " · SPLITTING ORBS" if study_id=="hollow-monarch" else " · SALVOS")
	if clip=="Summon":return "BROOD FURNACE · "+("OPENING HATCH" if phase<1.1 else "ENEMIES EMERGING" if phase<2.7 else "SEALING THE FOUNDRY")
	if clip=="Death":return "THE GUARDIAN FALLS SILENT"
	if clip=="Hit":return "CORE · RECOIL"
	return str(metadata.subtitle).to_upper()

func state() -> Dictionary:
	var result := super.state()
	result.merge({"meleeEvents":melee_events,"hazardHits":hazard_hits,"splits":split_events,"hazards":hazards.size(),"summonWarning":is_instance_valid(summon_warning) and summon_warning.visible,"summonsAlive":living_minions(),"summonsSpawned":summon_total,"summonHits":summon_hits,"summonKills":summon_kills,"peakSummons":peak_minions},true)
	return result
