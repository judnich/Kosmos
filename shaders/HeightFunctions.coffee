hfunctions = []

hfunctions[0] = """//precision highp float;

float heightFunc(vec3 coord, vec3 rndSeed)
{
        vec3 v;

        float a = 0.0;
        float p = 6.0 + rndSeed.x * 2.0;

        for (int i = 0; i < 6; ++i) {
                v = coord * p + rndSeed.xyz * 1001.0;

                float ridged = 1.0 - abs(snoise(v));
                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * rndSeed.y) + rndSeed.xyz * 1001.0;
                float k = (snoise(v)+1.0) / 2.0;

                v = coord * p + rndSeed.xyz * 1001.0;

                a += ridged * k;
                
                if (i >= 3) {
                        v = coord * p * 8.0 + rndSeed.xyz * 1001.0;
                        float rolling = (snoise(v)+1.0) / 2.0;
                        a += (rolling) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * rndSeed.x - rndSeed.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""

hfunctions[1] = """//precision highp float;

float heightFunc(vec3 coord, vec3 rndSeed)
{
        vec3 v;

        float a = 0.0;
        float p = 6.0 + rndSeed.x * 2.0;

        float rolly = clamp((snoise(coord * 3.0) + snoise(coord * 6.0) + rndSeed.y) / 2.0, 0.0, 1.0);

        for (int i = 0; i < 6; ++i) {
                v = coord * p + rndSeed.xyz * 1001.0;

                float ridged = 1.0 - abs(snoise(v)); // rolling
                ridged = ridged * (1.0 - rolly) + rolly * ((snoise(v)+1.0) / 2.0);

                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * rndSeed.y) + rndSeed.xyz * 1001.0;
                float k = (snoise(v)+1.0) / 2.0;

                v = coord * p + rndSeed.xyz * 1001.0;

                a += ridged * k;
                
                if (i >= 2) {
                        v = coord * p * 8.0 + rndSeed.xyz * 1001.0;
                        float ridged = 1.0 - abs(snoise(v));
                        a += (ridged) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * rndSeed.x - rndSeed.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""

hfunctions[2] = """//precision highp float;

float heightFunc(vec3 coord, vec3 rndSeed)
{
        vec3 v;

        float a = 0.0;
        float p = 6.0 + rndSeed.x * 2.0;

        for (int i = 0; i < 6; ++i) {
                v = coord * p + rndSeed.xyz * 1001.0;

                float rolly = clamp((snoise(v) + 1.0) / 2.0, 0.0, 1.0);

                float ridged = 1.0 - abs(snoise(v)); // rolling
                ridged = ridged * (1.0 - rolly) + rolly * ((snoise(v)+1.0) / 2.0);

                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * rndSeed.y) + rndSeed.xyz * 1001.0;
                float k = (1.0 - abs(snoise(v))); //(snoise(v)+1.0) / 2.0;

                v = coord * p + rndSeed.xyz * 1001.0;

                a += ridged * k;
                
                if (i >= 2) {
                        v = coord * p * 8.0 + rndSeed.xyz * 1001.0;
                        float ridged = 1.0 - abs(snoise(v));
                        a += (ridged) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * rndSeed.x - rndSeed.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""


root = exports ? this
root.kosmosShaderHeightFunctions = hfunctions


