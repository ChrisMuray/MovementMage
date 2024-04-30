shader_type spatial;

const int num_nodes = 50;

uniform  sampler2D noise_tex: hint_normal;

uniform float radii[num_nodes];
uniform vec3 nodes[num_nodes];

void vertex() {
	//VERTEX += NORMAL * 0.01f;
}

void fragment() {	
	// Called for every pixel the material is visible on.
	vec4 world_coord = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	
	// accumulates how iced something should be
	float d = 0.;
	
	// loop through all 50 ice nodes (oops) and accumulate d value.
	for (int i = 0; i < num_nodes; i++) {
		float dist = length(world_coord.xyz - nodes[i]);
		d += radii[i] / (dist * dist * dist); // cubing distance makes the best looking ice patches imo
	}
	
	ALBEDO = vec3(0.8,0.8,0.9);
	float icedness = smoothstep(0.0, 1.0, d - 0.5) * 0.75;
	ALPHA = icedness * texture(noise_tex, UV).r;
	CLEARCOAT = 0.9f;
	CLEARCOAT_ROUGHNESS = 0.75f;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
