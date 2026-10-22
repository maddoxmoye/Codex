extends Node3D
## Bounded, original combat presentation shared by all desktop quality presets.
var bursts: Array[Dictionary] = []
var sound_cache := {}
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var last_sound := {}
var visual_time := 0.0
var simple := false

func _ready() -> void:
 # Logic-only/server runs have no audio device or mix lifecycle.
 if DisplayServer.get_name()=="headless":return
 for id in ["bow","arrow_hit","windskip","salvo","hurt","slam","chime","woodland_air"]:
  sound_cache[id]=load("res://assets/audio/"+id+".wav")
 ambience=AudioStreamPlayer.new();add_child(ambience)
 var stream: AudioStreamWAV=sound_cache.woodland_air.duplicate()
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate)
 ambience.stream=stream;ambience.volume_db=-15;ambience.play()

func play_sound(id: String, gain := 0.0) -> void:
 if not sound_cache.has(id) or voices.size()>=14:return
 if visual_time-float(last_sound.get(id,-99))<(.09 if id=="arrow_hit" else .04):return
 last_sound[id]=visual_time
 var voice := AudioStreamPlayer.new();add_child(voice)
 voice.stream=sound_cache[id];voice.volume_db=-9+gain
 voice.pitch_scale=randf_range(.95,1.05);voices.append(voice)
 voice.finished.connect(func():voices.erase(voice);voice.queue_free())
 voice.play()

func particle_material(color: Color) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 mat.albedo_color=color;mat.vertex_color_use_as_albedo=true
 mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=1.2
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 return mat

func burst(point: Vector3, color: Color, count := 12, size := .045, strength := 2.5) -> void:
 if bursts.size()>=28:return
 var emitter := CPUParticles3D.new();add_child(emitter);emitter.position=point
 emitter.amount=maxi(3,count/2 if simple else count);emitter.lifetime=.48
 emitter.one_shot=true;emitter.explosiveness=.95;emitter.local_coords=false
 emitter.direction=Vector3.UP;emitter.spread=100;emitter.gravity=Vector3(0,-4,0)
 emitter.initial_velocity_min=strength*.4;emitter.initial_velocity_max=strength
 emitter.scale_amount_min=.5;emitter.scale_amount_max=1.3
 var gradient := Gradient.new();gradient.set_color(0,Color.WHITE);gradient.set_color(1,Color(1,1,1,0))
 emitter.color_ramp=gradient
 var mesh := QuadMesh.new();mesh.size=Vector2.ONE*size;mesh.material=particle_material(color)
 emitter.mesh=mesh;emitter.emitting=true
 bursts.append({"node":emitter,"life":.75})

func attach_trail(parent: Node3D, element: String) -> void:
 if simple or element=="physical":return
 var trail := CPUParticles3D.new();parent.add_child(trail)
 trail.amount=10;trail.lifetime=.14;trail.local_coords=false;trail.gravity=Vector3.ZERO
 trail.initial_velocity_min=0;trail.initial_velocity_max=.05
 trail.scale_amount_min=.25;trail.scale_amount_max=.8
 var color := Color("ff9450") if element=="fire" else Color("8ce0ff") if element=="ice" else Color("be88f4")
 var mesh := QuadMesh.new();mesh.size=Vector2(.10,.10);mesh.material=particle_material(color);trail.mesh=mesh
 var gradient := Gradient.new();gradient.set_color(0,Color.WHITE);gradient.set_color(1,Color(1,1,1,0));trail.color_ramp=gradient
 trail.emitting=true

func clear_transients() -> void:
 for effect in bursts:effect.node.queue_free()
 bursts.clear()

func _process(dt: float) -> void:
 visual_time+=dt
 for i in range(bursts.size()-1,-1,-1):
  bursts[i].life-=dt
  if bursts[i].life<=0:bursts[i].node.queue_free();bursts.remove_at(i)

func _exit_tree() -> void:
 if is_instance_valid(ambience):ambience.stop();ambience.stream=null
 for voice in voices:
  if is_instance_valid(voice):voice.stop();voice.stream=null
 voices.clear();sound_cache.clear()
