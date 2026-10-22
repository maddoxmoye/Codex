shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.54, 0.20, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float radius = length(p);
 float edge = (1.0-smoothstep(0.955, 0.985, radius))*smoothstep(0.91, 0.94, radius);
 float inner = (1.0-smoothstep(0.79, 0.805, radius))*smoothstep(0.765, 0.78, radius);
 float sweep = (1.0-smoothstep(progress-0.015, progress+0.015, radius))*0.10;
 float angle = atan(p.y,p.x);
 float dashes = step(0.45, sin(angle*24.0))*inner;
 float pulse = 0.88+0.12*sin(TIME*5.0);
 ALBEDO = tint.rgb;
 EMISSION = tint.rgb*(edge*1.25+dashes*.7+sweep)*pulse;
 ALPHA = clamp((edge+dashes*.6+sweep)*tint.a,0.0,0.9);
}
