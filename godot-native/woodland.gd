extends Node3D
## The Emberwood: original beveled ruin, layered forest and bounded ambient motion.
const RUIN = preload("res://assets/environment/emberwood-ruin.glb")
const FLAME = preload("res://shaders/ember_flame.gdshader")
const FIREFLY = preload("res://shaders/firefly.gdshader")
var fire_lights: Array[OmniLight3D] = []
var motes: MultiMeshInstance3D
var ember_motes: MultiMeshInstance3D
var fires: Array[Vector3] = []
var clock := 0.0
var owner_arena: Node3D
var reflected_scene: ReflectionProbe

func build(arena: Node3D) -> void:
	owner_arena=arena
	var ruin := RUIN.instantiate()
	ruin.name="EmberwoodRuin"
	add_child(ruin)
	# Imported texture filtering retains fine stone/bark details at oblique angles.
	for node in ruin.find_children("*","MeshInstance3D",true,false):
		# Reserve layer 2 for the static reflection capture; actors remain dynamic.
		node.layers=2
		for i in node.mesh.get_surface_count():
			var surface=node.mesh.surface_get_material(i)
			if surface is StandardMaterial3D:
				surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if "Weathered slate" in surface.resource_name:
					surface.albedo_color=Color(.64,.69,.76)
					surface.roughness=.72
					surface.normal_scale=.36
				if "Forest loam" in surface.resource_name:surface.albedo_color=Color(.45,.53,.60)
				if "Leaf" in surface.resource_name or "Moss" in surface.resource_name:surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/emberwood-layout.json"))
	for item in data.obstacles:
		arena.obstacles.append({"p":Vector3(item.p[0],0,item.p[2]),"r":float(item.r),"h":float(item.h)})
	for item in data.fires:fires.append(Vector3(item[0],item[1],item[2]))
	configure_light(arena.world.environment)
	for i in fires.size():make_fire(fires[i],i)
	motes=make_motes(52,Color("bfd9a1"),.022)
	ember_motes=make_motes(fires.size()*10,Color("ffb83d"),.018)
	set_process(true)

func configure_light(env: Environment) -> void:
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("14243b")
	sky_material.sky_horizon_color=Color("465b76")
	sky_material.ground_bottom_color=Color("121c1b")
	sky_material.ground_horizon_color=Color("283847")
	sky_material.sky_curve=.65
	sky_material.sky_energy_multiplier=.62
	sky.sky_material=sky_material
	env.sky=sky
	env.background_mode=Environment.BG_SKY
	env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color=Color("c6dbd5")
	env.ambient_light_energy=.28
	env.ambient_light_sky_contribution=.7
	env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure=1.0
	env.fog_enabled=true
	env.fog_light_color=Color("31445f")
	env.fog_light_energy=.42
	env.fog_density=.006
	env.fog_sky_affect=.25
	# High quality enables this restrained volume; Balanced keeps regular depth fog.
	env.volumetric_fog_density=.009
	env.volumetric_fog_albedo=Color("91a4b5")
	env.volumetric_fog_length=50
	var advanced := RenderingServer.get_current_rendering_method()=="forward_plus"
	env.glow_enabled=advanced
	env.glow_intensity=.42
	env.glow_bloom=.03
	env.glow_hdr_threshold=1.8
	env.ssao_enabled=advanced
	env.ssao_radius=1.4
	env.ssao_intensity=1.5
	env.ssao_power=1.25
	for child in owner_arena.get_children():
		if child is DirectionalLight3D:
			child.rotation_degrees=Vector3(-38,-32,0)
			child.light_color=Color("ffdbac")
			child.light_energy=.85
			child.shadow_enabled=true
			child.directional_shadow_max_distance=55
			child.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			child.shadow_bias=.035
			child.shadow_normal_bias=.7
	# Cool, shadowless fill keeps silhouetted cloth and bark readable from behind.
	var rim := DirectionalLight3D.new()
	rim.name="TwilightFill"
	rim.rotation_degrees=Vector3(-22,155,0)
	rim.light_color=Color("8ab5d6")
	rim.light_energy=.26
	rim.shadow_enabled=false
	add_child(rim)
	reflected_scene=ReflectionProbe.new()
	reflected_scene.name="RuinReflection"
	reflected_scene.position=Vector3(0,3,0)
	reflected_scene.size=Vector3(39,14,39)
	reflected_scene.max_distance=48
	reflected_scene.intensity=.65
	reflected_scene.update_mode=ReflectionProbe.UPDATE_ONCE
	reflected_scene.enable_shadows=false
	reflected_scene.cull_mask=2
	add_child(reflected_scene)

func make_fire(point: Vector3, index: int) -> void:
	var light := OmniLight3D.new()
	light.name="BrazierLight"+str(index)
	light.position=point+Vector3.UP*.35
	light.light_color=Color("ffb257")
	light.light_energy=2.3
	light.omni_range=8.5
	light.omni_attenuation=1.2
	light.shadow_enabled=false
	add_child(light)
	fire_lights.append(light)
	for j in 3:
		var flame := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius=.015;mesh.bottom_radius=.22-j*.035;mesh.height=1.05-j*.15;mesh.radial_segments=12;mesh.rings=6
		var material := ShaderMaterial.new()
		material.shader=FLAME
		material.set_shader_parameter("phase",index*1.7+j*2.0)
		material.set_shader_parameter("flame_color",Color("f17618") if j==0 else Color("ffc452"))
		flame.mesh=mesh;flame.material_override=material;flame.layers=2
		flame.position=point+Vector3(sin(j*2.1)*.11,.32+j*.06,cos(j*2.1)*.11)
		flame.scale=Vector3(1,.9+j*.1,.65)
		add_child(flame)

func make_motes(count: int, color: Color, radius: float) -> MultiMeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=5;mesh.rings=3
	var material := ShaderMaterial.new();material.shader=FIREFLY;material.set_shader_parameter("color",color)
	var multi := MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=mesh;multi.instance_count=count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh=multi;instance.material_override=material
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb=AABB(Vector3(-35,-2,-35),Vector3(70,20,70))
	add_child(instance)
	return instance

func _process(delta: float) -> void:
	if not is_instance_valid(owner_arena):return
	if owner_arena.paused:return
	clock+=minf(delta,.1)
	for i in fire_lights.size():
		fire_lights[i].light_energy=2.3+sin(clock*6+i*1.4)*.12+sin(clock*11.3+i)*.06
	if is_instance_valid(motes):
		for i in motes.multimesh.instance_count:
			var angle := i*2.399+sin(clock*.12+i)*.12
			var radius := 11.0+fmod(i*3.71,14.0)
			var p := Vector3(cos(angle)*radius,.6+fmod(i*.89,3.6)+sin(clock*.65+i)*.25,sin(angle)*radius)
			var scale := .4+.6*maxf(0,sin(clock*.8+i*2.4))
			motes.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),p))
	if is_instance_valid(ember_motes):
		for i in ember_motes.multimesh.instance_count:
			var age := fmod(clock*.36+i*.137,1.0)
			var p := fires[i/10]+Vector3(sin(clock+i*2.2)*age*.4,age*1.6,cos(clock*.9+i)*age*.4)
			ember_motes.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(1-age)),p))
