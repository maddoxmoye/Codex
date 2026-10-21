"""Run with Blender 4.3+: blender -b --python art/blender/build_roster.py.
Original, editable, palette-textured base assets; meters, floor origin, -Y forward.
Not final production character animation or a gameplay migration.
"""
import bpy, math, json, os, sys, struct, zlib, bmesh
from pathlib import Path
from mathutils import Vector, Quaternion
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'godot-models/assets'
SOURCE = ROOT / 'art/blender'
RENDERS = SOURCE / 'renders'
RENDERS.mkdir(parents=True, exist_ok=True)
COLORS = {
 'ink':'242d39','leather':'64483c','leather_light':'9b6b47','tan':'c99a69',
 'skin':'d7a780','skin_warm':'b97c60','skin_dark':'8b5949','skin_pale':'d2b5b0',
 'moss':'647b52','forest':'344f47','sage':'a6b38a','linen':'ddd2b8',
 'russet':'a9573e','ember':'d99559','coal':'393743','auburn':'573e37',
 'slate':'334a60','steel':'8babb4','steel_dark':'4c6374','silver':'b9c9c8',
 'indigo':'504d78','violet':'8c7ba9','lilac':'d0b9d8','moon':'87cad2',
 'teal':'397f7c','teal_dark':'295459','brass':'b19a60','gold':'d6b773',
 'fox':'c97b47','fox_light':'e7aa63','cream':'ece0c8','nose':'28323c',
 'wolf':'81949f','wolf_dark':'4c626f','wolf_light':'c2ced0','eye':'d0b476',
 'jade':'41827a','shell':'263f48','amber':'f0b965','glow':'93d9cb',
 'white':'f1e9da','red':'943f3f'
}
INDEX = {name:i for i,name in enumerate(COLORS)}
MATS = {}
PARTS = []
RIG = None
COLLECTION = None
ASSETS = []


def png(path):
    size=256; tile=32; values=list(COLORS.values()); raw=bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            i=((size-1-y)//tile)*8+x//tile
            h=values[i] if i<len(values) else '242d39'
            raw.extend(bytes.fromhex(h)+b'\xff')
    def chunk(kind,data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b''))


def material(kind):
    if kind in MATS: return MATS[kind]
    m=bpy.data.materials.new('Wildfall / '+kind);m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=.68 if kind=='Cloth & fur' else .37
    shader.inputs['Metallic'].default_value=.65 if kind=='Forged details' else 0
    tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images['Wildfall Palette'];tex.interpolation='Closest'
    m.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    if kind=='Luminous inlay':
        m.node_tree.links.new(tex.outputs['Color'],shader.inputs['Emission Color']);shader.inputs['Emission Strength'].default_value=.4
    MATS[kind]=m
    return m


def move_collection(obj):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    COLLECTION.objects.link(obj)


def finish(obj,name,color,bone='chest',kind='Cloth & fur',smooth=True,weights=None):
    obj.name=name;move_collection(obj)
    # Bake object transforms into mesh; armature and mesh exports have unit transforms.
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(obj.data);bm.free()
    obj.data.materials.clear();obj.data.materials.append(material(kind))
    uv=obj.data.uv_layers.new(name='Palette') if not obj.data.uv_layers else obj.data.uv_layers[0]
    uv.name='Palette';uv.active_render=True
    idx=INDEX[color];cx=(idx%8+.5)/8;cy=(idx//8+.5)/8
    for poly in obj.data.polygons:
        poly.use_smooth=smooth
        for j,li in enumerate(poly.loop_indices):
            angle=j*math.tau/max(3,len(poly.loop_indices))
            uv.data[li].uv=(cx+math.cos(angle)*.018,cy+math.sin(angle)*.018)
    if weights:
        for vi,entries in enumerate(weights):
            for group,weight in entries:
                vg=obj.vertex_groups.get(group) or obj.vertex_groups.new(name=group)
                vg.add([vi],weight,'REPLACE')
    else:
        vg=obj.vertex_groups.new(name=bone);vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    PARTS.append(obj);obj.select_set(False)
    return obj


def ball(name,pos,size,color,bone='head',kind='Cloth & fur',segments=12,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos)
    ob=bpy.context.object;ob.scale=size
    return finish(ob,name,color,bone,kind)


def block(name,pos,size,color,bone='chest',bevel=.025,rotation=None,kind='Cloth & fur'):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos);ob=bpy.context.object;ob.scale=size
    if rotation:ob.rotation_euler=rotation
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=ob.modifiers.new('Soft constructed edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(ob,name,color,bone,kind,False)


def geometry(name,verts,faces,color,bone='chest',kind='Cloth & fur',smooth=True,weights=None):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new(name,mesh);COLLECTION.objects.link(ob)
    return finish(ob,name,color,bone,kind,smooth,weights)


def loft(name,rings,color,bone='chest',sides=12,weights=None,kind='Cloth & fur',smooth=True):
    verts=[]
    for center,rx,ry in rings:
        for i in range(sides):
            a=i*math.tau/sides;verts.append((center[0]+rx*math.cos(a),center[1]+ry*math.sin(a),center[2]))
    faces=[tuple(reversed(range(sides)))]
    for k in range(len(rings)-1):
        for i in range(sides): faces.append((k*sides+i,k*sides+(i+1)%sides,(k+1)*sides+(i+1)%sides,(k+1)*sides+i))
    faces.append(tuple((len(rings)-1)*sides+i for i in range(sides)))
    expanded=None
    if weights:expanded=[entry for entry in weights for _ in range(sides)]
    return geometry(name,verts,faces,color,bone,kind,smooth,expanded)


def tube(name,points,radius,color,bone='chest',kind='Cloth & fur',sides=6,radii=None):
    points=[Vector(p) for p in points];verts=[]
    for j,p in enumerate(points):
        direction=(points[min(j+1,len(points)-1)]-points[max(0,j-1)]).normalized()
        axis=Vector((0,0,1)) if abs(direction.z)<.9 else Vector((0,1,0))
        u=direction.cross(axis).normalized();v=direction.cross(u).normalized()
        r=radii[j] if radii else radius
        for k in range(sides):verts.append(p+r*(u*math.cos(k*math.tau/sides)+v*math.sin(k*math.tau/sides)))
    faces=[tuple(reversed(range(sides)))]
    for j in range(len(points)-1):
        for k in range(sides):faces.append((j*sides+k,j*sides+(k+1)%sides,(j+1)*sides+(k+1)%sides,(j+1)*sides+k))
    faces.append(tuple((len(points)-1)*sides+k for k in range(sides)))
    return geometry(name,verts,faces,color,bone,kind,True)


def leaf(name,start,end,width,color,bone='chest'):
    a=Vector(start);b=Vector(end);mid=a.lerp(b,.45);side=(b-a).cross(Vector((0,-1,0))).normalized()*width
    ridge=mid+Vector((0,-width*.25,0))
    verts=[a,mid+side,b,mid-side,ridge,mid+Vector((0,.008,0))]
    return geometry(name,verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,5,1),(1,5,2),(2,5,3),(3,5,0)],color,bone,smooth=False)


def bone(name,a,b,parent=None):
    eb=RIG.data.edit_bones.new(name);eb.head=a;eb.tail=b
    if parent:eb.parent=RIG.data.edit_bones[parent]
    eb.use_deform=name!='root'
    return eb


def new_asset(asset_id,name):
    global PARTS,RIG,COLLECTION
    PARTS=[];COLLECTION=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(COLLECTION)
    arm=bpy.data.armatures.new(name+' Skeleton');RIG=bpy.data.objects.new(name+' Rig',arm);COLLECTION.objects.link(RIG)
    bpy.context.view_layer.objects.active=RIG;RIG.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    bone('root',(0,0,0),(0,0,.2));return RIG


def human_rig():
    bone('hips',(0,0,.88),(0,0,1.04),'root');bone('spine',(0,0,1.04),(0,0,1.23),'hips');bone('chest',(0,0,1.23),(0,0,1.46),'spine')
    bone('neck',(0,0,1.46),(0,0,1.58),'chest');bone('head',(0,0,1.58),(0,0,1.94),'neck')
    bone('cape',(0,.12,1.4),(0,.25,.75),'chest')
    for side,s in [('L',1),('R',-1)]:
        bone('upper_arm.'+side,(s*.30,0,1.43),(s*.47,-.01,1.17),'chest')
        bone('forearm.'+side,(s*.47,-.01,1.17),(s*.57,-.05,.96),'upper_arm.'+side)
        bone('hand.'+side,(s*.57,-.05,.96),(s*.57,-.09,.86),'forearm.'+side)
        bone('thigh.'+side,(s*.155,0,.91),(s*.155,-.015,.53),'hips')
        bone('shin.'+side,(s*.155,-.015,.53),(s*.155,0,.17),'thigh.'+side)
        bone('foot.'+side,(s*.155,0,.17),(s*.155,-.22,.10),'shin.'+side)
    bpy.ops.object.mode_set(mode='OBJECT');RIG.select_set(False)


ARCHERS=[
 dict(id='rowan',name='Rowan',role='Wayfarer',cloth='forest',accent='moss',trim='sage',skin='skin',hair='auburn',eye='sage',hood=True,bulk=1.0,description='Leaf-fastened forest cloak, layered trail leathers and an ashwood recurve.'),
 dict(id='ash',name='Ash',role='Cinder Scout',cloth='coal',accent='russet',trim='ember',skin='skin_warm',hair='auburn',eye='gold',hood=False,bulk=.94,description='Split russet scarf, swept hair and feather details on a lean scouting silhouette.'),
 dict(id='briar',name='Briar',role='Ironwarden',cloth='slate',accent='steel_dark',trim='steel',skin='skin_dark',hair='ink',eye='gold',hood=False,bulk=1.13,description='Layered blue-steel armor, broad pauldrons and an open-faced crested helmet.'),
 dict(id='nyx',name='Nyx',role='Moonstring',cloth='indigo',accent='violet',trim='silver',skin='skin_pale',hair='ink',eye='moon',hood=True,bulk=.98,description='Pointed moon hood, crescent clasp, split mantle and crystal-tipped silver bow.'),
 dict(id='pip',name='Pip',role='Gearwing',cloth='teal_dark',accent='teal',trim='brass',skin='skin',hair='auburn',eye='moon',hood=False,bulk=1.0,description='Teal utility coat, brass goggles, mechanical bow and a riveted clockwork pack.')
]


def make_hood(d):
    verts=[];faces=[];n=20;steps=7
    for j in range(steps):
        theta=.83+(math.pi-.86)*j/(steps-1)
        for i in range(n):
            phi=math.tau*i/n
            point=(.275*math.sin(theta)*math.cos(phi),-.24*math.cos(theta)+.015,1.72+.30*math.sin(theta)*math.sin(phi))
            verts.append(point)
    for j in range(steps-1):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    geometry('Sewn open-face hood',verts,faces,d['accent'],'head',smooth=True)
    # Solid edge trim reads from all angles; a thin back shell is intentional cloth.
    rim=[verts[i] for i in range(n)]+[verts[0]];tube('Hood binding',rim,.012,d['trim'],'head')
    if d['id']=='nyx':
        tube('Pointed moon hood',[(0,.12,1.94),(0,.28,1.98),(0,.42,1.80)],.11,d['accent'],'head',radii=[.16,.11,.015])


def make_cape(d):
    # Two-sided, low-cost volume; weighted at collar and cape bone, not cloth simulation.
    verts=[];faces=[];weights=[];rows=6;cols=9
    for back in [False,True]:
        for j in range(rows):
            t=j/(rows-1);z=1.40-t*(.71 if d['id']!='ash' else .52)
            for i in range(cols):
                u=i/(cols-1)*2-1;x=u*(.29+t*.13)
                y=.13+t*.16+math.sin(i*.9)*.025*(t+.2)+(.018 if back else 0)
                scallop=(.035*math.cos(i*math.pi) if j==rows-1 else 0)
                verts.append((x,y,z+scallop));w=max(0,min(1,t*1.5));weights.append([('chest',1-w),('cape',w)])
    layer=rows*cols
    for back in range(2):
        for j in range(rows-1):
            for i in range(cols-1):
                ids=(back*layer+j*cols+i,back*layer+j*cols+i+1,back*layer+(j+1)*cols+i+1,back*layer+(j+1)*cols+i)
                faces.append(tuple(reversed(ids)) if back else ids)
    for j in range(rows-1):
        for i in [0,cols-1]:
            a=j*cols+i;b=(j+1)*cols+i;faces.append((a,b,b+layer,a+layer))
    for j in [0,rows-1]:
        for i in range(cols-1):
            a=j*cols+i;faces.append((a,a+layer,a+1+layer,a+1))
    geometry('Bound traveling mantle',verts,faces,d['accent'],'cape',weights=weights)


def make_bow(d):
    first_part=len(PARTS)
    pts=[]
    for i in range(17):
        t=i/16;pts.append((.60,-.18-math.sin(t*math.pi)*.17, .48+t*1.1))
    tube('Sculpted recurve limbs',pts,.027,'brass' if d['id']=='pip' else 'leather_light','hand.L',kind='Forged details' if d['id']=='pip' else 'Cloth & fur',radii=[.012+.02*math.sin(i/16*math.pi) for i in range(17)])
    tube('Bowstring',[(.60,-.18,.48),(.60,-.14,1.03),(.60,-.18,1.58)],.004,'linen','hand.L',sides=4)
    block('Wrapped bow grip',(.60,-.35,1.03),(.07,.075,.17),d['cloth'],'hand.L',.012)
    for z in [.60,1.46]:
        ball('Bow tip inlay',(.60,-.23,z),(.035,.035,.055),d['trim'],'hand.L','Forged details',8,6)
    if d['id']=='nyx':
        for z in [.55,1.53]:leaf('Moonstone bow tip',(.60,-.23,z-.07),(.60,-.23,z+.07),.055,'moon','hand.L')
    if d['id']=='pip':
        ball('Bow mechanism',(.60,-.37,1.03),(.065,.035,.065),'brass','hand.L','Forged details')
        tube('Brass limb brace',[(.57,-.20,.62),(.57,-.25,1.03),(.57,-.20,1.44)],.012,'brass','hand.L','Forged details')

    # Put the grip inside the authored left hand before skinning/export.
    for part in PARTS[first_part:]:
        for vertex in part.data.vertices:vertex.co += Vector((-.02,.235,-.12))


def make_archer(d):
    new_asset(d['id'],d['name']);human_rig();b=d['bulk']
    # Softly lofted forms use shared torso weights to bend at the spine.
    loft('Fitted layered tunic',[((0,0,.86),.24*b,.15),((0,0,.97),.26*b,.17),((0,0,1.15),.28*b,.18),((0,0,1.37),.33*b,.18),((0,0,1.45),.24*b,.14)],d['cloth'],weights=[[('hips',1)],[('hips',.7),('spine',.3)],[('spine',.6),('chest',.4)],[('chest',1)],[('chest',1)]])
    # Front coat panels, collar and reinforced hem.
    for s in [-1,1]:
        block('Overlapping coat tail',(s*.14,-.075,.78),(.26,.22,.32),d['accent'],'hips',.045,rotation=(0,s*.09,s*.05))
    tube('Linen collar',[(-.15,-.12,1.45),(0,-.19,1.31),(.15,-.12,1.45)],.025,d['trim'],'chest')
    loft('Neck',[((0,0,1.43),.10,.09),((0,0,1.61),.105,.095)],d['skin'],'neck')
    ball('Sculpted face',(0,-.025,1.72),(.202,.174,.239),d['skin'],'head',segments=16,rings=12)
    for side,s in [('L',1),('R',-1)]:
        # Articulated limb volumes, reinforced gloves and split boot sole/toe.
        a=Vector((s*.30,0,1.43));e=Vector((s*.47,-.01,1.17));w=Vector((s*.57,-.05,.96))
        tube('Tunic sleeve '+side,[a,a.lerp(e,.45),e],.11,d['accent'],'upper_arm.'+side,radii=[.135*b,.113*b,.09*b],sides=10)
        tube('Bracer cuff '+side,[e,e.lerp(w,.3),w],.075,'leather','forearm.'+side,radii=[.084,.088,.065],sides=10)
        block('Bracer plate '+side,(s*.55,-.101,1.055),(.13,.04,.18),d['trim'],'forearm.'+side,.015,kind='Forged details')
        ball('Gloved hand '+side,(s*.58,-.065,.91),(.075,.065,.105),'leather','hand.'+side)
        ball('Thumb '+side,(s*.525,-.11,.92),(.034,.035,.056),'leather','hand.'+side,segments=8,rings=6)
        tube('Trouser leg '+side,[(s*.155,0,.88),(s*.155,-.01,.70),(s*.155,-.015,.53)],.115,d['cloth'],'thigh.'+side,radii=[.125,.115,.095],sides=10)
        tube('Tall boot '+side,[(s*.155,-.015,.53),(s*.155,0,.3),(s*.155,0,.16)],.10,'leather','shin.'+side,radii=[.105,.091,.09],sides=10)
        block('Leather boot toe '+side,(s*.155,-.085,.10),(.215,.37,.17),'leather','foot.'+side,.055)
        block('Boot sole '+side,(s*.155,-.085,.027),(.22,.38,.045),'ink','foot.'+side,.018)
        block('Boot binding '+side,(s*.155,-.105,.37),(.19,.035,.045),'tan','shin.'+side,.008)
        # Ears, inset eyes, a dark iris and small highlights; not a painted-on face.
        ball('Ear '+side,(s*.202,0,1.70),(.052,.05,.087),d['skin'],'head',segments=10,rings=6)
        ball('Eye socket '+side,(s*.083,-.177,1.755),(.044,.009,.031),'auburn','head')
        ball('Eye white '+side,(s*.083,-.193,1.757),(.037,.008,.024),'linen','head')
        ball('Iris '+side,(s*.083,-.205,1.757),(.018,.005,.021),d['eye'],'head',segments=10,rings=6)
        ball('Pupil '+side,(s*.083,-.213,1.757),(.009,.004,.015),'nose','head',segments=8,rings=6)
        ball('Catchlight '+side,(s*.077,-.218,1.767),(.006,.003,.007),'white','head',segments=8,rings=4)
        tube('Expressive brow '+side,[(s*.045,-.197,1.809),(s*.086,-.201,1.818),(s*.132,-.174,1.806)],.013,d['hair'],'head',sides=5)
    ball('Bridge of nose',(0,-.191,1.705),(.032,.04,.052),d['skin'],'head',segments=10,rings=6)
    tube('Quiet smile',[(-.043,-.182,1.636),(0,-.196,1.63),(.043,-.182,1.636)],.006,'auburn','head',sides=4)
    if d['hood']:make_hood(d)
    else:
        # Hair crown with tapered locks rather than a featureless sphere.
        loft('Swept hair crown',[((0,.01,1.82),.205,.175),((-.015,.035,1.94),.17,.14),((-.04,.055,1.985),.075,.065)],d['hair'],'head',sides=14)
        for i in range(5):
            x=(i-2)*.064
            leaf('Swept fringe',(x,-.14,1.93),(x-.035,-.19,1.82+abs(i-2)*.025),.055,d['hair'],'head')
    make_cape(d)
    block('Utility belt',(0,-.005,.945),(.55*b,.34,.075),'leather','hips',.025)
    block('Belt buckle',(0,-.191,.945),(.105,.035,.095),d['trim'],'hips',.012,kind='Forged details')
    # Diagonal leather strap follows the chest, leaving a separate attachment surface.
    tube('Quiver shoulder strap',[(-.24,-.13,1.42),(0,-.205,1.20),(.23,-.16,1.02)],.026,'tan','chest',sides=5)
    block('Trail pouch',(-.29,0,.90),(.15,.15,.19),'leather_light','hips',.025)
    block('Pouch flap',(-.29,-.078,.96),(.16,.025,.08),'leather','hips',.012)
    ball('Pouch stud',(-.29,-.10,.94),(.018,.012,.018),'gold','hips','Forged details',8,6)
    # Quiver and fletched arrows stay attached to the chest bone.
    loft('Arrow quiver',[((.18,.285,1.02),.09,.08),((.18,.285,1.44),.115,.10)],'leather','chest',sides=10)
    for i in range(4):
        x=.11+i*.046;y=.285+(i%2)*.025
        tube('Quiver arrow',[(x,y,1.25),(x,y,1.71)],.009,'tan','chest',sides=5)
        leaf('Arrow fletching',(x,y,1.57),(x,y,1.71),.028,d['trim'],'chest')
    make_bow(d)
    if d['id']=='rowan':
        leaf('Wayfarer leaf brooch',(-.22,-.16,1.37),(-.17,-.19,1.48),.045,'sage')
        for i in range(3):leaf('Layered leather shoulder',(-.25+i*.045,0,1.47),(-.43+i*.045,-.02,1.33),.07,'leather_light')
    elif d['id']=='ash':
        tube('Wrapped cinder scarf',[(-.17,-.04,1.49),(0,-.15,1.50),(.18,-.03,1.49)],.08,'russet','neck',sides=10)
        for i in range(3):leaf('Scout feather',(.18+i*.025,.07,1.87),(.28+i*.035,.08,2.08+i*.04),.045,'ember' if i%2 else 'linen','head')
        for s in [-1,1]:block('Knife sheath',(s*.30,.10,.85),(.07,.07,.27),'coal','hips',.015)
    elif d['id']=='briar':
        block('Ironwarden cuirass',(0,-.13,1.23),(.55,.16,.37),'steel_dark','chest',.075,kind='Forged details')
        leaf('Cuirass crest',(-.08,-.224,1.33),(.08,-.224,1.15),.10,'steel')
        for side,s in [('L',1),('R',-1)]:
            ball('Broad steel pauldron',(s*.345,0,1.43),(.21,.205,.14),'steel','upper_arm.'+side,'Forged details',12,8)
            block('Knee guard',(s*.155,-.105,.53),(.16,.07,.17),'steel','shin.'+side,.035,kind='Forged details')
        loft('Open-faced helmet',[((0,.03,1.84),.237,.20),((0,.035,1.98),.17,.16),((0,.04,2.025),.045,.06)],'steel_dark','head',sides=14,kind='Forged details')
        tube('Steel brow rim',[(-.2,-.11,1.86),(0,-.195,1.885),(.2,-.11,1.86)],.025,'steel','head','Forged details')
        leaf('Helmet crest',(0,0,1.99),(0,.10,2.15),.075,'steel','head')
    elif d['id']=='nyx':
        # Open crescent shape: a swept arc instead of a full halo.
        pts=[(.10*math.cos(a),-.195,1.93+.10*math.sin(a)) for a in [math.radians(45+i*27) for i in range(11)]]
        tube('Moonstring crescent',pts,.016,'silver','head','Forged details')
        for s in [-1,1]:
            leaf('Moonstone shoulder',(s*.31,-.02,1.43),(s*.40,-.02,1.61),.08,'moon','chest')
            leaf('Silver mantle clasp',(s*.16,-.16,1.42),(s*.21,-.17,1.32),.025,'silver')
    elif d['id']=='pip':
        tube('Goggle headband',[(-.205,-.06,1.86),(0,-.145,1.92),(.205,-.06,1.86)],.032,'leather','head')
        for s in [-1,1]:
            ball('Brass goggle frame',(s*.09,-.16,1.91),(.071,.035,.064),'brass','head','Forged details')
            ball('Goggle lens',(s*.09,-.189,1.91),(.048,.012,.044),'moon','head','Forged details')
        block('Clockwork pack',(0,.30,1.26),(.39,.24,.42),'leather','chest',.045)
        block('Brass pack housing',(0,.433,1.26),(.31,.035,.30),'brass','chest',.025,kind='Forged details')
        for j,(x,z,r) in enumerate([(-.065,1.32,.077),(.07,1.20,.055)]):
            points=[(x+math.cos(i*math.tau/24)*(r if i%3 else r*.77),.462,z+math.sin(i*math.tau/24)*(r if i%3 else r*.77)) for i in range(25)]
            tube('Pack gear '+str(j),points,.018,'steel_dark','chest','Forged details',sides=5)
        for x in [-.12,.12]:
            for z in [1.15,1.38]:ball('Pack rivet',(x,.46,z),(.017,.01,.017),'gold','chest','Forged details',8,6)
    finalize(d,'archers')


def pet_rig(wolf=False,beetle=False):
    if beetle:
        bone('body',(0,0,.18),(0,0,.38),'root');bone('head',(0,-.20,.28),(0,-.40,.30),'body')
        for side,s in [('L',1),('R',-1)]:
            bone('shell.'+side,(s*.03,.08,.36),(s*.23,.08,.39),'body')
            bone('wing.'+side,(s*.05,.03,.29),(s*.43,.03,.31),'body')
            bone('antenna.'+side,(s*.07,-.34,.31),(s*.16,-.46,.53),'head')
            for i in range(3):bone('leg%d.%s'%(i,side),(s*.15,-.15+i*.15,.27),(s*.34,-.20+i*.17,.06),'body')
    else:
        h=.48 if wolf else .34;front=-.28 if wolf else -.18;back=.30 if wolf else .22
        bone('body',(0,.15,h),(0,-.18,h),'root');bone('chest',(0,-.18,h),(0,-.29,h+.08),'body')
        bone('neck',(0,-.28,h+.05),(0,-.38,h+.21),'chest');bone('head',(0,-.36,h+.18),(0,-.65,h+.22),'neck')
        for side,s in [('L',1),('R',-1)]:
            bone('ear.'+side,(s*.12,-.35,h+.31),(s*.18,-.32,h+.54),'head')
            for prefix,y in [('front',front),('back',back)]:
                bone(prefix+'_upper.'+side,(s*.14,y,h),(s*.14,y+.015,h*.52),'chest' if prefix=='front' else 'body')
                bone(prefix+'_lower.'+side,(s*.14,y+.015,h*.52),(s*.14,y-.04,.06),prefix+'_upper.'+side)
        bone('tail01',(0,back,h),(0,back+.26,h+.08),'body');bone('tail02',(0,back+.26,h+.08),(0,back+.52,h+.28),'tail01');bone('tail03',(0,back+.52,h+.28),(0,back+.70,h+.43),'tail02')
    bpy.ops.object.mode_set(mode='OBJECT');RIG.select_set(False)


def animal_ear(name,s,z,color,inner):
    x=s*.13;y=-.35
    verts=[(x-s*.10,y-.025,z),(x+s*.095,y-.01,z+.025),(x+s*.065,y+.035,z+.26),(x,y+.075,z+.07)]
    geometry(name,verts,[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],color,'ear.'+('L' if s>0 else 'R'),smooth=False)
    geometry(name+' inner',[(x-s*.05,y-.028,z+.045),(x+s*.05,y-.015,z+.06),(x+s*.055,y+.025,z+.205)],[(0,1,2)],inner,'ear.'+('L' if s>0 else 'R'),smooth=False)


def make_animal(wolf=False):
    d=dict(id='wolf' if wolf else 'fox',name='Wild Wolf' if wolf else 'Forest Fox',role='Howling guardian' if wolf else 'Dart companion',description='Silver-blue coat, layered neck ruff, strong paws and a long brush tail.' if wolf else 'Russet coat, oversized ears, cream muzzle and a sweeping white-tipped brush.')
    new_asset(d['id'],d['name']);pet_rig(wolf)
    coat='wolf' if wolf else 'fox';light='wolf_light' if wolf else 'cream';dark='wolf_dark' if wolf else 'leather';h=.48 if wolf else .34
    ball('Lean haunches',(0,.13,h),(.205,.31 if wolf else .26,.235 if wolf else .18),coat,'body',segments=16,rings=10)
    ball('Deep chest',(0,-.18,h+.02),(.215,.24,.285 if wolf else .22),coat,'chest',segments=14,rings=10)
    ball('Light breast bib',(0,-.345,h+.015),(.155,.10,.24 if wolf else .19),light,'chest')
    ball('Neck ruff',(0,-.30,h+.12),(.225,.18,.22),coat,'neck')
    ball('Cheek silhouette',(0,-.38,h+.23),(.205,.20,.17),coat,'head',segments=14,rings=10)
    for s in [-1,1]:
        animal_ear('Alert pointed ear',s,h+.33,coat,dark if wolf else 'linen')
        for i in range(3):
            leaf('Cheek fur',(s*.13,-.43+i*.06,h+.24),(s*(.27-i*.01),-.38+i*.07,h+.13-i*.02),.055,light,'head')
        ball('Eye socket',(s*.128,-.527,h+.285),(.046,.022,.039),'nose','head',segments=10,rings=6)
        ball('Amber eye',(s*.128,-.545,h+.29),(.026,.009,.027),'eye' if wolf else 'ink','head',segments=10,rings=6)
        ball('Eye glint',(s*.119,-.553,h+.30),(.008,.004,.009),'white','head',segments=8,rings=4)
    ball('Tapered muzzle',(0,-.565,h+.18),(.115,.17 if wolf else .13,.09),light,'head')
    ball('Velvet nose',(0,-.71 if wolf else -.68,h+.21),(.065,.035,.041),'nose','head',segments=10,rings=6)
    tube('Muzzle line',[(0,-.706 if wolf else -.676,h+.195),(0,-.69 if wolf else -.66,h+.15)],.005,'nose','head',sides=4)
    front=-.28 if wolf else -.18;back=.30 if wolf else .22
    for side,s in [('L',1),('R',-1)]:
        for prefix,y in [('front',front),('back',back)]:
            limb=prefix+'_upper.'+side;lower=prefix+'_lower.'+side
            tube('Tapered leg',[(s*.14,y,h),(s*.14,y+.015,h*.53)],.068,coat,limb,radii=[.09,.062],sides=10)
            tube('Dark stocking',[(s*.14,y+.015,h*.53),(s*.14,y-.04,.075)],.052,dark,lower,radii=[.063,.044],sides=8)
            ball('Rounded paw',(s*.14,y-.075,.065),(.075,.11,.065),dark,lower,segments=10,rings=6)
            if wolf:
                for i in [-1,0,1]:ball('Ivory claw',(s*.14+i*.026,y-.17,.044),(.009,.026,.011),'linen',lower,segments=8,rings=4)
    # A multi-segment skinned tail with a contrasting tip, so wagging deforms its silhouette.
    points=[(0,back,h),(0,back+.14,h+.005),(.035,back+.29,h+.08),(.065,back+.44,h+.19),(.055,back+.58,h+.32),(.02,back+.72,h+.41)]
    tail=tube('Sweeping brush tail',points,.12,coat,'tail01',radii=[.07,.13,.16,.15,.11,.012],sides=12)
    # Replace the rigid assignment with smoothly blended tail bone weights.
    tail.vertex_groups.clear()
    for j in range(len(points)):
        frac=j/(len(points)-1)*2;lo=min(1,int(frac));t=frac-lo
        for bn,w in [('tail0'+str(lo+1),1-t),('tail0'+str(lo+2),t)]:
            vg=tail.vertex_groups.get(bn) or tail.vertex_groups.new(name=bn);vg.add(list(range(j*12,(j+1)*12)),w,'REPLACE')
    uv=tail.data.uv_layers[0];idx=INDEX[light]
    for poly in tail.data.polygons:
        if all(tail.data.vertices[v].co.y>back+.44 for v in poly.vertices):
            for li in poly.loop_indices:uv.data[li].uv=((idx%8+.5)/8,(idx//8+.5)/8)
    # An identifiable collar and clasp, independent of player element.
    tube('Companion collar',[(-.17,-.29,h+.10),(0,-.40,h+.06),(.17,-.29,h+.10)],.023,'teal_dark' if wolf else 'forest','neck')
    leaf('Companion charm',(0,-.415,h+.065),(0,-.43,h-.025),.045,'silver' if wolf else 'gold','neck')
    if wolf:
        for i in range(7):
            a=i*math.tau/7;leaf('Layered mane',(math.cos(a)*.16,-.21,h+.08+math.sin(a)*.14),(math.cos(a)*.27,-.03,h+.04+math.sin(a)*.24),.07,'wolf_dark','neck')
    finalize(d,'pets')


def make_beetle():
    d=dict(id='beetle',name='Lantern Beetle',role='Coin & experience scout',description='Split jade carapace, six brass legs, petal wings and a warm lantern abdomen.')
    new_asset(d['id'],d['name']);pet_rig(beetle=True)
    ball('Lantern abdomen',(0,.10,.28),(.205,.285,.17),'amber','body','Luminous inlay',16,10)
    ball('Dark thorax',(0,-.15,.28),(.16,.16,.12),'shell','body')
    for side,s in [('L',1),('R',-1)]:
        # Half-domes leave a visible gold center seam and unfold about their own bones.
        verts=[];faces=[];rows=7;cols=9
        for j in range(rows):
            lat=.08+(math.pi-.16)*j/(rows-1)
            for i in range(cols):
                angle=(i/(cols-1))*math.pi/2
                verts.append((s*(.018+.20*math.sin(lat)*math.sin(angle)),.08+.28*math.cos(lat),.27+.18*math.sin(lat)*math.cos(angle)))
        for j in range(rows-1):
            for i in range(cols-1):faces.append((j*cols+i,j*cols+i+1,(j+1)*cols+i+1,(j+1)*cols+i))
        geometry('Split enamel carapace',verts,faces,'jade','shell.'+side,kind='Forged details')
        tube('Gold shell edge',[(s*.02,-.17,.30),(s*.025,0,.45),(s*.02,.30,.34)],.012,'gold','shell.'+side,'Forged details')
        for i in range(3):
            y=-.15+i*.15
            tube('Articulated brass leg',[(s*.15,y,.27),(s*.30,y-.07,.20),(s*.35,y-.10,.055)],.015,'brass','leg%d.%s'%(i,side),'Forged details',sides=6)
            ball('Leg joint',(s*.30,y-.07,.20),(.028,.028,.028),'gold','leg%d.%s'%(i,side),'Forged details',8,6)
        tube('Curled antenna',[(s*.07,-.34,.31),(s*.12,-.40,.46),(s*.16,-.46,.53)],.012,'brass','antenna.'+side,'Forged details')
        ball('Luminous antenna tip',(s*.16,-.46,.53),(.035,.035,.04),'glow','antenna.'+side,'Luminous inlay',10,6)
        leaf('Folded petal wing',(s*.06,-.08,.29),(s*.42,.23,.29),.09,'linen','wing.'+side)
    ball('Scout head',(0,-.32,.29),(.135,.13,.10),'shell','head',segments=14,rings=8)
    for s in [-1,1]:
        ball('Jewel eye',(s*.09,-.407,.32),(.042,.026,.041),'glow','head','Luminous inlay',10,8)
        ball('Eye glint',(s*.083,-.428,.33),(.01,.006,.012),'white','head',segments=8,rings=4)
    for y in [.03,.15,.26]:tube('Lantern cage rib',[(-.18,y,.27),(0,y,.105),(.18,y,.27)],.013,'brass','body','Forged details')
    finalize(d,'pets')


def animate(kind,name):
    rig=RIG;scene=bpy.context.scene;scene.render.fps=30
    clips=['Idle','Walk'] if kind=='archers' else ['Idle','Hover'] if name=='Lantern Beetle' else ['Idle','Trot']
    rig.animation_data_create()
    for clip in clips:
        action=bpy.data.actions.new(name+' / '+clip);rig.animation_data.action=action
        frames=72 if clip=='Idle' else 30
        for frame in range(1,frames+2,3):
            f=min(frame,frames+1);phase=(f-1)/frames*math.tau;v=math.sin(phase)
            for p in rig.pose.bones:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
            if kind=='archers':
                if clip=='Idle':
                    rig.pose.bones['chest'].rotation_euler.x=v*.018
                    rig.pose.bones['head'].rotation_euler.y=math.sin(phase+.3)*.035
                    rig.pose.bones['cape'].rotation_euler.x=math.sin(phase+.6)*.035
                    rig.pose.bones['upper_arm.L'].rotation_euler.y=v*.025
                    rig.pose.bones['upper_arm.R'].rotation_euler.x=-v*.025
                else:
                    rig.pose.bones['hips'].location.y=abs(v)*.025
                    for side,s in [('L',1),('R',-1)]:
                        rig.pose.bones['thigh.'+side].rotation_euler.x=v*.40*s
                        rig.pose.bones['shin.'+side].rotation_euler.x=max(0,-v*s)*.48
                        rig.pose.bones['foot.'+side].rotation_euler.x=-max(0,v*s)*.12
                        rig.pose.bones['upper_arm.'+side].rotation_euler.x=-v*.17*s
                        rig.pose.bones['forearm.'+side].rotation_euler.x=-.10-max(0,v*s)*.12
                    rig.pose.bones['chest'].rotation_euler.y=v*.045
                    rig.pose.bones['cape'].rotation_euler.x=-.08+math.sin(phase-.4)*.10
            elif name=='Lantern Beetle':
                rig.pose.bones['body'].location.y=v*.012 if clip=='Idle' else .11+v*.025
                for side,s in [('L',1),('R',-1)]:
                    rig.pose.bones['antenna.'+side].rotation_euler.x=v*.10*s
                    rig.pose.bones['shell.'+side].rotation_euler.y=s*(.07 if clip=='Idle' else .48)
                    rig.pose.bones['wing.'+side].rotation_euler.y=s*(.1 if clip=='Idle' else .4+math.sin(phase*4)*.35)
                    for i in range(3):rig.pose.bones['leg%d.%s'%(i,side)].rotation_euler.x=math.sin(phase+i)*(.05 if clip=='Idle' else .17)
            else:
                rig.pose.bones['body'].location.y=(abs(v)*.023 if clip=='Trot' else v*.009)
                rig.pose.bones['head'].rotation_euler.y=math.sin(phase)*.055
                for i in range(3):rig.pose.bones['tail0'+str(i+1)].rotation_euler.y=math.sin(phase-i*.55)*(.18 if clip=='Trot' else .12)
                for side,s in [('L',1),('R',-1)]:
                    rig.pose.bones['ear.'+side].rotation_euler.x=math.sin(phase+s*.5)*.045
                    for prefix,k in [('front',1),('back',-1)]:
                        rig.pose.bones[prefix+'_upper.'+side].rotation_euler.x=v*.43*s*k if clip=='Trot' else 0
                        rig.pose.bones[prefix+'_lower.'+side].rotation_euler.x=max(0,-v*s*k)*.45 if clip=='Trot' else 0
            for p in rig.pose.bones:
                p.keyframe_insert(data_path='rotation_euler',frame=f,group=p.name)
                if p.name in ['hips','body']:p.keyframe_insert(data_path='location',frame=f,group=p.name)
        track=rig.animation_data.nla_tracks.new();track.name=clip
        strip=track.strips.new(clip,1,action);strip.action_frame_start=1;strip.action_frame_end=frames+1
        track.mute=True
        rig.animation_data.action=None
    # Unmute tracks for NLA export; the rest pose is restored for the Blender library.
    for track in rig.animation_data.nla_tracks:track.mute=False
    rig.animation_data.action=None
    return clips


def finalize(d,kind):
    rig=RIG;bpy.ops.object.select_all(action='DESELECT')
    for ob in PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name=d['name']+' / skinned model'
    # Blender join preserves face UVs and the named vertex groups.
    mesh.parent=rig;mod=mesh.modifiers.new('Wildfall deformation rig','ARMATURE');mod.object=rig
    for vertex in mesh.data.vertices:
        total=sum(g.weight for g in vertex.groups)
        if abs(total-1)>1e-4:raise RuntimeError('Non-normalized skin weight: '+str(total))
    # Single shared material per surface category, with no per-part draw calls.
    unique=[];mapping={}
    for i,m in enumerate(mesh.data.materials):
        if m not in unique:unique.append(m)
        mapping[i]=unique.index(m)
    old=[mapping[p.material_index] for p in mesh.data.polygons];mesh.data.materials.clear()
    for m in unique:mesh.data.materials.append(m)
    for p,index in zip(mesh.data.polygons,old):p.material_index=index
    for vert in mesh.data.vertices:
        if len([g for g in vert.groups if g.weight>0])>4:raise RuntimeError('More than four skin influences')
    mesh.data.calc_loop_triangles();triangles=len(mesh.data.loop_triangles)
    clips=animate(kind,d['name'])
    path=OUT/kind/(d['id']+'.glb');path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=73;bpy.context.scene.frame_set(1)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_def_bones=True,export_optimize_animation_size=True,export_rest_position_armature=True)
    for track in rig.animation_data.nla_tracks:track.mute=True
    for p in rig.pose.bones:p.rotation_euler=(0,0,0);p.location=(0,0,0)
    bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    positions=[mesh.matrix_world@Vector(v) for v in mesh.bound_box];height=max(v.z for v in positions)-min(v.z for v in positions)
    entry={**d,'kind':kind,'triangles':triangles,'vertices':len(mesh.data.vertices),'bones':sum(b.use_deform for b in rig.data.bones),'materials':len(unique),'clips':clips,'heightMeters':round(height,3),'file':str(path.relative_to(ROOT/'godot-models')),'bytes':path.stat().st_size}
    ASSETS.append((entry,rig,mesh));print('ASSET_COMPLETE',json.dumps(entry),flush=True)


def stage_and_render():
    scene=bpy.context.scene
    # A compact studio lineup is saved with the source library, editable collections intact.
    for i,(d,rig,mesh) in enumerate(ASSETS):
        if d['kind']=='archers':rig.location=((i-2)*1.55,0,0)
        else:rig.location=((i-6)*1.7,-1.7,0)
    studio=bpy.data.collections.new('Studio / presentation only');scene.collection.children.link(studio)
    def studio_obj(ob):
        for c in list(ob.users_collection):c.objects.unlink(ob)
        studio.objects.link(ob)
    bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.name='Studio floor';studio_obj(floor)
    m=bpy.data.materials.new('Studio charcoal');m.diffuse_color=(.035,.047,.055,1);floor.data.materials.append(m)
    def area(name,location,energy,color,size):
        data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=size
        ob=bpy.data.objects.new(name,data);studio.objects.link(ob);ob.location=location;ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
    area('Warm softbox',(-4,-5,7),950,(1,.84,.67),6)
    area('Cool fill',(5,-2,4),700,(.63,.81,1),5)
    area('Edge light',(0,4,6),1200,(.67,1,.86),5)
    world=bpy.data.worlds.new('Studio world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.17,.20,1);world.node_tree.nodes['Background'].inputs[1].default_value=.4;scene.world=world
    camera_data=bpy.data.cameras.new('Review camera');camera=bpy.data.objects.new('Review camera',camera_data);studio.objects.link(camera);scene.camera=camera
    camera.location=(5.3,-13.5,6.3);target=Vector((0,-.4,1.0));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=9.2;camera_data.lens=50
    scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
    scene.render.resolution_x=2000;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
    scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(RENDERS/'roster.png')
    # Source stays compact; all packed palette textures travel with the .blend.
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'wildfall-roster.blend'),compress=True)
    if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.materials):bpy.data.materials.remove(block)
    SOURCE.mkdir(exist_ok=True,parents=True);palette=SOURCE/'wildfall-palette.png';png(palette)
    image=bpy.data.images.load(str(palette));image.name='Wildfall Palette';image.pack()
    for d in ARCHERS:make_archer(d)
    make_animal(False);make_animal(True);make_beetle()
    (OUT/'manifest.json').write_text(json.dumps({'edition':'Base designs 01','units':'meters','blenderVersion':bpy.app.version_string,'paletteSize':256,'assets':[a[0] for a in ASSETS]},indent=2)+'\n')
    stage_and_render()

if __name__=='__main__':main()
