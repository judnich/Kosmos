frag = """precision highp float;

varying vec3 vPos;
varying vec3 vTangent;
varying vec3 vBinormal;

uniform float randomSeed;

float heightFunc(vec3 coord)
{
        vec3 v;

        coord += randomSeed * 101.0;

        float a = 0.0;
        //float p = 4.0;
        float p = 8.0;

        for (int i = 0; i < 6; ++i) {
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

#define ONE_TEXEL (1.0/4096.0)


float getHeightOnCube(vec3 cubePos)
{
        vec3 pos = normalize(cubePos);
        return heightFunc(pos);
 }


void main(void) {
        float height = getHeightOnCube(vPos);
        gl_FragColor = vec4(height, height, height, height);
}

"""


vert = """
attribute vec2 aUV;
attribute vec3 aPos;
attribute vec3 aTangent;
attribute vec3 aBinormal;
varying vec3 vPos;
varying vec3 vTangent;
varying vec3 vBinormal;

uniform vec2 verticalViewport;

void main(void) {
	vPos = aPos;
        vTangent = aTangent;
        vBinormal = aBinormal;

        vec2 pos = aUV;
        pos.y = (pos.y - verticalViewport.x) / verticalViewport.y;
        pos = pos * 2.0 - 1.0;

	gl_Position = vec4(pos, 0.0, 1.0);
}

"""

xgl.addProgram("nearMapGenerator", vert, xgl.commonNoiseShaderSource + frag)

