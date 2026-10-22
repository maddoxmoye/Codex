extends SubViewportContainer
## Native staged reveal. Its clock belongs to the reward UI, never to combat.
signal completed
const TIMING := {"normal":{"land":.35,"shake":.8,"open":1.2,"reward":1.45,"done":2.0},"mythic":{"land":.5,"shake":1.25,"open":1.85,"reward":2.15,"done":2.9}}
var elapsed := 0.0
var finished := false
var chest: Node3D
var lid: Node3D
var treasure: MeshInstance3D
var rays: Node3D
var sparks: Array[MeshInstance3D]=[]
var timing: Dictionary
var view: SubViewport
var glow: OmniLight3D
func part(parent: Node3D, size: Vector3, color: Color, point: Vector3, emission := 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new();var shape := BoxMesh.new();shape.size=size;mesh.mesh=shape
	var material := StandardMaterial3D.new();material.albedo_color=color;material.roughness=.45;material.metallic=.65 if emission>0 else .05
	if emission>0:material.emission_enabled=true;material.emission=color;material.emission_energy_multiplier=emission
	mesh.material_override=material;parent.add_child(mesh);mesh.position=point
	return mesh
func setup(mythic: bool, rarity: Color, texture: Texture2D) -> void:
	stretch=true;custom_minimum_size=Vector2(360,320);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE
	timing=TIMING.mythic if mythic else TIMING.normal
	view=SubViewport.new();view.size=Vector2i(640,420);view.own_world_3d=true;view.transparent_bg=true;add_child(view)
	var scene := Node3D.new();view.add_child(scene)
	var environment := WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("fff2df");environment.environment.ambient_light_energy=.7;scene.add_child(environment)
	var light := DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);light.light_energy=1.5;scene.add_child(light)
	var camera := Camera3D.new();scene.add_child(camera);camera.position=Vector3(2.6,2.4,4.7);camera.look_at(Vector3(0,1.0,0));camera.fov=39
	chest=Node3D.new();scene.add_child(chest)
	var wood := Color("9c382f") if mythic else Color("47735a")
	var brass := Color("efbd65") if mythic else Color("b8a279")
	part(chest,Vector3(1.75,.78,1),wood,Vector3(0,.43,0))
	# Individual timber seams and forged bands read as a physical object.
	for y in [.22,.45,.68]:part(chest,Vector3(1.76,.025,1.01),wood.darkened(.3),Vector3(0,y,0))
	for x in [-.63,.63]:part(chest,Vector3(.14,.88,1.05),brass,Vector3(x,.45,0),.08)
	part(chest,Vector3(1.82,.10,1.08),brass,Vector3(0,.07,0),.08)
	lid=Node3D.new();chest.add_child(lid);lid.position=Vector3(0,.83,-.5)
	part(lid,Vector3(1.82,.22,1.08),wood.lightened(.08),Vector3(0,.1,.5))
	for x in [-.63,.63]:part(lid,Vector3(.15,.25,1.10),brass,Vector3(x,.1,.5),.08)
	part(lid,Vector3(.28,.33,.07),brass,Vector3(0,-.04,1.07),.1)
	glow=OmniLight3D.new();scene.add_child(glow);glow.position=Vector3(0,1,0);glow.light_color=rarity;glow.omni_range=4
	rays=Node3D.new();scene.add_child(rays);rays.position=Vector3(0,1.1,0)
	for i in (16 if mythic else 10):
		var ray := part(rays,Vector3(.025,1.4,.025),rarity,Vector3.ZERO,1.5)
		ray.rotation.z=TAU*i/(16 if mythic else 10);ray.position=Vector3(sin(ray.rotation.z),cos(ray.rotation.z),0)*.8
	for i in (32 if mythic else 16):
		var spark := part(scene,Vector3.ONE*.035,brass,Vector3.ZERO,1.0);sparks.append(spark)
	treasure=MeshInstance3D.new();var quad := QuadMesh.new();quad.size=Vector2.ONE*.8;treasure.mesh=quad
	var mat := StandardMaterial3D.new();mat.albedo_texture=texture;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.no_depth_test=true
	treasure.material_override=mat;scene.add_child(treasure)
	advance(0)
func _process(dt: float) -> void:advance(minf(dt,.1))
func advance(dt: float) -> void:
	if timing.is_empty():return
	elapsed+=dt
	var drop := clampf(elapsed/float(timing.land),0,1)
	chest.position.y=2.5*pow(1-drop,3)+sin(drop*PI*2)*.1*(1-drop)
	var shaking := elapsed>float(timing.land) and elapsed<float(timing.shake)
	chest.rotation.z=sin(elapsed*65)*.035 if shaking else 0.0
	var opening := smoothstep(float(timing.shake),float(timing.open),elapsed)
	lid.rotation.x=-1.95*opening
	glow.light_energy=opening*2
	rays.visible=opening>.05;rays.scale=Vector3.ONE*maxf(.001,opening);rays.rotation.z=elapsed*.18
	treasure.visible=elapsed>float(timing.open)
	treasure.position=Vector3(0,lerpf(.8,2.0,smoothstep(float(timing.open),float(timing.reward),elapsed)),.1)
	for i in sparks.size():
		var spark := sparks[i];spark.visible=opening>.1
		var phase := fposmod(elapsed-float(timing.shake)+float(i)*.061,1.8)/1.8
		var angle := i*2.39996
		spark.position=Vector3(sin(angle)*phase,1+phase*1.8,cos(angle)*phase);spark.scale=Vector3.ONE*(1-phase)*opening
	if elapsed>=float(timing.done) and not finished:finished=true;completed.emit()
