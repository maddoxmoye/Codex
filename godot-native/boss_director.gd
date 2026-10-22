extends RefCounted
## Production adaptation of godot-boss/guardian_motion.gd. Authored event markers,
## socket transforms and distinct geometries are retained; campaign supplies scaling.
var game: Node3D
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/guardians.json"))
func setup(target: Node3D) -> void:game=target
func socket(unit: HuntUnit, name: String) -> Vector3:
	var data: Dictionary=definitions[unit.kind].sockets[name]
	var local: Array=data.local
	return unit.socket(data.bone,Vector3(local[0],local[1],local[2]))
func begin(unit: HuntUnit, forced := "") -> void:
	var info: Dictionary=definitions[unit.kind]
	var serial: int=int(unit.extra.get("attacks",0))
	var clip := forced
	if clip=="":
		clip="Melee" if unit.position.distance_to(game.player_unit.position)<4.5 else "Ranged"
		if info.has("summon") and serial%3==0 and brood_count()<6:clip="Summon"
	unit.extra.attacks=serial+1;unit.extra.event=0;unit.extra.beam_tick=0.0
	unit.state="Attack";unit.action_time=0;unit.release_index=0;unit.fired=false;unit.wave_hit=false
	unit.attack_center=game.player_unit.position;unit.charge_start=unit.position
	unit.aim=(unit.attack_center-unit.position).normalized();unit.aim.y=0;unit.rotation.y=atan2(unit.aim.x,unit.aim.z)
	unit.play(clip,true)
	if is_instance_valid(unit.warning):unit.warning.queue_free()
	var radius: float=float(info.melee.radius) if clip=="Melee" else 1.2
	unit.warning=game.warning_ring(radius,str(info.color),.8);unit.warning.position=unit.attack_center+Vector3.UP*.04
	if clip=="Melee" and unit.kind=="briar-king":unit.attack_center=unit.position+Vector3(-.65,0,.94).rotated(Vector3.UP,unit.rotation.y);unit.warning.position=unit.attack_center+Vector3.UP*.04
	if clip=="Melee" and info.melee.get("pattern","") in ["charge","lunge"]:
		unit.warning.queue_free();unit.warning=game.mesh_part(game.box(Vector3(2.1,.025,6)),game.material(info.color,.2,.3),game,unit.position+unit.aim*3+Vector3.UP*.04);unit.warning.rotation.y=unit.rotation.y
	if clip=="Ranged" and info.ranged.get("style","")=="beam":
		unit.warning.queue_free();unit.warning=game.mesh_part(game.box(Vector3(1.2,.025,16)),game.material(info.color,.2,.3),game,unit.position+unit.aim*8+Vector3.UP*.04);unit.warning.rotation.y=unit.rotation.y
func update(unit: HuntUnit, dt: float) -> void:
	var info: Dictionary=definitions[unit.kind]
	var rate := .8 if unit.ice_time>0 else 1.0
	dt*=rate
	unit.cooldown=maxf(0,unit.cooldown-dt)
	if unit.state!="Attack":
		var offset: Vector3=game.player_unit.position-unit.position
		if unit.cooldown<=0 and offset.length()<17:begin(unit);return
		if offset.length()>5:
			game.move_actor(unit,offset.normalized()*unit.speed*dt);unit.face(game.player_unit.position,dt);unit.play("Run")
		else:unit.play("Idle")
		unit.pose(dt);return
	unit.action_time+=dt
	var t := unit.action_time
	unit.pose(dt)
	if unit.clip=="Melee":
		var events: Array=info.melee.get("events",[info.melee.contact])
		var pattern: String=info.melee.get("pattern","slam")
		if pattern in ["charge","lunge"]:
			var start := .8 if pattern=="charge" else .7
			var end := float(events[0])
			var goal: Vector3=unit.charge_start+unit.aim*(5 if pattern=="charge" else 3.4)*smoothstep(start,end,t)
			game.move_actor(unit,goal-unit.position)
		while int(unit.extra.event)<events.size() and t>=float(events[int(unit.extra.event)]):
			melee_event(unit,int(unit.extra.event));unit.extra.event+=1
		if is_instance_valid(unit.warning):unit.warning.visible=t<float(events[0])
	elif unit.clip=="Ranged":
		while unit.release_index<info.ranged.releases.size() and t>=float(info.ranged.releases[unit.release_index]):
			launch(unit);unit.release_index+=1
		if info.ranged.get("style","")=="beam":beam(unit,dt)
		if is_instance_valid(unit.warning):unit.warning.visible=t<float(info.ranged.releases[0])
	elif unit.clip=="Summon":
		while unit.release_index<info.summon.releases.size() and t>=float(info.summon.releases[unit.release_index]):
			for i in int(info.summon.perRelease):summon(unit)
			unit.release_index+=1
	if is_instance_valid(unit.warning) and unit.warning.material_override is ShaderMaterial:
		unit.warning.material_override.set_shader_parameter("progress",clampf(t/float(info.melee.contact),0,1))
	if t>=float(info.clips[unit.clip]):
		game.finish_attack(unit,.9 if unit.kind=="briar-king" else .65)
		if is_instance_valid(unit.extra.get("beam",null)):unit.extra.beam.queue_free();unit.extra.erase("beam")
func melee_event(unit: HuntUnit, index: int) -> void:
	var info: Dictionary=definitions[unit.kind]
	var factors: Array=info.melee.get("multipliers",[1])
	var amount: float=float(info.melee.damage)*float(factors[index])*unit.damage_scale
	var center := unit.attack_center
	var offset: Vector3=game.player_unit.position-center
	var struck := false
	match str(info.melee.get("pattern","slam")):
		"prison":
			var angle := fposmod(atan2(offset.x,offset.z)-unit.rotation.y,TAU)
			struck=(offset.length()>1.1 and offset.length()<1.8 and angle>.7 and angle<TAU-.7) if index==0 else offset.length()<2.1
			var group := Node3D.new();game.add_child(group);group.position=center
			for i in (10 if index==0 else 5):
				var a: float=.7+i*(TAU-1.4)/9+unit.rotation.y
				var shape := CylinderMesh.new();shape.top_radius=0;shape.bottom_radius=.22;shape.height=2.6;shape.radial_segments=5
				game.mesh_part(shape,game.material(info.color,.4),group,Vector3(sin(a)*1.45,1.3,cos(a)*1.45))
			game.effects.append({"node":group,"life":1.5,"duration":1.5,"velocity":Vector3.ZERO,"label":false,"fixed":true})
		"lunge":
			center=unit.position;struck=game.player_unit.position.distance_to(center)<2.2
		"charge":
			center=unit.position
			struck=Geometry3D.get_closest_point_to_segment(game.player_unit.position,unit.charge_start,unit.position).distance_to(game.player_unit.position)<1.2
		_:
			struck=offset.length()<float(info.melee.radius)+game.player_unit.radius
	game.pulse(center+Vector3.UP*.08,float(info.melee.radius),info.color,.6)
	if game.native_fx:game.native_fx.burst(center+Vector3.UP*.2,Color(info.color),28,.10,4);game.native_fx.play_sound("slam",2)
	if struck:game.hurt_player(amount,info.melee.name)
func launch(unit: HuntUnit) -> void:
	var info: Dictionary=definitions[unit.kind]
	var style: String=info.ranged.get("style","thorn")
	if style=="beam":return
	var start := socket(unit,"muzzle")
	var target := unit.attack_center+Vector3.UP*.95
	var direction := (target-start).normalized()
	if style=="thorn":
		for side in [-1,0,1]:game.spawn_bolt(start,direction.rotated(Vector3.UP,side*.22+(unit.release_index-1)*.08),"enemy",float(info.ranged.damage)*unit.damage_scale,"thorn")
		return
	var node := Node3D.new();game.add_child(node);node.position=start
	if style=="avalanche":
		game.mesh_part(game.sphere(.95),game.material("78c9e7",.65,.7),node,Vector3.ZERO)
		game.mesh_part(game.sphere(.48),game.material("ddf6fa",1),node,Vector3.ZERO)
		for i in 8:
			var angle: float=i*TAU/8
			var spike := CylinderMesh.new();spike.top_radius=0;spike.bottom_radius=.18;spike.height=.65
			game.mesh_part(spike,game.material(info.color,.4),node,Vector3(sin(angle)*.8,cos(angle)*.8,0)).rotation.z=-angle
	else:
		var torus := TorusMesh.new();torus.inner_radius=.66;torus.outer_radius=.91;torus.rings=24;torus.ring_segments=5
		game.mesh_part(torus,game.material(info.color,.8),node,Vector3.ZERO)
		game.mesh_part(game.box(Vector3(.09,.09,2.1)),game.material("dce3ec",.6),node,Vector3.ZERO)
		for side in [-1,1]:
			var blade := PrismMesh.new();blade.size=Vector3(.8,.13,.8)
			game.mesh_part(blade,game.material("e3c5f2",.8),node,Vector3(side*.37,0,side*.65)).rotation.y=side*.9
	game.projectiles.append({"node":node,"owner":"enemy","style":style,"age":0.0,"start":start,"target":target,"direction":direction,"speed":float(info.ranged.speed),"damage":float(info.ranged.damage)*unit.damage_scale,"potency":unit.damage_scale,"element":"ice" if style=="avalanche" else "physical","radius":float(info.ranged.radius),"passes":[]})
func special_projectile(item: Dictionary, dt: float) -> bool:
	var previous: Vector3=item.node.position
	item.age+=dt
	if item.style=="avalanche":
		var next: Vector3=previous+item.direction*item.speed*dt
		item.node.position=next;item.node.rotate_z(dt*1.8)
		var hit: bool=game.segment_time(previous,next,game.player_unit.position+Vector3.UP*.95,1.3)<INF
		var reached: bool=next.distance_to(item.start)>=item.target.distance_to(item.start)
		if hit or reached or item.age>3:
			var distance: float=next.distance_to(game.player_unit.position+Vector3.UP*.95)
			if distance<2.2:game.hurt_player(float(item.damage)*(1 if hit else .5),"Avalanche Heart")
			for i in 8:
				var direction := Vector3(sin(i*TAU/8),0,cos(i*TAU/8))
				game.spawn_bolt(next+direction*1.05,direction,"enemy",18*float(item.potency),"ice-shard")
			game.pulse(next,2.2,"9ee3ff",.5);return true
	else:
		var u: float=clampf(float(item.age)/2.4,0,1)
		var forward: Vector3=item.target-item.start
		var side := Vector3(forward.z,0,-forward.x).normalized()
		var next: Vector3=item.start+forward*(1-cos(u*TAU))*.5+side*sin(u*TAU)*2.5
		item.node.position=next;item.node.rotate_y(dt*15)
		var pass_index := 0 if u<.5 else 1
		if pass_index not in item.passes and game.segment_time(previous,next,game.player_unit.position+Vector3.UP*.95,1.15)<INF:
			item.passes.append(pass_index);game.hurt_player(float(item.damage)*(1 if pass_index==0 else .5),"Widow's Orbit")
		if u>=1:return true
	return false
func beam(unit: HuntUnit, dt: float) -> void:
	var info: Dictionary=definitions[unit.kind].ranged
	var elapsed: float=unit.action_time-float(info.releases[0])
	if elapsed<0 or elapsed>float(info.duration):
		if is_instance_valid(unit.extra.get("beam",null)):unit.extra.beam.visible=false
		return
	var start := socket(unit,"muzzle")
	var angle: float=lerpf(-float(info.sweepAngle),float(info.sweepAngle),elapsed/float(info.duration))
	var end: Vector3=start+unit.aim.rotated(Vector3.UP,angle)*18;end.y=.95
	var node: MeshInstance3D=unit.extra.get("beam",null)
	if not is_instance_valid(node):
		node=game.mesh_part(game.box(Vector3(.76,.76,1)),game.material("ffd98a",2,.65),game,Vector3.ZERO);unit.extra.beam=node
	node.position=(start+end)*.5;node.look_at(end,Vector3.UP,true);node.scale.z=start.distance_to(end)
	unit.extra.beam_tick=maxf(0,float(unit.extra.beam_tick)-dt)
	if float(unit.extra.beam_tick)<=0 and Geometry3D.get_closest_point_to_segment(game.player_unit.position+Vector3.UP*.95,start,end).distance_to(game.player_unit.position+Vector3.UP*.95)<float(info.halfWidth)+.4:
		unit.extra.beam_tick=float(info.tickInterval);game.hurt_player(float(info.damage)*unit.damage_scale,"Daybreak Engine")
func brood_count() -> int:
	var count := 0
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.extra.get("brood",false):count+=1
	return count
func summon(unit: HuntUnit) -> void:
	if brood_count()>=6:return
	var slot := brood_count()
	var start := socket(unit,"hatch")
	var landing: Vector3=game.clamp_position(unit.position+unit.aim*(2.1+(slot/2)*.30)+unit.aim.rotated(Vector3.UP,PI/2)*(slot%2*2-1)*(1+slot/2*.25),.3)
	var brood: HuntUnit=game.spawn_enemy("briarling",landing)
	brood.actor.scale*=.65;brood.radius*=.65;brood.maximum*=.65;brood.hp=brood.maximum
	brood.extra={"brood":true,"air":0.0,"start":start,"landing":landing};brood.position=start
func clear_unit(unit: HuntUnit) -> void:
	if is_instance_valid(unit.extra.get("beam",null)):unit.extra.beam.queue_free();unit.extra.erase("beam")
