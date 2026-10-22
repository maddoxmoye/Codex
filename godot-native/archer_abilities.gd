extends RefCounted
## One timeline for all approved roster clips. Gameplay events use metadata release
## markers; movement remains independent of the upper-body action.
var game: Node3D
var defense_left := 0.0
var defense_elapsed := 0.0
var offense_left := 0.0
var offense_elapsed := 0.0
var release_index := 0
var defense_fired := false
func setup(target: Node3D) -> void:game=target
func reset() -> void:
	defense_left=0;defense_elapsed=0;offense_left=0;offense_elapsed=0;release_index=0;defense_fired=false
func cast(slot: String) -> bool:
	if not game.running or game.paused or game.ended or game.stage not in ["skirmish","boss","test","tour"]:return false
	var info: Dictionary=game.archer
	if slot=="space":
		if game.dash_cooldown>0:return false
		game.dash_cooldown=float(info.spaceCooldown)*(1-float(game.run_stats.haste))
		defense_left=float(info.spaceDuration);defense_elapsed=0;defense_fired=false
		game.invulnerable=maxf(game.invulnerable,float(info.defense.invulnerability))
	else:
		if game.salvo_cooldown>0:return false
		game.salvo_cooldown=float(info.attackCooldown)*(1-float(game.run_stats.haste))
		offense_left=maxf(float(info.attackDuration),float(info.clips[info.attack]) if float(info.attackDuration)==0 else 0)
		offense_elapsed=0;release_index=0
	game.shooting=false;game.nocked.visible=false;game.player_unit.play(info[slot],true)
	game.pulse(game.player_unit.position+Vector3.UP*.08,1.3,info.color,.4)
	return true
func speed_multiplier() -> float:
	return float(game.archer.get("defense",{}).get("speed",1)) if defense_left>0 else 1.0
func slow_at(point: Vector3) -> float:
	var info: Dictionary=game.archer.get("defense",{})
	return 1-float(info.get("slow",0)) if defense_left>0 and point.distance_to(game.player_unit.position)<float(info.get("radius",0)) else 1.0
func update(dt: float, aim: Vector3) -> bool:
	if game.selected_archer=="rowan":return false
	var info: Dictionary=game.archer
	var had_defense := defense_left>0
	if had_defense:
		defense_left=maxf(0,defense_left-dt);defense_elapsed+=dt
		if not defense_fired and defense_elapsed>=.2:
			defense_fired=true
			var radius: float=float(info.defense.get("repel",0))
			if radius>0:
				for enemy in game.enemies:
					if enemy.hp>0 and enemy.position.distance_to(game.player_unit.position)<radius:game.move_actor(enemy,(enemy.position-game.player_unit.position).normalized()*3)
				for i in range(game.projectiles.size()-1,-1,-1):
					var shot: Dictionary=game.projectiles[i]
					if shot.owner=="enemy" and shot.node.position.distance_to(game.player_unit.position)<radius:shot.node.queue_free();game.projectiles.remove_at(i)
			game.pulse(game.player_unit.position+Vector3.UP*.05,maxf(radius,1.5),info.color,.5)
		if int(defense_elapsed*10)!=int((defense_elapsed-dt)*10):game.pulse(game.player_unit.position+Vector3.UP*.07,.65,info.color,.18)
	if offense_left>0:
		offense_left=maxf(0,offense_left-dt);offense_elapsed+=dt
		var profile: Dictionary=info.offense
		var cycle: float=float(profile.cycle)
		var rate: float=float(info.attackCycle)/cycle if cycle>0 else 1.0
		game.player_unit.play(info.attack)
		# Repeating skills reuse the authored draw cycle without restarting blends.
		game.player_unit.anim_time=fposmod(offense_elapsed-dt,cycle)*rate if cycle>0 else offense_elapsed-dt
		game.player_unit.pose(dt,rate)
		var release: float=cycle*float(info.releaseTime)/float(info.clips.Shoot) if cycle>0 else float(info.burstReleaseTime)
		while offense_elapsed>=release+release_index*cycle and (release_index==0 or cycle>0):
			if cycle>0 and release+release_index*cycle>=float(info.attackDuration):break
			emit(profile,aim);release_index+=1
			if cycle<=0:break
		return true
	if had_defense and (defense_elapsed<.4 or not game.auto_fire):
		game.player_unit.play(info.space)
		game.player_unit.anim_time=maxf(0,defense_elapsed-dt);game.player_unit.pose(dt)
		return true
	return false
func emit(profile: Dictionary, aim: Vector3) -> void:
	var start: Vector3=game.player_unit.socket("bowstring")
	var direction := (aim-start).normalized()
	var count: int=int(profile.count)
	for i in count:
		var angle: float=TAU*i/count if bool(profile.get("radial",false)) else (i-(count-1)*.5)*.11
		game.fire_arrow(start,direction.rotated(Vector3.UP,angle),"player",float(profile.damage),true)
	var radius: float=float(profile.get("blast",0))
	if radius>0:
		game.pulse(game.player_unit.position+Vector3.UP*.1,radius,game.archer.color,.6)
		for enemy in game.enemies:
			if enemy.hp>0 and enemy.position.distance_to(game.player_unit.position)<radius:game.damage_enemy(enemy,float(game.run_stats.damage)*1.5,"physical","ability")
