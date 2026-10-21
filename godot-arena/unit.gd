class_name HuntUnit
extends Node3D
## A real animated actor. The arena owns combat; this node owns skeletal presentation.
var actor: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var kind := "briarling"
var hp := 60.0
var maximum := 60.0
var radius := .4
var height := 1.0
var speed := 2.2
var clip := "Idle"
var anim_time := 0.0
var action_time := 0.0
var state := "Chase"
var cooldown := 0.0
var fired := false
var release_index := 0
var aim := Vector3.FORWARD
var attack_center := Vector3.ZERO
var charge_start := Vector3.ZERO
var wave_hit := false
var fire_time := 0.0
var poison_time := 0.0
var poison_stacks := 0
var ice_time := 0.0
var dot_clock := 0.0
var flash := 0.0
var dead_time := 0.0
var materials: Array[ShaderMaterial] = []
var hp_bar: Node3D
var hp_fill: MeshInstance3D
var warning: MeshInstance3D
var base_aim := 0.0
var blend_from: Array[Transform3D] = []
var blend_elapsed := .08
const BLEND_DURATION := .08
static var shader: Shader

func configure(id: String) -> void:
	kind = id
	var file := id+"-motion.glb" if id!="briar-king" else "briar-king.glb"
	actor = load("res://assets/"+file).instantiate()
	add_child(actor)
	animation = actor.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = actor.find_children("*","Skeleton3D",true,false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name in animation.get_animation_list():animation.get_animation(name).loop_mode = Animation.LOOP_NONE
	match id:
		"rowan":maximum=140;radius=.4;height=2.15;speed=5.0
		"fox":maximum=1;radius=.25;height=.95;speed=4.5
		"briar-king":maximum=1200;radius=1.0;height=4.05;speed=1.65
		"sporecaller":maximum=90;radius=.42;height=1.6;speed=1.35
		"thornback":maximum=145;radius=.6;height=1.6;speed=1.8
		_:maximum=70;radius=.38;height=1.55;speed=2.1
	hp = maximum
	if shader==null:
		shader = Shader.new()
		shader.code = "shader_type spatial; uniform sampler2D palette_tex:source_color; uniform float flash=0.0; uniform vec4 element:source_color=vec4(1.0); uniform float amount=0.0; void fragment(){vec3 base=texture(palette_tex,UV).rgb;ALBEDO=mix(mix(base,element.rgb,amount),vec3(1.0,.87,.70),flash*.85);ROUGHNESS=.75;}"
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.albedo_texture and not original.emission_enabled:
				var mat := ShaderMaterial.new()
				mat.shader = shader
				mat.set_shader_parameter("palette_tex",original.albedo_texture)
				mesh.set_surface_override_material(i,mat)
				materials.append(mat)
	if id=="rowan":
		play("Shoot")
		animation.seek(1.75,true)
		var direction := socket("bow")+Vector3.UP*.08-socket("bowstring")
		base_aim = atan2(direction.x,direction.z)
	play("Idle")
	blend_from.clear()
	blend_elapsed = BLEND_DURATION
	animation.seek(0,true)

func play(name: String, restart := false) -> void:
	if clip==name and not restart and animation.current_animation==name:return
	if not animation.has_animation(name):name="Idle"
	# AnimationPlayer's own crossfade clock does not progress through seek().
	# Sample unblended authored poses, then blend local bones on our simulation clock.
	blend_from.clear()
	for i in skeleton.get_bone_count():blend_from.append(skeleton.get_bone_pose(i))
	blend_elapsed = 0
	clip = name
	anim_time = 0
	animation.stop()
	animation.play(name,0)
	animation.advance(0)
	for i in blend_from.size():skeleton.set_bone_pose(i,blend_from[i])

func pose(dt: float, rate := 1.0) -> void:
	anim_time += dt*rate
	var length := animation.get_animation(clip).length
	animation.seek(fmod(anim_time,length) if clip in ["Idle","Run","RunShoot","Trot"] else minf(anim_time,length),true)
	blend_elapsed = minf(BLEND_DURATION,blend_elapsed+dt)
	if blend_elapsed<BLEND_DURATION and blend_from.size()==skeleton.get_bone_count():
		var weight := smoothstep(0,BLEND_DURATION,blend_elapsed)
		for i in skeleton.get_bone_count():
			skeleton.set_bone_pose(i,blend_from[i].interpolate_with(skeleton.get_bone_pose(i),weight))
	flash = maxf(0,flash-dt)
	var tint := Color("ef564e") if fire_time>0 else Color("61c9ee") if ice_time>0 else Color("b16de5")
	var amount := .32 if fire_time>0 or ice_time>0 or poison_time>0 else 0.0
	for mat in materials:
		mat.set_shader_parameter("flash",flash/.15)
		mat.set_shader_parameter("element",tint)
		mat.set_shader_parameter("amount",amount)
	if hp_fill:
		var fraction := clampf(hp/maximum,0,1)
		hp_fill.scale.x = maxf(.001,fraction)
		hp_fill.position.x = -.35*(1-fraction)
	if hp_bar:hp_bar.visible = hp>0

func socket(bone: String, offset := Vector3.ZERO) -> Vector3:
	var index := skeleton.find_bone(bone)
	if index<0:return global_position+Vector3.UP
	return skeleton.global_transform*skeleton.get_bone_global_pose(index)*offset

func face(point: Vector3, dt: float, turn := 14.0) -> void:
	var delta := point-global_position
	if Vector2(delta.x,delta.z).length()<.02:return
	rotation.y = rotate_toward(rotation.y,atan2(delta.x,delta.z)-(base_aim if kind=="rowan" else 0.0),dt*turn)

func clear_status() -> void:
	fire_time=0;poison_time=0;poison_stacks=0;ice_time=0;dot_clock=0
