
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;
varying float camDist;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

uniform vec4 uvRect;

const float uvScalar = 4097.0 / 4096.0;
#define ONE_TEXEL (1.0/4096.0)

float computeLighting(vec3 N, float ambient)
{
	float d = clamp(dot(lightVec, N), 0.0, 1.0);
	float gd = clamp(-dot(lightVec, vNormal), 0.0, 1.0);

 	float nightLight = clamp(0.1 / camDist - 0.015, 0.0, 1.0);
 	d = d * 0.90 + ambient * mix(0.1, nightLight * 0.1, gd);

 	return d;
 	//return ambient * mix(0.1, 0.025, gd);
}

void main(void) {
	vec4 tex = texture2D(sampler, vUV * uvScalar, -0.5);

	float ao = (tex.a * 0.5 + 0.5);
	
	// extract normal and horizon values
	vec3 norm = tex.xyz * 2.0 - 1.0;
	float len = length(norm);
	norm /= len;
	float ambient = clamp(((len - 0.0625) / 0.9375), 0.0, 1.0);

	float l = ao * computeLighting(norm, ambient);

    gl_FragColor.xyz = vec3(l);
    gl_FragColor.w = 1.0; //alpha;
}

"""


vert = """

precision highp float;

attribute vec3 aUV;

uniform mat4 projMat;
uniform mat4 modelViewMat;
uniform mat3 cubeMat;

varying vec3 vNormal;
varying vec2 vUV;
varying float camDist;

uniform vec4 uvRect;
uniform sampler2D vertSampler;

const float uvScalar = 4097.0 / 4096.0;

void main(void) {
	vec2 uv = aUV.xy * uvRect.zw + uvRect.xy;

	vec3 aPos = vec3(uv * 2.0 - 1.0, 1.0);
	aPos = normalize(aPos * cubeMat);

	float height = texture2D(vertSampler, uv * uvScalar).a;
	aPos *= 0.99 + (height - (uvRect.z * 3.0) * aUV.z) * 0.01;

	vNormal = aPos;
	vUV = uv.xy;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;

    camDist = gl_Position.z;
}

"""

xgl.addProgram("planetNearMesh", vert, frag)
