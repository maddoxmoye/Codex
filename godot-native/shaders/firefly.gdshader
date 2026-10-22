shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled;
uniform vec4 color : source_color = vec4(.95,.64,.18,1.0);
void fragment(){ALBEDO=color.rgb;EMISSION=color.rgb*2.3;}
