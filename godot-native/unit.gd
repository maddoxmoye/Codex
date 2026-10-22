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
var damage_scale := 1.0
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
static var gait_cache := {}
const LOWER_BODY := ["hips","thigh.L","shin.L","foot.L","thigh.R","shin.R","foot.R"]
const ARCHERS := ["rowan","ash","briar","nyx","pip"]
const AIMING_CLIPS := ["Idle","Run","Shoot","RunShoot","Salvo","Arrowpalooza","Quiverquake","HuntersMoon","Gearstorm","HareTrigger","Shell","Bramble","BorrowedTime"]
const RUN_STRIDE_SPEED := 2.27272727
var motion_enabled := false
var motion_target := Vector3.ZERO
var motion_velocity := Vector3.ZERO
var motion_clock := 0.0
var gait_time := 0.0
var gait_weight := 0.0
var gait_yaw := 0.0
var motion_layer := 1.0
var turning_lean := 0.0
var last_facing := 0.0
var gait_bones: Array[int] = []
var gait_frames: Array = []
var gait_idle: Array = []
var gait_length := .8
var spine_bone := -1
var bow_bone := -1
var cape_bone := -1
var tail_bones: Array[int] = []

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
		"rowan","ash","briar","nyx","pip":maximum=140;radius=.4;height=2.15;speed=5.0
		"fox":maximum=1;radius=.25;height=.95;speed=4.5
		"briar-king":maximum=1200;radius=1.0;height=4.05;speed=1.65
		"sporecaller":maximum=90;radius=.42;height=1.6;speed=1.35
		"thornback":maximum=145;radius=.6;height=1.6;speed=1.8
		_:maximum=70;radius=.38;height=1.55;speed=2.1
	hp = maximum
	if shader==null:
		shader = load("res://shaders/actor_surface.gdshader")
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.albedo_texture and not original.emission_enabled:
				var mat := ShaderMaterial.new()
				mat.shader = shader
				mat.set_shader_parameter("palette_tex",original.albedo_texture)
				mat.set_shader_parameter("base_roughness",original.roughness)
				mat.set_shader_parameter("base_metallic",original.metallic)
				mat.set_shader_parameter("grain",.025 if original.metallic>.3 else .055)
				mat.set_shader_parameter("surface_kind",1.0 if id=="fox" else 2.0 if id in ["briarling","briar-king"] else 0.0)
				mesh.set_surface_override_material(i,mat)
				materials.append(mat)
	if id in ARCHERS:
		play("Shoot")
		animation.seek(1.75,true)
		var direction := socket("bow")+Vector3.UP*.08-socket("bowstring")
		base_aim = atan2(direction.x,direction.z)
		prepare_gait()
	if id=="fox":
		for name in ["tail01","tail02","tail03"]:tail_bones.append(skeleton.find_bone(name))
	play("Idle")
	blend_from.clear()
	blend_elapsed = BLEND_DURATION
	animation.seek(0,true)

func play(name: String, restart := false) -> void:
	if clip==name and not restart and animation.current_animation==name:return
	if not animation.has_animation(name):name="Idle"
	if motion_enabled and kind in ARCHERS and clip not in AIMING_CLIPS and name in AIMING_CLIPS:motion_layer=0.0
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
	# A paused frame must retain the final layered pose, rather than repeatedly
	# converting global and local transforms and accumulating floating-point drift.
	if dt>0:
		if motion_enabled:update_motion(dt)
		anim_time += dt*rate
		var length := animation.get_animation(clip).length
		var sample_time := fmod(anim_time,length) if clip in ["Idle","Run","RunShoot","Trot"] else minf(anim_time,length)
		if motion_enabled and ((kind=="fox" and clip=="Trot") or (kind in ARCHERS and clip=="Run")):
			sample_time=fposmod(gait_time,length)
		animation.seek(sample_time,true)
		blend_elapsed = minf(BLEND_DURATION,blend_elapsed+dt)
		if blend_elapsed<BLEND_DURATION and blend_from.size()==skeleton.get_bone_count():
			var weight := smoothstep(0,BLEND_DURATION,blend_elapsed)
			for i in skeleton.get_bone_count():
				skeleton.set_bone_pose(i,blend_from[i].interpolate_with(skeleton.get_bone_pose(i),weight))
		if motion_enabled and kind in ARCHERS and clip in AIMING_CLIPS:layer_gait()
		if motion_enabled and kind=="fox":layer_fox_turn()
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

func configure_motion(world_velocity: Vector3, _dt: float) -> void:
	## Movement owns position; this layer only animates the rig from measured travel.
	motion_enabled=true
	motion_target=world_velocity
	motion_target.y=0

func reset_motion() -> void:
	motion_target=Vector3.ZERO;motion_velocity=Vector3.ZERO;motion_clock=0;gait_time=0;gait_weight=0;gait_yaw=0;motion_layer=1;turning_lean=0;last_facing=rotation.y

func prepare_gait() -> void:
	for name in LOWER_BODY:gait_bones.append(skeleton.find_bone(name))
	spine_bone=skeleton.find_bone("spine");bow_bone=skeleton.find_bone("bow");cape_bone=skeleton.find_bone("cape")
	if kind!="rowan":
		var reference: Node3D=load("res://assets/rowan-motion.glb").instantiate()
		var player: AnimationPlayer=reference.find_children("*","AnimationPlayer",true,false)[0]
		var path := str(animation.get_animation("Run").track_get_path(0)).split(":")[0]
		var run: Animation=player.get_animation("Run").duplicate()
		for track in run.get_track_count():
			var bone := str(run.track_get_path(track)).split(":")[1]
			run.track_set_path(track,NodePath(path+":"+bone))
		animation.get_animation_library("").remove_animation("Run")
		animation.get_animation_library("").add_animation("Run",run)
		reference.free()
	gait_length=animation.get_animation("Run").length
	if not gait_cache.has(kind):
		var frames: Array=[]
		var idle: Array=[]
		animation.play("Idle",0);animation.advance(0);animation.seek(0,true)
		for bone in gait_bones:idle.append(skeleton.get_bone_pose(bone))
		animation.play("Run",0);animation.advance(0)
		var count := maxi(2,int(ceil(gait_length*60)))
		for frame in count:
			animation.seek(float(frame)/count*gait_length,true)
			var poses: Array=[]
			for bone in gait_bones:poses.append(skeleton.get_bone_pose(bone))
			frames.append(poses)
		gait_cache[kind]={"frames":frames,"idle":idle}
	gait_frames=gait_cache[kind].frames;gait_idle=gait_cache[kind].idle

func update_motion(dt: float) -> void:
	if dt<=0:return
	motion_clock+=dt
	motion_velocity=motion_velocity.lerp(motion_target,1-exp(-dt*14))
	var actual_speed := motion_velocity.length()
	var local_move := global_transform.basis.inverse()*motion_velocity
	var backward := local_move.z<-.05
	var angle := atan2(local_move.x,local_move.z) if actual_speed>.08 else 0.0
	if backward:angle=wrapf(angle+PI,-PI,PI)
	gait_yaw=lerp_angle(gait_yaw,clampf(angle,-1.30,1.30),1-exp(-dt*12))
	gait_weight=lerpf(gait_weight,smoothstep(.06,1.1,actual_speed),1-exp(-dt*14))
	motion_layer=minf(1,motion_layer+dt*8)
	if kind in ARCHERS:
		gait_time+=dt*motion_target.length()/RUN_STRIDE_SPEED*(-1 if backward else 1)
	elif kind=="fox":
		gait_time+=dt*clampf(actual_speed/1.9,.0,2.6)
	var turn_rate := wrapf(rotation.y-last_facing,-PI,PI)/maxf(.001,dt)
	turning_lean=lerpf(turning_lean,clampf(turn_rate*.028,-.11,.11)*smoothstep(.2,2,actual_speed),1-exp(-dt*8))
	last_facing=rotation.y

func layer_gait() -> void:
	if gait_frames.is_empty():return
	var frame: float = fposmod(gait_time,gait_length)/gait_length*gait_frames.size()
	var first := int(floor(frame))%gait_frames.size()
	var next := (first+1)%gait_frames.size()
	var t: float = frame-floor(frame)
	var upper := skeleton.get_bone_global_pose(spine_bone)
	var bow := skeleton.get_bone_global_pose(bow_bone)
	var old_hips := skeleton.get_bone_global_pose(gait_bones[0]).origin
	for i in gait_bones.size():
		var run_pose: Transform3D=gait_frames[first][i].interpolate_with(gait_frames[next][i],t)
		var target: Transform3D=gait_idle[i].interpolate_with(run_pose,gait_weight)
		if i==0:target.basis=Basis(Vector3.UP,gait_yaw*gait_weight)*target.basis
		skeleton.set_bone_pose(gait_bones[i],skeleton.get_bone_pose(gait_bones[i]).interpolate_with(target,motion_layer))
	# Counter-rotate the torso: the archer can strafe while bow/shoulders keep aiming.
	var bob := skeleton.get_bone_global_pose(gait_bones[0]).origin-old_hips
	upper.origin+=bob;bow.origin+=bob
	skeleton.set_bone_global_pose(spine_bone,upper)
	skeleton.set_bone_global_pose(bow_bone,bow)
	if cape_bone>=0:
		var cape := skeleton.get_bone_pose(cape_bone)
		cape.basis=cape.basis*Basis(Vector3.RIGHT,sin(motion_clock*8)*.035*gait_weight)*Basis(Vector3.UP,turning_lean*.6)
		skeleton.set_bone_pose(cape_bone,cape)

func layer_fox_turn() -> void:
	# Small bounded secondary motion; never moves the pet or changes its collision body.
	for i in tail_bones.size():
		var bone := tail_bones[i]
		if bone<0:continue
		var tail := skeleton.get_bone_pose(bone)
		var lag := turning_lean*(1-float(i)*.16)
		tail.basis=tail.basis*Basis(Vector3.UP,-lag)
		skeleton.set_bone_pose(bone,tail)

func socket(bone: String, offset := Vector3.ZERO) -> Vector3:
	var index := skeleton.find_bone(bone)
	if index<0:return global_position+Vector3.UP
	return skeleton.global_transform*skeleton.get_bone_global_pose(index)*offset

func face(point: Vector3, dt: float, turn := 14.0) -> void:
	var delta := point-global_position
	if Vector2(delta.x,delta.z).length()<.02:return
	rotation.y = rotate_toward(rotation.y,atan2(delta.x,delta.z)-(base_aim if kind in ARCHERS else 0.0),dt*turn)

func clear_status() -> void:
	fire_time=0;poison_time=0;poison_stacks=0;ice_time=0;dot_clock=0
