frag = """//precision highp float;

varying vec3 vPos;
varying vec3 vTangent;
varying vec3 vBinormal;
varying vec3 vRandomSeed;

#define ONE_TEXEL (1.0/4096.0)


float getHeightOnCube(vec3 cubePos)
{
        vec3 pos = normalize(cubePos);
        return heightFunc(pos, vRandomSeed);
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

varying vec3 vRandomSeed;
uniform vec4 randomSeed;

void main(void) {
	vPos = aPos;
        vTangent = aTangent;
        vBinormal = aBinormal;
        vRandomSeed = randomSeed.xyz;

        vec2 pos = aUV;
        pos.y = (pos.y - verticalViewport.x) / verticalViewport.y;
        pos = pos * 2.0 - 1.0;

	gl_Position = vec4(pos, 0.0, 1.0);
}

"""

for i in [0..kosmosShaderHeightFunctions.length-1]
        xgl.addProgram("nearMapGenerator" + i, vert, xgl.commonNoiseShaderSource + kosmosShaderHeightFunctions[i] + frag)

