shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture;
uniform sampler2D noise_texture;

const float amplitude = 0.05f;
const float tail_amplitude = 0.025f;
const float tail_offset = 0.015f;
const float tail_cutoff = 0.4f;
const float tail_speed = 20.0f;
const float speed = 15.0f;
const float radius = 0.2f;

void vertex() {
	// Called for every vertex the material is visible on.
	if (VERTEX.y >= tail_cutoff){ // tail
		//VERTEX.y -= tail_amplitude * texture(noise_texture, VERTEX.y * vec2(TIME * 0.01f, 0)).r;
		//VERTEX.xz += tail_amplitude * vec2(sin(TIME * VERTEX.y * speed), sin(TIME * VERTEX.y * speed));
		VERTEX.z += tail_amplitude * sin(TIME * VERTEX.y * tail_speed) + tail_offset * VERTEX.y;
	}		
	else
		VERTEX.y -= amplitude * texture(noise_texture, VERTEX.xz * vec2(TIME * speed, 0)).r;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(albedo_texture, UV * vec2(1, 0.3f) + vec2(0, 0)).rgb;
}