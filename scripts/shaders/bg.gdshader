shader_type canvas_item;
const float intensity = 0.18;
const float period = 2.0;
const float speed = 0.8;
void fragment() {
	COLOR.rgb = vec3(0.08+(sin(UV.x*period+TIME*speed)/2.5+0.4)*intensity,0,0.12+UV.y*intensity*1.2);
	//COLOR.rgb = vec3(0.125+UV.x*intensity,0,0.125+UV.y*intensity);
}