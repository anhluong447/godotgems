shader_type canvas_item;
// Full-screen color grade. Presets "xuan" (warm, saturated) and "thuc" (cold, desaturated)
// are driven by PaletteController. A LUT can replace this later without changing callers.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation = 1.0;
uniform vec3 tint = vec3(1.0);
uniform float contrast = 1.0;
uniform float brightness = 0.0;
uniform float vignette = 0.0;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(luma), c, saturation);
	c = (c - 0.5) * contrast + 0.5 + brightness;
	c *= tint;
	float d = distance(UV, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.35, 0.85, d);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
