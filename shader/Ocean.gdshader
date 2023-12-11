shader_type spatial;

uniform vec3 albedo_base: source_color;
uniform vec3 albedo_shallow: source_color;
uniform float matallic: hint_range(0.0, 1.0) = 0;
uniform float roughness: hint_range(0.0, 1.0) = 0.02;

uniform sampler2D normal_1;
uniform vec2 wave_direction_normal_1 = vec2(2.0,0);

uniform sampler2D normal_2;
uniform vec2 wave_direction_normal_2 = vec2(0,0.5);

uniform float timescale: hint_range(0.0, 5.0) = 1.0;
uniform float normal_blending: hint_range(0.0, 1.0) = 0.5;

uniform sampler2D DEPTH_TEXTURE: source_color, hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float fersnel_amount = 5.0;

uniform sampler2D wave;
uniform float noise_scale;
uniform float height_sacle;

uniform vec4 color_deep: source_color;
uniform vec4 color_shallow: source_color;
uniform float beers_law_power = 2.0;
uniform float depth_offset = -0.75;

varying float height;
varying vec3 world_pos;

float fersnel(float amount, vec3 normal, vec3 view) {
	float dot_p = dot(normalize(normal), normalize(view));
	float invert = 1.0 - clamp(dot_p, 0.0, 1.0);
	return pow( invert , amount);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * timescale).r;
	VERTEX.y += height * height_sacle;
}

void fragment() {
	
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / ((depth_texture) + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp( (depth + VERTEX.z + depth_offset) * -beers_law_power );
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_pow = clamp( pow(depth_blend, 2.5), 0.0, 1.0 );
	
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_pow * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_pow);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_pow * 0.5);
	
	
	vec2 normal_1_speed = TIME * wave_direction_normal_1 * timescale;
	vec2 normal_2_speed = TIME * wave_direction_normal_2 * timescale;
	vec3 mix_normal = mix(texture(normal_1, world_pos.xz + normal_1_speed).rgb, texture(normal_2,world_pos.xz + normal_2_speed).rgb, normal_blending );
	
	vec3 albedo_base_wave = mix(albedo_base, albedo_shallow, fersnel(fersnel_amount, NORMAL, VIEW) );
	
	
	ALBEDO = mix(albedo_base_wave, color, 0.75);
	METALLIC = matallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = mix_normal;
}
