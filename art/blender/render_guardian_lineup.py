"""Real Blender comparison render of the four approved/generated boss sources."""
import bpy, math
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'art/blender'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for i,id in enumerate(['briar-king','frost-oracle','hollow-monarch','gilded-colossus']):
 with bpy.data.libraries.load(str(ART/(id+'.blend')),link=False) as (source,target):target.objects=list(source.objects)
 models=[ob for ob in target.objects if ob and ob.type in ['ARMATURE','MESH']]
 for ob in models:bpy.context.scene.collection.objects.link(ob)
 for ob in models:
  if ob.type=='ARMATURE':
   for tr in ob.animation_data.nla_tracks:tr.mute=True
   ob.location.x=(i-1.5)*3.9
 bpy.context.scene.frame_set(1)
def area(name,pos,power,tint):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=8;data.color=tint;ob=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,2))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Key',(-6,-8,9),2200,(1,.86,.67));area('Fill',(8,-3,7),1800,(.62,.83,1));area('Rim',(0,6,8),2600,(.74,1,.86))
world=bpy.data.worlds.new('Guardian lineup');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.045,.075,.08,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45;bpy.context.scene.world=world
camdata=bpy.data.cameras.new('Guardian lineup');cam=bpy.data.objects.new('Guardian lineup',camdata);bpy.context.scene.collection.objects.link(cam);cam.location=(-1.8,-23,8);cam.rotation_euler=(Vector((0,0,2.2))-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=17.3
scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.render.resolution_x=2400;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ART/'renders/guardian-lineup.png');bpy.ops.render.render(write_still=True)
