
frag = """

precision mediump float;

varying vec3 vNormal;
uniform float alpha;

void main(void) {
    gl_FragColor.xyz = vec3(1, 0, 0);
    gl_FragColor.w = alpha;
}

"""


vert = """

attribute vec3 aPos;
attribute vec2 aUV;

uniform mat4 projMat;
uniform mat4 modelViewMat;

varying vec3 vNormal;

void main(void) {
	vNormal = aPos;

	vec4 pos = vec4(aPos, 1.0);
	pos = modelViewMat * pos;
    gl_Position = projMat * pos;
}

"""

xgl.addProgram("planetFarMesh", vert, frag)
