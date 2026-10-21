extends Node3D
const Unit := preload("res://unit.gd")
const COLORS := {"physical":"e8d8a8","fire":"f35e51","ice":"66ccec","poison":"b071e4"}
var player_unit: HuntUnit
var fox: HuntUnit
var enemies: Array[HuntUnit] = []
var camera: Camera3D
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var materials := {}
var shapes := {}
var request := {}
var equipped := "fire"
var elemental_power := 8.0
var auto_fire := true
var running := false
var paused := false
var ended := false
var victory := false
var stage := "skirmish"
var clock := 0.0
var stage_time := 0.0
var spawned := 0
var killed := 0
var boss_spawned := false
var spawn_clock := 0.0
var gold := 0
var experience := 0.0
var level := 1
var shots := 0
var hits := 0
var dealt := 0.0
var taken := 0.0
var pet_hits := 0
var dot_ticks := 0
var status_ticks := {"fire":0,"poison":0}
var dash_cooldown := 0.0
var salvo_cooldown := 0.0
var dash_left := 0.0
var invulnerable := 0.0
var dash_direction := Vector3.FORWARD
var movement := Vector3.ZERO
var facing := Vector3.FORWARD
var shoot_time := 0.0
var shooting := false
var shot_fired := false
var salvo_left := 0.0
var salvo_fired := false
var nocked: Node3D
var reticle: MeshInstance3D
var aim_point := Vector3.ZERO
var fox_target: HuntUnit
var fox_attacking := false
var fox_fired := false
var fox_clock := 0.0
var fox_cooldown := 0.0
var yaw := .35
var pitch := .62
var distance := 13.5
var camera_focus := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var poll := 0.0
var end_time := 0.0
var current_quality := ""
var native_drag := false
var native_mouse := Vector2(.5,.5)
var world: WorldEnvironment

func material(color: String, emission := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var key := color+str(emission)+str(alpha)
	if materials.has(key):return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.albedo_color.a = alpha
	m.roughness = .88
	if alpha<1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission>0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = emission
	materials[key] = m
	return m

func mesh_part(shape: Mesh, mat: Material, parent: Node3D, point: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat
	parent.add_child(n)
	n.position = point
	return n

func box(size: Vector3) -> BoxMesh:
	var key := str(size)
	if shapes.has(key):return shapes[key]
	var b := BoxMesh.new();b.size=size;shapes[key]=b;return b

func sphere(radius: float) -> SphereMesh:
	var key := "sphere"+str(radius)
	if shapes.has(key):return shapes[key]
	var s := SphereMesh.new();s.radius=radius;s.height=radius*2;s.radial_segments=10;s.rings=5;shapes[key]=s;return s

func ring(radius: float, color: String, alpha := .6) -> MeshInstance3D:
	var key := "ring"+str(radius)
	if not shapes.has(key):
		var t := TorusMesh.new();t.inner_radius=radius-.04;t.outer_radius=radius;t.rings=40;t.ring_segments=4;shapes[key]=t
	return mesh_part(shapes[key],material(color,.2,alpha),self,Vector3.ZERO)

func _ready() -> void:
	Engine.max_fps = 60
	rng.seed = 8237
	world = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("203c3b")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b6d3ce")
	world.environment.ambient_light_energy = .42
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color("ffe4ba")
	sun.light_energy = .85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 36
	add_child(sun)
	build_world()
	player_unit = make_unit("rowan",Vector3(0,0,5))
	fox = make_unit("fox",Vector3(-1.7,0,6))
	camera = Camera3D.new()
	camera.fov = 52
	camera.near = .08
	camera.far = 90
	add_child(camera)
	camera.current = true
	camera_focus = player_unit.position+Vector3.UP
	nocked = arrow_mesh("fire",false)
	add_child(nocked)
	nocked.visible = false
	reticle = ring(.34,"e5dfc4",.6)
	reticle.visible = false
	update_camera(1)
	if OS.has_feature("web"):
		get_viewport().scaling_3d_scale = .85
		JavaScriptBridge.eval("window.huntReady=true",true)
	else:start_run(false)
	print("FIRST_HUNT_READY: playable Rowan, independent fox, three enemy types, Briar King and elemental arrows")

func build_world() -> void:
	var ground := CylinderMesh.new()
	ground.top_radius=25;ground.bottom_radius=25;ground.height=.3;ground.radial_segments=64
	mesh_part(ground,material("304c3d"),self,Vector3(0,-.20,0))
	for i in 14:
		var patch := CylinderMesh.new();patch.top_radius=rng.randf_range(.7,2.3);patch.bottom_radius=patch.top_radius;patch.height=.008;patch.radial_segments=9
		mesh_part(patch,material("415b45" if i%2==0 else "36543f"),self,Vector3(rng.randf_range(-13,13),-.04,rng.randf_range(-13,13)))
	for i in 22:
		var angle := i*TAU/22
		var point := Vector3(sin(angle),0,cos(angle))*rng.randf_range(18.5,21.0)
		var trunk := CylinderMesh.new();trunk.top_radius=.22;trunk.bottom_radius=.5;trunk.height=4.6;trunk.radial_segments=7
		mesh_part(trunk,material("665e45"),self,point+Vector3.UP*2.3)
		obstacles.append({"p":point,"r":.55,"h":4.6})
		for j in 2:
			var canopy := mesh_part(sphere(1.8-j*.25),material("345b4c" if i%2==0 else "406850"),self,point+Vector3(j*.35,4.0+j*.9,0))
			canopy.scale.y = .75
	for i in 12:
		var angle := i*TAU/12+.12
		var point := Vector3(sin(angle),0,cos(angle))*rng.randf_range(15.8,17.6)
		var rock := mesh_part(sphere(.85),material("76827b"),self,point+Vector3.UP*.45)
		rock.scale = Vector3(1.2,.7,.95)
		obstacles.append({"p":point,"r":.95,"h":1.2})
	for i in 4:
		var angle := i*PI/2+.3
		var point := Vector3(sin(angle),0,cos(angle))*14.3
		mesh_part(box(Vector3(.5,1.9,.5)),material("94a38c"),self,point+Vector3.UP*.95)
		mesh_part(box(Vector3(.20,.55,.035)),material("d3b976",.35),self,point+Vector3(0,1.2,.26))
		obstacles.append({"p":point,"r":.4,"h":1.9})
	# One draw call for the grass scatter; the center remains open.
	var grass_mesh := PrismMesh.new();grass_mesh.size=Vector3(.12,.38,.12)
	var multi := MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=grass_mesh;multi.instance_count=240
	for i in 240:
		var point := Vector3(rng.randf_range(-20,20),.12,rng.randf_range(-20,20))
		multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU),point))
	var scatter := MultiMeshInstance3D.new();scatter.multimesh=multi;scatter.material_override=material("81926a");add_child(scatter)
	var boundary := ring(18,"c4b77c",.16);boundary.position.y=.015

func make_unit(id: String, at: Vector3) -> HuntUnit:
	var unit := Unit.new()
	add_child(unit)
	unit.configure(id)
	unit.position = at
	if id not in ["fox"]:
		unit.hp_bar = Node3D.new();unit.add_child(unit.hp_bar);unit.hp_bar.position.y=unit.height+.15
		mesh_part(box(Vector3(.80,.09,.025)),material("152a28"),unit.hp_bar,Vector3.ZERO)
		unit.hp_fill = mesh_part(box(Vector3(.70,.045,.030)),material("dfae78" if id!="rowan" else "a7d7a1"),unit.hp_bar,Vector3(0,0,.02))
	return unit

func start_run(boss_only: bool) -> void:
	for unit in enemies:
		if is_instance_valid(unit.warning):unit.warning.queue_free()
		unit.queue_free()
	enemies.clear()
	for list in [projectiles,effects,hazards,pickups]:
		for item in list:item.node.queue_free()
		list.clear()
	player_unit.actor.rotation.z=0
	player_unit.hp=player_unit.maximum;player_unit.position=Vector3(0,0,5);player_unit.clear_status();player_unit.play("Idle",true)
	fox.position=Vector3(-1.7,0,6);fox.play("Idle",true)
	running=true;paused=false;ended=false;victory=false;end_time=0;clock=0;stage_time=0;spawned=0;killed=0;boss_spawned=false
	stage="boss" if boss_only else "skirmish"
	gold=0;experience=0;level=1;shots=0;hits=0;dealt=0;taken=0;pet_hits=0;dot_ticks=0;status_ticks={"fire":0,"poison":0}
	dash_cooldown=0;salvo_cooldown=0;dash_left=0;invulnerable=1.5;shooting=false;shoot_time=0;salvo_left=0;fox_attacking=false;fox_cooldown=0;spawn_clock=0
	camera_focus=player_unit.position+Vector3.UP
	if boss_only:
		spawn_clock=8
		spawn_boss()
	else:
		for i in 4:spawn_enemy(["briarling","briarling","sporecaller","thornback"][i],Vector3((i-1.5)*3.5,0,-3-i%2*2))
		spawn_clock=3

func spawn_enemy(id: String, point: Vector3) -> HuntUnit:
	var enemy := make_unit(id,point)
	enemy.cooldown=.5+rng.randf()*.8
	enemies.append(enemy)
	if id!="briar-king":spawned+=1
	return enemy

func spawn_boss() -> void:
	boss_spawned=true
	spawn_enemy("briar-king",Vector3(0,0,-5.5))
	pulse(Vector3(0,.04,-5.5),3.0,"d7b778",1.0)

func living_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.hp>0 and enemy.kind!="briar-king":count+=1
	return count

func nearest_enemy(point: Vector3, limit := 18.0) -> HuntUnit:
	var selected: HuntUnit
	var best := limit
	for enemy in enemies:
		if enemy.hp<=0:continue
		var d := enemy.position.distance_to(point)
		if d<best:best=d;selected=enemy
	return selected

func clamp_position(point: Vector3, radius: float) -> Vector3:
	var flat := Vector2(point.x,point.z)
	if flat.length()>18-radius:flat=flat.normalized()*(18-radius)
	point.x=flat.x;point.z=flat.y;point.y=0
	for obstacle in obstacles:
		var delta: Vector3 = point-obstacle.p
		var minimum: float = radius+obstacle.r
		if delta.length()<minimum:
			if delta.length()<.001:delta=Vector3.RIGHT
			point=obstacle.p+delta.normalized()*minimum
	var boundary := Vector2(point.x,point.z).limit_length(18-radius)
	return Vector3(boundary.x,0,boundary.y)

func move_actor(unit: HuntUnit, delta: Vector3) -> void:
	unit.position=clamp_position(unit.position+delta,unit.radius)

func set_element(name: String) -> bool:
	if name not in COLORS:return false
	if name==equipped:return true
	equipped=name
	for enemy in enemies:enemy.clear_status()
	for i in range(projectiles.size()-1,-1,-1):
		if projectiles[i].owner=="player":projectiles[i].node.queue_free();projectiles.remove_at(i)
	return true

func cast_dash() -> bool:
	if not running or paused or ended or dash_cooldown>0:return false
	dash_cooldown=2.6;dash_left=.19;invulnerable=maxf(invulnerable,.3);shooting=false;salvo_left=0;nocked.visible=false
	dash_direction=movement.normalized() if movement.length()>.05 else facing
	player_unit.play("Windskip",true)
	pulse(player_unit.position+Vector3.UP*.04,.8,"9ee6d9",.35)
	return true

func cast_salvo() -> bool:
	if not running or paused or ended or salvo_cooldown>0 or dash_left>0:return false
	salvo_cooldown=11;salvo_left=1.1;salvo_fired=false;shooting=false
	player_unit.play("Salvo",true)
	return true

func consume_command(command: String) -> void:
	match command:
		"start":start_run(false)
		"boss":start_run(true)
		"pause":
			if running and not ended:paused=not paused
		"dash":cast_dash()
		"salvo":cast_salvo()
		"auto":auto_fire=not auto_fire
		"physical","fire","ice","poison":set_element(command)

func read_controls() -> void:
	if not OS.has_feature("web"):return
	var data = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(window.huntInput || {})",true))
	if not data:return
	request=data
	for command in request.get("commands",[]):consume_command(str(command))
	JavaScriptBridge.eval("if(window.huntInput){window.huntInput.commands=[];window.huntInput.dx=0;window.huntInput.dy=0;window.huntInput.wheel=0;}",true)
	if request.get("hidden",false) and running and not ended:paused=true
	var quality := str(request.get("quality","balanced"))
	if quality!=current_quality:
		current_quality=quality
		get_viewport().scaling_3d_scale=.65 if quality=="light" else .85
	yaw-=float(request.get("dx",0))*.004
	pitch=clampf(pitch+float(request.get("dy",0))*.003,.27,1.12)
	distance=clampf(distance+float(request.get("wheel",0))*.01,8,19)

func input_move() -> Vector3:
	var vector := Vector2.ZERO
	if OS.has_feature("web"):
		var keys: Dictionary = request.get("keys",{})
		vector=Vector2(float(keys.get("KeyD",false))-float(keys.get("KeyA",false)),float(keys.get("KeyS",false))-float(keys.get("KeyW",false)))
	else:vector=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var stick: Array = request.get("move",[0,0])
	vector+=Vector2(float(stick[0]),float(stick[1]))
	vector=vector.limit_length(1)
	return Vector3(vector.x,0,vector.y).rotated(Vector3.UP,yaw)

func _input(event: InputEvent) -> void:
	if OS.has_feature("web"):return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:cast_dash()
			KEY_E:cast_salvo()
			KEY_P,KEY_ESCAPE:consume_command("pause")
			KEY_F:consume_command("auto")
			KEY_0:set_element("physical")
			KEY_1:set_element("fire")
			KEY_2:set_element("ice")
			KEY_3:set_element("poison")
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:native_drag=event.pressed
	if event is InputEventMouseMotion:
		native_mouse=event.position/get_viewport().get_visible_rect().size
		if native_drag:yaw-=event.relative.x*.004;pitch=clampf(pitch+event.relative.y*.003,.27,1.12)

func _process(delta: float) -> void:
	read_controls()
	var remaining := minf(delta,.1)
	if running and not paused and not ended:
		while remaining>.00001:
			var step := minf(remaining,1.0/60)
			simulate(step)
			remaining-=step
	else:
		player_unit.pose(0);fox.pose(0)
		if ended and not paused and end_time<3.1:
			end_time+=minf(delta,.1)
			for enemy in enemies:
				if enemy.hp<=0:enemy.pose(minf(delta,.1))
	update_camera(minf(delta,.1))
	poll+=delta
	if OS.has_feature("web") and poll>=.1:
		poll=0
		JavaScriptBridge.eval("window.huntState="+JSON.stringify(snapshot()),true)

func simulate(dt: float) -> void:
	if not running or paused or ended:return
	clock+=dt;stage_time+=dt
	dash_cooldown=maxf(0,dash_cooldown-dt);salvo_cooldown=maxf(0,salvo_cooldown-dt);invulnerable=maxf(0,invulnerable-dt)
	movement=input_move()
	update_player(dt)
	for enemy in enemies:
		update_enemy(enemy,dt)
	update_fox(dt)
	update_projectiles(dt)
	update_hazards(dt)
	update_effects(dt)
	update_pickups(dt)
	update_encounter(dt)
	for i in range(enemies.size()-1,-1,-1):
		if enemies[i].hp<=0 and enemies[i].dead_time>3.1:
			if is_instance_valid(enemies[i].warning):enemies[i].warning.queue_free()
			enemies[i].queue_free();enemies.remove_at(i)

func update_encounter(dt: float) -> void:
	spawn_clock-=dt
	if stage=="skirmish":
		if spawned<8 and living_count()<5 and spawn_clock<=0:
			var angle := rng.randf()*TAU
			var point := clamp_position(player_unit.position+Vector3(sin(angle),0,cos(angle))*10,.65)
			spawn_enemy(["briarling","sporecaller","briarling","thornback"][spawned%4],point)
			spawn_clock=3
		if killed>=8:
			stage="breather";stage_time=0;player_unit.hp=minf(player_unit.maximum,player_unit.hp+35)
	elif stage=="breather" and stage_time>3:
		stage="boss";stage_time=0;spawn_clock=8;spawn_boss()
	elif stage=="boss" and not ended and spawn_clock<=0 and living_count()<3:
		var angle := rng.randf()*TAU
		spawn_enemy("sporecaller" if int(clock)%2==0 else "briarling",clamp_position(player_unit.position+Vector3(sin(angle),0,cos(angle))*11,.6))
		spawn_clock=10

func update_player(dt: float) -> void:
	var target := nearest_enemy(player_unit.position,20)
	var mouse: Array = request.get("mouse",[native_mouse.x,native_mouse.y])
	var screen := Vector2(float(mouse[0]),float(mouse[1]))*get_viewport().get_visible_rect().size
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var point = Plane(Vector3.UP,0).intersects_ray(origin,direction)
	aim_point=point if point!=null else player_unit.position+facing*8
	var aim := aim_point+Vector3.UP*.9
	if auto_fire and is_instance_valid(target):aim=target.position+Vector3.UP*target.height*.47
	var flat := aim-player_unit.position;flat.y=0
	if flat.length()>.1:facing=flat.normalized()
	player_unit.face(aim,dt,18)
	if dash_left>0:
		move_actor(player_unit,dash_direction*15*dt)
		dash_left=maxf(0,dash_left-dt)
		player_unit.pose(dt,3.4)
		return
	move_actor(player_unit,movement*player_unit.speed*dt)
	# Solid actors cannot walk through the King or crowd into a trunk.
	for enemy in enemies:
		if enemy.hp<=0:continue
		var delta := player_unit.position-enemy.position
		var minimum := player_unit.radius+enemy.radius
		if delta.length()<minimum and delta.length()>.001:player_unit.position=clamp_position(enemy.position+delta.normalized()*minimum,player_unit.radius)
	var trigger := (auto_fire and is_instance_valid(target)) or bool(request.get("fire",false)) or (not OS.has_feature("web") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if salvo_left>0:
		salvo_left=maxf(0,salvo_left-dt)
		if 1.1-salvo_left>=.625625 and not salvo_fired:
			salvo_fired=true
			var start := player_unit.socket("bowstring")
			var shot_direction := (aim-start).normalized()
			for i in 8:fire_arrow(start,shot_direction.rotated(Vector3.UP,(i-3.5)*.055),"player",1.4,true)
			pulse(player_unit.position+Vector3.UP*.1,1.2,"d6eeb0",.6)
		player_unit.pose(dt)
	elif shooting:
		shoot_time+=dt
		var next_clip := "RunShoot" if movement.length()>.1 else "Shoot"
		if player_unit.clip!=next_clip:
			player_unit.play(next_clip);player_unit.anim_time=shoot_time*4
		if shoot_time>=1.82/4 and not shot_fired:
			shot_fired=true
			fire_arrow(player_unit.socket("bowstring"),(aim-player_unit.socket("bowstring")).normalized(),"player",1,false)
		player_unit.pose(dt,4)
		if shoot_time>=.8:shooting=false
	elif trigger:
		shooting=true;shoot_time=0;shot_fired=false;player_unit.play("RunShoot" if movement.length()>.1 else "Shoot",true)
	else:
		player_unit.play("Run" if movement.length()>.1 else "Idle")
		player_unit.pose(dt,2.7 if movement.length()>.1 else 1)
	nocked.visible=shooting and not shot_fired
	if nocked.visible:
		nocked.position=player_unit.socket("bowstring")
		nocked.look_at(aim,Vector3.UP,true)
		for child in nocked.get_children():child.material_override=material(COLORS[equipped],.25)
	reticle.visible=not auto_fire
	reticle.position=aim_point+Vector3.UP*.04

func update_enemy(enemy: HuntUnit, dt: float) -> void:
	if enemy.hp<=0:
		enemy.dead_time+=dt
		enemy.pose(dt)
		return
	update_status(enemy,dt)
	if enemy.hp<=0:return
	enemy.cooldown=maxf(0,enemy.cooldown-dt)
	var to_player := player_unit.position-enemy.position
	var reach := to_player.length()
	var slowing := .85 if enemy.kind=="briar-king" else .65
	var rate := slowing if enemy.ice_time>0 else 1.0
	if enemy.state=="Attack":
		enemy.action_time+=dt*rate
		var t := enemy.action_time
		if enemy.kind=="briar-king":
			if enemy.clip=="Melee":
				if t>=1.55 and not enemy.fired:
					enemy.fired=true
					pulse(enemy.attack_center,2.3,"e6be77",.6)
				if t>=1.55 and t<=2.15 and not enemy.wave_hit:
					if player_unit.position.distance_to(enemy.attack_center)<2.3*clampf((t-1.55)/.6,0,1)+.35:
						enemy.wave_hit=true;hurt_player(36,"Thronebreaker")
				if t>=3.4:finish_attack(enemy,1.0)
			else:
				while enemy.release_index<3 and t>=[1.2,1.55,1.9][enemy.release_index]:
					var angle: float = -.08 if enemy.release_index==1 else .08 if enemy.release_index==2 else 0
					var offset := Vector3(.0000001,.71,0)
					var start := enemy.socket("cannon",offset)
					var direction := (enemy.attack_center+Vector3.UP*.95-start).normalized()
					for side in [-1,0,1]:spawn_bolt(start,direction.rotated(Vector3.UP,side*.22+angle),"enemy",16,"thorn")
					enemy.release_index+=1
				if t>=3.8:finish_attack(enemy,.8)
		elif enemy.kind=="sporecaller":
			if t>=.72 and not enemy.fired:
				enemy.fired=true
				spawn_lob(enemy.socket("head",Vector3(0,.31,.3)),enemy.attack_center)
			if t>=2.2:finish_attack(enemy,.8)
		elif enemy.kind=="thornback":
			if t>=.78 and t<=1.25:
				move_actor(enemy,enemy.aim*7*dt*rate)
				if not enemy.wave_hit and enemy.position.distance_to(player_unit.position)<1.15:
					enemy.wave_hit=true;hurt_player(24,"Tusk charge")
			if t>=2.65:finish_attack(enemy,.8)
		else:
			if t>=.56 and not enemy.fired:
				enemy.fired=true
				pulse(enemy.position+enemy.aim*.8+Vector3.UP*.15,.6,"dcae83",.2)
				if enemy.position.distance_to(player_unit.position)<1.65:hurt_player(12,"Briarling claw")
			if t>=1.2:finish_attack(enemy,.45)
		if is_instance_valid(enemy.warning):enemy.warning.visible=t<(1.55 if enemy.clip=="Melee" else 1.9 if enemy.kind=="briar-king" else .72 if enemy.kind=="sporecaller" else .78 if enemy.kind=="thornback" else .56)
		enemy.pose(dt,rate)
		return
	var attack_distance := 13.0 if enemy.kind=="sporecaller" else 14.0 if enemy.kind=="briar-king" else 5.0 if enemy.kind=="thornback" else 1.45
	if reach<attack_distance and enemy.cooldown<=0:
		begin_attack(enemy)
		return
	var direction := to_player.normalized()
	if enemy.kind=="sporecaller" and reach<4:direction=-direction
	var wants_move := reach>(6.0 if enemy.kind=="briar-king" else 7.0 if enemy.kind=="sporecaller" else 1.2) or (enemy.kind=="sporecaller" and reach<4)
	if wants_move:
		for other in enemies:
			if other==enemy or other.hp<=0:continue
			var delta := enemy.position-other.position
			if delta.length()<enemy.radius+other.radius+.45 and delta.length()>.01:direction+=delta.normalized()*.6
		move_actor(enemy,direction.limit_length(1)*enemy.speed*rate*dt)
		enemy.face(enemy.position+direction,dt)
		enemy.play("Run")
	else:enemy.play("Idle");enemy.face(player_unit.position,dt)
	enemy.pose(dt,rate*(2 if wants_move else 1))

func begin_attack(enemy: HuntUnit) -> void:
	enemy.state="Attack";enemy.action_time=0;enemy.fired=false;enemy.wave_hit=false;enemy.release_index=0
	enemy.aim=(player_unit.position-enemy.position).normalized();enemy.aim.y=0
	enemy.rotation.y=atan2(enemy.aim.x,enemy.aim.z)
	enemy.attack_center=player_unit.position
	if is_instance_valid(enemy.warning):enemy.warning.queue_free()
	if enemy.kind=="briar-king":
		if enemy.position.distance_to(player_unit.position)<3.6:
			enemy.play("Melee",true)
			enemy.attack_center=enemy.position+Vector3(-.65,0,.94).rotated(Vector3.UP,enemy.rotation.y)
			enemy.warning=ring(2.3,"e7bd75",.8)
			enemy.warning.position=enemy.attack_center+Vector3.UP*.04
		else:
			enemy.play("Ranged",true)
			enemy.warning=ring(.8,"f1b37c",.7)
			enemy.warning.position=enemy.attack_center+Vector3.UP*.04
	else:
		enemy.play("Attack",true)
		if enemy.kind=="sporecaller":
			enemy.warning=ring(1.3,"d6ab79",.7)
			enemy.warning.position=enemy.attack_center+Vector3.UP*.04
		elif enemy.kind=="thornback":
			enemy.warning=mesh_part(box(Vector3(1.1,.012,3.6)),material("e1ad75",0,.25),self,enemy.position+enemy.aim*1.8+Vector3.UP*.04)
			enemy.warning.rotation.y=enemy.rotation.y
		else:
			enemy.warning=ring(.8,"e3b58b",.6)
			enemy.warning.position=enemy.position+enemy.aim*.65+Vector3.UP*.04

func finish_attack(enemy: HuntUnit, rest: float) -> void:
	enemy.state="Chase";enemy.cooldown=rest;enemy.play("Idle")
	if is_instance_valid(enemy.warning):enemy.warning.visible=false

func damage_enemy(enemy: HuntUnit, amount: float, element: String, source := "arrow") -> void:
	if enemy.hp<=0:return
	var actual := minf(enemy.hp,amount)
	enemy.hp=maxf(0,enemy.hp-amount);enemy.flash=.15;dealt+=actual
	if source=="pet":pet_hits+=1
	if source=="dot":dot_ticks+=1
	if source!="dot":hits+=1
	number(amount,enemy.position+Vector3.UP*(enemy.height*.6),COLORS.get(element,"e9d7a1"))
	if element!="physical" and source!="dot" and element==equipped:
		match element:
			"fire":enemy.fire_time=3
			"ice":enemy.ice_time=2.5
			"poison":enemy.poison_time=4;enemy.poison_stacks=mini(4,enemy.poison_stacks+1)
	if enemy.hp<=0:
		enemy.state="Dead";enemy.dead_time=0;enemy.clear_status();enemy.play("Death",true)
		if is_instance_valid(enemy.warning):enemy.warning.visible=false
		killed+=1
		spawn_pickup(enemy.position,enemy.kind=="briar-king")
		if enemy.kind=="briar-king":victory=true;ended=true

func update_status(enemy: HuntUnit, dt: float) -> void:
	if enemy.fire_time>0 or enemy.poison_time>0:
		enemy.dot_clock+=dt
		while enemy.dot_clock+1e-9>=.5:
			enemy.dot_clock=maxf(0,enemy.dot_clock-.5)
			if enemy.fire_time>0:
				status_ticks.fire+=1
				damage_enemy(enemy,3,"fire","dot")
			if enemy.poison_time>0 and enemy.hp>0:
				status_ticks.poison+=1
				damage_enemy(enemy,1.5*enemy.poison_stacks,"poison","dot")
	enemy.fire_time=maxf(0,enemy.fire_time-dt);enemy.poison_time=maxf(0,enemy.poison_time-dt);enemy.ice_time=maxf(0,enemy.ice_time-dt)
	if enemy.poison_time<=0:enemy.poison_stacks=0

func hurt_player(amount: float, _source: String) -> bool:
	if invulnerable>0 or ended or not running:return false
	player_unit.hp=maxf(0,player_unit.hp-amount);taken+=amount;player_unit.flash=.15;invulnerable=.5
	number(amount,player_unit.position+Vector3.UP*1.9,"f28e83",true)
	pulse(player_unit.position+Vector3.UP*.08,.6,"ee7365",.3)
	if player_unit.hp<=0:
		ended=true;victory=false;shooting=false;nocked.visible=false;player_unit.actor.rotation.z=-1.3
	return true

func update_fox(dt: float) -> void:
	fox_cooldown=maxf(0,fox_cooldown-dt)
	if fox_attacking:
		fox_clock+=dt
		if is_instance_valid(fox_target) and fox_target.hp>0:fox.face(fox_target.position,dt,7)
		if fox_clock>=.32 and not fox_fired:
			fox_fired=true
			if is_instance_valid(fox_target) and fox_target.hp>0:
				var start := fox.socket("head",Vector3(0,.321,.014))
				var direction := (fox_target.position+Vector3.UP*fox_target.height*.47-start).normalized()
				for side in [-1,0,1]:spawn_bolt(start,direction.rotated(Vector3.UP,side*.08),"pet",6,"dart")
		fox.pose(dt)
		if fox_clock>=.85:fox_attacking=false;fox_cooldown=1.1
		return
	var target := nearest_enemy(player_unit.position,8)
	var goal := player_unit.position+Vector3(sin(clock*.2)*2,0,cos(clock*.2)*2)
	if is_instance_valid(target):
		goal=target.position+(player_unit.position-target.position).normalized()*3.5+Vector3(-1.2,0,0)
		var offset := goal-player_unit.position
		if offset.length()>6:goal=player_unit.position+offset.normalized()*6
	if fox.position.distance_to(player_unit.position)>9:goal=player_unit.position+Vector3(-1.5,0,1.5)
	if fox.position.distance_to(goal)>.45:
		var delta := goal-fox.position
		move_actor(fox,delta.normalized()*minf(fox.speed*dt,delta.length()))
		fox.face(goal,dt,5)
		fox.play("Trot");fox.pose(dt,2)
	else:
		fox.play("Idle");fox.pose(dt)
	if is_instance_valid(target) and fox.position.distance_to(target.position)<8 and fox.position.distance_to(player_unit.position)<8 and fox_cooldown<=0:
		fox_target=target;fox_attacking=true;fox_clock=0;fox_fired=false;fox.play("Attack",true)

func arrow_mesh(element: String, special: bool) -> Node3D:
	var node := Node3D.new()
	mesh_part(box(Vector3(.025,.025,.64)),material("b3a17a"),node,Vector3(0,0,-.1))
	var tip := PrismMesh.new();tip.size=Vector3(.11,.08,.19)
	mesh_part(tip,material(COLORS[element],.4),node,Vector3(0,0,.26))
	for side in [-1,1]:
		var feather := mesh_part(box(Vector3(.11,.012,.14)),material(COLORS[element],.2),node,Vector3(side*.045,0,-.36))
		feather.rotation.y=side*.25
	if special:
		for side in [-1,1]:mesh_part(box(Vector3(.19,.018,.10)),material("c9e1a9",.3),node,Vector3(side*.11,0,-.18)).rotation.y=side*.4
	return node

func fire_arrow(start: Vector3, direction: Vector3, owner: String, multiplier: float, special: bool) -> void:
	var node := arrow_mesh(equipped,special)
	add_child(node)
	node.position=start+direction*.12
	node.look_at(start+direction,Vector3.UP,true)
	projectiles.append({"node":node,"direction":direction,"age":0.0,"speed":22.0,"owner":owner,"damage":(22+elemental_power if equipped!="physical" else 22)*multiplier,"element":equipped,"style":"arrow","radius":.10})
	shots+=1

func spawn_bolt(start: Vector3, direction: Vector3, owner: String, damage: float, style: String) -> void:
	var node := Node3D.new();add_child(node);node.position=start
	if style=="thorn":
		var thorn := PrismMesh.new();thorn.size=Vector3(.13,.13,.7)
		mesh_part(thorn,material("d5b179",.2),node,Vector3.ZERO)
		for side in [-1,1]:mesh_part(box(Vector3(.18,.025,.13)),material("ca855d"),node,Vector3(side*.07,0,-.18))
	else:mesh_part(sphere(.07),material("e6d6a4",.5),node,Vector3.ZERO)
	node.look_at(start+direction,Vector3.UP,true)
	projectiles.append({"node":node,"direction":direction,"age":0.0,"speed":8.5 if owner=="enemy" else 14.0,"owner":owner,"damage":damage,"element":"physical","style":style,"radius":.20 if style=="thorn" else .09})

func spawn_lob(start: Vector3, end: Vector3) -> void:
	var node := mesh_part(sphere(.18),material("cba285",.2),self,start)
	projectiles.append({"node":node,"direction":Vector3.ZERO,"age":0.0,"speed":0.0,"owner":"enemy","damage":10.0,"element":"physical","style":"lob","start":start,"end":end})

func segment_time(start: Vector3, end: Vector3, center: Vector3, radius: float) -> float:
	var direction := end-start
	var offset := start-center
	var c := offset.length_squared()-radius*radius
	if c<=0:return 0
	var a := direction.length_squared()
	if a<.000001:return INF
	var b := offset.dot(direction)
	var discriminant := b*b-a*c
	if discriminant<0:return INF
	var entry := (-b-sqrt(discriminant))/a
	return entry if entry>=0 and entry<=1 else INF

func update_projectiles(dt: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var item := projectiles[i]
		item.age+=dt
		if item.style=="lob":
			var u: float=clampf(item.age/1.05,0,1)
			item.node.position=item.start.lerp(item.end+Vector3.UP*.1,u)+Vector3.UP*sin(u*PI)*1.8
			if u>=1:
				add_spores(item.end)
				item.node.queue_free();projectiles.remove_at(i)
			continue
		var previous: Vector3=item.node.position
		var next: Vector3=previous+item.direction*item.speed*dt
		var nearest := INF
		var target: HuntUnit
		for obstacle in obstacles:
			if previous.y>float(obstacle.h):continue
			var center: Vector3=obstacle.p+Vector3.UP*previous.y
			var collision := segment_time(previous,next,center,float(obstacle.r)+float(item.radius))
			if collision<nearest:nearest=collision;target=null
		if item.owner=="enemy":
			var collision := segment_time(previous,next,player_unit.position+Vector3.UP*.95,player_unit.radius+float(item.radius))
			if collision<nearest:nearest=collision;target=player_unit
		else:
			for enemy in enemies:
				if enemy.hp<=0:continue
				var collision := segment_time(previous,next,enemy.position+Vector3.UP*enemy.height*.47,enemy.radius+float(item.radius))
				if collision<nearest:nearest=collision;target=enemy
		if nearest<INF:
			var point := previous.lerp(next,nearest)
			if is_instance_valid(target):
				if target==player_unit:hurt_player(float(item.damage),"Thorn spear")
				else:damage_enemy(target,float(item.damage),str(item.element),"pet" if item.owner=="pet" else "arrow")
			impact(point,COLORS.get(str(item.element),"e7d5a1"))
			item.node.queue_free();projectiles.remove_at(i)
		elif item.age>3 or next.length()>45:
			item.node.queue_free();projectiles.remove_at(i)
		else:item.node.position=next

func add_spores(point: Vector3) -> void:
	var node := ring(1.3,"d19d82",.55);node.position=point+Vector3.UP*.04
	var disc := CylinderMesh.new();disc.top_radius=1.25;disc.bottom_radius=1.25;disc.height=.012;disc.radial_segments=24
	mesh_part(disc,material("ad7f6d",0,.20),node,Vector3.ZERO)
	hazards.append({"node":node,"age":0.0,"tick":.0,"damage":6.0})
	if player_unit.position.distance_to(point)<1.55:hurt_player(10,"Spore burst")
	for i in 5:impact(point+Vector3(rng.randf_range(-1,1),.3,rng.randf_range(-1,1)),"d0a388")

func update_hazards(dt: float) -> void:
	for i in range(hazards.size()-1,-1,-1):
		var item := hazards[i];item.age+=dt;item.tick-=dt
		if item.tick<=0:
			item.tick=.7
			if player_unit.position.distance_to(item.node.position)<1.5:hurt_player(float(item.damage),"Spore pool")
		if item.age>2.6:item.node.queue_free();hazards.remove_at(i)

func number(amount: float, point: Vector3, color: String, incoming := false) -> void:
	if effects.size()>100:return
	var label := Label3D.new()
	label.text=("−" if incoming else "")+str(snappedf(amount,.1))
	label.font_size=40 if incoming else 30;label.pixel_size=.0033 if incoming else .003
	label.outline_size=8;label.modulate=Color(color);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label);label.position=point+Vector3(rng.randf_range(-.2,.2),0,0)
	effects.append({"node":label,"life":.8,"duration":.8,"label":true,"velocity":Vector3(rng.randf_range(-.15,.15),.8,0)})

func pulse(point: Vector3, radius: float, color: String, duration: float) -> void:
	if effects.size()>110:return
	var node := ring(radius,color,.7);node.position=point
	effects.append({"node":node,"life":duration,"duration":duration,"label":false,"velocity":Vector3.ZERO})

func impact(point: Vector3, color: String) -> void:
	if effects.size()>110:return
	for i in 3:
		var node := mesh_part(box(Vector3(.045,.045,.10)),material(color,.2),self,point)
		effects.append({"node":node,"life":.32,"duration":.32,"label":false,"velocity":Vector3(rng.randf_range(-1,1),rng.randf_range(.2,1.2),rng.randf_range(-1,1))})

func update_effects(dt: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var item := effects[i];item.life-=dt
		item.node.position+=item.velocity*dt
		if item.label:item.node.modulate.a=clampf(item.life/.25,0,1)
		else:item.node.scale=Vector3.ONE*maxf(.02,1-item.life/item.duration) if item.duration>.4 else Vector3.ONE*maxf(.02,item.life/item.duration)
		if item.life<=0:item.node.queue_free();effects.remove_at(i)

func spawn_pickup(point: Vector3, boss := false) -> void:
	var node := Node3D.new();add_child(node);node.position=point+Vector3.UP*.35
	var coin := CylinderMesh.new();coin.top_radius=.12;coin.bottom_radius=.12;coin.height=.055;coin.radial_segments=10
	mesh_part(coin,material("e8bc5c",.25),node,Vector3.ZERO).rotation.x=PI/2
	mesh_part(sphere(.08),material("8bd4bb",.35),node,Vector3(.23,0,0))
	pickups.append({"node":node,"gold":25 if boss else 3,"xp":50 if boss else 12})

func update_pickups(dt: float) -> void:
	for i in range(pickups.size()-1,-1,-1):
		var item := pickups[i]
		item.node.rotation.y+=dt*2
		if item.node.position.distance_to(player_unit.position)<2:
			item.node.position=item.node.position.move_toward(player_unit.position+Vector3.UP*.65,dt*9)
			if item.node.position.distance_to(player_unit.position+Vector3.UP*.65)<.3:
				gold+=item.gold;experience+=item.xp
				while experience>=level*60:experience-=level*60;level+=1
				item.node.queue_free();pickups.remove_at(i)

func update_camera(dt: float) -> void:
	camera_focus=camera_focus.lerp(player_unit.position+Vector3.UP,1-exp(-dt*7))
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.x/maxf(1,viewport_size.y)<.8
	camera.fov=65 if portrait else 52
	camera.position=camera_focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance*(1.12 if portrait else 1.0)
	camera.look_at(camera_focus)
	for unit in enemies+[player_unit]:
		if is_instance_valid(unit.hp_bar):unit.hp_bar.look_at(camera.global_position,Vector3.UP,true)

func snapshot() -> Dictionary:
	var boss: HuntUnit
	var statuses := {"fire":0,"ice":0,"poison":0}
	var enemy_states: Array = []
	for enemy in enemies:
		if enemy.kind=="briar-king" and enemy.hp>0:boss=enemy
		if enemy.fire_time>0:statuses.fire+=1
		if enemy.ice_time>0:statuses.ice+=1
		if enemy.poison_time>0:statuses.poison+=1
		enemy_states.append({"kind":enemy.kind,"hp":snappedf(enemy.hp,.1),"state":enemy.state,"clip":enemy.clip,"time":snappedf(enemy.action_time,.01),"x":snappedf(enemy.position.x,.01),"z":snappedf(enemy.position.z,.01),"poison":enemy.poison_stacks})
	return {"running":running,"paused":paused,"ended":ended,"victory":victory,"stage":stage,"time":snappedf(clock,.1),"hp":snappedf(player_unit.hp,.1),"maxHp":player_unit.maximum,"element":equipped,"elementPower":elemental_power,"auto":auto_fire,"dash":snappedf(dash_cooldown,.1),"salvo":snappedf(salvo_cooldown,.1),"invulnerable":invulnerable>0,"gold":gold,"xp":experience,"level":level,"xpNeeded":level*60,"kills":killed,"spawned":spawned,"alive":living_count(),"bossHp":boss.hp if is_instance_valid(boss) else 0,"bossMax":boss.maximum if is_instance_valid(boss) else 1200,"bossAction":boss.clip if is_instance_valid(boss) else "","shots":shots,"hits":hits,"petHits":pet_hits,"dotTicks":dot_ticks,"dealt":snappedf(dealt,.1),"taken":taken,"projectiles":projectiles.size(),"effects":effects.size(),"statuses":statuses,"enemies":enemy_states,"x":snappedf(player_unit.position.x,.01),"z":snappedf(player_unit.position.z,.01),"petDistance":snappedf(fox.position.distance_to(player_unit.position),.1),"fps":Engine.get_frames_per_second()}
