shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D mask_tex : filter_linear;

uniform vec2 viewport_size = vec2(1152.0, 648.0);
uniform vec3 tint : source_color = vec3(0.6, 0.9, 1.0);   // only colors the player glow now

uniform vec2 player_pos = vec2(0.0);
uniform float player_inner = 20.0;
uniform float player_outer = 90.0;
uniform float player_strength = 0.8;

void fragment() {
    vec2 px = SCREEN_UV * viewport_size;
    float ambient = (1.0 - smoothstep(player_inner, player_outer, distance(px, player_pos))) * player_strength;

    vec3 echo_light = texture(mask_tex, SCREEN_UV).rgb;   // colored by the ramp
    vec3 light = max(echo_light, tint * ambient);

    COLOR = vec4(texture(screen_tex, SCREEN_UV).rgb * light, 1.0);
}