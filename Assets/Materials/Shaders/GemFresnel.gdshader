shader_type spatial;

render_mode diffuse_toon;

uniform vec3 base_color : source_color;
uniform vec3 fresnel_color : source_color;
uniform float fresnel_amount;
uniform float fresnel_intensity;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec3 fresnel_glow(vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), fresnel_amount) * color * fresnel_intensity;
}

void fragment()
{
	vec3 fresnel = fresnel_glow(fresnel_color, NORMAL, VIEW);
	ALBEDO = base_color + fresnel;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
