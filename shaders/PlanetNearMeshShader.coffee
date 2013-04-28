
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

void main(void) {
	vec4 tex = texture2D(sampler, vUV, -0.5);
	
	vec3 norm = normalize(tex.xyz * 2.0 - 1.0);
    float l = (tex.a * 0.5 + 0.4) * dot(norm, lightVec) * 0.9 + 0.1;
    gl_FragColor.xyz = vec3(l);
    gl_FragColor.w = 1.0; //alpha;

    //gl_FragColor = tex;
}

"""


vert = """

attribute vec2 aUV;

uniform mat4 projMat;
uniform mat4 modelViewMat;
uniform mat3 cubeMat;

varying vec3 vNormal;
varying vec2 vUV;

uniform vec4 uvRect;

void main(void) {
	vec2 uv = aUV * uvRect.zw + uvRect.xy;

	vec3 aPos = vec3(uv * 2.0 - 1.0, 1.0);
	aPos = normalize(aPos * cubeMat);

	vNormal = aPos;
	vUV = aUV;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;
}

"""

xgl.addProgram("planetNearMesh", vert, frag)
