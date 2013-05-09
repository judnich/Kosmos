hfunctions = []

hfunctions[0] = """precision highp float;

float heightFunc(vec3 coord, vec4 random)
{
        vec3 v;

        coord += random.xyz * 1001.0;

        float a = 0.0;
        float p = 6.0 + random.x * 2.0;

        for (int i = 0; i < 6; ++i) {
                v = coord * p;

                float ridged = 1.0 - abs(snoise(v));
                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * random.y);
                float k = (snoise(v)+1.0) / 2.0;

                v = coord * p;

                a += ridged * k;
                
                if (i >= 3) {
                        v = coord * p * 8.0;
                        float rolling = (snoise(v)+1.0) / 2.0;
                        a += (rolling) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * random.x - random.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""

hfunctions[1] = """precision highp float;

float heightFunc(vec3 coord, vec4 random)
{
        vec3 v;

        coord += random.xyz * 1001.0;

        float a = 0.0;
        float p = 6.0 + random.x * 2.0;

        float rolly = clamp((snoise(coord * 3.0) + snoise(coord * 6.0) + random.w) / 2.0, 0.0, 1.0);

        for (int i = 0; i < 6; ++i) {
                v = coord * p;

                float ridged = 1.0 - abs(snoise(v)); // rolling
                ridged = ridged * (1.0 - rolly) + rolly * ((snoise(v)+1.0) / 2.0);

                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * random.y);
                float k = (snoise(v)+1.0) / 2.0;

                v = coord * p;

                a += ridged * k;
                
                if (i >= 2) {
                        v = coord * p * 8.0;
                        float ridged = 1.0 - abs(snoise(v));
                        a += (ridged) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * random.x - random.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""

hfunctions[2] = """precision highp float;

float heightFunc(vec3 coord, vec4 random)
{
        vec3 v;

        coord += random.xyz * 1001.0;

        float a = 0.0;
        float p = 6.0 + random.x * 2.0;

        for (int i = 0; i < 6; ++i) {
                v = coord * p;

                float rolly = clamp((snoise(v) + 1.0) / 2.0, 0.0, 1.0);

                float ridged = 1.0 - abs(snoise(v)); // rolling
                ridged = ridged * (1.0 - rolly) + rolly * ((snoise(v)+1.0) / 2.0);

                ridged /= float(i)+1.0;

                v = coord * p / (2.5 + 2.5 * random.y);
                float k = (1.0 - abs(snoise(v))); //(snoise(v)+1.0) / 2.0;

                v = coord * p;

                a += ridged * k;
                
                if (i >= 2) {
                        v = coord * p * 8.0;
                        float ridged = 1.0 - abs(snoise(v));
                        a += (ridged) * (1.0-k) / float(50);
                }

                p *= 2.25 - 0.25 * random.x - random.z * 0.5;
        }

        a /= 1.6;

        return a;
}

"""



root = exports ? this
root.kosmosShaderHeightFunctions = hfunctions
