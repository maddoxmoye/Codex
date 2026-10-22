"""Original Emberwood ruin. Deterministic, editable Blender source + batched GLB.
Run: blender -b --factory-startup --python art/blender/build_emberwood.py
Blender +Z is up; its +Y becomes Godot -Z. Gameplay paving is at zero.
"""
import bpy, math, random, json
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'godot-native/assets/environment';OUT.mkdir(parents=True,exist_ok=True)
rng=random.Random(48231);TAU=math.tau
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={};batches={};obstacles=[];fires=[]
def mat(name,color,rough=.85,metal=0,texture=None,emission=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 if texture:
  for kind in ['albedo','roughness','normal']:
   t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(OUT/f'{texture}_{kind}.png'),check_existing=True);t.image.colorspace_settings.name='sRGB' if kind=='albedo' else 'Non-Color'
   if kind=='albedo':m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
   elif kind=='roughness':m.node_tree.links.new(t.outputs['Color'],p.inputs['Roughness'])
   else:
    normal=n.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.55;m.node_tree.links.new(t.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],p.inputs['Normal'])
 materials[name]=m;batches[name]=[[],[],[]];return name
stone=mat('Weathered slate • porous stone',(.4,.43,.42),texture='stone')
lightstone=mat('Old limestone • arch edges',(.46,.50,.45),.86)
soil=mat('Forest loam • moss and roots',(.12,.17,.12),texture='soil')
bark=mat('Ancient bark • vertical grain',(.19,.13,.09),texture='bark')
bronze=mat('Aged bronze • worn edges',(.33,.22,.075),.34,.8)
ember=mat('Heartfire • amber glass',(.95,.36,.075),.25,.25,emission=2.8)
coal=mat('Charcoal and iron',(.035,.045,.039),.55,.65)
leaf=[mat('Leaf • '+str(i),c,.92) for i,c in enumerate([(.052,.115,.085),(.075,.17,.105),(.13,.22,.12),(.19,.26,.125)])]
moss=mat('Moss • stone crevices',(.12,.19,.075),1)
def geom(name,verts,faces,smooth=False):
 v,f,s=batches[name];start=len(v);v.extend([tuple(x) for x in verts]);f.extend([tuple(start+i for i in face) for face in faces]);s.extend([smooth]*len(faces))
def stonepoly(points,z,depth,name=stone,bevel=.035):
 # Three perimeter rings produce bevels that catch light without costly modifiers.
 c=sum((Vector((p[0],p[1])) for p in points),Vector((0,0)))/len(points);N=len(points);verts=[]
 for h,inset in [(z-depth,0),(z-bevel,0),(z,bevel)]:
  for x,y in points:
   p=Vector((x,y));q=p+(c-p).normalized()*inset;verts.append((q.x,q.y,h))
 faces=[tuple(range(2*N,3*N)),tuple(reversed(range(N)))]
 for j in range(2):
  for i in range(N):k=(i+1)%N;faces.append((j*N+i,j*N+k,(j+1)*N+k,(j+1)*N+i))
 geom(name,verts,faces)
def box(x,y,z,sx,sy,sz,name=stone,angle=0):
 c=math.cos(angle);s=math.sin(angle);pts=[(x+dx*c-dy*s,y+dx*s+dy*c) for dx,dy in [(-sx/2,-sy/2),(sx/2,-sy/2),(sx/2,sy/2),(-sx/2,sy/2)]]
 stonepoly(pts,z+sz/2,sz,name,min(.045,sz*.2))
def tube(points,radii,name,sides=10):
 verts=[]
 for j,p in enumerate(points):
  p=Vector(p);axis=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(0,j-1)]);axis.normalize();a=axis.cross(Vector((0,0,1)))
  if a.length<.01:a=axis.cross(Vector((0,1,0)))
  a.normalize();b=axis.cross(a).normalized()
  for k in range(sides):verts.append(p+(a*math.cos(k*TAU/sides)+b*math.sin(k*TAU/sides))*radii[j])
 faces=[]
 for j in range(len(points)-1):
  for k in range(sides):q=(k+1)%sides;faces.append((j*sides+k,j*sides+q,(j+1)*sides+q,(j+1)*sides+k))
 faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+k for k in range(sides))]);geom(name,verts,faces,True)
def cylinder(x,y,z,r,h,name,sides=16):tube([(x,y,z),(x,y,z+h)],[r,r],name,sides)
def ring(radius,z,width,name,start=0,end=TAU,segments=128):
 verts=[];faces=[]
 for i in range(segments+1):
  a=start+(end-start)*i/segments
  for r in [radius-width/2,radius+width/2]:verts.append((math.cos(a)*r,math.sin(a)*r,z))
 for i in range(segments):faces.append((2*i,2*i+1,2*i+3,2*i+2))
 geom(name,verts,faces)
def blade(point,angle,length,width,name,rise=.06):
 p=Vector(point);d=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-d.y,d.x,0));mid=p+d*length*.45+Vector((0,0,rise));tip=p+d*length
 geom(name,[p,mid+side*width,mid+Vector((0,0,.025)),mid-side*width,tip],[(0,1,2),(0,2,3),(1,4,2),(2,4,3)])
def godot(p):return [round(p[0],4),round(p[2] if len(p)>2 else 0,4),round(-p[1],4)]
# Earth apron with low rolling distant terrain; playable stone remains perfectly level.
verts=[(0,0,-.13)];faces=[]
terrain_radii=[9,18,27,36,46,58,74,95,125]
for r in terrain_radii:
 for i in range(96):
  a=i*TAU/96
  # A low wooded ridge closes the horizon without cluttering playable paving.
  rise=max(0,min(1,(r-30)/38))
  z=-.14 if r<28 else rise*(7.5+2.2*math.sin(a*3+.7)+1.8*math.sin(a*7-1.2))
  verts.append((math.cos(a)*r,math.sin(a)*r,z))
for i in range(96):faces.append((0,1+i,1+(i+1)%96))
for j in range(len(terrain_radii)-1):
 for i in range(96):q=(i+1)%96;faces.append((1+j*96+i,1+j*96+q,1+(j+1)*96+q,1+(j+1)*96+i))
geom(soil,verts,faces,True)
# Hand-laid circular paving, real seams and softly worn bevels.
for row,(inside,outside,count) in enumerate([(0,2.95,10),(3.02,6.0,20),(6.07,9.15,30),(9.22,12.35,40),(12.42,15.65,52),(15.72,17.8,60)]):
 for i in range(count):
  a=(i+.16*(row%2))*TAU/count+.003;end=a+TAU/count-.006
  if row==5 and i%13 in [0,1]:continue
  arcs=4;pts=[]
  for j in range(arcs+1):q=a+(end-a)*j/arcs;pts.append((math.cos(q)*outside,math.sin(q)*outside))
  if inside>0:
   for j in range(arcs,-1,-1):q=a+(end-a)*j/arcs;pts.append((math.cos(q)*inside,math.sin(q)*inside))
  else:pts.append((0,0))
  stonepoly(pts,0,.16,stone,.022)
for radius in [3.0,6.035,12.385,15.685]:ring(radius,.012,.025,bronze)
# Four restrained ember sigils let the ruin feel authored, not covered in neon.
for k in range(4):
 a=k*math.pi/2+.2;r=9.18
 ring(r,.014,.025,ember,a-.055,a+.055,12)
 for j in range(3):
  p=Vector((math.cos(a)*r,math.sin(a)*r,.017));d=Vector((math.cos(a),math.sin(a),0));t=Vector((-d.y,d.x,0))
  p+=d*(j-.5)*.25
  geom(bronze,[p-t*.17,p+d*.12,p+t*.17,p-d*.12],[(0,1,2,3)])
# Column pairs and broken stone arches frame the woodland.
def column(x,y,height,angle):
 box(x,y,.15,1.35,1.35,.30,lightstone,angle);box(x,y,.42,1.08,1.08,.24,stone,angle)
 # Entasis and narrow grooves catch the grazing key light.
 points=[(x,y,.53),(x,y,height*.35),(x,y,height*.72),(x,y,height-.30)]
 tube(points,[.40,.44,.37,.34],stone,20)
 for z,r in [(.65,.46),(height-.4,.42),(height-.25,.49)]:cylinder(x,y,z,r,.12,lightstone,20)
 box(x,y,height-.02,1.06,1.06,.32,lightstone,angle)
 obstacles.append({'p':godot((x,y,0)),'r':.78,'h':height})
for j,a in enumerate([.58,1.62,2.67,3.7,4.75,5.8]):
 center=Vector((math.cos(a)*18.0,math.sin(a)*18.0));t=Vector((-math.sin(a),math.cos(a)));height=4.8+(j%3)*.55;span=2.4
 for side in [-1,1]:
  p=center+t*(span*side);column(p.x,p.y,height, a)
 # Voussoirs: even broken arches retain an intentionally readable curvature.
 for k in range(13):
  if j in [2,4] and k in [4,5,6,7]:continue
  if j==0 and k>8:continue
  a0=k*math.pi/13+.014;a1=(k+1)*math.pi/13-.014
  pts=[]
  for rr,q in [(span-.25,a0),(span+.25,a0),(span+.25,a1),(span-.25,a1)]:
   horizontal=math.cos(q)*rr;z=height+math.sin(q)*rr;v=center+t*horizontal;pts.append((v.x,v.y,z))
  n=Vector((math.cos(a),math.sin(a),0))*.42
  vertices=[Vector(p)-n for p in pts]+[Vector(p)+n for p in pts]
  geom(lightstone,vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
 # Low broken wall courses behind the gate; individual beveled blocks.
 for side in [-1,1]:
  for row in range(3):
   for n in range(4-row):
    p=center+t*side*(3.55+n*1.05+row*.25)
    box(p.x,p.y,.32+row*.57,1.0,.65,.54,stone,a+math.pi/2)
# Braziers: iron cages, bronze collars, glowing coals. Fire is animated in Godot.
for i,a in enumerate([.2,1.25,2.3,3.35,4.4,5.45]):
 x,y=math.cos(a)*14.6,math.sin(a)*14.6
 cylinder(x,y,0,.50,.15,stone);cylinder(x,y,.15,.32,.95,bronze,12);cylinder(x,y,1.04,.48,.12,bronze,16)
 tube([(x,y,1.15),(x,y,1.45),(x,y,1.57)],[.31,.51,.50],coal,16)
 cylinder(x,y,1.55,.41,.05,ember,16)
 for j in range(8):
  q=j*TAU/8;tube([(x+math.cos(q)*.31,y+math.sin(q)*.31,1.14),(x+math.cos(q)*.54,y+math.sin(q)*.54,1.62)],[.028,.025],bronze,5)
 fires.append(godot((x,y,1.60)));obstacles.append({'p':godot((x,y,0)),'r':.60,'h':2.0})
# Trees have roots, tapering boughs and individually shaped leaves.
for i in range(48):
 distant=i>=24
 a=(i%24)*TAU/24+(.13 if distant else 0)+rng.uniform(-.06,.06);r=rng.uniform(31,40) if distant else rng.uniform(21,27);x,y=math.cos(a)*r,math.sin(a)*r;h=rng.uniform(10,15) if distant else rng.uniform(8.5,12.5);lean=Vector((rng.uniform(-1,1),rng.uniform(-1,1),0))
 trunk=[Vector((x,y,0)),Vector((x,y,h*.25))+lean*.2,Vector((x,y,h*.58))+lean*.65,Vector((x,y,h*.88))+lean,Vector((x,y,h))+lean*1.1]
 tube(trunk,[.67,.50,.34,.18,.055],bark,11)
 for j in range(6):
  q=j*TAU/6+a;end=Vector((x+math.cos(q)*2,y+math.sin(q)*2,.02));tube([Vector((x,y,.75)),Vector((x+math.cos(q),y+math.sin(q),.16)),end],[.24,.12,.018],bark,7)
 for j in range(8):
  q=j*2.4+a;z=h*(.4+j*.068);base=Vector((x,y,z))+lean*.6;reach=rng.uniform(2.2,3.6)*(1-j*.05);end=base+Vector((math.cos(q)*reach,math.sin(q)*reach,1.2))
  tube([base,base.lerp(end,.4)+Vector((0,0,.30)),end,end+Vector((math.cos(q)*.55,math.sin(q)*.55,.7))],[.20,.13,.058,.008],bark,8)
  for k in range(35 if distant else 65):
   theta=rng.random()*TAU;rad=math.sqrt(rng.random())*1.65;p=end+Vector((math.cos(theta)*rad,math.sin(theta)*rad,rng.uniform(-.30,.55)))
   blade(p,rng.random()*TAU,rng.uniform(.38,.85),rng.uniform(.17,.30),leaf[rng.randrange(4)],rng.uniform(.04,.2))
# Forest floor ferns, leaf litter and moss pockets keep the center clear.
for i in range(220):
 a=rng.random()*TAU;r=rng.uniform(16.3,27);x,y=math.cos(a)*r,math.sin(a)*r
 for j in range(6):
  q=j*TAU/6+rng.random()*.2;length=rng.uniform(.35,.85)
  for k in range(5):
   p=Vector((x,y,.02))+Vector((math.cos(q),math.sin(q),0))*(k*.10)
   p.z+=math.sin(k/5*math.pi)*.17
   for side in [-1,1]:blade(p,q+side*.85,length*(1-k*.15)*.40,.065,leaf[(i+j)%4],.045)
for i in range(180):
 a=rng.random()*TAU;r=rng.uniform(10,18);p=Vector((math.cos(a)*r,math.sin(a)*r,.018));blade(p,rng.random()*TAU,rng.uniform(.06,.15),.04,moss,.003)
# Debris is outside the main combat disk, avoiding hidden walking obstacles.
for i in range(45):
 a=rng.random()*TAU;r=rng.uniform(17.7,20.5);x,y=math.cos(a)*r,math.sin(a)*r
 box(x,y,rng.uniform(.08,.22),rng.uniform(.3,1),rng.uniform(.3,.8),rng.uniform(.16,.42),stone,rng.random()*TAU)
# Build one mesh per surface family: low draw count, all original geometry.
for name,(verts,faces,smoothing) in batches.items():
 if not verts:continue
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.materials.append(materials[name]);mesh.update()
 uv=mesh.uv_layers.new(name='Surface meters')
 for polygon in mesh.polygons:
  polygon.use_smooth=smoothing[polygon.index];normal=polygon.normal;axis=max(range(3),key=lambda k:abs(normal[k]))
  for loop in polygon.loop_indices:
   p=mesh.vertices[mesh.loops[loop].vertex_index].co
   if axis==2:u,v=p.x/1.5,p.y/1.5
   elif axis==1:u,v=p.x/1.5,p.z/1.5
   else:u,v=p.y/1.5,p.z/1.5
   if name==bark:v=p.z/3
   uv.data[loop].uv=(u,v)
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
# Non-destructive source camera for art review.
world=bpy.data.worlds.new('Emberwood twilight');bpy.context.scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.095,.14,.20,1);world.node_tree.nodes['Background'].inputs[1].default_value=.55
light=bpy.data.lights.new('Late sun','AREA');light.energy=2200;light.shape='DISK';light.size=9;obj=bpy.data.objects.new('Late sun',light);bpy.context.collection.objects.link(obj);obj.location=(5,-6,13);obj.rotation_euler=(.35,0,.4)
cam=bpy.data.cameras.new('Review camera');obj=bpy.data.objects.new('Review camera',cam);bpy.context.collection.objects.link(obj);obj.location=(11,-18,8);direction=Vector((0,2,2))-obj.location;obj.rotation_euler=direction.to_track_quat('-Z','Y').to_euler();cam.lens=27;bpy.context.scene.camera=obj
bpy.context.scene.render.engine='BLENDER_EEVEE_NEXT';bpy.context.scene.render.resolution_x=1400;bpy.context.scene.render.resolution_y=900;bpy.context.scene.render.resolution_percentage=100
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/emberwood-ruin.blend'))
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.context.scene.objects:
 if obj.type=='MESH':obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'emberwood-ruin.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_lights=False,export_cameras=False,export_animations=False)
meta={'obstacles':obstacles,'fires':fires,'vertices':sum(len(v[0]) for v in batches.values()),'faces':sum(len(v[1]) for v in batches.values()),'materials':len(materials),'radius':18,'floorHeight':0}
(OUT/'emberwood-layout.json').write_text(json.dumps(meta,indent=2))
print('EMBERWOOD_ASSET_OK',json.dumps({k:meta[k] for k in ['vertices','faces','materials']}))
