extends SceneTree
func _init() -> void:call_deferred("validate")
func validate() -> void:
	var stage = load("res://bestiary.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	var failures: Array[String] = []
	for id in ["sporecaller","thornback","hollowhart"]:
		stage.select_model(id)
		var enemy = stage.models[id]
		if enemy.skeleton.get_bone_count()!=int(enemy.metadata.bones):failures.append(id+" incorrect joint count")
		for clip in ["Idle","Run","Attack","Hit","Death"]:
			if not enemy.player.has_animation(clip):failures.append(id+" missing "+clip)
			enemy.player.stop()
			enemy.player.play(clip,0)
			enemy.player.advance(0)
			enemy.player.seek(0,true)
			var before: Array = []
			for i in enemy.skeleton.get_bone_count():before.append(enemy.skeleton.get_bone_pose(i))
			enemy.player.seek(float(enemy.metadata.clips[clip])*0.4,true)
			var changed := false
			for i in enemy.skeleton.get_bone_count():
				if not enemy.skeleton.get_bone_pose(i).is_equal_approx(before[i]):changed = true
			if not changed:failures.append(id+" static "+clip+" clip")
		for dt in [0.016,0.1]:
			enemy.command("Reset")
			enemy.command("Attack")
			var contacts: int = enemy.contacts
			var releases: int = enemy.releases
			for i in range(int((float(enemy.metadata.clips.Attack)+0.9)/dt)):enemy.advance_simulation(dt)
			if enemy.contacts-contacts!=1:failures.append(id+" attack must land exactly once at "+str(dt))
			if id=="sporecaller" and enemy.releases-releases!=1:failures.append("Spore launch must occur once")
			if enemy.clip!="Idle":failures.append(id+" does not recover to idle")
			enemy.command("Reset")
			enemy.command("Attack")
			enemy.advance_simulation(0.15)
			contacts = enemy.contacts
			enemy.take_damage(int(enemy.metadata.arrowDamage))
			for i in range(int(3.0/dt)):enemy.advance_simulation(dt)
			if enemy.contacts!=contacts:failures.append(id+" interrupted windup still hits")
			enemy.command("Reset")
			for hit in 3:
				if not enemy.command("Arrow"):failures.append(id+" ready arrow rejected")
				for i in range(int((float(enemy.metadata.clips.Hit)+0.6)/dt)):enemy.advance_simulation(dt)
				var expected: int = int(enemy.metadata.health)-(hit+1)*int(enemy.metadata.arrowDamage)
				if enemy.hp!=expected:failures.append(id+" arrow does not physically hit at "+str(dt))
			if enemy.hp!=0 or enemy.clip!="Death" or enemy.command("Arrow"):failures.append(id+" defeat gating broken")
			enemy.command("Reset")
			enemy.command("Hold")
			var time: float = enemy.phase
			enemy.advance_simulation(0.1)
			if enemy.phase!=time or not enemy.paused:failures.append(id+" hold windup does not freeze")
			enemy.paused = false
			contacts = enemy.contacts
			for i in range(int(4.0/dt)):enemy.advance_simulation(dt)
			if enemy.contacts-contacts!=1:failures.append(id+" resumed held attack does not land once")
		if id=="sporecaller":
			enemy.player.stop()
			enemy.player.play("Run",0)
			enemy.player.advance(0)
			for time in [0.0,0.15,0.33,0.55,0.88]:
				enemy.player.seek(time,true)
				for side in ["L","R"]:
					var foot: Transform3D = enemy.skeleton.global_transform*enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("foot."+side))
					if foot.origin.y<0.21:failures.append("Sporecaller foot sinks below its rest contact height")
			enemy.command("Reset")
			enemy.command("Attack")
			for i in 50:enemy.advance_simulation(0.016)
			if not is_instance_valid(enemy.blob):failures.append("Spore has no visible flight after release")
			var point: Vector3 = enemy.blob.position if is_instance_valid(enemy.blob) else Vector3.ZERO
			enemy.paused = true
			enemy.advance_simulation(0.1)
			if is_instance_valid(enemy.blob) and enemy.blob.position!=point:failures.append("Paused spore still moves")
			enemy.paused = false
			var contacts: int = enemy.contacts
			enemy.take_damage(int(enemy.metadata.arrowDamage))
			for i in 100:enemy.advance_simulation(0.016)
			if enemy.contacts-contacts!=1:failures.append("Already launched spore is incorrectly cancelled by caster recoil")
		if id=="thornback":
			enemy.player.stop()
			enemy.player.play("Death",0)
			enemy.player.advance(0)
			enemy.player.seek(float(enemy.metadata.clips.Death),true)
			var body_pose: Transform3D = enemy.skeleton.global_transform*enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("body"))
			if body_pose.origin.y>0.45:failures.append("Thornback defeat must lower the body toward the ground")
			enemy.command("Reset")
			enemy.command("Attack")
			for i in 13:enemy.advance_simulation(0.1)
			if absf(enemy.actor.position.z-float(enemy.metadata.chargeDistance))>0.05:failures.append("Charge has no correct root displacement")
		if id=="hollowhart":
			enemy.player.stop()
			enemy.player.play("Attack",0)
			enemy.player.advance(0)
			enemy.player.seek(0.9,true)
			var raised: Vector3 = enemy.socket_point("handL")
			enemy.player.seek(float(enemy.metadata.attackContact),true)
			var struck: Vector3 = enemy.socket_point("handL")
			if raised.y-struck.y<1.0 or struck.y>0.20:failures.append("Guardian fists do not reach a ground slam from overhead")
		enemy.command("Reset")
		enemy.command("Demo")
		for i in 3600:enemy.advance_simulation(0.016)
		if enemy.effects.size()>60 or enemy.shockwaves.size()>2:failures.append(id+" effects grow without bounds")
		print("SPECIES_MOTION_CHECK: ",id," ",enemy.skeleton.get_bone_count()," bones")
	for size in [Vector2i(1280,900),Vector2i(390,844)]:
		root.size = size
		stage.attack_view = true
		for id in ["sporecaller","thornback","hollowhart"]:
			stage.select_model(id)
			stage.update_camera(1.0)
			var z := 3.25 if id=="sporecaller" else 3.35 if id=="thornback" else 3.05
			var screen: Vector2 = stage.camera.unproject_position(Vector3(0,0.03,z))
			if screen.y>size.y*0.70 or screen.y<0:failures.append(id+" ground warning hidden behind review controls at "+str(size))
	stage.select_model("lineup")
	for id in stage.models:
		if stage.models[id].active or stage.models[id].hp_root.visible:failures.append(id+" controller leaks into static lineup")
	for error in failures:push_error(error)
	print("OTHER_MONSTERS_VALIDATION: ","PASS" if failures.is_empty() else "FAIL")
	stage.free()
	quit(0 if failures.is_empty() else 1)
