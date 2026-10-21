"""Editable character-specific combat studies. Reuses Rowan's approved analytic IK.
blender -b --factory-startup --python art/blender/animate_combat_roster.py
Geometry, palette, bow sockets and skin weights remain the approved base designs.
"""
import bpy, math, json, importlib.util
from pathlib import Path
from mathutils import Vector, Euler
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('rowan_motion',ROOT/'art/blender/animate_rowan.py')
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
b=r.b;OUT=ROOT/'godot-combat/assets';OUT.mkdir(parents=True,exist_ok=True)
KITS={
 'ash':dict(space='HareTrigger',attack='Arrowpalooza',spaceName='Hare Trigger',attackName='Arrowpalooza',spaceDuration=4.,attackDuration=5.,spaceCooldown=10.,attackCooldown=14.,color='f09559',damage=22.,description='A low, scarf-led sprint and a fast alternating bow rhythm.',spaceDetail='+70% speed for 4s; first 0.8s avoids damage.',attackDetail='Double bow attack speed for 5s.'),
 'briar':dict(space='Shell',attack='Quiverquake',spaceName='Shell Yeah!',attackName='Quiverquake',spaceDuration=3.,attackDuration=0.,spaceCooldown=12.,attackCooldown=8.,color='83becb',damage=16.,description='A planted armored brace and a heavy twelve-arrow ground burst.',spaceDetail='Blocks all damage for 3s.',attackDetail='Close-range blast plus 12 arrows in a ring.'),
 'nyx':dict(space='Bramble',attack='HuntersMoon',spaceName='Bramble Bouncer',attackName='Hunter’s Moon',spaceDuration=1.5,attackDuration=4.,spaceCooldown=9.,attackCooldown=14.,color='b69ce6',damage=15.,description='A warding open-hand sweep and a crescent-lit empowered draw.',spaceDetail='Pushes enemies away, clears hostile shots, blocks damage for 1.5s.',attackDetail='Double physical and elemental arrow impact damage for 4s.'),
 'pip':dict(space='BorrowedTime',attack='Gearstorm',spaceName='Borrowed Time',attackName='Gear Expectations',spaceDuration=4.,attackDuration=4.,spaceCooldown=12.,attackCooldown=13.,color='67d2bd',damage=20.,description='A winding-key gesture, a slowing clock field and three-arrow gear fans.',spaceDetail='+25% speed for 4s; nearby enemies and shots 65% slower. First 1s blocks damage.',attackDetail='Three empowered clockwork arrows every 0.6s for 4s.')
}
CURRENT=None

def pose(t,clip):
    kit=KITS[CURRENT];space=clip==kit['space'];attack=clip==kit['attack']
    if not (space or attack):r.pose(t,clip);return
    rig=r.rig
    if attack and CURRENT in ('ash','nyx','pip'):
        # Complete nock/draw/release cycles: release at the exact exported marker.
        cycle=.8 if CURRENT=='ash' else 1.6 if CURRENT=='nyx' else .6
        last_cycle=math.ceil((kit['attackDuration']-cycle*1.82/3.2)/cycle)
        r.pose((t%cycle)*3.2/cycle,'Shoot') if t<last_cycle*cycle else r.pose(t,'Idle')
        rig.pose.bones['cape'].rotation_quaternion=Euler((-.10,.04*math.sin(t*12),0)).to_quaternion()
        return
    if space and CURRENT=='ash':
        r.pose(t*1.7,'Run');rig.pose.bones['hips'].rotation_quaternion=Euler((.25,0,0)).to_quaternion()
        rig.pose.bones['cape'].rotation_quaternion=Euler((-.45,.06*math.sin(t*16),0)).to_quaternion();return
    r.pose(t,'Idle')
    duration=1.2 if attack else 1.0
    pulse=r.ease(t,0,.22)*(1-r.ease(t,.55,duration))
    if CURRENT=='briar':
        # Weight drops into the brace, then the armored torso drives the burst.
        weight=(r.ease(t,0,.22)*(1-r.ease(t,2.7,3.))) if space else pulse
        rig.pose.bones['hips'].location.y=-.10*weight
        rig.pose.bones['chest'].rotation_quaternion=Euler((.12*weight,0,-.06*weight)).to_quaternion()
        bpy.context.view_layer.update()
        for side,s in [('L',1),('R',-1)]:
            foot=r.limb('thigh.'+side,'shin.'+side,(s*.23,.02*s,.17),(s*.23,-1,.5));r.world_bone('foot.'+side,foot,r.Quaternion())
        # Bow hand stays driven by the hand; free hand guards the sternum, then strikes down.
        hand=r.limb('upper_arm.R','forearm.R',(-.15,-.28,1.30-.35*pulse if attack else 1.30),(-.8,-.3,1.2))
        r.world_bone('hand.R',hand,r.Quaternion())
    else:
        # Nyx opens a ward with the right palm; Pip turns an imaginary winding key at his pack.
        sweep=r.ease(t,0,.35)*(1-r.ease(t,.75,1.5 if CURRENT=='nyx' else 2.0))
        dest=Vector((-.55,-.25,1.35)).lerp(Vector((-.63,-.48,1.65)),sweep) if CURRENT=='nyx' else Vector((-.35,.24,1.28))
        hand=r.limb('upper_arm.R','forearm.R',dest,(-.9,0,1.4))
        rotation=Euler((-.7*sweep,0,math.sin(t*10)*.22 if CURRENT=='pip' else -.4*sweep)).to_quaternion()
        r.world_bone('hand.R',hand,rotation)
        rig.pose.bones['head'].rotation_quaternion=Euler((0,0,-.1*sweep)).to_quaternion()
        rig.pose.bones['cape'].rotation_quaternion=Euler((-.16*sweep,.06*math.sin(t*8)*sweep,0)).to_quaternion()
    bpy.context.view_layer.update()

def capture(d,kind):
    r.rig,r.mesh=r.prepare(d,kind);rig=r.rig;mesh=r.mesh;kit=KITS[CURRENT]
    mesh.name=d['name']+' / combat skin'
    clips={'Idle':3.2,'Run':.8,'Shoot':3.2,kit['space']:kit['spaceDuration'],kit['attack']:max(1.2,kit['attackDuration']+.4)}
    actions={};rig.animation_data_create()
    for clip,length in clips.items():
        action=bpy.data.actions.new(d['name']+' / '+clip);rig.animation_data.action=action
        times={i/30 for i in range(int(length*30)+1)}|{length}
        if clip=='Shoot':times|={1.815,1.82,1.885}
        if clip==kit['attack'] and CURRENT in ('ash','nyx','pip'):
            cycle=.8 if CURRENT=='ash' else 1.6 if CURRENT=='nyx' else .6
            for i in range(math.ceil(kit['attackDuration']/cycle)):
                for marker in [1.75,1.815,1.82,1.885]:
                    at=i*cycle+cycle*marker/3.2
                    if at<length:times.add(at)
        for t in sorted(times):
            bpy.context.scene.frame_set(1+int(t*30));pose(t,clip)
            for bone in rig.pose.bones:
                bone.keyframe_insert('rotation_quaternion',frame=1+t*30,group=bone.name)
                bone.keyframe_insert('location',frame=1+t*30,group=bone.name)
        actions[clip]=action;track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action);track.mute=True;rig.animation_data.action=None
    for track in rig.animation_data.nla_tracks:track.mute=False
    bpy.context.scene.render.fps=30;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(CURRENT+'-motion.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_rest_position_armature=True)
    for track in rig.animation_data.nla_tracks:track.mute=True
    rig.animation_data.action=actions[kit['attack']];bpy.context.scene.frame_set(12);bpy.context.scene.frame_end=round(clips[kit['attack']]*30)+1
    mesh.data.calc_loop_triangles()
    metadata={**kit,'id':CURRENT,'name':d['name'],'role':d['role'],'file':CURRENT+'-motion.glb','clips':clips,'bones':22,'triangles':len(mesh.data.loop_triangles),'anchorTime':1.75,'releaseTime':1.82,'attackCycle':.8 if CURRENT=='ash' else 1.6 if CURRENT=='nyx' else .6 if CURRENT=='pip' else 1.2,'burstReleaseTime':.35,'notes':'Review choreography uses readable windups and slower base archery. Existing gameplay values are unchanged.'}
    (OUT/(CURRENT+'.json')).write_text(json.dumps(metadata,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender'/(CURRENT+'-combat.blend')),compress=True)
    print('COMBAT_EXPORTED',CURRENT,json.dumps(metadata),flush=True)

for d in b.ARCHERS[1:]:
    CURRENT=d['id'];bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);b.MATS.clear()
    for image in list(bpy.data.images):bpy.data.images.remove(image)
    image=bpy.data.images.load(str(ROOT/'art/blender/wildfall-palette.png'));image.name='Wildfall Palette';image.pack()
    b.finalize=capture;b.make_archer(d)
