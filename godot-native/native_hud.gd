extends CanvasLayer
## Native game UI. All purchases and progression remain validated by the arena.
const INK := Color("101917")
const PANEL := Color("17211f")
const IVORY := Color("eee9dc")
const GOLD := Color("dcc58b")
const MUTED := Color("a0b0a6")
const LINE := Color("405149")
const SHOP_PANEL := Color("d6d1c7")
const SHOP_INK := Color("242525")
const SHOP_MUTED := Color("686760")
const SHOP_LINE := Color("aaa59a")
const SHOP_GOLD := Color("b17f2f")
const SHOP_GAIN := Color("9ee06d")
const SHOP_LOSS := Color("ff8a7a")
const SHOP_CARD_TEXT := Color("f6f2e9")
const SHOP_CARD_MUTED := Color("d8d4cc")
const SHOP_STATS_PANEL := Color("25292d")
const SHOP_STATS_LINE := Color("4b5055")
const SHOP_RARITIES := {"common":Color("626873"),"uncommon":Color("2f7658"),"rare":Color("65458d"),"mythic":Color("8e3f36")}
const SHOP_RARITY_BORDERS := {"common":Color("c7ccd2"),"uncommon":Color("76d3a3"),"rare":Color("c49bf1"),"mythic":Color("ff8b70")}
const ELEMENTS := {"physical":Color("dfd4b3"),"fire":Color("f17960"),"ice":Color("78cce6"),"poison":Color("b189df")}
const RARITIES := {"common":Color("acb9af"),"uncommon":Color("8dc4ad"),"rare":Color("bca8df"),"mythic":Color("f36862")}
var game: Node3D
var ui: Control
var hud: Control
var title_layer: Control
var modal_layer: Control
var modal_panel: PanelContainer
var title_box: VBoxContainer
var modal_content: VBoxContainer
var title_footer: Label
var hp_text: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var xp_text: Label
var element_text: Label
var gold_text: Label
var wave_text: Label
var timer_text: Label
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var boss_text: Label
var dash_button: Button
var salvo_button: Button
var fps_text: Label
var objective_text: Label
var element_buttons := {}
var controls_text: Label
var tour_buttons: HBoxContainer
var serif_font: Font
var body_font: Font
var settings_open := false
var settings_resume := false
var poll_time := 0.0
var last_modal_key := ""
var current_modal := ""
var current_state: Dictionary = {}
var current_preset := "balanced"
var current_volume := .7
var texture_cache := {}

func setup(target: Node3D) -> void:
	game=target;layer=20
	serif_font=load("res://assets/ui/DejaVuSerif.ttf")
	body_font=load("res://assets/ui/DejaVuSans.ttf")
	ui=Control.new();add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new();ui_theme.default_font=body_font;ui_theme.default_font_size=15;ui.theme=ui_theme
	build_hud();build_title();build_modal_root()
	get_viewport().size_changed.connect(layout)
	layout();refresh()
	set_process(true)

func box_style(color: Color, border: Color=LINE, padding:=18.0, radius:=8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new();style.bg_color=color
	style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(radius)
	style.content_margin_left=padding;style.content_margin_right=padding;style.content_margin_top=padding;style.content_margin_bottom=padding
	return style

func label(value: String, size:=16, color: Color=IVORY, serif:=false) -> Label:
	var node := Label.new();node.text=value;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color)
	node.add_theme_font_override("font",serif_font if serif else body_font);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func paragraph(value: String, size:=15, color: Color=MUTED) -> Label:
	var node := label(value,size,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return node

func button(value: String, callback: Callable, primary:=false, light:=false) -> Button:
	var node := Button.new();node.text=value;node.custom_minimum_size=Vector2(0,44);node.mouse_filter=Control.MOUSE_FILTER_STOP
	node.add_theme_font_size_override("font_size",14)
	var bg: Color=IVORY if primary else Color("e2ded3") if light else Color("1b2924")
	var fg: Color=INK if primary or light else IVORY
	node.add_theme_color_override("font_color",fg);node.add_theme_color_override("font_hover_color",fg);node.add_theme_color_override("font_pressed_color",fg)
	node.add_theme_color_override("font_disabled_color",Color(fg,.38))
	node.add_theme_stylebox_override("normal",box_style(bg,Color("a6aa98") if primary or light else LINE,14,6))
	node.add_theme_stylebox_override("hover",box_style(bg.lightened(.10),GOLD,14,6))
	node.add_theme_stylebox_override("pressed",box_style(bg.darkened(.12),GOLD,14,6))
	node.add_theme_stylebox_override("disabled",box_style(Color(bg,.5),Color(LINE,.5),14,6))
	node.add_theme_stylebox_override("focus",box_style(Color(0,0,0,0),GOLD,0,6))
	node.pressed.connect(callback)
	return node

func row(gap:=12) -> HBoxContainer:
	var node := HBoxContainer.new();node.add_theme_constant_override("separation",gap);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func column(gap:=12) -> VBoxContainer:
	var node := VBoxContainer.new();node.add_theme_constant_override("separation",gap);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func divider(color: Color=LINE) -> HSeparator:
	var node := HSeparator.new();var style := StyleBoxLine.new();style.color=color;style.thickness=1;node.add_theme_stylebox_override("separator",style)
	return node

func flex() -> Control:
	var node := Control.new();node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func make_bar(color: Color, height:=8) -> ProgressBar:
	var node := ProgressBar.new();node.show_percentage=false;node.custom_minimum_size.y=height;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("background",box_style(Color("081310"),Color("33473e"),0,2))
	node.add_theme_stylebox_override("fill",box_style(color,color,0,2));node.max_value=100;node.value=100
	return node

func anchored(parent: Control, preset: int, offsets: Rect2) -> Control:
	var node := Control.new();parent.add_child(node);node.set_anchors_and_offsets_preset(preset);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.offset_left=offsets.position.x;node.offset_top=offsets.position.y;node.offset_right=offsets.end.x;node.offset_bottom=offsets.end.y
	return node

func build_hud() -> void:
	hud=Control.new();ui.add_child(hud);hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top := anchored(hud,Control.PRESET_TOP_WIDE,Rect2(30,24,-60,50));var top_row := row();top.add_child(top_row);top_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var brand := column(2);brand.add_child(label("W I L D F A L L",18,GOLD,true));brand.add_child(label("T H E   E M B E R W O O D",8,MUTED));top_row.add_child(brand)
	top_row.add_child(flex())
	var gold_chip := row(6);top_row.add_child(gold_chip);gold_chip.add_child(coin_icon(30))
	gold_text=label("0",25,GOLD,true);gold_chip.add_child(gold_text)
	top_row.add_child(button("Pause  Ⅱ",func():_send("pause")))
	var fullscreen := button("⛶",toggle_fullscreen);fullscreen.tooltip_text="Toggle fullscreen · F11";top_row.add_child(fullscreen)
	var mission := anchored(hud,Control.PRESET_CENTER_TOP,Rect2(-260,24,520,88));var mission_column := column(3);mission.add_child(mission_column);mission_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_text=label("WAVE 1 / THE CLEARING",10,GOLD);wave_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mission_column.add_child(wave_text)
	timer_text=label("0:45",31,IVORY,true);timer_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mission_column.add_child(timer_text)
	objective_text=label("Survive the woodland",11,MUTED);objective_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mission_column.add_child(objective_text)
	var boss_anchor := anchored(hud,Control.PRESET_CENTER_TOP,Rect2(-255,120,510,68));boss_box=column(5);boss_anchor.add_child(boss_box);boss_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var boss_name := label("THE BRIAR KING",16,IVORY,true);boss_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;boss_box.add_child(boss_name)
	boss_bar=make_bar(Color("c9ac75"),7);boss_box.add_child(boss_bar);boss_text=label("A crown of thorns",9,MUTED);boss_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;boss_box.add_child(boss_text)
	var vitals_anchor := anchored(hud,Control.PRESET_BOTTOM_LEFT,Rect2(30,-173,335,132));var vitals_panel := PanelContainer.new();vitals_anchor.add_child(vitals_panel);vitals_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);vitals_panel.add_theme_stylebox_override("panel",box_style(Color("101c17e8"),Color("67725877"),18,8));vitals_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var vitals := column(6);vitals_panel.add_child(vitals);var name_row := row();vitals.add_child(name_row);player_name=label("Rowan",24,IVORY,true);name_row.add_child(player_name);name_row.add_child(flex());hp_text=label("140 / 140",13,IVORY);name_row.add_child(hp_text)
	hp_bar=make_bar(Color("a5c694"),9);vitals.add_child(hp_bar);element_text=label("FIRE ARROWS · POWER 8",10,GOLD);vitals.add_child(element_text)
	xp_bar=make_bar(Color("73b7a5"),4);vitals.add_child(xp_bar);xp_text=label("LEVEL 1 · 0 / 60 XP",10,MUTED);vitals.add_child(xp_text)
	var skills_anchor := anchored(hud,Control.PRESET_BOTTOM_RIGHT,Rect2(-395,-173,365,132));var skills_column := column(8);skills_anchor.add_child(skills_column);skills_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var skills_row := row(8);skills_column.add_child(skills_row);dash_button=button("SPACE  Windskip",func():_send("dash"));dash_button.custom_minimum_size=Vector2(176,54);skills_row.add_child(dash_button);salvo_button=button("E  Flock & Awe",func():_send("salvo"));salvo_button.custom_minimum_size=Vector2(176,54);skills_row.add_child(salvo_button)
	fps_text=label("",10,MUTED);fps_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;skills_column.add_child(fps_text)
	var footer := anchored(hud,Control.PRESET_BOTTOM_WIDE,Rect2(30,-29,-60,22));controls_text=label("WASD Move    Space Dash    E Salvo    Right-drag Orbit    Scroll Zoom    Esc Pause",11,Color("afc0ad"));footer.add_child(controls_text);controls_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);controls_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var tour_anchor := anchored(hud,Control.PRESET_CENTER_BOTTOM,Rect2(-250,-104,500,48));tour_buttons=row();tour_anchor.add_child(tour_buttons);tour_buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tour_buttons.alignment=BoxContainer.ALIGNMENT_CENTER
	tour_buttons.add_child(button("Face the King",_begin.bind("boss"),true));tour_buttons.add_child(button("Return to title",_return_title))

var selection_detail: VBoxContainer
var selection_buttons := {}
var player_name: Label

func archer_portrait(id: String, parent: Control) -> SubViewportContainer:
	var holder := SubViewportContainer.new();holder.custom_minimum_size=Vector2(120,240);holder.stretch=true
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(holder)
	var viewport := SubViewport.new();viewport.size=Vector2i(220,220);viewport.transparent_bg=true
	viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;holder.add_child(viewport)
	var actor := HuntUnit.new();viewport.add_child(actor);actor.configure(id);actor.pose(.4);actor.rotation.y=-.25
	var light := DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.4;viewport.add_child(light)
	var fill := WorldEnvironment.new();fill.environment=Environment.new();fill.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;fill.environment.ambient_light_color=Color("fff1d6");fill.environment.ambient_light_energy=.7;viewport.add_child(fill)
	var camera := Camera3D.new();viewport.add_child(camera);camera.position=Vector3(0,1.35,3.8);camera.look_at(Vector3(0,1.05,0));camera.fov=34
	return holder

func build_title() -> void:
	title_layer=Control.new();ui.add_child(title_layer);title_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new();shade.color=SHOP_PANEL;title_layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new();title_layer.add_child(scroll);scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.offset_left=40;scroll.offset_right=-40;scroll.offset_top=24;scroll.offset_bottom=-24;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	title_box=column(14);title_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(title_box)
	var heading := row();title_box.add_child(heading);heading.add_child(label("Wildfall",40,SHOP_INK,true));heading.add_child(flex());heading.add_child(label("THE EMBERWOOD   /   CHOOSE YOUR ARCHER",12,SHOP_MUTED))
	title_box.add_child(divider(SHOP_LINE))
	var cards := row(14);title_box.add_child(cards)
	for id in game.Archers.IDS:
		var info: Dictionary=game.Archers.get_archer(id)
		var card := PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.size_flags_stretch_ratio=1;cards.add_child(card)
		card.add_theme_stylebox_override("panel",box_style(Color("e7e2d8"),Color(info.color),12,9))
		var stack := column(5);card.add_child(stack);archer_portrait(id,stack)
		var select := button(info.name,select_character.bind(id),false,true);select.name="Select_"+id;select.add_theme_font_size_override("font_size",21);stack.add_child(select);selection_buttons[id]=select
		var role := label(info.role,12,SHOP_MUTED);role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;stack.add_child(role)
	selection_detail=column(12);title_box.add_child(selection_detail);update_character_detail()
	var controls := row();title_box.add_child(controls)
	var start := button("Start Run",_begin.bind("start"),true,true);start.custom_minimum_size=Vector2(250,52);start.add_theme_stylebox_override("normal",box_style(SHOP_INK,SHOP_GOLD,14,6));start.add_theme_color_override("font_color",IVORY);controls.add_child(start);controls.add_child(flex())
	for pair in [["Explore the ruins","tour"],["Visit the trader","camp"],["Face the Briar King","boss"]]:controls.add_child(button(pair[0],_begin.bind(pair[1]),false,true))
	controls.add_child(button("Settings",open_settings,false,true));controls.add_child(button("Quit",func():get_tree().quit(),false,true))
	title_footer=label("WASD move   ·   Space defense   ·   E special   ·   Right-drag orbit   ·   F11 fullscreen",12,SHOP_MUTED);title_box.add_child(title_footer)

func select_character(id: String) -> void:
	if game.select_archer(id):update_character_detail()

func update_character_detail() -> void:
	for child in selection_detail.get_children():selection_detail.remove_child(child);child.queue_free()
	var info: Dictionary=game.archer
	for id in selection_buttons:
		selection_buttons[id].text=("✓  " if id==game.selected_archer else "")+game.Archers.get_archer(id).name
		selection_buttons[id].add_theme_stylebox_override("normal",box_style(Color(info.color) if id==game.selected_archer else Color("e2ded3"),Color("55554d"),12,6))
	var detail := row(24);selection_detail.add_child(detail)
	var identity := column(5);identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_child(identity)
	identity.add_child(label(info.name+"  /  "+info.role,24,SHOP_INK,true));identity.add_child(paragraph(info.description,14,SHOP_MUTED))
	identity.add_child(paragraph("Basic arrows · No companion yet. Discover elemental quivers and pets at the trader.",13,SHOP_MUTED))
	for slot in ["space","attack"]:
		var ability := column(6);ability.custom_minimum_size.x=280;ability.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_child(ability)
		ability.add_child(label(("SPACE  /  " if slot=="space" else "E  /  ")+info[slot+"Name"],17,SHOP_INK,true))
		ability.add_child(paragraph(info[slot+"Detail"],14,SHOP_MUTED));ability.add_child(label("%s second cooldown"%number(info[slot+"Cooldown"]),12,SHOP_MUTED))

func build_modal_root() -> void:
	modal_layer=Control.new();ui.add_child(modal_layer);modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);modal_layer.mouse_filter=Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new();shade.color=Color("030a09d9");modal_layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_panel=PanelContainer.new();modal_layer.add_child(modal_panel);modal_panel.add_theme_stylebox_override("panel",box_style(PANEL,LINE,28,10))
	modal_layer.hide()

func layout() -> void:
	if not is_instance_valid(title_box):return
	var viewport: Vector2=get_viewport().get_visible_rect().size
	title_box.custom_minimum_size.x=maxf(0,viewport.x-100)
	if is_instance_valid(modal_panel):
		var width: float=minf(1320,viewport.x-72) if current_modal=="shop" else minf(1140,viewport.x-72) if current_modal=="training" else minf(990,viewport.x-72)
		var height: float=minf(790,viewport.y-64) if current_modal=="shop" else minf(650,viewport.y-64)
		modal_panel.position=Vector2((viewport.x-width)*.5,(viewport.y-height)*.5);modal_panel.size=Vector2(width,height)

func captures_movement_input() -> bool:
	return not is_instance_valid(game) or title_layer.visible or modal_layer.visible

func captures_gameplay_input() -> bool:
	if captures_movement_input():return true
	# Query the current control instead of accumulating hover signals: hiding a
	# menu or disabling a cooldown button must never leave input stuck.
	var hovered: Control=get_viewport().gui_get_hovered_control()
	while is_instance_valid(hovered):
		if hovered is BaseButton or hovered is Range:return true
		hovered=hovered.get_parent() as Control
	return false

func _process(delta: float) -> void:
	if not is_instance_valid(game):return
	poll_time+=delta
	if poll_time>=.1:poll_time=0;refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11:toggle_fullscreen();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE and settings_open:
			close_settings();get_viewport().set_input_as_handled()

func refresh() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.get("player_unit")):return
	var s: Dictionary=game.call("snapshot");current_state=s
	current_preset=str(game.get("graphics_preset"));current_volume=float(game.get("master_volume"))
	var title: bool=bool(game.get("is_title"));var tour: bool=bool(game.get("tour_mode"))
	title_layer.visible=title;hud.visible=not title
	player_name.text=s.archer.name
	gold_text.text=str(int(s.gold));hp_text.text="%d / %d"%[ceili(float(s.hp)),int(s.maxHp)];hp_bar.max_value=float(s.maxHp);hp_bar.value=float(s.hp)
	xp_bar.max_value=float(s.xpNeeded);xp_bar.value=float(s.xp);xp_text.text="LEVEL %d · %d / %d XP"%[int(s.level),int(s.xp),int(s.xpNeeded)]
	if not s.pendingLevels.is_empty():xp_text.text+=" · %d FREE PICK"%s.pendingLevels.size()
	element_text.text="%s ARROWS · POWER %s"%[str(s.element).to_upper(),number(float(s.elementPower))];element_text.add_theme_color_override("font_color",ELEMENTS.get(s.element,GOLD))
	wave_text.text="EXPLORING / THE EMBERWOOD" if tour else "THE BRIAR KING / PRACTICE" if bool(s.practice) else "WAVE %d / 20"%int(s.wave)
	var seconds: int=ceili(float(s.waveLeft));timer_text.text="THE RUINS" if tour else "THE CROWN AWAITS" if bool(s.practice)  else "%d:%02d"%[seconds/60,seconds%60]
	timer_text.add_theme_font_size_override("font_size",23 if tour or bool(s.practice) else 31)
	objective_text.text="Wander, turn the camera and take in the light." if tour else "Read the warnings. Keep moving." if bool(s.practice) else "Defeat the guardian to earn a Mythic chest." if int(s.wave)%5==0 else "Survive until the camp opens."
	boss_box.visible=not tour and str(s.stage)=="boss" and float(s.bossHp)>0
	(boss_box.get_child(0) as Label).text=str(s.bossName).to_upper()
	boss_bar.max_value=maxf(1,float(s.bossMax));boss_bar.value=float(s.bossHp);boss_text.text="%d / %d   ·   %s"%[ceili(float(s.bossHp)),int(s.bossMax),"THRONEBREAKER" if s.bossAction=="Melee" else "BRIAR DECREE" if s.bossAction=="Ranged" else "THE KING ADVANCES"]
	dash_button.text="SPACE  "+s.archer.spaceName if float(s.dash)<=0 else s.archer.spaceName+" · %.1fs"%float(s.dash);dash_button.disabled=float(s.dash)>0
	salvo_button.text="E  "+s.archer.attackName if float(s.salvo)<=0 else s.archer.attackName+" · %.1fs"%float(s.salvo);salvo_button.disabled=float(s.salvo)>0
	for key in element_buttons:
		var b: Button=element_buttons[key];b.add_theme_color_override("font_color",ELEMENTS[key] if key==s.element else MUTED)
		b.add_theme_stylebox_override("normal",box_style(Color("2b3b2e") if key==s.element else Color("101b18e0"),ELEMENTS[key] if key==s.element else LINE,10,5))
	fps_text.text="%d FPS  ·  %s"%[int(s.fps),current_preset.capitalize()]
	tour_buttons.visible=tour
	controls_text.text="WASD Move    Space Windskip    E Salvo    %s    Scroll Zoom    Esc Pause"%["Mouse Orbit · Free camera" if bool(game.get("free_camera")) else "Right-drag Orbit"]
	if not bool(s.auto):controls_text.text+="    Click Fire"
	var mode := "settings" if settings_open else "chest" if str(s.stage)=="chest" else "training" if str(s.stage)=="training" and not bool(s.ended) else "shop" if str(s.stage)=="shop" and not bool(s.ended) else "pause" if (bool(s.paused) or bool(s.ended)) and not title else ""
	if title and not settings_open:mode=""
	modal_layer.visible=mode!=""
	if mode=="":current_modal="";last_modal_key="";return
	var key: String=mode+":"+str(s.build.revision)+":"+str(s.build.draftRevision)+":"+str(s.gold)+":"+str(s.hp)+":"+str(s.element)+":"+str(s.ended)+":"+str(s.paused)+":"+str(s.chests.revision)
	if mode=="settings":key="settings"
	if key!=last_modal_key:
		last_modal_key=key;current_modal=mode;rebuild_modal(s,mode)

func rebuild_modal(s: Dictionary, mode: String) -> void:
	for child in modal_panel.get_children():modal_panel.remove_child(child);child.queue_free()
	var light: bool=mode=="training"
	var modal_bg: Color=IVORY if light else SHOP_PANEL if mode in ["shop","chest"] else PANEL
	var modal_border: Color=Color("d8d3c5") if light else Color("8d887f") if mode=="shop" else LINE
	modal_panel.add_theme_stylebox_override("panel",box_style(modal_bg,modal_border,28,10))
	var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;modal_panel.add_child(scroll)
	modal_content=column(18);modal_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(modal_content)
	match mode:
		"training":build_training(s)
		"shop":build_shop(s)
		"chest":build_chest(s)
		"settings":build_settings()
		_:build_pause(s)
	layout()

func training_card_style(rarity: String, hovered: bool) -> StyleBoxFlat:
	var base: Color=SHOP_RARITIES.get(rarity,Color("626873"))
	var border: Color=SHOP_RARITY_BORDERS.get(rarity,Color("c7ccd2"))
	var style := box_style(base.lightened(.06) if hovered else base,border.lightened(.10) if hovered else border,18,9)
	style.border_width_top=5
	style.shadow_color=Color(border,.34 if hovered else .16)
	style.shadow_size=11 if hovered else 5
	style.shadow_offset=Vector2(0,3)
	return style

func training_effect_text(item: Dictionary) -> Array[String]:
	var lines: Array[String]=[]
	var effects: Dictionary=item.get("effects",{})
	for key in effects:
		var value: float=float(effects[key])
		match str(key):
			"max_hp":
				lines.append("+%s maximum health"%number(value))
				lines.append("+%s health immediately"%number(value))
			"damage":lines.append("+%s base arrow damage"%number(value))
			"elemental_power":lines.append("+%s shared elemental power"%number(value))
			"armor":lines.append("+%s armor"%number(value))
			"speed_bonus":lines.append("+%d%% movement speed"%roundi(value*100))
			_:lines.append(effect_delta_text(str(key),value))
	return lines

func build_training(s: Dictionary) -> void:
	var level_number: int=int(s.pendingLevels[0]) if not s.pendingLevels.is_empty() else int(s.level)
	var eyebrow := label("FIELD TRAINING / LEVEL %d"%level_number,11,SHOP_GOLD);eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(eyebrow)
	var heading := label("Choose your edge.",40,SHOP_INK,true);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(heading)
	var caption := label("One free reward. Higher rarity means a stronger permanent boost.",14,SHOP_MUTED);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(caption)
	modal_content.add_child(divider(SHOP_LINE))
	var choices := HBoxContainer.new();choices.add_theme_constant_override("separation",14);choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;modal_content.add_child(choices)
	for item in s.build.draft:
		var rarity: String=str(item.get("rarity","common"));var rarity_color: Color=SHOP_RARITY_BORDERS.get(rarity,Color("c7ccd2"))
		var card := PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(230,290);card.mouse_filter=Control.MOUSE_FILTER_PASS
		card.add_theme_stylebox_override("panel",training_card_style(rarity,false))
		card.mouse_entered.connect(func():card.add_theme_stylebox_override("panel",training_card_style(rarity,true)))
		card.mouse_exited.connect(func():card.add_theme_stylebox_override("panel",training_card_style(rarity,false)))
		choices.add_child(card)
		var contents := column(9);card.add_child(contents)
		var top := row(8);contents.add_child(top)
		var emblem := PanelContainer.new();emblem.custom_minimum_size=Vector2(62,62);emblem.add_theme_stylebox_override("panel",box_style(Color("ffffff22"),rarity_color,8,31));top.add_child(emblem)
		emblem.add_child(icon(str(item.icon),Color("ffffff"),46))
		var names := column(2);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(names)
		names.add_child(label(rarity.to_upper(),9,rarity_color))
		var title := paragraph(str(item.name),20,Color("ffffff"));title.add_theme_font_override("font",serif_font);names.add_child(title)
		var divider_line := divider(Color(rarity_color,.55));contents.add_child(divider_line)
		for line in training_effect_text(item):
			var boost := paragraph("+  "+str(line).trim_prefix("+"),12,Color("b7f08a"));boost.name="TrainingBoost";contents.add_child(boost)
		var space := Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;contents.add_child(space)
		var command: String="train:%d:%s"%[int(s.build.draftRevision),str(item.id)]
		var choose := button("Choose   →",_send.bind(command),false,true);choose.custom_minimum_size.y=44
		choose.add_theme_stylebox_override("normal",box_style(Color("f3efe7"),Color("d8d2c7"),12,6));choose.add_theme_stylebox_override("hover",box_style(Color("ffffff"),rarity_color,12,6));choose.add_theme_color_override("font_color",SHOP_INK);choose.add_theme_color_override("font_hover_color",SHOP_INK);contents.add_child(choose)
	var remaining := label("%d free choice%s remaining before the trader."%[s.pendingLevels.size(),"" if s.pendingLevels.size()==1 else "s"],13,SHOP_MUTED);remaining.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(remaining)

func build_shop(s: Dictionary) -> void:
	var header := row();modal_content.add_child(header)
	var heading := column(4);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
	heading.add_child(label("CAMP / WAVE %d COMPLETE"%int(s.wave),10,SHOP_GOLD))
	heading.add_child(label("The woodland trader.",32,SHOP_INK,true))
	var recovered: Dictionary=s.get("settlement",{})
	heading.add_child(paragraph("Recovered %d gold · %d XP · %s health · %d%% ground recovery"%[int(recovered.get("gold",0)),int(recovered.get("xp",0)),number(float(recovered.get("healed",0))),roundi(float(recovered.get("rate",.5))*100)],11,SHOP_MUTED))
	var wallet := column(2);header.add_child(wallet)
	var coin_row := row(6);coin_row.alignment=BoxContainer.ALIGNMENT_END;wallet.add_child(coin_row);coin_row.add_child(coin_icon(34))
	var coins := label(str(int(s.gold)),30,SHOP_GOLD,true);coins.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;coin_row.add_child(coins)
	var level_line := label("LEVEL %d  ·  %s ARROWS"%[int(s.level),str(s.element).to_upper()],10,SHOP_MUTED);level_line.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;wallet.add_child(level_line)
	modal_content.add_child(divider(SHOP_LINE))

	var body := row(18);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;modal_content.add_child(body)
	var stock := column(10);stock.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(stock)
	var stock_header := row(8);stock.add_child(stock_header)
	stock_header.add_child(label("TRADER STOCK",11,SHOP_INK))
	stock_header.add_child(flex())
	var reroll := button("Reroll",_send.bind("reroll"));reroll.disabled=int(s.gold)<int(s.build.rerollCost);reroll.custom_minimum_size=Vector2(105,36)
	reroll.add_theme_stylebox_override("normal",box_style(Color("efebe4"),Color("a7a199"),9,6));reroll.add_theme_stylebox_override("hover",box_style(Color("ffffff"),SHOP_GOLD,9,6));reroll.add_theme_color_override("font_color",SHOP_INK);reroll.add_theme_color_override("font_hover_color",SHOP_INK);stock_header.add_child(reroll)
	var reroll_cost := row(4);stock_header.add_child(reroll_cost);reroll_cost.add_child(coin_icon(20));reroll_cost.add_child(label(str(int(s.build.rerollCost)),12,SHOP_GOLD,true))

	var cards := HBoxContainer.new();cards.add_theme_constant_override("separation",10);cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stock.add_child(cards)
	for item in s.build.offers:
		if bool(item.sold):
			var empty_slot := Control.new()
			empty_slot.custom_minimum_size=Vector2(195,275)
			empty_slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			empty_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
			cards.add_child(empty_slot)
		else:
			cards.add_child(shop_card(item,s))

	var owned_panel := PanelContainer.new();owned_panel.add_theme_stylebox_override("panel",box_style(Color("ece8e0"),Color("bbb5aa"),12,8));stock.add_child(owned_panel)
	var owned_box := column(7);owned_panel.add_child(owned_box)
	var owned_header := row(8);owned_box.add_child(owned_header)
	owned_header.add_child(label("OWNED / CURRENT RUN",11,SHOP_INK));owned_header.add_child(flex())
	owned_header.add_child(label("%d entries"%active_inventory_count(s),10,SHOP_MUTED))
	add_shop_inventory(owned_box,s,118)

	var sidebar_panel := PanelContainer.new();sidebar_panel.custom_minimum_size.x=260;sidebar_panel.add_theme_stylebox_override("panel",box_style(SHOP_STATS_PANEL,Color("565b61"),16,9));body.add_child(sidebar_panel)
	var sidebar := column(8);sidebar_panel.add_child(sidebar)
	sidebar.add_child(label(str(s.archer.name).to_upper()+" / STATS",11,SHOP_GOLD));sidebar.add_child(label("Current build",22,Color("f4f1e9"),true))
	add_shop_stats(sidebar,s)
	sidebar.add_child(divider(SHOP_STATS_LINE))
	sidebar.add_child(label("ARROW ELEMENT",10,Color("aeb4b8")))
	sidebar.add_child(label(str(s.element).capitalize()+" arrows",17,ELEMENTS[s.element]))
	sidebar.add_child(paragraph("Purchase a quiver to change arrows. Old elemental fittings are discarded; shared gear stays.",10,Color("aeb4b8")))

	var footer := row(10);modal_content.add_child(footer)
	var settings_button := button("Settings",open_settings);settings_button.add_theme_color_override("font_color",SHOP_INK);settings_button.add_theme_stylebox_override("normal",box_style(Color("e8e4dc"),Color("aaa59a"),12,6));footer.add_child(settings_button)
	var leave_button := button("Leave run",_return_title);leave_button.add_theme_color_override("font_color",SHOP_INK);leave_button.add_theme_stylebox_override("normal",box_style(Color("e8e4dc"),Color("aaa59a"),12,6));footer.add_child(leave_button)
	footer.add_child(flex())
	var continue_button := button("Enter wave %d%s   →"%[int(s.wave)+1," · Guardian encounter" if (int(s.wave)+1)%5==0 else ""],_send.bind("continue"),true)
	continue_button.custom_minimum_size.x=330;continue_button.add_theme_stylebox_override("normal",box_style(Color("fffaf0"),Color("c8b78e"),14,7));continue_button.add_theme_stylebox_override("hover",box_style(Color("ffffff"),SHOP_GOLD,14,7));footer.add_child(continue_button)

func armor_reduction(value: float) -> int:
	return roundi(value/(20+value)*100) if value>0 else 0

func add_shop_stats(parent: VBoxContainer, s: Dictionary) -> void:
	var p: Dictionary=s.build.stats;var arrow: float=float(p.damage)*(1+float(p.damage_bonus))+(float(p.elemental_power)*(1+float(p.element_bonus)) if str(s.element)!="physical" else 0)
	var stats: Array=[
		["Maximum health",number(float(p.max_hp)),Color("ff8c8c")],
		["Arrow damage",number(arrow),Color("ffd36f")],
		["Elemental power",number(float(p.elemental_power)),ELEMENTS.get(s.element,Color("9bd5e6"))],
		["Armor",number(float(p.armor))+" · %d%%"%armor_reduction(float(p.armor)),Color("9ebcf4")],
		["Move speed","%.2f m/s"%(5*(1+float(p.speed_bonus))),Color("82d9d2")],
		["Attack cadence","%.2f sec"%(.8/(1+float(p.attack_speed))),Color("efb6ff")],
		["Pickup radius","%.2f m"%float(p.pickup_radius),Color("b8d98e")],
		["Economy","%d%%"%int(p.economy),SHOP_GOLD],
		["Gold earned","+%d%%"%roundi(float(p.gold_bonus)*100),SHOP_GOLD],
		["Ground recovery","%d%%"%roundi(float(p.salvage)*100),SHOP_GOLD],
		["Pet damage","%.2f×"%float(p.pet_damage),Color("d4b07c")],
		["Critical chance","%d%%"%roundi(float(p.crit)*100),Color("f0a6c6")],
		["Cooldown reduction","%d%%"%roundi(float(p.haste)*100),Color("b8a8ff")],
		["Regeneration","%.1f / sec"%float(p.regen),Color("8ee89e")]
	]
	if float(p.mending)>0:stats.append(["Mending","%d%% max HP/sec after 5s"%roundi(float(p.mending)*100),Color("a7e58a")])
	if str(s.element)=="fire":stats.append(["Burn damage","%.1f / sec"%(float(p.elemental_power)*.75*(1+float(p.burn_bonus))),ELEMENTS.fire]);stats.append(["Burn duration","%.1f sec"%(3+float(p.duration)),ELEMENTS.fire])
	elif str(s.element)=="ice":stats.append(["Ice slow","%d%%"%roundi(minf(.6,.35+float(p.slow_bonus))*100),ELEMENTS.ice]);stats.append(["Ice duration","%.1f sec"%(2.5+float(p.duration)),ELEMENTS.ice])
	elif str(s.element)=="poison":stats.append(["Poison / stack","%.1f / sec"%(float(p.elemental_power)*.375*(1+float(p.venom_bonus))),ELEMENTS.poison]);stats.append(["Poison stacks",str(int(p.stacks)),ELEMENTS.poison])
	var grid := GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",4);parent.add_child(grid)
	for stat in stats:
		var stat_name := label(str(stat[0]),10,Color("b9bec1"));stat_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(stat_name)
		var stat_value := label(str(stat[1]),10,stat[2]);stat_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;grid.add_child(stat_value)

func active_inventory_count(s: Dictionary) -> int:
	var count := 0
	for item in s.build.history:
		var state: String="used" if str(item.id)=="heartwood" and bool(s.build.reviveUsed) else str(item.status)
		if state!="discarded" and not (state=="used" and str(item.id)!="heartwood"):count+=1
	return count

func add_shop_inventory(parent: VBoxContainer, s: Dictionary, height:=120) -> void:
	var scroll := ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;parent.add_child(scroll)
	var grid := GridContainer.new();grid.columns=5;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);scroll.add_child(grid)
	var grouped := {}
	for item in s.build.history:
		var state: String="used" if str(item.id)=="heartwood" and bool(s.build.reviveUsed) else str(item.status)
		if state=="discarded" or (state=="used" and str(item.id)!="heartwood"):continue
		var key: String=str(item.id)+":"+str(item.source)+":"+state
		if grouped.has(key):grouped[key].count+=1
		else:grouped[key]={"item":item,"state":state,"count":1}
	if grouped.is_empty():
		var empty := paragraph("Nothing packed yet. Purchases and level training will appear here.",11,SHOP_MUTED);grid.add_child(empty);return
	for value in grouped.values():
		var item: Dictionary=value.item;var rarity: String=str(item.get("rarity","common"));var rarity_color: Color=SHOP_RARITIES.get(rarity,Color("6d7783"))
		if str(item.source)=="level":rarity_color=Color("3b78a8")
		var tile := PanelContainer.new();tile.name="OwnedItemTile";tile.custom_minimum_size=Vector2(128,44);tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",box_style(rarity_color,rarity_color.lightened(.25),6,6));tile.tooltip_text=str(item.get("description",""));grid.add_child(tile)
		var item_row := row(5);tile.add_child(item_row);item_row.add_child(icon(str(item.get("icon","gem")),Color("f6f2e9"),22))
		var item_text := column(0);item_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item_row.add_child(item_text)
		var title_text: String=str(item.name)+(" ×%d"%int(value.count) if int(value.count)>1 else "")
		var title_label := label(title_text,9,Color("ffffff"));title_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title_label.clip_text=true;item_text.add_child(title_label)
		var source_text: String="Spent" if value.state=="used" else "Training" if str(item.source)=="level" else rarity.capitalize()
		item_text.add_child(label(source_text,7,Color("e5e2dc")))
		if value.state=="used":tile.modulate=Color(1,1,1,.56)

func shop_card_style(rarity: String, hovered: bool) -> StyleBoxFlat:
	var base: Color=SHOP_RARITIES.get(rarity,Color("626873"))
	var border: Color=SHOP_RARITY_BORDERS.get(rarity,Color("c7ccd2"))
	var style := box_style(base.lightened(.06) if hovered else base,border.lightened(.08) if hovered else border,13,8)
	style.border_width_top=5
	style.shadow_color=Color(border,.30 if hovered else .16)
	style.shadow_size=10 if hovered else 4
	style.shadow_offset=Vector2(0,2)
	return style

func effect_display_name(key: String) -> String:
	match key:
		"damage":return "base arrow damage"
		"damage_bonus":return "physical arrow damage"
		"max_hp":return "maximum health"
		"armor":return "armor"
		"speed_bonus":return "movement speed"
		"pickup_radius":return "pickup radius"
		"economy":return "shop savings"
		"salvage":return "ground gold recovery"
		"gold_bonus":return "gold earned"
		"heal":return "maximum health restored now"
		"attack_speed":return "attack speed"
		"pet_damage":return "fox dart damage"
		"elemental_power":return "elemental power"
		"crit":return "critical chance"
		"heal_kill":return "health on kill"
		"regen":return "health regeneration"
		"mending":return "max health regeneration after 5 seconds safe"
		"haste":return "ability cooldown reduction"
		"revive":return "lethal-hit revive"
		"burn_bonus":return "burn damage"
		"venom_bonus":return "poison tick damage"
		"duration":return "status duration"
		"element_bonus":return "element impact damage"
		"slow_bonus":return "ice slow"
		"stacks":return "maximum poison stack"
		_:return key.replace("_"," ")

func effect_delta_text(key: String, value: float) -> String:
	var sign: String="+" if value>=0 else "−"
	var magnitude: float=absf(value)
	match key:
		"damage","max_hp","armor","economy","heal_kill","elemental_power","stacks":
			return "%s%s %s"%[sign,number(magnitude),effect_display_name(key)]
		"pickup_radius":
			return "%s%.2fm %s"%[sign,magnitude,effect_display_name(key)]
		"regen":
			return "%s%.1f HP/sec %s"%[sign,magnitude,effect_display_name(key)]
		"mending":
			return "%s%d%% max HP/sec after 5 sec safe"%[sign,roundi(magnitude*100)]
		"duration":
			return "%s%.1f sec %s"%[sign,magnitude,effect_display_name(key)]
		"heal":
			return "%s%d%% %s"%[sign,roundi(magnitude*100),effect_display_name(key)]
		"revive":
			return "Survive one lethal hit"
		_:
			return "%s%d%% %s"%[sign,roundi(magnitude*100),effect_display_name(key)]

func shop_effect_lines(item: Dictionary) -> Array[Dictionary]:
	if item.effects.has("fox") or item.effects.has("wolf") or item.effects.has("beetle"):return [{"text":"Recruit companion","positive":true}]
	if item.has("arrow_type"):return [{"text":"Equip "+str(item.arrow_type).capitalize()+" arrows","positive":true}]
	var lines: Array[Dictionary]=[]
	var effects: Dictionary=item.get("effects",{})
	for key in effects:
		var value: float=float(effects[key])
		lines.append({"text":effect_delta_text(str(key),value),"positive":value>=0})
	if str(item.get("element",""))!="":
		lines.append({"text":"Discarded if arrow element changes","positive":false})
	return lines

func shop_card(item: Dictionary, s: Dictionary) -> Control:
	var card := PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(195,275);card.mouse_filter=Control.MOUSE_FILTER_PASS
	var rarity: String=str(item.rarity);var rarity_color: Color=SHOP_RARITY_BORDERS.get(rarity,Color("c7ccd2"))
	card.add_theme_stylebox_override("panel",shop_card_style(rarity,false))
	card.mouse_entered.connect(func():card.add_theme_stylebox_override("panel",shop_card_style(rarity,true)))
	card.mouse_exited.connect(func():card.add_theme_stylebox_override("panel",shop_card_style(rarity,false)))
	var content := column(7);card.add_child(content)

	var item_heading := row(7);content.add_child(item_heading);var element: String=str(item.get("element",""));item_heading.add_child(icon(str(item.icon),Color("ffffff"),42))
	var names := column(2);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item_heading.add_child(names)
	var rarity_label := label(rarity.to_upper()+(" / "+element.to_upper() if element!="" else ""),8,rarity_color);rarity_label.name="ShopRarity";names.add_child(rarity_label)
	var title := paragraph(str(item.name),15,Color("ffffff"));title.add_theme_font_override("font",serif_font);names.add_child(title)

	var description := paragraph(str(item.description),9,SHOP_CARD_MUTED);description.custom_minimum_size.y=36;content.add_child(description)

	var stats_box := column(2);content.add_child(stats_box)
	for entry in shop_effect_lines(item):
		var positive: bool=bool(entry.positive)
		var stat_color: Color=SHOP_GAIN if positive else SHOP_LOSS
		var prefix: String="+ " if positive else "- "
		var stat := paragraph(prefix+str(entry.text).trim_prefix("+").trim_prefix("−").trim_prefix("-"),9,stat_color)
		stat.name="ShopStatLine";stats_box.add_child(stat)
	var space := Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(space)
	var sold: bool=bool(item.sold);var eligible: bool=bool(item.get("eligible",true));var affordable: bool=bool(item.affordable)
	var unavailable: bool=sold or not eligible
	var ribbon := Button.new();ribbon.name="ShopPurchase";ribbon.custom_minimum_size=Vector2(0,44);ribbon.size_flags_horizontal=Control.SIZE_EXPAND_FILL;ribbon.mouse_filter=Control.MOUSE_FILTER_STOP
	ribbon.disabled=unavailable or not affordable
	var ribbon_normal := box_style(Color("2d3032"),Color("55595d"),10,7)
	var ribbon_hover := box_style(Color("383c3f"),SHOP_GOLD,10,7)
	var ribbon_pressed := box_style(Color("242729"),SHOP_GOLD,10,7)
	var ribbon_disabled := box_style(Color("4a2224") if not affordable and not unavailable else Color("d7d2ca"),Color("d85f63") if not affordable and not unavailable else Color("aaa59f"),10,7)
	if not affordable and not unavailable:
		ribbon_disabled.shadow_color=Color("e44f55aa");ribbon_disabled.shadow_size=9
	ribbon.add_theme_stylebox_override("normal",ribbon_normal);ribbon.add_theme_stylebox_override("hover",ribbon_hover);ribbon.add_theme_stylebox_override("pressed",ribbon_pressed);ribbon.add_theme_stylebox_override("disabled",ribbon_disabled)
	ribbon.pressed.connect(_send.bind("buy:"+str(item.id)));content.add_child(ribbon)
	var price_row := row(7);price_row.alignment=BoxContainer.ALIGNMENT_CENTER;price_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;ribbon.add_child(price_row);price_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var coin := coin_icon(27);price_row.add_child(coin)
	var price_color: Color=Color("ffffff") if affordable and not unavailable else Color("ff7a78") if not affordable and not unavailable else Color("76736d")
	var price := label(str(int(item.cost)),14,price_color,true);price.name="ShopPrice";price_row.add_child(price)
	var owned_text: String="ONE PER RUN" if str(item.id)=="heartwood" else "OWNED %d / %d"%[int(item.owned),int(item.cap)]
	content.add_child(label(owned_text,8,Color("eeeae3")))
	return card

func add_stats(parent: VBoxContainer, s: Dictionary, compact:=false) -> void:
	var p: Dictionary=s.build.stats;var arrow: float=float(p.damage)*(1+float(p.damage_bonus))+(float(p.elemental_power)*(1+float(p.element_bonus)) if str(s.element)!="physical" else 0)
	var stats: Array=[["Maximum health",number(float(p.max_hp))],["Arrow damage",number(arrow)],["Elemental power",number(float(p.elemental_power))],["Armor",number(float(p.armor))+" · %d%% reduction"%roundi(float(p.armor)/(20+float(p.armor))*100)],["Move speed","%.2f m/s"%(5*(1+float(p.speed_bonus)))],["Attack cadence","%.2f sec"%(.8/(1+float(p.attack_speed)))],["Pickup radius","%.2f m"%float(p.pickup_radius)],["Economy","%d%% savings"%int(p.economy)],["Gold earned","+%d%%"%roundi(float(p.gold_bonus)*100)],["Ground recovery","%d%%"%roundi(float(p.salvage)*100)],["Pet damage","%.2f×"%float(p.pet_damage)],["Critical chance","%d%%"%roundi(float(p.crit)*100)],["Cooldown reduction","%d%%"%roundi(float(p.haste)*100)],["Regeneration","%.1f / sec"%float(p.regen)],["Mending","%d%% max HP/sec after 5s"%roundi(float(p.mending)*100)]]
	if str(s.element)=="fire":stats.append(["Burn damage","%.1f / sec"%(float(p.elemental_power)*.75*(1+float(p.burn_bonus)))]);stats.append(["Burn duration","%.1f sec"%(3+float(p.duration))])
	elif str(s.element)=="ice":stats.append(["Ice slow","%d%%"%roundi(minf(.6,.35+float(p.slow_bonus))*100)]);stats.append(["Ice duration","%.1f sec"%(2.5+float(p.duration))])
	elif str(s.element)=="poison":stats.append(["Poison / stack","%.1f / sec"%(float(p.elemental_power)*.375*(1+float(p.venom_bonus)))]);stats.append(["Poison stacks",str(int(p.stacks))])
	var grid := GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",15);grid.add_theme_constant_override("v_separation",5 if compact else 8);parent.add_child(grid)
	for stat in stats:
		var title := label(str(stat[0]),11 if compact else 13,MUTED);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(title)
		var value := label(str(stat[1]),11 if compact else 13,IVORY);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;grid.add_child(value)

func add_inventory(parent: VBoxContainer, s: Dictionary, height:=140) -> void:
	var scroll := ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll)
	var contents := column(8);contents.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(contents)
	if s.build.history.is_empty():contents.add_child(paragraph("Your pack is empty. Training and purchased items appear here.",12,MUTED));return
	var grouped := {}
	for item in s.build.history:
		var state: String="used" if str(item.id)=="heartwood" and bool(s.build.reviveUsed) else str(item.status)
		var key: String=str(item.id)+":"+str(item.source)+":"+state
		if grouped.has(key):grouped[key].count+=1
		else:grouped[key]={"item":item,"state":state,"count":1}
	for value in grouped.values():
		var item: Dictionary=value.item;var item_row := row(10);contents.add_child(item_row);item_row.add_child(icon(str(item.get("icon","gem")),ELEMENTS.get(str(item.get("element","")),GOLD),28))
		var item_text := column(3);item_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item_row.add_child(item_text);item_text.add_child(paragraph(str(item.name)+(" ×%d"%int(value.count) if int(value.count)>1 else ""),12,IVORY))
		item_text.add_child(label("Discarded on swap" if value.state=="discarded" else "Used" if value.state=="used" else "Level training" if str(item.source)=="level" else str(item.get("rarity","common")).capitalize()+" item",9,MUTED))
		if value.state=="discarded":item_row.modulate=Color(1,1,1,.5)

func build_pause(s: Dictionary) -> void:
	var ended: bool=bool(s.ended);var heading: String="The crown falls." if ended and bool(s.victory) else "The forest won." if ended else "Take a breath."
	modal_content.add_child(label("THE EMBERWOOD / "+("VICTORY" if bool(s.victory) else "DEFEATED") if ended else "THE EMBERWOOD / PAUSED",11,GOLD));modal_content.add_child(label(heading,40,IVORY,true))
	modal_content.add_child(paragraph("%d enemies defeated · %d damage dealt · %d damage taken · %.0f seconds"%[int(s.kills),int(s.dealt),int(s.taken),float(s.time)] if ended else "Wave %d · Level %d · The forest can wait."%[int(s.wave),int(s.level)],14,MUTED));modal_content.add_child(divider())
	var body := row(36);modal_content.add_child(body);var stats_column := column(12);stats_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(stats_column);stats_column.add_child(label("CURRENT BUILD",11,GOLD));add_stats(stats_column,s)
	var pack := column(12);pack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(pack);pack.add_child(label("PACKED & EQUIPPED",11,GOLD));add_inventory(pack,s,240)
	var actions := row();modal_content.add_child(actions)
	if not ended:actions.add_child(button("Resume   →",func():_send("pause"),true))
	else:actions.add_child(button("Try again   →",_begin.bind("boss" if bool(s.practice) else "start"),true))
	actions.add_child(button("Settings",open_settings));actions.add_child(button("Return to title",_return_title));actions.add_child(button("Quit",func():get_tree().quit()))
	modal_content.add_child(paragraph("WASD move · Space dash · E salvo · F toggles auto-aim · Right-drag orbit · Scroll zoom · 0–3 elements",11,MUTED))

func build_settings() -> void:
	modal_content.add_child(label("THE EMBERWOOD / SETTINGS",11,GOLD));modal_content.add_child(label("Make yourself at home.",36,IVORY,true));modal_content.add_child(divider())
	modal_content.add_child(label("GRAPHICS",12,GOLD));var graphics_row := row();modal_content.add_child(graphics_row)
	for preset in ["high","balanced","performance"]:
		var b := button(str(preset).capitalize(),set_preset.bind(preset),preset==current_preset);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;graphics_row.add_child(b)
	modal_content.add_child(paragraph("Balanced is tuned for an M1 Mac with 8 GB of memory. High adds reflections and volumetric light; Performance reduces the rendering load.",13,MUTED))
	modal_content.add_child(label("SOUND",12,GOLD));var sound := HSlider.new();sound.min_value=0;sound.max_value=1;sound.step=.01;sound.value=current_volume;sound.custom_minimum_size.y=34;sound.value_changed.connect(func(value:float):current_volume=value;if_call("set_master_volume",value));modal_content.add_child(sound)
	var camera_check := CheckButton.new();camera_check.text="Free camera — move the mouse to orbit";camera_check.button_pressed=bool(game.get("free_camera"));camera_check.toggled.connect(func(value:bool):if_call("set_free_camera",value));modal_content.add_child(camera_check)
	modal_content.add_child(paragraph("With free camera off, hold the right mouse button to orbit. Mouse wheel adjusts distance.",13,MUTED))
	var auto_check := CheckButton.new();auto_check.text="Auto-aim and fire";auto_check.button_pressed=bool(current_state.get("auto",true));auto_check.toggled.connect(func(_value:bool):_send("auto"));modal_content.add_child(auto_check)
	var actions := row();modal_content.add_child(actions);actions.add_child(button("Back   →",close_settings,true));actions.add_child(button("Toggle fullscreen",toggle_fullscreen))
	modal_content.add_child(paragraph("F11 toggles fullscreen. Esc returns to the game menu.",12,MUTED))

func coin_icon(dimensions:=24) -> TextureRect:
	var node := TextureRect.new();node.custom_minimum_size=Vector2(dimensions,dimensions);node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var path := "res://assets/ui/gold_coin.svg"
	if not texture_cache.has(path):texture_cache[path]=load(path)
	node.texture=texture_cache[path]
	return node

func icon(name: String, color: Color=GOLD, dimensions:=48) -> TextureRect:
	var node := TextureRect.new();node.custom_minimum_size=Vector2(dimensions,dimensions);node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var path: String="res://assets/ui/"+name+".svg"
	if not ResourceLoader.exists(path):path="res://assets/ui/gem.svg"
	if not texture_cache.has(path):texture_cache[path]=load(path)
	node.texture=texture_cache[path];node.modulate=color/Color("e8d4a1")
	return node

func number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value,roundf(value)) else "%.1f"%value

func _send(command: String) -> void:
	if not is_instance_valid(game):return
	game.call("consume_command",command);last_modal_key="";refresh()
	if not captures_movement_input():get_viewport().gui_release_focus()

func _begin(mode: String) -> void:
	settings_open=false;settings_resume=false;last_modal_key="";game.call("begin_mode",mode);refresh()

func _return_title() -> void:
	settings_open=false;settings_resume=false;last_modal_key="";game.call("return_to_title");refresh()

func if_call(method: String, value: Variant) -> void:
	if is_instance_valid(game) and game.has_method(method):game.call(method,value)

func set_preset(value: String) -> void:
	current_preset=value;if_call("set_graphics_preset",value);last_modal_key="";refresh()

func open_settings() -> void:
	settings_resume=not bool(current_state.get("paused",false)) and not bool(current_state.get("ended",false)) and not bool(game.get("is_title")) and str(current_state.get("stage","")) not in ["shop","training","chest"]
	if settings_resume:game.call("consume_command","pause")
	settings_open=true;last_modal_key="";refresh()

func close_settings() -> void:
	settings_open=false
	if settings_resume and bool(game.get("paused")):game.call("consume_command","pause")
	settings_resume=false;last_modal_key="";refresh()

func toggle_fullscreen() -> void:
	var mode: int=DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN] else DisplayServer.WINDOW_MODE_FULLSCREEN)

func build_chest(s: Dictionary) -> void:
	var reward: Dictionary=s.chests.current
	if reward.is_empty():return
	var item: Dictionary=reward.item
	var accent: Color=SHOP_RARITY_BORDERS[item.rarity]
	var eyebrow := label("GUARDIAN SPOILS / MYTHIC CHEST" if reward.mythic else "SPOILS OF THE EMBERWOOD",12,SHOP_GOLD);eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(eyebrow)
	var heading := label("A crown's ransom." if reward.mythic else "Something worth keeping.",36,SHOP_INK,true);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(heading)
	var body := row(24);modal_content.add_child(body)
	var reveal=load("res://chest_reveal.gd").new();reveal.name="ChestReveal";body.add_child(reveal)
	var image := icon(str(item.icon),accent,88)
	reveal.setup(bool(reward.mythic),accent,image.texture)
	var card := PanelContainer.new();card.name="ChestRewardCard";card.custom_minimum_size.x=350;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(card);card.add_theme_stylebox_override("panel",shop_card_style(item.rarity,false))
	var content := column(14);card.add_child(content);content.add_child(label(str(item.rarity).to_upper()+" / FOUND ITEM",12,accent));content.add_child(image);content.add_child(label(item.name,26,SHOP_CARD_TEXT,true));content.add_child(paragraph(item.description,15,SHOP_CARD_MUTED))
	for line in shop_effect_lines(item):content.add_child(paragraph(line.text,15,SHOP_GAIN if line.positive else SHOP_LOSS))
	card.modulate.a=0
	reveal.reward_visible.connect(func():card.modulate.a=1.0)
	var caption := label("%d chest%s remaining · Level rewards and trader follow"%[int(s.chests.queued),"" if int(s.chests.queued)==1 else "s"],12,SHOP_MUTED);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(caption)
	var choices := row();choices.alignment=BoxContainer.ALIGNMENT_CENTER;modal_content.add_child(choices)
	var take := button("Take item",_send.bind("chest:take:"+str(reward.token)),true,true);choices.add_child(take)
	var reroll := button("Reroll · %d gold"%int(s.chests.rerollCost),_send.bind("chest:reroll:"+str(reward.token)),false,true);choices.add_child(reroll)
	var sell := button("Sell · %d gold"%int(s.chests.sellPrice),_send.bind("chest:sell:"+str(reward.token)),false,true);choices.add_child(sell)
	for control in [take,reroll,sell]:control.disabled=true
	reveal.completed.connect(func():take.disabled=false;sell.disabled=false;reroll.disabled=int(s.gold)<int(s.chests.rerollCost))
