shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec4 flame_color : source_color = vec4(1.0, .38, .055, 1.0);
uniform float phase = 0.0;
varying float height;
void vertex(){
 height = UV.y;
 float bend = pow(max(VERTEX.y,0.0),1.4);
 VERTEX.x += sin(TIME*4.5+phase+VERTEX.y*5.0)*bend*.13;
 VERTEX.z += cos(TIME*3.3+phase+VERTEX.y*3.0)*bend*.09;
}
void fragment(){
 float pulse=.88+.12*sin(TIME*7.0+phase+height*8.0);
 vec3 warm=mix(vec3(1.0,.78,.25),flame_color.rgb,smoothstep(.2,.9,height));
 ALBEDO=warm;
 EMISSION=warm*(1.4+1.7*pulse);
}
