shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D palette_tex : source_color, filter_linear_mipmap;
uniform float base_roughness : hint_range(0.0,1.0)=0.68;
uniform float base_metallic : hint_range(0.0,1.0)=0.0;
uniform float grain : hint_range(0.0,0.15)=0.04;
uniform float surface_kind=0.0;
uniform float flash=0.0;
uniform vec4 element : source_color=vec4(1.0);
uniform float amount=0.0;
varying vec3 surface_position;

float hash3(vec3 p){return fract(sin(dot(p,vec3(12.9898,78.233,47.113)))*43758.5453);}
void vertex(){surface_position=VERTEX;}
void fragment(){
 vec3 base=texture(palette_tex,UV).rgb;
 vec3 p=surface_position;
 float coarse=hash3(floor(p*55.0));
 float fiber=sin(p.y*155.0+sin(p.x*50.0))*sin(p.z*125.0+p.x*140.0);
 if(surface_kind>1.5)fiber=sin(p.y*35.0+sin(p.x*48.0)*2.0+sin(p.z*20.0));
 if(surface_kind>0.5&&surface_kind<1.5)fiber=sin(p.y*180.0+p.x*18.0+p.z*19.0);
 float variation=(coarse-.5)*grain+fiber*grain*.32;
 base*=1.0+variation;
 ALBEDO=mix(mix(base,element.rgb,amount),vec3(1.0,.87,.70),flash*.85);
 METALLIC=base_metallic;
 ROUGHNESS=clamp(base_roughness+variation*.8,.18,.92);
 SPECULAR=mix(.33,.55,base_metallic);
 RIM=(1.0-base_metallic)*.10;
 RIM_TINT=.5;
}
