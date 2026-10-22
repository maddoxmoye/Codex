"""Author the native Rowan running gait while preserving approved attack clips.
Run from repository: blender -b --factory-startup --python godot-native/tools/author_motion.py
The original Blender source and all browser exports remain unchanged.
"""
import bpy, importlib.util, inspect, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
NATIVE=ROOT/'godot-native'
spec=importlib.util.spec_from_file_location('rowan_author',ROOT/'art/blender/animate_rowan.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/blender/rowan-motion.blend'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
a.rig=rig
# Reuse the original grounded leg IK and hand/bow constraints. Only the new
# locomotion clip gets the longer stride and lower, balanced running stance.
source=inspect.getsource(a.pose)
for old,new in [
 ('(-.075+abs(math.sin(phase))*.025)', '(-.20+abs(math.sin(phase))*.035)'),
 ('y=-.28+.56*u/.55','y=-.50+1.0*u/.55'),
 ('y=.28-.56*smooth(swing);z+=math.sin(swing*math.pi)*.18','y=.50-1.0*smooth(swing);z+=math.sin(swing*math.pi)*.22'),
 ('lean=.10 if run','lean=.14 if run'),
]:
 assert old in source,old
 source=source.replace(old,new)
exec(compile(source,'native_grounded_run','exec'),a.__dict__)
run=bpy.data.actions.get('Rowan / Run')
assert run is not None
for curve in list(run.fcurves):run.fcurves.remove(curve)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=run
for frame in range(49):
 t=frame/60
 bpy.context.scene.frame_set(1+frame//2, subframe=(frame%2)/2)
 a.pose(t,'Run')
 for bone in rig.pose.bones:
  bone.keyframe_insert('rotation_quaternion',frame=1+t*30,group=bone.name)
  bone.keyframe_insert('location',frame=1+t*30,group=bone.name)
for curve in run.fcurves:
 for point in curve.keyframe_points:point.interpolation='LINEAR'
rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=False
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.context.scene.render.fps=30
bpy.context.scene.frame_set(1)
bpy.ops.export_scene.gltf(filepath=str(NATIVE/'assets/rowan-motion.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_optimize_animation_size=True,export_rest_position_armature=True)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=run;bpy.context.scene.frame_set(7)
(NATIVE/'source').mkdir(exist_ok=True)
(NATIVE/'source/.gdignore').touch()
bpy.ops.wm.save_as_mainfile(filepath=str(NATIVE/'source/rowan-emberwood.blend'),compress=True)
(NATIVE/'assets/native-motion.json').write_text(json.dumps({'source':'source/rowan-emberwood.blend','strideMeters':1.0,'stanceFraction':0.55,'runCycleSeconds':0.8,'authoredStrideSpeed':1.0/(0.8*.55),'runtime':'Cached lower-body run poses, distance-driven cycle, independent upper-body aiming and attacks','attackClips':'Approved original clips and timings retained'},indent=2)+'\n')
print('EMBERWOOD_MOTION_AUTHORED',flush=True)
