frag = """precision mediump float;

varying vec3 vUVW;

float smooth(vec3 uv) {
	return snoise(uv) * 0.5 + 0.5;
}

float ridged(vec3 uv) {
	float f = abs(snoise(uv));
	return f;
}

float heightFunc(vec3 coord)
{
        vec3 v;

        float a = 0.0;
        //float p = 4.0;
        float p = 8.0;

        //for (int i = 0; i < 5; ++i) {
        for (int i = 0; i < 7; ++i) {
                v.x = coord.x * p; v.y = coord.y * p; v.z = coord.z * p;

                float ridged;

                ridged = 1.0 - abs(snoise(v));
                ridged /= float(i)+1.0;

                v.x = coord.x * p / 2.5; v.y = coord.y * p / 2.5; v.z = coord.z * p / 2.5;
                float k = (snoise(v)+1.0) / 2.0;

                v.x = coord.x * p / 1.0; v.y = coord.y * p / 1.0; v.z = coord.z * p / 1.0;

                a += ridged * k;
                
                if (i >= 3) {
                        v.x = coord.x * p * 8.0; v.y = coord.y * p * 8.0; v.z = coord.z * p * 8.0;
                        float rolling = (snoise(v)+1.0) / 2.0;
                        a += (rolling) * (1.0-k) / float(50);
                }

                p *= 2.0;
        }

        a /= 1.6;

        return a;
}


void main(void) {
	float l;

	vec3 uv = normalize(vUVW);

	l = heightFunc(uv);

	/*l = ridged(uv * 5.0) * 0.5;
	l += smooth(uv * 30.0) * 0.25;
	l += smooth(uv * 90.0) * 0.125;
	l += smooth(uv * 270.0) * 0.125;*/

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

