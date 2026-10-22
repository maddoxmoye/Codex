extends SceneTree
## Native-only regressions: title isolation, camera ownership, graphics budget and presentation lifetime.
var game: Node3D
var failures: Array[String] = []
func check(ok: bool, description: String) -> void:
	if not ok:failures.append(description);push_error(description)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false)
	var quality: String=game.graphics_preset
	var volume: float=game.master_volume
	game.native_hud.refresh()
	check(game.is_title and not game.running and game.enemies.size()==1,"Title stages the King without starting combat")
	check(not game.cast_dash() and not game.cast_salvo(),"Title cannot spend combat abilities")
	var clock: float=game.clock;game.simulate(1)
	check(game.clock==clock,"Title cannot advance combat")
	for preset in ["performance","balanced","high"]:
		game.set_graphics_preset(preset)
		var budget: float=800000 if preset=="performance" else 1440000 if preset=="balanced" else 2304000
		for pixels in [Vector2(1280,800),Vector2(2560,1600),Vector2(3840,2160)]:
			var scale: float=game.render_scale_for_size(pixels)
			check(scale>=.25 and scale<=1,"Supported render scale "+preset)
			check(pixels.x*pixels.y*scale*scale<=budget+1,"Retina/fullscreen respects 3D pixel budget "+preset)
	game.set_graphics_preset("unknown");check(game.graphics_preset=="balanced","Invalid graphics setting falls back to Balanced")
	game.set_master_volume(2);check(game.master_volume==1,"Audio slider clamps high")
	game.set_master_volume(-1);check(game.master_volume==0 and AudioServer.is_bus_mute(0),"Mute actually mutes the audio bus")
	game.begin_mode("tour");game.native_hud.refresh()
	check(game.tour_mode and game.enemies.is_empty() and not game.auto_fire,"Exploration starts without enemies or autofire")
	game.request={"move":[1,0]}
	var before: Vector3=game.player_unit.position
	for i in 30:game.simulate(1.0/60)
	check(game.player_unit.position.distance_to(before)>1.5,"Native exploration moves through the map")
	game.update_encounter(100)
	check(game.enemies.is_empty() and game.stage=="tour","Exploration stays peaceful beyond the normal wave timer")
	game.set_free_camera(true);game.native_drag=true;game.consume_command("pause");game.native_hud.refresh()
	check(game.paused and game.movement_input_blocked() and not game.native_drag,"Pause blocks motion and clears a held orbit drag")
	clock=game.clock;game.simulate(1);check(game.clock==clock,"Pause freezes native simulation")
	game.return_to_title();game.native_hud.refresh()
	check(game.is_title and not game.tour_mode and not game.running and game.projectiles.is_empty(),"Return to title clears exploration and combat")
	check(game.player_unit.motion_velocity.length()<.001 and game.fox.motion_velocity.length()<.001,"Return to title resets gait momentum")
	game.begin_mode("boss");game.native_hud.refresh()
	check(game.practice and game.enemies.size()==1 and game.enemies[0].kind=="briar-king","Native title starts the actual King encounter")
	check(not game.movement_input_blocked(),"Gameplay controls are released after title")
	game.native_drag=true;game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(game.paused and not game.native_drag,"Switching applications pauses safely and releases orbit")
	game.consume_command("pause");game.native_hud.refresh()
	game.native_fx.clear_transients()
	for i in 100:game.native_fx.burst(Vector3.ZERO,Color.WHITE)
	check(game.native_fx.bursts.size()==28,"Impact particles have a hard active-emitter cap")
	game.native_fx._process(1)
	check(game.native_fx.bursts.is_empty(),"Expired particle emitters are removed")
	game.cast_dash();game.begin_mode("start");game.native_hud.refresh()
	check(game.wave==1 and game.wave_left==45 and game.dash_cooldown==0 and game.salvo_cooldown==0,"Fresh hunt resets wave, cooldowns and ability state")
	check(not game.tour_mode and not game.practice and game.enemies.size()==4,"Hunt starts the expected full combat mode")
	game.set_free_camera(false);game.set_graphics_preset(quality);game.set_master_volume(volume)
	game.free()
	# Let the audio mix thread finish its scheduled stop/fade before engine exit.
	await create_timer(.15).timeout
	if failures.is_empty():print("EMBERWOOD_NATIVE_OK: mode flow, safe input/camera, Retina render budgets, audio controls, focus pause, bounded effects and reset")
	else:print("EMBERWOOD_NATIVE_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
