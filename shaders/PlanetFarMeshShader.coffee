
frag = """

precision mediump float;

varying vec3 vNormal;
varying vec2 vUV;

uniform float alpha;
uniform vec3 lightVec;
uniform sampler2D sampler;

void main(void) {
    gl_FragColor.xyz = texture2D(sampler, vUV).xyz * dot(vNormal, lightVec) * 0.9 + 0.1;
    gl_FragColor.w = alpha;
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
	vNormal = aPos + aUV.x * 0.0;
	vUV = aUV;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;
}

"""

xgl.addProgram("planetFarMesh", vert, frag)
