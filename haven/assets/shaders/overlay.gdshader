shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D mask_tex : filter_linear;
uniform sampler2D vis_tex : filter_nearest, repeat_enable;

uniform vec2 viewport_size = vec2(1152.0, 648.0);
uniform float zoom = 1.0;

const int MAX_LIGHTS = 8;
uniform int light_count = 0;
uniform vec2 light_pos[MAX_LIGHTS];
uniform float light_inner[MAX_LIGHTS];
uniform float light_outer[MAX_LIGHTS];
uniform float light_strength[MAX_LIGHTS];
uniform vec4 light_color[MAX_LIGHTS];

void fragment() {
    vec2 px = SCREEN_UV * viewport_size;

    vec3 light = texture(mask_tex, SCREEN_UV).rgb;

    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (i >= light_count) break;

        vec2 delta = px - light_pos[i];
        float dist = length(delta);
        if (dist > light_outer[i]) continue;

        float u = atan(delta.y, delta.x) / TAU + 0.5;
        float vis = texture(vis_tex, vec2(u, (float(i) + 0.5) / float(MAX_LIGHTS))).r;
        float limit = vis >= 0.0 ? vis * zoom : 1.0e6;
        float visible = 1.0 - smoothstep(limit - 1.0, limit + 2.0, dist);

        float a = (1.0 - smoothstep(light_inner[i], light_outer[i], dist)) * light_strength[i] * visible;
        light = max(light, light_color[i].rgb * a);
    }

    COLOR = vec4(texture(screen_tex, SCREEN_UV).rgb * light, 1.0);
}