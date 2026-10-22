extends CanvasLayer
## Native game UI. All purchases and progression remain validated by the arena.
const INK := Color("101917")
const PANEL := Color("17211f")
const IVORY := Color("eee9dc")
const GOLD := Color("dcc58b")
const MUTED := Color("a0b0a6")
const LINE := Color("405149")
const SHOP_PANEL := Color("13201b")
const SHOP_CARD := Color("192821")
const SHOP_CARD_HOVER := Color("22352b")
const SHOP_LINE := Color("4d6255")
const SHOP_MUTED := Color("aab9ad")
const SHOP_GOLD := Color("d7bd7a")
const SHOP_GAIN := Color("8fd39c")
const SHOP_TILE := Color("17251f")
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
	top_row.add_child(flex());gold_text=label("◉  0",25,GOLD,true);top_row.add_child(gold_text)
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
	var vitals := column(6);vitals_panel.add_child(vitals);var name_row := row();vitals.add_child(name_row);name_row.add_child(label("Rowan",24,IVORY,true));name_row.add_child(flex());hp_text=label("140 / 140",13,IVORY);name_row.add_child(hp_text)
	hp_bar=make_bar(Color("a5c694"),9);vitals.add_child(hp_bar);element_text=label("FIRE ARROWS · POWER 8",10,GOLD);vitals.add_child(element_text)
	xp_bar=make_bar(Color("73b7a5"),4);vitals.add_child(xp_bar);xp_text=label("LEVEL 1 · 0 / 60 XP",10,MUTED);vitals.add_child(xp_text)
	var skills_anchor := anchored(hud,Control.PRESET_BOTTOM_RIGHT,Rect2(-395,-173,365,132));var skills_column := column(8);skills_anchor.add_child(skills_column);skills_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var skills_row := row(8);skills_column.add_child(skills_row);dash_button=button("SPACE  Windskip",func():_send("dash"));dash_button.custom_minimum_size=Vector2(176,54);skills_row.add_child(dash_button);salvo_button=button("E  Flock & Awe",func():_send("salvo"));salvo_button.custom_minimum_size=Vector2(176,54);skills_row.add_child(salvo_button)
	var element_row := row(5);skills_column.add_child(element_row)
	for element in ["physical","fire","ice","poison"]:
		var b := button("Plain" if element=="physical" else str(element).capitalize(),_send.bind(element));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=38;b.add_theme_font_size_override("font_size",12);element_row.add_child(b);element_buttons[element]=b
	fps_text=label("",10,MUTED);fps_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;skills_column.add_child(fps_text)
	var footer := anchored(hud,Control.PRESET_BOTTOM_WIDE,Rect2(30,-29,-60,22));controls_text=label("WASD Move    Space Dash    E Salvo    Right-drag Orbit    Scroll Zoom    Esc Pause",11,Color("afc0ad"));footer.add_child(controls_text);controls_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);controls_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var tour_anchor := anchored(hud,Control.PRESET_CENTER_BOTTOM,Rect2(-250,-104,500,48));tour_buttons=row();tour_anchor.add_child(tour_buttons);tour_buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tour_buttons.alignment=BoxContainer.ALIGNMENT_CENTER
	tour_buttons.add_child(button("Face the King",_begin.bind("boss"),true));tour_buttons.add_child(button("Return to title",_return_title))

func build_title() -> void:
	title_layer=Control.new();ui.add_child(title_layer);title_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);title_layer.mouse_filter=Control.MOUSE_FILTER_STOP
	var gradient := Gradient.new();gradient.colors=PackedColorArray([Color("06100ee8"),Color("07100b96"),Color("06100c00")]);gradient.offsets=PackedFloat32Array([0,.47,1])
	var texture := GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=Vector2.ZERO;texture.fill_to=Vector2.RIGHT
	var shade := TextureRect.new();shade.texture=texture;shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title_layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title_box=column(15);title_layer.add_child(title_box)
	title_box.add_child(label("C H A P T E R   I",13,GOLD))
	title_box.add_child(label("Wildfall",76,IVORY,true))
	title_box.add_child(label("T H E   E M B E R W O O D",17,GOLD))
	title_box.add_child(divider(Color("bdad7b66")))
	title_box.add_child(paragraph("A forgotten crown. A forest that remembers.\nTake Rowan and the Forest Fox into the ruins.",17,Color("c4ccba")))
	var spacer := Control.new();spacer.custom_minimum_size.y=10;title_box.add_child(spacer)
	title_box.add_child(button("Face the Briar King   →",_begin.bind("boss"),true))
	title_box.add_child(button("Play the three-wave hunt",_begin.bind("start")))
	var options := row();title_box.add_child(options)
	for pair in [["Explore the ruins","tour"],["Visit the trader","camp"]]:
		var b := button(pair[0],_begin.bind(pair[1]));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;options.add_child(b)
	var lower := row();title_box.add_child(lower);lower.add_child(button("Settings",open_settings));lower.add_child(button("Quit",func():get_tree().quit()))
	title_footer=label("WASD move  ·  Space dash  ·  E salvo\nRight-drag orbit  ·  F11 fullscreen",12,MUTED);title_box.add_child(title_footer)

func build_modal_root() -> void:
	modal_layer=Control.new();ui.add_child(modal_layer);modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);modal_layer.mouse_filter=Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new();shade.color=Color("030a09d9");modal_layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_panel=PanelContainer.new();modal_layer.add_child(modal_panel);modal_panel.add_theme_stylebox_override("panel",box_style(PANEL,LINE,28,10))
	modal_layer.hide()

func layout() -> void:
	if not is_instance_valid(title_box):return
	var viewport: Vector2=get_viewport().get_visible_rect().size
	title_box.position=Vector2(maxf(50,viewport.x*.075),maxf(35,(viewport.y-650)*.5))
	title_box.size=Vector2(minf(540,viewport.x*.43),650)
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
	gold_text.text="◉  %d"%int(s.gold);hp_text.text="%d / %d"%[ceili(float(s.hp)),int(s.maxHp)];hp_bar.max_value=float(s.maxHp);hp_bar.value=float(s.hp)
	xp_bar.max_value=float(s.xpNeeded);xp_bar.value=float(s.xp);xp_text.text="LEVEL %d · %d / %d XP"%[int(s.level),int(s.xp),int(s.xpNeeded)]
	if not s.pendingLevels.is_empty():xp_text.text+=" · %d FREE PICK"%s.pendingLevels.size()
	element_text.text="%s ARROWS · POWER %s"%[str(s.element).to_upper(),number(float(s.elementPower))];element_text.add_theme_color_override("font_color",ELEMENTS.get(s.element,GOLD))
	wave_text.text="EXPLORING / THE EMBERWOOD" if tour else "THE BRIAR KING / PRACTICE" if bool(s.practice) else "WAVE %d / 3"%int(s.wave)
	var seconds: int=ceili(float(s.waveLeft));timer_text.text="THE RUINS" if tour else "THE CROWN AWAITS" if bool(s.practice) else "OVERTIME" if seconds<=0 and int(s.wave)==3 and float(s.bossHp)>0 else "%d:%02d"%[seconds/60,seconds%60]
	timer_text.add_theme_font_size_override("font_size",23 if tour or bool(s.practice) else 31)
	objective_text.text="Wander, turn the camera and take in the light." if tour else "Read the warnings. Keep moving." if bool(s.practice) else "Defeat the King and survive the timer." if int(s.wave)==3 else "Survive until the camp opens."
	boss_box.visible=not tour and str(s.stage)=="boss" and float(s.bossHp)>0
	boss_bar.max_value=maxf(1,float(s.bossMax));boss_bar.value=float(s.bossHp);boss_text.text="%d / %d   ·   %s"%[ceili(float(s.bossHp)),int(s.bossMax),"THRONEBREAKER" if s.bossAction=="Melee" else "BRIAR DECREE" if s.bossAction=="Ranged" else "THE KING ADVANCES"]
	dash_button.text="SPACE  Windskip" if float(s.dash)<=0 else "Windskip · %.1fs"%float(s.dash);dash_button.disabled=float(s.dash)>0
	salvo_button.text="E  Flock & Awe" if float(s.salvo)<=0 else "Flock & Awe · %.1fs"%float(s.salvo);salvo_button.disabled=float(s.salvo)>0
	for key in element_buttons:
		var b: Button=element_buttons[key];b.add_theme_color_override("font_color",ELEMENTS[key] if key==s.element else MUTED)
		b.add_theme_stylebox_override("normal",box_style(Color("2b3b2e") if key==s.element else Color("101b18e0"),ELEMENTS[key] if key==s.element else LINE,10,5))
	fps_text.text="%d FPS  ·  %s"%[int(s.fps),current_preset.capitalize()]
	tour_buttons.visible=tour
	controls_text.text="WASD Move    Space Windskip    E Salvo    %s    Scroll Zoom    Esc Pause"%["Mouse Orbit · Free camera" if bool(game.get("free_camera")) else "Right-drag Orbit"]
	if not bool(s.auto):controls_text.text+="    Click Fire"
	var mode := "settings" if settings_open else "training" if str(s.stage)=="training" and not bool(s.ended) else "shop" if str(s.stage)=="shop" and not bool(s.ended) else "pause" if (bool(s.paused) or bool(s.ended)) and not title else ""
	if title and not settings_open:mode=""
	modal_layer.visible=mode!=""
	if mode=="":current_modal="";last_modal_key="";return
	var key: String=mode+":"+str(s.build.revision)+":"+str(s.build.draftRevision)+":"+str(s.gold)+":"+str(s.hp)+":"+str(s.element)+":"+str(s.ended)+":"+str(s.paused)
	if mode=="settings":key="settings"
	if key!=last_modal_key:
		last_modal_key=key;current_modal=mode;rebuild_modal(s,mode)

func rebuild_modal(s: Dictionary, mode: String) -> void:
	for child in modal_panel.get_children():modal_panel.remove_child(child);child.queue_free()
	var light: bool=mode=="training"
	var modal_bg: Color=IVORY if light else SHOP_PANEL if mode=="shop" else PANEL
	var modal_border: Color=Color("d8d3c5") if light else Color("667a6b") if mode=="shop" else LINE
	modal_panel.add_theme_stylebox_override("panel",box_style(modal_bg,modal_border,28,10))
	var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;modal_panel.add_child(scroll)
	modal_content=column(18);modal_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(modal_content)
	match mode:
		"training":build_training(s)
		"shop":build_shop(s)
		"settings":build_settings()
		_:build_pause(s)
	layout()

func build_training(s: Dictionary) -> void:
	var level_number: int=int(s.pendingLevels[0]) if not s.pendingLevels.is_empty() else int(s.level)
	var eyebrow := label("FIELD TRAINING / LEVEL %d"%level_number,12,Color("657366"));eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(eyebrow)
	var heading := label("Choose your edge.",42,INK,true);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(heading)
	var caption := label("One free choice for this level. Your gold stays yours.",15,Color("59665d"));caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(caption)
	modal_content.add_child(divider(Color("b6bcad")))
	var choices := HBoxContainer.new();choices.add_theme_constant_override("separation",16);modal_content.add_child(choices)
	for item in s.build.draft:
		var card := PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size.y=265;card.add_theme_stylebox_override("panel",box_style(Color("f8f5ed"),Color("b3bba9"),20,7));choices.add_child(card)
		var contents := column(13);card.add_child(contents);contents.add_child(icon(str(item.icon),Color("476251"),58))
		contents.add_child(label(str(item.name),21,INK,true));contents.add_child(paragraph(str(item.description),14,Color("47574e")))
		var space := Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;contents.add_child(space)
		var command: String="train:%d:%s"%[int(s.build.draftRevision),str(item.id)];contents.add_child(button("Choose   →",_send.bind(command),false,true))
	var remaining := label("%d free choice%s remaining before the trader."%[s.pendingLevels.size(),"" if s.pendingLevels.size()==1 else "s"],14,Color("59665d"));remaining.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_content.add_child(remaining)

func build_shop(s: Dictionary) -> void:
	var header := row();modal_content.add_child(header)
	var heading := column(5);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
	heading.add_child(label("CAMP / WAVE %d COMPLETE"%int(s.wave),10,SHOP_GOLD))
	heading.add_child(label("The woodland trader.",32,IVORY,true))
	var recovered: Dictionary=s.get("settlement",{})
	heading.add_child(paragraph("Recovered %d gold · %d XP · %s health · %d%% ground recovery"%[int(recovered.get("gold",0)),int(recovered.get("xp",0)),number(float(recovered.get("healed",0))),roundi(float(recovered.get("rate",.5))*100)],11,SHOP_MUTED))
	var wallet := column(3);header.add_child(wallet)
	var coins := label("◉ %d"%int(s.gold),29,SHOP_GOLD,true);coins.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;wallet.add_child(coins)
	var level_line := label("LEVEL %d  ·  %s ARROWS"%[int(s.level),str(s.element).to_upper()],10,SHOP_MUTED);level_line.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;wallet.add_child(level_line)
	modal_content.add_child(divider(Color("516659")))

	var body := row(18);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;modal_content.add_child(body)
	var stock := column(10);stock.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(stock)
	var stock_header := row(8);stock.add_child(stock_header)
	stock_header.add_child(label("TRADER STOCK",11,SHOP_GOLD))
	stock_header.add_child(flex())
	var reroll := button("Reroll · ◉ %d"%int(s.build.rerollCost),_send.bind("reroll"));reroll.disabled=int(s.gold)<int(s.build.rerollCost);reroll.custom_minimum_size=Vector2(150,38);stock_header.add_child(reroll)

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

	var shop_note := paragraph("Hover an offer to highlight it. Purchased cards leave their slot so the shop never shifts under your cursor.",10,SHOP_MUTED)
	stock.add_child(shop_note)
	stock.add_child(divider(Color("405549")))
	var owned_header := row(8);stock.add_child(owned_header)
	owned_header.add_child(label("OWNED / CURRENT RUN",11,SHOP_GOLD));owned_header.add_child(flex())
	owned_header.add_child(label("%d entries"%active_inventory_count(s),10,SHOP_MUTED))
	add_shop_inventory(stock,s,122)

	var sidebar_panel := PanelContainer.new();sidebar_panel.custom_minimum_size.x=255;sidebar_panel.add_theme_stylebox_override("panel",box_style(Color("101c17"),Color("40564a"),16,8));body.add_child(sidebar_panel)
	var sidebar := column(9);sidebar_panel.add_child(sidebar)
	sidebar.add_child(label("ROWAN / STATS",11,SHOP_GOLD));sidebar.add_child(label("Current build",21,IVORY,true))
	add_stats(sidebar,s,true)
	sidebar.add_child(divider(Color("405549")))
	sidebar.add_child(label("ARROW ELEMENT",10,SHOP_MUTED))
	var element_row := GridContainer.new();element_row.columns=2;element_row.add_theme_constant_override("h_separation",5);element_row.add_theme_constant_override("v_separation",5);sidebar.add_child(element_row)
	for element in ["physical","fire","ice","poison"]:
		var b := button("Plain" if element=="physical" else str(element).capitalize(),_send.bind(element))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=35;b.add_theme_font_size_override("font_size",10)
		b.add_theme_color_override("font_color",ELEMENTS[element] if element==s.element else SHOP_MUTED);element_row.add_child(b)
	sidebar.add_child(paragraph("Element gear follows the equipped arrow type. Shared gear stays with Rowan.",10,SHOP_MUTED))

	var footer := row(10);modal_content.add_child(footer)
	footer.add_child(button("Settings",open_settings));footer.add_child(button("Leave run",_return_title));footer.add_child(flex())
	var continue_button := button("Enter wave %d%s   →"%[int(s.wave)+1," · The Briar King" if int(s.wave)==2 else ""],_send.bind("continue"),true)
	continue_button.custom_minimum_size.x=330;footer.add_child(continue_button)

func active_inventory_count(s: Dictionary) -> int:
	var count := 0
	for item in s.build.history:
		var state: String="used" if str(item.id)=="heartwood" and bool(s.build.reviveUsed) else str(item.status)
		if state!="discarded" and not (state=="used" and str(item.id)!="heartwood"):count+=1
	return count

func add_shop_inventory(parent: VBoxContainer, s: Dictionary, height:=120) -> void:
	var scroll := ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;parent.add_child(scroll)
	var grid := GridContainer.new();grid.columns=4;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",7);grid.add_theme_constant_override("v_separation",7);scroll.add_child(grid)
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
		var item: Dictionary=value.item;var rarity_color: Color=RARITIES.get(str(item.get("rarity","common")),SHOP_LINE)
		var tile := PanelContainer.new();tile.name="OwnedItemTile";tile.custom_minimum_size=Vector2(155,52);tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",box_style(SHOP_TILE,rarity_color.lerp(SHOP_LINE,.5),8,6));tile.tooltip_text=str(item.get("description",""))
		grid.add_child(tile)
		var item_row := row(7);tile.add_child(item_row);item_row.add_child(icon(str(item.get("icon","gem")),ELEMENTS.get(str(item.get("element","")),rarity_color),28))
		var item_text := column(1);item_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item_row.add_child(item_text)
		var title_text: String=str(item.name)+(" ×%d"%int(value.count) if int(value.count)>1 else "")
		item_text.add_child(paragraph(title_text,10,IVORY))
		var source_text: String="Spent" if value.state=="used" else "Training" if str(item.source)=="level" else str(item.get("rarity","common")).capitalize()
		item_text.add_child(label(source_text,8,SHOP_MUTED))
		if value.state=="used":tile.modulate=Color(1,1,1,.52)

func shop_card_style(rarity_color: Color, hovered: bool, mythic: bool) -> StyleBoxFlat:
	var border: Color=rarity_color.lerp(SHOP_GOLD,.28) if hovered else rarity_color.lerp(SHOP_LINE,.35)
	var style := box_style(SHOP_CARD_HOVER if hovered else SHOP_CARD,border,13,8)
	style.border_width_top=3
	style.shadow_color=Color(rarity_color,.22 if hovered else .09)
	style.shadow_size=8 if hovered else 3
	style.shadow_offset=Vector2(0,2 if hovered else 1)
	if mythic:
		style.shadow_color=Color("f3686255") if hovered else Color("db4a3b33")
		style.shadow_size=10 if hovered else 6
	return style

func projected_stats(item: Dictionary, s: Dictionary) -> Dictionary:
	var result: Dictionary=s.build.stats.duplicate(true)
	var effects: Dictionary=item.get("effects",{})
	for key in effects:
		if result.has(key):result[key]=float(result[key])+float(effects[key])
	result.economy=minf(50,float(result.economy));result.haste=minf(.45,float(result.haste));result.crit=minf(.6,float(result.crit));result.salvage=minf(.75,float(result.salvage))
	return result

func arrow_damage_for(p: Dictionary, element: String) -> float:
	return float(p.damage)*(1+float(p.damage_bonus))+(float(p.elemental_power)*(1+float(p.element_bonus)) if element!="physical" else 0)

func armor_reduction(value: float) -> int:
	return roundi(value/(20+value)*100) if value>0 else 0

func shop_payoffs(item: Dictionary, s: Dictionary) -> Array[String]:
	var lines: Array[String]=[]
	var before: Dictionary=s.build.stats;var after: Dictionary=projected_stats(item,s);var effects: Dictionary=item.get("effects",{});var element: String=str(s.element)
	if effects.has("damage") or effects.has("damage_bonus") or effects.has("elemental_power") or effects.has("element_bonus"):
		lines.append("Arrow damage  %s → %s"%[number(arrow_damage_for(before,element)),number(arrow_damage_for(after,element))])
	if effects.has("elemental_power"):lines.append("Elemental power  %s → %s"%[number(float(before.elemental_power)),number(float(after.elemental_power))])
	if effects.has("max_hp"):
		lines.append("Max health  %s → %s"%[number(float(before.max_hp)),number(float(after.max_hp))])
		lines.append("Heal now  +%s"%number(float(after.max_hp)-float(before.max_hp)))
	if effects.has("armor"):lines.append("Armor  %s → %s  ·  %d%% → %d%% reduction"%[number(float(before.armor)),number(float(after.armor)),armor_reduction(float(before.armor)),armor_reduction(float(after.armor))])
	if effects.has("speed_bonus"):lines.append("Move speed  %.2f → %.2f m/s"%[5*(1+float(before.speed_bonus)),5*(1+float(after.speed_bonus))])
	if effects.has("pickup_radius"):lines.append("Pickup radius  %.2f → %.2f m"%[float(before.pickup_radius),float(after.pickup_radius)])
	if effects.has("economy"):lines.append("Shop savings  %d%% → %d%%"%[int(before.economy),int(after.economy)])
	if effects.has("salvage"):lines.append("Ground recovery  %d%% → %d%%"%[roundi(float(before.salvage)*100),roundi(float(after.salvage)*100)])
	if effects.has("gold_bonus"):lines.append("Gold earned  +%d%% → +%d%%"%[roundi(float(before.gold_bonus)*100),roundi(float(after.gold_bonus)*100)])
	if effects.has("heal"):lines.append("Restore now  +%d HP"%roundi(float(effects.heal)*float(s.maxHp)))
	if effects.has("attack_speed"):lines.append("Attack cadence  %.2f → %.2f sec"%[.8/(1+float(before.attack_speed)),.8/(1+float(after.attack_speed))])
	if effects.has("pet_damage"):lines.append("Fox damage  %.2f× → %.2f×"%[float(before.pet_damage),float(after.pet_damage)])
	if effects.has("crit"):lines.append("Critical chance  %d%% → %d%%"%[roundi(float(before.crit)*100),roundi(float(after.crit)*100)])
	if effects.has("heal_kill"):lines.append("Heal on kill  %s → %s HP"%[number(float(before.heal_kill)),number(float(after.heal_kill))])
	if effects.has("regen"):lines.append("Regeneration  %.1f → %.1f HP/sec"%[float(before.regen),float(after.regen)])
	if effects.has("haste"):lines.append("Cooldown reduction  %d%% → %d%%"%[roundi(float(before.haste)*100),roundi(float(after.haste)*100)])
	if effects.has("revive"):lines.append("Survive one lethal hit this run");lines.append("Revive with 35% maximum health")
	if effects.has("burn_bonus"):
		var before_burn: float=float(before.elemental_power)*.75*(1+float(before.burn_bonus));var after_burn: float=float(after.elemental_power)*.75*(1+float(after.burn_bonus))
		lines.append("Burn damage  %.1f → %.1f / sec"%[before_burn,after_burn])
	if effects.has("venom_bonus"):
		var before_poison: float=float(before.elemental_power)*.375*(1+float(before.venom_bonus));var after_poison: float=float(after.elemental_power)*.375*(1+float(after.venom_bonus))
		lines.append("Poison / stack  %.1f → %.1f / sec"%[before_poison,after_poison])
	if effects.has("slow_bonus"):lines.append("Ice slow  %d%% → %d%%"%[roundi(minf(.6,.35+float(before.slow_bonus))*100),roundi(minf(.6,.35+float(after.slow_bonus))*100)])
	if effects.has("stacks"):lines.append("Poison stacks  %d → %d"%[int(before.stacks),int(after.stacks)])
	if effects.has("duration"):
		var base_duration: float=3 if element=="fire" else 2.5 if element=="ice" else 4
		lines.append("%s duration  %.1f → %.1f sec"%["Burn" if element=="fire" else "Ice slow" if element=="ice" else "Poison",base_duration+float(before.duration),base_duration+float(after.duration)])
	if lines.is_empty():lines.append(str(item.get("description","Upgrade your current build.")))
	return lines

func shop_card(item: Dictionary, s: Dictionary) -> Control:
	var card := PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size=Vector2(195,275);card.mouse_filter=Control.MOUSE_FILTER_PASS
	var rarity_color: Color=RARITIES.get(str(item.rarity),SHOP_MUTED);var mythic: bool=str(item.rarity)=="mythic"
	card.add_theme_stylebox_override("panel",shop_card_style(rarity_color,false,mythic))
	card.mouse_entered.connect(func():card.add_theme_stylebox_override("panel",shop_card_style(rarity_color,true,mythic)))
	card.mouse_exited.connect(func():card.add_theme_stylebox_override("panel",shop_card_style(rarity_color,false,mythic)))
	var content := column(7);card.add_child(content)
	var item_heading := row(7);content.add_child(item_heading);var element: String=str(item.get("element",""));item_heading.add_child(icon(str(item.icon),ELEMENTS.get(element,rarity_color),42))
	var names := column(2);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item_heading.add_child(names)
	names.add_child(label(str(item.rarity).to_upper()+(" / "+element.to_upper() if element!="" else ""),8,rarity_color))
	var title := paragraph(str(item.name),15,IVORY);title.add_theme_font_override("font",serif_font);names.add_child(title)
	var description := paragraph(str(item.description),9,SHOP_MUTED);description.custom_minimum_size.y=32;content.add_child(description)
	var payoff_panel := PanelContainer.new();payoff_panel.add_theme_stylebox_override("panel",box_style(Color("101d17"),Color("355044"),8,5));content.add_child(payoff_panel)
	var payoff_box := column(2);payoff_panel.add_child(payoff_box);payoff_box.add_child(label("PAYOFF",8,SHOP_GAIN))
	for payoff in shop_payoffs(item,s):
		var payoff_label := paragraph("＋  "+payoff,9,SHOP_GAIN);payoff_label.name="ShopPayoff";payoff_box.add_child(payoff_label)
	var space := Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(space)
	var full: bool=str(item.id)=="bandages" and float(s.hp)>=float(s.maxHp)
	var sold: bool=bool(item.sold);var eligible: bool=bool(item.get("eligible",true));var affordable: bool=bool(item.affordable)
	var caption: String="Packed  ✓" if sold else "Unavailable" if not eligible else "Health full" if full else "Need ◉ %d"%int(item.cost) if not affordable else "Buy · ◉ %d"%int(item.cost)
	var buy := button(caption,_send.bind("buy:"+str(item.id)));buy.custom_minimum_size.y=38
	buy.disabled=sold or not eligible or not affordable or full
	buy.add_theme_stylebox_override("normal",box_style(Color("203229"),rarity_color.lerp(SHOP_LINE,.45),10,6))
	buy.add_theme_stylebox_override("hover",box_style(Color("2d4437"),rarity_color.lerp(SHOP_GOLD,.42),10,6))
	buy.add_theme_stylebox_override("pressed",box_style(Color("17261f"),SHOP_GOLD,10,6))
	buy.add_theme_stylebox_override("disabled",box_style(Color("17231e"),Color("3d4c43"),10,6))
	buy.add_theme_color_override("font_color",IVORY);buy.add_theme_color_override("font_hover_color",Color("fff5da"));buy.add_theme_color_override("font_pressed_color",IVORY);buy.add_theme_color_override("font_disabled_color",Color(SHOP_MUTED,.45))
	content.add_child(buy)
	var owned_text: String="ONE PER RUN" if str(item.id)=="heartwood" else "OWNED %d / %d"%[int(item.owned),int(item.cap)]
	content.add_child(label(owned_text,8,SHOP_MUTED))
	return card

func add_stats(parent: VBoxContainer, s: Dictionary, compact:=false) -> void:
	var p: Dictionary=s.build.stats;var arrow: float=float(p.damage)*(1+float(p.damage_bonus))+(float(p.elemental_power)*(1+float(p.element_bonus)) if str(s.element)!="physical" else 0)
	var stats: Array=[["Maximum health",number(float(p.max_hp))],["Arrow damage",number(arrow)],["Elemental power",number(float(p.elemental_power))],["Armor",number(float(p.armor))+" · %d%% reduction"%roundi(float(p.armor)/(20+float(p.armor))*100)],["Move speed","%.2f m/s"%(5*(1+float(p.speed_bonus)))],["Attack cadence","%.2f sec"%(.8/(1+float(p.attack_speed)))],["Pickup radius","%.2f m"%float(p.pickup_radius)],["Economy","%d%% savings"%int(p.economy)],["Gold earned","+%d%%"%roundi(float(p.gold_bonus)*100)],["Ground recovery","%d%%"%roundi(float(p.salvage)*100)],["Fox damage","%.2f×"%float(p.pet_damage)],["Critical chance","%d%%"%roundi(float(p.crit)*100)],["Cooldown reduction","%d%%"%roundi(float(p.haste)*100)],["Regeneration","%.1f / sec"%float(p.regen)]]
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
	settings_resume=not bool(current_state.get("paused",false)) and not bool(current_state.get("ended",false)) and not bool(game.get("is_title")) and str(current_state.get("stage","")) not in ["shop","training"]
	if settings_resume:game.call("consume_command","pause")
	settings_open=true;last_modal_key="";refresh()

func close_settings() -> void:
	settings_open=false
	if settings_resume and bool(game.get("paused")):game.call("consume_command","pause")
	settings_resume=false;last_modal_key="";refresh()

func toggle_fullscreen() -> void:
	var mode: int=DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN] else DisplayServer.WINDOW_MODE_FULLSCREEN)
