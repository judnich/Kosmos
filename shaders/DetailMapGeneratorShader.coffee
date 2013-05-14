# Copyright (C) 2013 John Judnich
# Released under The MIT License - see "LICENSE" file for details.

frag = """precision highp float;

varying vec2 vUV;

#define ONE_TEXEL (1.0/1024.0)


float rnoise(vec2 uv) {
        return 1.0 - abs(snoise(uv));
}
float hnoise(vec2 uv) {
        return snoise(uv) * 0.5 + 0.5;
}

float hfunc(vec2 v) {
        float a = 0.0;

        a += rnoise(v * 8.0) / 4.0;
        v += 0.1;
        a += rnoise(v * 16.0) / 4.0;
        v += 0.1;
        a += rnoise(v * 32.0) / 4.0;
        v += 0.1;
        a += rnoise(v * 64.0) / 4.0;
        v += 0.1;

        v = (v - 12.345) * -2.345;

        a += rnoise(v * 128.0) / 8.0;
        v += 0.1;
        a += rnoise(v * 256.0) / 8.0;
        v += 0.1;
        a += rnoise(v * 512.0) / 8.0;
        v += 0.1;
        a += rnoise(v * 1024.0) / 8.0;
        v += 0.1;

        v = (v - 12.345) * -2.345;

        a += hnoise(v * 8.0) / 8.0;
        v += 0.1;
        a += hnoise(v * 16.0) / 8.0;
        v += 0.1;
        a += hnoise(v * 32.0) / 8.0;
        v += 0.1;
        a += hnoise(v * 64.0) / 8.0;
        v += 0.1;

        a /= 2.0;

        return a;
}


void main(void) {
        float f = hfunc(vUV) * 0.5 + hfunc(vec2(1,0) - vUV) * 0.25 + hfunc(vec2(0,1) - vUV) * 0.25;
        gl_FragColor = vec4(f, f, f, 1.0);
}

"""


vert = """
attribute vec2 aUV;
varying vec2 vUV;

void main(void) {
	vUV = aUV;
	gl_Position = vec4(aUV * 2.0 - 1.0, 0.0, 1.0);
}

"""

xgl.addProgram("detailMapGenerator", vert, xgl.commonNoiseShaderSource2 + frag)

