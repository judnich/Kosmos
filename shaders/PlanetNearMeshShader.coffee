
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

varying vec3 vView;

uniform vec4 uvRect;

const float uvScalar = 4097.0 / 4096.0;
#define ONE_TEXEL (1.0/4096.0)

float computeLighting(vec3 N)
{
	vec3 V = normalize(vView);
	vec3 L = lightVec;

	/*float shininess = 1.0;
	float attenuation = 0.0;

	float diffuse = dot(N, L);

	float specularReflection;
	if (diffuse < 0.0) {
		specularReflection = 0.0;
	}
	else {
		specularReflection = attenuation * pow(max(0.0, dot(reflect(-L, N), V)), shininess);
	}*/

	float d = dot(N, L);
 	return d;
}

void main(void) {
	vec4 tex = texture2D(sampler, vUV * uvScalar, -0.5);

	/*for (int i = 0; i < 8; ++i) {
		tex = tex * 0.5 + texture2D(sampler, vUV * uvScalar + vec2(ONE_TEXEL, ONE_TEXEL) * float(i), -0.5) * 0.5;
	}*/

	float ao = (tex.a * 0.5 + 0.5);
	vec3 norm = normalize(tex.xyz * 2.0 - 1.0);
	float l = ao * computeLighting(norm) * 0.9 + 0.1;

    gl_FragColor.xyz = vec3(l);
    gl_FragColor.w = 1.0; //alpha;

    //gl_FragColor = tex;
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
varying vec3 vView;

uniform vec4 uvRect;
uniform sampler2D vertSampler;
uniform vec3 camPos;

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

    vView = normalize(aPos.xyz - camPos);
}

"""

xgl.addProgram("planetNearMesh", vert, frag)
