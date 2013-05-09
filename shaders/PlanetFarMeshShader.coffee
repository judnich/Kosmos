
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

uniform vec3 planetColor1;
uniform vec3 planetColor2;


vec3 computeLighting(float globalDot, float diffuse, float ambient, vec3 color)
{
	/*float nightBlend = clamp(0.5 - globalDot * 4.0, 0.0, 1.0);
 	float nightLight = clamp(0.2 / sqrt(camDist) - 0.001, 0.0, 1.0);
 	float ambientNight = nightBlend * (ambient * ambient * 0.14 + 0.02) * nightLight;

 	float grayColor = (color.r + color.g + color.b) / 3.0;
 	vec3 nightColor = vec3(grayColor * 0.4, grayColor * 0.1, grayColor * 1.0);*/

 	return color * diffuse;// + nightColor * ambientNight;
}

vec3 computeColor(float height, float ambient)
{
	float selfShadowing = 1.01 - dot(planetColor1, vec3(1,1,1)/3.0);

	vec3 color = vec3(1,1,1);
	float edge = mix(1.0, ambient, selfShadowing);
	color *= mix(planetColor2, vec3(1,1,1) * edge, clamp(abs(height - 0.0) / 1.5, 0.0, 1.0));
	color *= mix(planetColor1, vec3(1,1,1) * edge, clamp(abs(height - 0.5) / 2.5, 0.0, 1.0));

	color *= height * 0.25 + 1.00;

	return color;
}

void main(void) {
	// extract terrain info
	vec4 tex = texture2D(sampler, vUV);
	vec3 norm = normalize(tex.xyz * 2.0 - 1.0);

	// compute terrain shape features values
	float globalDot = dot(lightVec, vNormal);
	float diffuse = clamp(dot(lightVec, norm), 0.0, 1.0);
 	float ambient = clamp(1.0 - 2.0 * acos(dot(norm, normalize(vNormal))), 0.0, 1.0);
	float height = tex.a;

	// compute color based on terrain features
 	vec3 color = computeColor(height, ambient);

	gl_FragColor.xyz = computeLighting(globalDot, diffuse, ambient, color);

    gl_FragColor.w = 1.0; //alpha;
}

"""


vert = """

attribute vec3 aPos;
attribute vec2 aUV;

uniform mat4 projMat;
uniform mat4 modelViewMat;

varying vec3 vNormal;
varying vec2 vUV;

void main(void) {
	vNormal = aPos;
	vUV = aUV;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;
}

"""

xgl.addProgram("planetFarMesh", vert, frag)
