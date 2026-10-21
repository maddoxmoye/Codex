extends "res://boss_motion.gd"
## Different attack geometry, movement and timing for each guardian.
const BROOD := preload("res://assets/broodling.glb")
var melee_index := 0
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
var giant_bursts := 0
var return_hits := 0
var beam_ticks := 0
var beam_cooldowns: Array[float] = []
var beam: Node3D
var beam_body: MeshInstance3D
var beam_core: MeshInstance3D
var beam_active := false
var prison: Node3D
var beam_material: StandardMaterial3D
func setup_attack_target() -> void:
	melee_center = Vector3(-.55,.035,1.35)
	if study_id=="hollow-monarch":melee_center = Vector3(0,.035,0)
	dummy = make_dummy(Vector3(-1.95 if study_id=="frost-oracle" else -.55,0,2.65),true)
	dummy_material = target_materials.pop_back()
	contact_height = 1.15
	target_flash.clear()
	target_damage.clear()
	var count: int = metadata.ranged.targetPosts
	for i in count:
		var point := Vector3(.70+(i-(count-1)*.5)*1.0,0,6.0)
		targets.append(make_dummy(point))
		target_points.append(point+Vector3.UP*1.15)
		target_flash.append(0)
		target_damage.append(0)


func setup_extras() -> void:
	melee_warning = Node3D.new()
	add_child(melee_warning)
	if study_id=="frost-oracle":
		melee_center = Vector3(-.55,.035,2.65)
		# The missing sector is the escape route; no complete King-style shockwave.
		for i in 10:
			var a := .7+i*(TAU-1.4)/9
			mesh_part(ring(.19,.23),transparent("9ddfed",.65),melee_warning,melee_center+Vector3(sin(a)*1.45,0,cos(a)*1.45))
		mesh_part(box(Vector3(.10,.012,2.5)),transparent("bdebf0",.5),melee_warning,melee_center+Vector3(0,0,-.25))
	else:
		mesh_part(box(Vector3(1.7 if study_id=="hollow-monarch" else 2.1,.012,4.5)),transparent(str(metadata.color),.22),melee_warning,Vector3(0,.045,2.25))
		for x in [-1,1]:mesh_part(box(Vector3(.06,.015,4.5)),transparent(str(metadata.color),.8),melee_warning,Vector3(x*(.85 if study_id=="hollow-monarch" else 1.05),.06,2.25))
	ranged_warning = Node3D.new()
	add_child(ranged_warning)
	if study_id=="frost-oracle":
		mesh_part(box(Vector3(1.9,.012,5.8)),transparent("9ddfed",.20),ranged_warning,Vector3(.7,.04,3.1))
		mesh_part(ring(2.14,2.2),transparent("9ddfed",.6),ranged_warning,Vector3(.7,.05,6))
	elif study_id=="hollow-monarch":
		for i in 26:
			var a := i*TAU/26
			mesh_part(box(Vector3(.20,.012,.20)),transparent("bf9ce5",.55),ranged_warning,Vector3(.7+sin(a)*2.5,.04,3.6-cos(a)*2.7))
	else:
		for side in [-1,1]:
			var lane := mesh_part(box(Vector3(.06,.012,7)),transparent("efbb6c",.7),ranged_warning,Vector3(.7+side*2.1,.04,3.8))
			lane.rotation.y = side*.60
		for i in 10:mesh_part(ring(.11,.15),transparent("efbb6c",.55),ranged_warning,Vector3(-2.8+i*.78,.04,6))
	beam = Node3D.new()
	add_child(beam)
	beam_material = transparent("f7b75a",.65)
	beam_material.emission_enabled = true
	beam_material.emission = Color("ffc16c")
	beam_material.emission_energy_multiplier = 2
	beam_body = mesh_part(box(Vector3(.76,.76,1)),beam_material,beam,Vector3.ZERO)
	beam_core = mesh_part(box(Vector3(.18,.18,1)),mat("fff1bf",2),beam,Vector3.ZERO)
	beam.visible = false
	for i in target_points.size():beam_cooldowns.append(0)
	summon_warning = Node3D.new()
	add_child(summon_warning)
	for i in 6:mesh_part(ring(.23,.27),transparent("eab773",.7),summon_warning,Vector3((i%2*2-1)*(1.0+(i/2)*.25),.045,2.1+(i/2)*.30))
	melee_warning.visible = false
	ranged_warning.visible = false
	summon_warning.visible = false

func on_clip_started(name: String) -> void:
	super.on_clip_started(name)
	melee_index = 0
	summon_index = 0
	if is_instance_valid(summon_warning):summon_warning.visible = false
	if is_instance_valid(beam):beam.visible = false
	beam_active = false
	for i in beam_cooldowns.size():beam_cooldowns[i] = 0
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
	if metadata.has("summon"):sequence = [["Idle",1.6],["Summon",8.5],["Ranged",5.5],["Melee",4.5],["Idle",1.2]]
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


func launch_volley(at: float) -> void:
	volleys += 1
	if study_id=="gilded-colossus":
		beam_active = true
		return
	var point := sample_socket("muzzle","Ranged",at)
	var node := Node3D.new()
	add_child(node)
	node.position = point
	if study_id=="frost-oracle":
		var shell := mesh_part(sphere(.95),transparent("78c9e7",.68),node,Vector3.ZERO)
		mesh_part(sphere(.48),mat("ddf6fa",1.0),node,Vector3.ZERO)
		for i in 8:
			var a := i*TAU/8
			var spike := CylinderMesh.new()
			spike.top_radius = 0
			spike.bottom_radius = .18
			spike.height = .65
			mesh_part(spike,mat("b7e8f7",.3),node,Vector3(sin(a)*.8,cos(a)*.8,0)).rotation.z = -a
		outgoing.append({"node":node,"age":0.0,"style":"avalanche","direction":(target_points[target_points.size()/2]-point).normalized(),"trail":0.0})
	else:
		mesh_part(ring(.66,.91),mat("b18ccf",.8),node,Vector3.ZERO).rotation.x = PI/2
		mesh_part(box(Vector3(.09,.09,2.1)),mat("dce3ec",.6),node,Vector3.ZERO)
		for side in [-1,1]:
			var blade := PrismMesh.new()
			blade.size = Vector3(.8,.13,.8)
			mesh_part(blade,mat("e3c5f2",.8),node,Vector3(side*.37,0,side*.65)).rotation.y = side*.9
		outgoing.append({"node":node,"age":0.0,"style":"boomerang","start":point,"outHit":[],"backHit":[]})
	thorn_shots += 1

func close_hit(amount: int, point: Vector3) -> void:
	slam_hits += 1
	contacts += 1
	close_damage += amount
	dummy_flash = .2
	number(str(amount),point+Vector3.UP*1.55,Color(str(metadata.color)))

func start_melee_event(index: int) -> void:
	melee_events += 1
	var damage := int(float(metadata.melee.damage)*float(metadata.melee.multipliers[index]))
	if study_id=="frost-oracle":
		var group := Node3D.new()
		add_child(group)
		group.position = melee_center
		var crystal := CylinderMesh.new()
		crystal.top_radius = 0
		crystal.bottom_radius = .22 if index==0 else .45
		crystal.height = 2.6 if index==0 else 2.4
		crystal.radial_segments = 5
		if index==0:
			for i in 10:
				var a := .7+i*(TAU-1.4)/9
				mesh_part(crystal,mat("6aabc9"),group,Vector3(sin(a)*1.45,1.3,cos(a)*1.45))
		else:
			for i in 5:mesh_part(crystal,mat("9dd9ed",.1),group,Vector3((i-2)*.38,1.1,0))
		hazards.append({"node":group,"age":0.0,"kind":"prison","duration":1.5 if index==0 else 1.0})
		var offset := dummy.position-melee_center
		var angle := fposmod(atan2(offset.x,offset.z),TAU)
		if index==0 and offset.length()>1.1 and offset.length()<1.8 and angle>.7 and angle<TAU-.7:close_hit(damage,dummy.position)
		elif index==1 and offset.length()<2.1:close_hit(damage,dummy.position)
	elif study_id=="hollow-monarch":
		var arc := mesh_part(ring(.95,1.15),transparent("c9a5ef",.8),self,actor.position+Vector3(0,1.4,.35))
		arc.rotation.z = .5 if index==0 else -.5
		effects.append({"node":arc,"life":.38,"duration":.38,"velocity":Vector3.ZERO,"label":false})
		if Vector2(dummy.position.x-actor.position.x,dummy.position.z-actor.position.z).length()<1.8:close_hit(damage,dummy.position)
	else:
		if index==0:
			if absf(dummy.position.x)<1.05 and dummy.position.z<4.5:close_hit(damage,dummy.position)
		else:
			for i in 8:
				var rock := mesh_part(box(Vector3(.35,.25,.38)),mat("bc8956",.2),self,Vector3((i%2*2-1)*.65,.15,1+i*.38))
				effects.append({"node":rock,"life":.9,"duration":.9,"velocity":Vector3(0,.65,0),"label":false})
			if absf(dummy.position.x)<.95:close_hit(damage,dummy.position)

func update_extra(dt: float) -> void:
	melee_warning.visible = clip=="Melee" and phase>=.08 and phase<float(metadata.melee.events[0])
	ranged_warning.visible = clip=="Ranged" and phase>=.1 and phase<float(metadata.ranged.releases[0])
	summon_warning.visible = clip=="Summon" and phase>=.15 and phase<2.0
	if clip=="Melee":
		if study_id=="hollow-monarch":
			actor.position = Vector3(-.55*smoothstep(.7,1.1,phase)*(1-smoothstep(2.25,3.5,phase)),0,2.5*smoothstep(.7,1.1,phase)*(1-smoothstep(2.25,3.5,phase)))
		elif study_id=="gilded-colossus":actor.position = Vector3(0,0,3.2*smoothstep(.8,1.45,phase)*(1-smoothstep(2.3,3.55,phase)))
		while melee_index<metadata.melee.events.size() and phase>=float(metadata.melee.events[melee_index]):
			start_melee_event(melee_index)
			melee_index += 1
	if clip=="Ranged":
		while release_index<metadata.ranged.releases.size() and phase>=float(metadata.ranged.releases[release_index]):
			launch_volley(float(metadata.ranged.releases[release_index]))
			release_index += 1
	if clip=="Summon":
		while summon_index<metadata.summon.releases.size() and phase>=float(metadata.summon.releases[summon_index]):
			for i in int(metadata.summon.perRelease):spawn_minion(float(metadata.summon.releases[summon_index]))
			summon_index += 1
	update_bolts(dt)
	update_beam(dt)
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

func target_hit(index: int, damage: int, point: Vector3) -> void:
	thorn_hits += 1
	contacts += 1
	target_damage[index] += damage
	target_flash[index] = .2
	number(str(damage),point+Vector3.UP*.3,Color(str(metadata.color)))

func burst_heart(item: Dictionary) -> void:
	giant_bursts += 1
	var point: Vector3 = item.node.position
	for j in target_points.size():
		var distance := point.distance_to(target_points[j])
		if distance<float(metadata.ranged.blastRadius):target_hit(j,int(metadata.ranged.damage) if distance<1.2 else int(metadata.ranged.damage)/2,target_points[j])
	for i in 8:
		var direction := Vector3(sin(i*TAU/8),0,cos(i*TAU/8))
		var shard := PrismMesh.new()
		shard.size = Vector3(.22,.22,.75)
		var node := mesh_part(shard,mat("bcecf8",.6),self,point+direction*1.05)
		node.look_at(node.position+direction,Vector3.UP,true)
		outgoing.append({"node":node,"style":"fragment","age":0.0,"direction":direction,"hit":[]})
		thorn_shots += 1
	var flash := mesh_part(sphere(1),transparent("b7e9f5",.28),self,point)
	flash.scale = Vector3.ONE*float(metadata.ranged.blastRadius)
	effects.append({"node":flash,"life":.35,"duration":.35,"velocity":Vector3.ZERO,"label":false})
	chips(point,12,true)

func update_bolts(dt: float) -> void:
	for i in range(outgoing.size()-1,-1,-1):
		var item := outgoing[i]
		var previous: Vector3 = item.node.position
		item.age += dt
		if item.style=="avalanche":
			item.node.position += item.direction*float(metadata.ranged.speed)*dt
			item.node.rotation.z += dt*1.8
			item.trail += dt
			if item.trail>.16:
				item.trail = 0
				var patch := mesh_part(ring(.55,.72),transparent("9bdde9",.48),self,Vector3(item.node.position.x,.04,item.node.position.z))
				hazards.append({"node":patch,"age":0.0})
			if item.node.position.z>=5.6:
				burst_heart(item)
				item.node.queue_free()
				outgoing.remove_at(i)
		elif item.style=="fragment":
			item.node.position += item.direction*5.5*dt
			for j in target_points.size():
				if j not in item.hit and Geometry3D.get_closest_point_to_segment(target_points[j],previous,item.node.position).distance_to(target_points[j])<.40:
					item.hit.append(j)
					target_hit(j,int(metadata.ranged.shardDamage),target_points[j])
			if item.age>1.1:
				item.node.queue_free()
				outgoing.remove_at(i)
		else:
			var u: float = clampf(item.age/float(metadata.ranged.flightDuration),0,1)
			# Outward left lane and return right lane form a closed loop; no homing.
			item.node.position = Vector3(.7-sin(u*TAU)*2.5,1.15,3.6-cos(u*TAU)*2.7)
			item.node.rotation.y += dt*15
			var struck: Array = item.outHit if u<.5 else item.backHit
			for j in target_points.size():
				if j not in struck and Geometry3D.get_closest_point_to_segment(target_points[j],previous,item.node.position).distance_to(target_points[j])<float(metadata.ranged.radius)+.18:
					struck.append(j)
					target_hit(j,int(metadata.ranged.damage) if u<.5 else int(metadata.ranged.returnDamage),target_points[j])
					if u>=.5:return_hits += 1
			if u>=1:
				item.node.queue_free()
				outgoing.remove_at(i)

func update_beam(dt: float) -> void:
	if not is_instance_valid(beam):return
	beam.visible = beam_active and clip=="Ranged" and phase<float(metadata.ranged.get("releases",[1.05])[0])+float(metadata.ranged.get("duration",1.9))
	if not beam.visible:return
	var u := clampf((phase-float(metadata.ranged.releases[0]))/float(metadata.ranged.duration),0,1)
	var angle := lerpf(-float(metadata.ranged.sweepAngle),float(metadata.ranged.sweepAngle),u)
	var start := socket("muzzle")
	var end := Vector3(.7+sin(angle)*7.2,1.15,cos(angle)*7.2)
	var length := start.distance_to(end)
	beam.position = (start+end)*.5
	beam.look_at(end,Vector3.UP,true)
	beam_body.scale.z = length
	beam_core.scale.z = length
	beam_body.scale.x = 1+.08*sin(phase*40)
	for j in target_points.size():
		beam_cooldowns[j] = maxf(0,beam_cooldowns[j]-dt)
		if beam_cooldowns[j]<=0 and Geometry3D.get_closest_point_to_segment(target_points[j],start,end).distance_to(target_points[j])<float(metadata.ranged.halfWidth)+.28:
			beam_cooldowns[j] = float(metadata.ranged.tickInterval)
			beam_ticks += 1
			target_hit(j,int(metadata.ranged.damage),target_points[j])

func update_hazards(dt: float) -> void:
	for i in range(hazards.size()-1,-1,-1):
		hazards[i].age += dt
		var duration: float = hazards[i].get("duration",1.4)
		if hazards[i].get("kind","")=="prison":hazards[i].node.scale.y = smoothstep(0,.14,hazards[i].age)*(1-smoothstep(duration-.25,duration,hazards[i].age))
		if hazards[i].age>duration:
			hazards[i].node.queue_free()
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
	if clip=="Melee":return str(metadata.melee.name).to_upper()+(" · TELEGRAPH" if phase<float(metadata.melee.events[0]) else " · ERUPTION" if study_id=="frost-oracle" else " · LUNGING COMBO" if study_id=="hollow-monarch" else " · CHARGE / RUPTURE")
	if clip=="Ranged":return str(metadata.ranged.name).to_upper()+(" · CHARGE" if phase<float(metadata.ranged.releases[0]) else " · GIANT ICE HEART" if study_id=="frost-oracle" else " · OUTWARD / RETURN" if study_id=="hollow-monarch" else " · SWEEPING BEAM")
	if clip=="Summon":return "BROOD FURNACE · "+("OPENING HATCH" if phase<1.1 else "ENEMIES EMERGING" if phase<2.7 else "SEALING THE FOUNDRY")
	if clip=="Death":return "THE GUARDIAN FALLS SILENT"
	if clip=="Hit":return "CORE · RECOIL"
	return str(metadata.subtitle).to_upper()

func state() -> Dictionary:
	var result := super.state()
	result.merge({"meleeEvents":melee_events,"hazardHits":hazard_hits,"splits":split_events,"hazards":hazards.size(),"giantBursts":giant_bursts,"returnHits":return_hits,"beamTicks":beam_ticks,"beamActive":beam.visible,"summonWarning":is_instance_valid(summon_warning) and summon_warning.visible,"summonsAlive":living_minions(),"summonsSpawned":summon_total,"summonHits":summon_hits,"summonKills":summon_kills,"peakSummons":peak_minions},true)
	return result
