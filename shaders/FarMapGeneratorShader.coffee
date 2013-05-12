frag = """//precision highp float;

varying vec3 vPos;
varying vec3 vTangent;
varying vec3 vBinormal;

""" + windowsCompatibilityUglyHacks.randomSeedDefString + """ //uniform vec3 randomSeed;

#define ONE_TEXEL (1.0/256.0)


vec4 positionAndHeight(vec3 cubePos)
{
        vec3 pos = normalize(cubePos);
        float h = heightFunc(pos, randomSeed);
        pos *= 0.997 + h * 0.003;
        return vec4(pos, h);
}


void main(void) {
	vec4 h00 = positionAndHeight(vPos);
        vec4 h10 = positionAndHeight(vPos + ONE_TEXEL * vBinormal);
        vec4 h01 = positionAndHeight(vPos + ONE_TEXEL * vTangent);
        
        vec3 right = (h10.xyz - h00.xyz);
        vec3 forward = (h01.xyz - h00.xyz);
        vec3 normal = normalize(cross(right, forward));

        float height = h00.a;
        gl_FragColor = vec4((normal + 1.0) * 0.5, height);
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

void main(void) {
	vPos = aPos;
        vTangent = aTangent;
        vBinormal = aBinormal;
	gl_Position = vec4(aUV * 2.0 - 1.0, 0.0, 1.0);
}

"""

for i in [0..kosmosShaderHeightFunctions.length-1]
        xgl.addProgram("farMapGenerator" + i, vert, xgl.commonNoiseShaderSource3 + kosmosShaderHeightFunctions[i] + frag)

