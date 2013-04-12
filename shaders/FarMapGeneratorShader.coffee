
frag = """

precision mediump float;

varying vec2 vUV;

float smooth(vec2 uv) {
	return snoise(uv) * 0.5 + 0.5;
}

float ridged(vec2 uv) {
	float f = abs(snoise(uv));
	return f;
}


void main(void) {
	float l;
	l = ridged(vUV * 5.0) * 0.5;
	l += smooth(vUV * 30.0) * 0.25;
	l += smooth(vUV * 90.0) * 0.125;
	l += smooth(vUV * 270.0) * 0.125;

	gl_FragColor = vec4(l,l,l,1.0);
}

"""


vert = """

attribute vec2 aUV;
varying vec2 vUV;

void main(void) {
	vUV = aUV;
	gl_Position = vec4(vUV * 2.0 - 1.0, 1.0, 1.0);
}

"""

xgl.addProgram("farMapGenerator", vert, xgl.commonNoiseShaderSource + frag)

