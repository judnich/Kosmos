
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

void main(void) {
	vec4 tex = texture2D(sampler, vUV);
	
	vec3 norm = normalize(tex.xyz * 2.0 - 1.0);
    float l = (tex.a * 0.5 + 0.5) * clamp(dot(norm, lightVec), 0.0, 1.0);
    gl_FragColor.xyz = vec3(l);
    gl_FragColor.w = alpha;

    //gl_FragColor = vec4(tex.a, tex.a, tex.a, 1.0);
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
