extends RefCounted
## Bought companions act independently inside a player-centered leash.
## Movement belongs to the arena; complete attack clips keep paws planted.
var game: Node3D
var actors: Array[HuntUnit] = []
var states: Array[Dictionary] = []
const KINDS := ["fox","wolf","beetle"]
const STOP_PHASES := ["shop","training","chest","chests","treasure","checkpoint","complete"]
const LEASH := 8.0
const RECALL := 11.5

func setup(target: Node3D) -> void:
	game=target

func reset() -> void:
	for unit in actors:
		if is_instance_valid(unit):unit.queue_free()
	actors.clear();states.clear()

func sync_build() -> void:
	if not is_instance_valid(game):return
	for i in range(states.size()-1,-1,-1):
		if float(game.run_stats.get(states[i].kind,0))<=0:
			var unit: HuntUnit=states[i].unit
			actors.erase(unit);unit.queue_free();states.remove_at(i)
	for kind in KINDS:
		if float(game.run_stats.get(kind,0))<=0:continue
		var found := false
		for state in states:
			if state.kind==kind:found=true;break
		if not found:add_pet(kind)

func add_pet(kind: String) -> Dictionary:
	var index := KINDS.find(kind)
	var offset := Vector3(-1.6+index*1.5,0,1.6)
	var unit: HuntUnit=game.make_unit(kind,game.clamp_position(game.player_unit.position+offset,.3))
	unit.reset_motion()
	if is_instance_valid(unit.hp_bar):unit.hp_bar.hide()
	var state := {"kind":kind,"unit":unit,"phase":"Roam","time":0.0,"cooldown":.3,"howl":3.0,"released":false,"target":null,"loot":null,"goal":unit.position,"roam_left":0.0,"lap":index*3,"collected":0,"bites":0,"howls":0,"volleys":0}
	actors.append(unit);states.append(state)
	return state

func update(dt: float) -> void:
	if not is_instance_valid(game) or dt<=0 or not game.running or game.paused or game.ended or game.is_title or game.stage in STOP_PHASES:return
	for state in states:
		var unit: HuntUnit=state.unit
		if not is_instance_valid(unit):continue
		state.time+=dt
		state.cooldown=maxf(0,float(state.cooldown)-dt)
		state.howl=maxf(0,float(state.howl)-dt)
		state.roam_left=maxf(0,float(state.roam_left)-dt)
		# Only an emergency recall interrupts a committed animation.
		if unit.position.distance_to(game.player_unit.position)>(maxf(RECALL,float(game.run_stats.collector_radius)+2) if state.kind=="beetle" else RECALL) and state.phase not in ["Return","Roam"]:
			enter(state,"Return")
		match state.kind:
			"fox":update_fox(state,dt)
			"wolf":update_wolf(state,dt)
			"beetle":update_beetle(state,dt)
		if is_instance_valid(unit.hp_bar):unit.hp_bar.hide()

func enter(state: Dictionary, phase: String) -> void:
	state.phase=phase;state.time=0.0;state.released=false
	var unit: HuntUnit=state.unit
	var clip := "Attack" if phase=="Shoot" else "Bite" if phase=="Bite" else "Howl" if phase=="Howl" else "Collect" if phase=="Collect" else "Deliver" if phase=="Deliver" else "Idle"
	unit.play(clip,true)
	unit.configure_motion(Vector3.ZERO,0)

func cadence() -> float:
	return maxf(.35,1-float(game.run_stats.get("pet_haste",0)))

func physical_damage() -> float:
	return float(game.run_stats.get("damage",22))*(1+float(game.run_stats.get("damage_bonus",0)))

func living_target(state: Dictionary) -> HuntUnit:
	var target=state.target
	if is_instance_valid(target) and target.hp>0 and target.position.distance_to(game.player_unit.position)<=LEASH+target.radius:return target
	return null

func choose_target(state: Dictionary, reach: float) -> HuntUnit:
	var unit: HuntUnit=state.unit
	var best := reach
	var chosen: HuntUnit
	for enemy in game.enemies:
		if enemy.hp<=0 or enemy.position.distance_to(game.player_unit.position)>LEASH+enemy.radius:continue
		var distance: float=unit.position.distance_to(enemy.position)
		if distance<best:best=distance;chosen=enemy
	return chosen

func walk(state: Dictionary, goal: Vector3, dt: float, speed: float, fly := false) -> bool:
	var unit: HuntUnit=state.unit
	goal=game.clamp_position(goal,unit.radius)
	var delta := goal-unit.position;delta.y=0
	if delta.length()<.13:
		unit.configure_motion(Vector3.ZERO,dt);unit.play("Idle");unit.pose(dt)
		unit.actor.position.y=move_toward(unit.actor.position.y,0,dt*2)
		return true
	var before := unit.position
	game.move_actor(unit,delta.normalized()*minf(speed*dt,delta.length()))
	unit.configure_motion((unit.position-before)/maxf(dt,.001),dt)
	var turn := atan2(delta.x,delta.z)-unit.base_aim
	unit.rotation.y=rotate_toward(unit.rotation.y,turn,2.8*dt)
	unit.play("Fly" if fly else "Crawl" if state.kind=="beetle" else "Trot")
	unit.pose(dt,1.6 if state.kind!="beetle" else 1.0)
	unit.actor.position.y=move_toward(unit.actor.position.y,.38 if fly else 0,dt*1.6)
	return unit.position.distance_to(goal)<.16

func hold(state: Dictionary, dt: float) -> void:
	var unit: HuntUnit=state.unit
	unit.configure_motion(Vector3.ZERO,dt);unit.pose(dt)
	unit.actor.position.y=move_toward(unit.actor.position.y,0,dt*2)

func roam(state: Dictionary, dt: float) -> void:
	var unit: HuntUnit=state.unit
	var player: Vector3=game.player_unit.position
	if state.roam_left<=0 or state.goal.distance_to(player)>5 or unit.position.distance_to(player)>7:
		state.lap+=1
		var angle := float(state.lap)*2.39996323
		state.goal=game.clamp_position(player+Vector3(cos(angle),0,sin(angle))*(2.0+float(int(state.lap)%3)*.45),unit.radius)
		state.roam_left=2.4
	var speed := 5.4 if unit.position.distance_to(player)>6 else 2.3 if state.kind=="beetle" else 3.5
	walk(state,state.goal,dt,speed,state.kind=="beetle" and unit.position.distance_to(player)>4)

func recall(state: Dictionary, dt: float) -> bool:
	var unit: HuntUnit=state.unit
	var near: Vector3=game.player_unit.position+Vector3(-1.2,0,1.3)
	walk(state,near,dt,7.5,state.kind=="beetle")
	if unit.position.distance_to(game.player_unit.position)<3.2:
		state.target=null;state.loot=null;enter(state,"Roam");return true
	return false

func update_fox(state: Dictionary, dt: float) -> void:
	var unit: HuntUnit=state.unit
	if state.phase=="Return":recall(state,dt);return
	if state.phase=="Shoot":
		var target := living_target(state)
		if is_instance_valid(target):unit.face(target.position,dt,5)
		hold(state,dt)
		if state.time>=.32 and not state.released:
			state.released=true
			if is_instance_valid(target):
				var muzzle := unit.socket("head",Vector3(0,.321,.014))
				var direction := (target.position+Vector3.UP*target.height*.47-muzzle).normalized()
				for spread in [-.12,0,.12]:game.spawn_bolt(muzzle,direction.rotated(Vector3.UP,spread),"pet",physical_damage()*.30,"dart")
				state.volleys+=1
		if state.time>=.85:state.cooldown=1.1*cadence();enter(state,"Roam")
		return
	var target := choose_target(state,9.0)
	if is_instance_valid(target):
		var away := (unit.position-target.position).normalized()
		if away.length()<.1:away=Vector3.BACK
		var goal := target.position+away*3.5
		var from_player: Vector3=goal-game.player_unit.position
		goal=game.player_unit.position+from_player.limit_length(5.5)
		walk(state,goal,dt,4.8)
		if state.cooldown<=0 and unit.position.distance_to(target.position)<=7.5:
			state.target=target;enter(state,"Shoot")
	else:roam(state,dt)

func update_wolf(state: Dictionary, dt: float) -> void:
	var unit: HuntUnit=state.unit
	if state.phase=="Return":recall(state,dt);return
	if state.phase=="Bite":
		hold(state,dt)
		if state.time>=.29 and not state.released:
			state.released=true
			var target := living_target(state)
			if is_instance_valid(target) and unit.position.distance_to(target.position)<=target.radius+unit.radius+.75:
				game.damage_enemy(target,physical_damage()*1.3*float(game.run_stats.get("pet_damage",1)),"physical","pet")
				state.bites+=1
		if state.time>=.8:state.cooldown=.8*cadence();enter(state,"Rest")
		return
	if state.phase=="Howl":
		hold(state,dt)
		if state.time>=.55 and not state.released:
			state.released=true;state.howls+=1
			game.pulse(unit.position+Vector3.UP*.06,3.8,"b6d9ee",.8)
			for enemy in game.enemies:
				if enemy.hp>0 and unit.position.distance_to(enemy.position)<=3.8+enemy.radius:
					enemy.slow_time=maxf(enemy.slow_time,2.0);enemy.slow_amount=maxf(enemy.slow_amount,.30)
		if state.time>=1.7:state.howl=6.0*cadence();enter(state,"Rest")
		return
	if state.phase=="Rest":
		hold(state,dt)
		if state.time>=.2:enter(state,"Roam")
		return
	var target := living_target(state)
	if not is_instance_valid(target):target=choose_target(state,9.0);state.target=target
	if not is_instance_valid(target):roam(state,dt);return
	var separation := target.radius+unit.radius+.18
	var away := (unit.position-target.position).normalized()
	if away.length()<.1:away=Vector3.BACK
	var goal := target.position+away*separation
	if state.howl<=0 and unit.position.distance_to(target.position)<3.8:
		enter(state,"Howl");return
	walk(state,goal,dt,5.3)
	if unit.position.distance_to(target.position)<=separation+.17 and state.cooldown<=0:
		var direction: Vector3=target.position-unit.position
		var desired := atan2(direction.x,direction.z)-unit.base_aim
		unit.rotation.y=rotate_toward(unit.rotation.y,desired,3.4*dt)
		if absf(angle_difference(unit.rotation.y,desired))<.22:enter(state,"Bite")

func loot_index(node: Node) -> int:
	if not is_instance_valid(node):return -1
	for i in game.pickups.size():
		if game.pickups[i].node==node and (float(game.pickups[i].get("gold",0))>0 or float(game.pickups[i].get("xp",0))>0):return i
	return -1

func choose_loot(state: Dictionary) -> Node3D:
	var unit: HuntUnit=state.unit
	var limit := float(game.run_stats.get("collector_radius",7.5))
	var best := INF
	var target: Node3D
	for item in game.pickups:
		if float(item.get("gold",0))<=0 and float(item.get("xp",0))<=0:continue
		if item.node.position.distance_to(game.player_unit.position)>limit:continue
		var distance: float=unit.position.distance_to(item.node.position)
		if distance<best:best=distance;target=item.node
	return target

func update_beetle(state: Dictionary, dt: float) -> void:
	var unit: HuntUnit=state.unit
	if state.phase=="Return":recall(state,dt);return
	if state.phase=="Collect":
		hold(state,dt)
		if state.time>=.48 and not state.released:
			state.released=true
			var index := loot_index(state.loot)
			if index>=0 and unit.position.distance_to(game.pickups[index].node.position)<.85:
				game.collect_pickup(index);state.collected+=1
				game.pulse(unit.position+Vector3.UP*.13,.45,"efc366",.4)
			state.loot=null
		if state.time>=1.0:enter(state,"Home")
		return
	if state.phase=="Home":
		var home: Vector3=game.player_unit.position+Vector3(.9,0,.8)
		if walk(state,home,dt,6.5,true):enter(state,"Deliver")
		return
	if state.phase=="Deliver":
		hold(state,dt)
		if state.time>=.75:enter(state,"Roam")
		return
	var index := loot_index(state.loot)
	if index<0:state.loot=choose_loot(state);index=loot_index(state.loot)
	if index<0:roam(state,dt);return
	var target: Vector3=game.pickups[index].node.position;target.y=0
	if target.distance_to(game.player_unit.position)>float(game.run_stats.get("collector_radius",7.5)):
		state.loot=null;enter(state,"Return");return
	if walk(state,target,dt,6.5,true):enter(state,"Collect")
