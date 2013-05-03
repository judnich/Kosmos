frag = """precision highp float;

varying vec3 vPos;
varying vec3 vTangent;
varying vec3 vBinormal;
varying vec2 vUV;

uniform sampler2D sampler;

#define ONE_TEXEL (1.0/4096.0)


vec4 positionAndHeight(vec3 cubePos, vec2 uv)
{
        vec3 pos = normalize(cubePos);
        float h = texture2D(sampler, uv).a;
        pos *= 0.997 + h * 0.003;
        return vec4(pos, h);
}


void main(void) {
	vec4 hCenter = positionAndHeight(vPos, vUV);

        vec4 hR = positionAndHeight(vPos + ONE_TEXEL * vBinormal, vUV + vec2(ONE_TEXEL, 0));
        vec4 hF = positionAndHeight(vPos + ONE_TEXEL * vTangent, vUV + vec2(0, ONE_TEXEL));
        vec4 hL = positionAndHeight(vPos - ONE_TEXEL * vBinormal, vUV - vec2(ONE_TEXEL, 0));
        vec4 hB = positionAndHeight(vPos - ONE_TEXEL * vTangent, vUV - vec2(0, ONE_TEXEL));

        vec3 right = (hR.xyz - hL.xyz);
        vec3 forward = (hF.xyz - hB.xyz);
        vec3 normal = normalize(cross(right, forward));

        // this has a very nice sharpening effect on normals for peaks
        float ave = (hR.a + hF.a + hL.a + hB.a) * 0.25;
        float diff = abs(hCenter.a - ave) * 1000.0;
        normal /= (1.0 + diff);

        float height = hCenter.a;
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
varying vec2 vUV;

uniform vec2 verticalViewport;

void main(void) {
        vUV = aUV;
	vPos = aPos;
        vTangent = aTangent;
        vBinormal = aBinormal;

        vec2 pos = aUV;
        pos.y = (pos.y - verticalViewport.x) / verticalViewport.y;
        pos = pos * 2.0 - 1.0;

	gl_Position = vec4(pos, 0.0, 1.0);
}

"""

xgl.addProgram("normalMapGenerator", vert, xgl.commonNoiseShaderSource + frag)

