
frag = """

precision mediump float;

varying vec3 vUVW;

float smooth(vec3 uv) {
	return snoise(uv) * 0.5 + 0.5;
}

float ridged(vec3 uv) {
	float f = abs(snoise(uv));
	return f;
}


void main(void) {
	float l;

	vec3 uv = normalize(vUVW);
	l = ridged(uv * 5.0) * 0.5;
	l += smooth(uv * 30.0) * 0.25;
	l += smooth(uv * 90.0) * 0.125;
	l += smooth(uv * 270.0) * 0.125;

	gl_FragColor = vec4(l,l,l,1.0);
}

"""


vert = """
attribute vec2 aXY;
attribute vec3 aUVW;
varying vec3 vUVW;

void main(void) {
	vUVW = aUVW;
	gl_Position = vec4(aXY * 2.0 - 1.0, 0.0, 1.0);
}

"""

xgl.addProgram("farMapGenerator", vert, xgl.commonNoiseShaderSource + frag)

