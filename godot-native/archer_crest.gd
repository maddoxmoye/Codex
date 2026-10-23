extends Control
## Lightweight illustrated heraldry; no model or extra 3D viewport on selection cards.
var archer_id := "rowan"
var accent := Color.WHITE
var selected := false
var hovered := false
var lift := 0.0
func setup(id: String, color: Color) -> void:
	archer_id=id;accent=color;custom_minimum_size=Vector2(100,132);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt: float) -> void:
	var target := 1.0 if hovered or selected else 0.0
	var next := move_toward(lift,target,dt*5)
	if next!=lift:lift=next;queue_redraw()
func stroke(points: Array, color: Color, width:=3.0) -> void:
	draw_polyline(PackedVector2Array(points),color,width,true)
func _draw() -> void:
	var center := size*.5+Vector2(0,-lift*4)
	draw_set_transform(center)
	var ink := Color("343934")
	draw_circle(Vector2(0,5),49,Color(ink,.08))
	draw_circle(Vector2.ZERO,48,accent.darkened(.12))
	draw_circle(Vector2.ZERO,43,accent.lightened(.22))
	draw_arc(Vector2.ZERO,39,0,TAU,64,Color(ink,.25),1.0,true)
	match archer_id:
		"rowan":
			stroke([Vector2(-14,-28),Vector2(7,-15),Vector2(14,0),Vector2(7,15),Vector2(-14,28)],ink,4)
			stroke([Vector2(-14,-28),Vector2(-4,0),Vector2(-14,28)],ink,1.5)
			stroke([Vector2(-29,0),Vector2(30,0),Vector2(21,-8)],ink)
			stroke([Vector2(30,0),Vector2(21,8)],ink)
		"ash":
			var flame := PackedVector2Array([Vector2(0,-32),Vector2(8,-9),Vector2(21,-18),Vector2(25,8),Vector2(12,28),Vector2(-11,28),Vector2(-26,8),Vector2(-19,-12),Vector2(-10,0)])
			draw_colored_polygon(flame,ink)
			draw_colored_polygon(PackedVector2Array([Vector2(1,-6),Vector2(12,14),Vector2(0,24),Vector2(-11,14)]),accent.lightened(.55))
		"briar":
			var shield := [Vector2(0,-30),Vector2(25,-20),Vector2(22,9),Vector2(0,30),Vector2(-22,9),Vector2(-25,-20),Vector2(0,-30)]
			draw_colored_polygon(PackedVector2Array(shield),ink)
			stroke([Vector2(-14,-9),Vector2(-2,13),Vector2(16,-16)],accent.lightened(.5),4)
		"nyx":
			draw_circle(Vector2.ZERO,28,ink)
			draw_circle(Vector2(13,-9),25,accent.lightened(.22))
			stroke([Vector2(17,8),Vector2(17,25)],ink,2)
			stroke([Vector2(9,16),Vector2(25,16)],ink,2)
		"pip":
			for i in 12:
				var direction := Vector2.from_angle(TAU*i/12)
				stroke([direction*25,direction*34],ink,7)
			draw_circle(Vector2.ZERO,27,ink)
			draw_circle(Vector2.ZERO,19,accent.lightened(.4))
			stroke([Vector2(0,-13),Vector2(0,0),Vector2(10,6)],ink,3)
	if selected:
		draw_circle(Vector2(34,34),12,ink)
		stroke([Vector2(28,34),Vector2(32,38),Vector2(40,29)],Color("fff5dd"),2.5)
