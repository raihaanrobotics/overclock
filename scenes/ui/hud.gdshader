shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 glass_color : source_color = vec4(0.05, 0.08, 0.12, 0.45);

void fragment() {
    vec4 bg = textureLod(screen_texture, SCREEN_UV, blur_amount);
    COLOR = mix(bg, glass_color, glass_color.a);
}
