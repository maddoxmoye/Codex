extends SceneTree
## Exercises the native UI against live arena state, including real callbacks.
var game: Node3D
var hud: CanvasLayer
var failures: Array[String]=[]
var assertions:=0
var original_quality: String
var original_volume: float

func _initialize() -> void:call_deferred("run")

func check(ok: bool, message: String) -> void:
	assertions+=1
	if not ok:failures.append(message);push_error(message)

func buttons(node: Node, prefix: String="") -> Array[Button]:
	var matches: Array[Button]=[]
	if node is Button and node.is_visible_in_tree() and node.text.begins_with(prefix):matches.append(node)
	for child in node.get_children():matches.append_array(buttons(child,prefix))
	return matches

func click(prefix: String) -> void:
	var matches:=buttons(hud.ui,prefix)
	check(not matches.is_empty(),"Visible button exists: "+prefix)
	if matches.is_empty():return
	var selected: Button=matches[0]
	check(not selected.disabled,"Button enabled: "+prefix)
	selected.pressed.emit()

func settle() -> void:
	for i in 4:await process_frame
	hud.refresh()

func check_horizontal_bounds(node: Node, viewport_width: float) -> void:
	if node is Control and node.is_visible_in_tree() and (node is Button or node is Label or node is ProgressBar):
		var rect: Rect2=node.get_global_rect()
		check(rect.position.x>=-1 and rect.end.x<=viewport_width+1,"Control fits horizontal viewport: "+node.name)
	for child in node.get_children():check_horizontal_bounds(child,viewport_width)

func run() -> void:
	game=load("res://arena.tscn").instantiate();root.add_child(game);game.set_process(false)
	hud=game.native_hud
	original_quality=game.graphics_preset;original_volume=game.master_volume
	await settle()
	check(game.is_title and hud.title_layer.visible and not hud.hud.visible,"Title opens over the native scene")
	check(hud.captures_movement_input() and hud.captures_gameplay_input(),"Title blocks combat input")
	click("Settings");await settle()
	check(hud.current_modal=="settings" and hud.settings_open,"Title settings opens without starting combat")
	click("Performance");check(game.graphics_preset=="performance" and hud.current_preset=="performance","Graphics selection updates renderer and display")
	game.set_master_volume(.42);hud.refresh();check(is_equal_approx(hud.current_volume,.42),"Saved sound state is reflected in native UI")
	click("Back");await settle();check(not hud.settings_open and game.is_title,"Back returns to title")
	click("Face the Briar King");await settle()
	check(game.practice and game.running and not game.is_title,"Primary title button starts boss practice")
	check(not hud.captures_movement_input() and not hud.modal_layer.visible,"Gameplay movement unblocked after leaving title")
	check(root.gui_get_focus_owner()==null,"Starting combat releases keyboard focus")
	hud.salvo_button.grab_focus();click("E  Flock");check(root.gui_get_focus_owner()==null,"HUD ability clicks release keyboard focus for Space dash")
	click("Pause");await settle();check(game.paused and hud.current_modal=="pause","Pause button opens stats and inventory")
	click("Settings");await settle();check(game.paused and hud.current_modal=="settings","Settings preserves paused game")
	click("Back");await settle();check(game.paused and hud.current_modal=="pause","Closing settings restores pause menu")
	click("Resume");await settle();check(not game.paused and not hud.modal_layer.visible,"Resume returns to combat")
	hud.open_settings();await settle();check(game.paused and hud.settings_resume,"Direct gameplay settings pauses the arena")
	hud.close_settings();await settle();check(not game.paused,"Closing directly opened settings resumes the arena")
	hud._return_title();await settle();click("Visit the trader");await settle()
	check(game.stage=="training" and hud.current_modal=="training","Trader preview starts with its own level reward screen")
	check(buttons(hud.modal_panel,"Choose").size()==4,"Level reward presents four independent choices")
	var coins: int=game.gold
	click("Choose");await settle();check(game.stage=="shop" and game.gold==coins,"Free choice advances to shop without spending gold")
	check(hud.current_modal=="shop" and buttons(hud.modal_panel,"Choose").is_empty(),"Shop replaces the separate reward menu")
	game.gold=500;hud.refresh();await settle()
	var history_size: int=game.build.history.size()
	var purchase_buttons:=buttons(hud.modal_panel,"Buy item")
	check(not purchase_buttons.is_empty(),"Shop has purchasable stock")
	if not purchase_buttons.is_empty():purchase_buttons[0].pressed.emit()
	await settle();check(game.gold<500 and game.build.history.size()==history_size+1,"Purchase button charges coins and equips an item")
	check(buttons(hud.modal_panel,"Packed").size()==1,"Purchased slot remains visibly sold")
	var before_reroll: int=game.build.reroll_price();click("Reroll");await settle()
	check(game.build.reroll_price()>before_reroll,"Reroll button increases this visit's price")
	# The canvas scales to the window; validate at both supported desktop sizes.
	for window_size in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=window_size;hud.layout();await settle()
		check_horizontal_bounds(hud.ui,root.get_visible_rect().size.x)
		check(hud.modal_panel.get_global_rect().end.y<=root.get_visible_rect().size.y+1,"Shop panel fits window height")
	click("Enter wave");await settle();check(game.wave==2 and not hud.modal_layer.visible,"Shop continue starts the next wave")
	hud._return_title();await settle();click("Explore the ruins");await settle()
	check(game.tour_mode and not hud.boss_box.visible and hud.tour_buttons.visible,"Exploration has its own HUD and navigation")
	click("Return to title");await settle();check(game.is_title,"Exploration returns to title")
	game.set_graphics_preset(original_quality);game.set_master_volume(original_volume)
	game.free();await create_timer(.15).timeout
	if failures.is_empty():print("NATIVE_HUD_OK: ",assertions," assertions; title, input, settings, rewards, purchases, rerolls, pause, exploration and desktop layout")
	else:print("NATIVE_HUD_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
