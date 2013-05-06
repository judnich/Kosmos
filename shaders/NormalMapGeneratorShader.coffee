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
        pos *= 0.995 + h * 0.005;
        return vec4(pos, h);
}


void main(void) {
        // ========================== Compute normal vector =======================
	vec4 hCenter = positionAndHeight(vPos, vUV);

        vec4 hR = positionAndHeight(vPos + ONE_TEXEL * vBinormal, vUV + vec2(ONE_TEXEL, 0));
        vec4 hF = positionAndHeight(vPos + ONE_TEXEL * vTangent, vUV + vec2(0, ONE_TEXEL));
        vec4 hL = positionAndHeight(vPos - ONE_TEXEL * vBinormal, vUV - vec2(ONE_TEXEL, 0));
        vec4 hB = positionAndHeight(vPos - ONE_TEXEL * vTangent, vUV - vec2(0, ONE_TEXEL));

        vec3 right = (hR.xyz - hL.xyz);
        vec3 forward = (hF.xyz - hB.xyz);
        vec3 normal = normalize(cross(right, forward));

        // ========================== Compute horizon angle ==========================
        float horizon = 0.0;
        vec3 vUnitPos = normalize(vPos);
        for (int i = 1; i < 8; ++i) {
                float n = float(i);

                float a = n * .0981748;
                float x, y;

                x = sin(a);
                y = cos(a);
                vec3 hR = positionAndHeight(vPos + x * ONE_TEXEL * vBinormal * n + y * ONE_TEXEL * vTangent * n, vUV + vec2(x, y) * ONE_TEXEL * n).xyz - hCenter.xyz;

                x = sin(a + 1.57079632);
                y = cos(a + 1.57079632);
                vec3 hF = positionAndHeight(vPos + x * ONE_TEXEL * vBinormal * n + y * ONE_TEXEL * vTangent * n, vUV + vec2(x, y) * ONE_TEXEL * n).xyz - hCenter.xyz;

                x = sin(a + 1.57079632 * 2.0);
                y = cos(a + 1.57079632 * 2.0);
                vec3 hL = positionAndHeight(vPos + x * ONE_TEXEL * vBinormal * n + y * ONE_TEXEL * vTangent * n, vUV + vec2(x, y) * ONE_TEXEL * n).xyz - hCenter.xyz;

                x = sin(a + 1.57079632 * 3.0);
                y = cos(a + 1.57079632 * 3.0);
                vec3 hB = positionAndHeight(vPos + x * ONE_TEXEL * vBinormal * n + y * ONE_TEXEL * vTangent * n, vUV + vec2(x, y) * ONE_TEXEL * n).xyz - hCenter.xyz;

                float d1 = dot(normalize(hR), vUnitPos);
                float d2 = dot(normalize(hF), vUnitPos);
                float d3 = dot(normalize(hL), vUnitPos);
                float d4 = dot(normalize(hB), vUnitPos);

                float d = max(d1, max(d2, max(d3, d4)));
                horizon = max(horizon, d);
        }
        horizon = clamp(horizon, 0.0, 1.0);


        // this is a very unique and extremely efficient hack
        // basically we encode the ambient occlusion map / horizon map as the normal vector length!
        // not only does this efficiently pack this info, but actually ENHANCES the normal map quality
        // because wide open areas determined by the horizon map scale down the vector length, resulting
        // in a "sharpening" effect for these areas, and a smoothing effect for curved surfaces. the end
        // result is sharpened normal maps in general appearing 2x as high resolution! mainly this is because
        // mountain peaks are sharpened, and thus dont appear as blurry as regular normals do.
        // Note: The reason scaling down normal vectors sharpens them is when interpolating linearly between
        // a large vector to a small vector, and renormalizing in the fragment shader, this has the effect of
        // producing a nonlinear interpolation. Specifically, the smaller the destination vector, the faster
        // it is approached, thus creating a "sharpened" look. 

        float ave = (hR.a + hF.a + hL.a + hB.a) * 0.25;
        float diff = abs(hCenter.a - ave) * 500.0;
        //normal /= (1.0 + diff);
        normal *= ((1.0-horizon) * 0.9375 + 0.0625);


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

