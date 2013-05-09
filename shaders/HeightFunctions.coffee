hfunctions = []

hfunctions[0] = """
float heightFunc(vec3 coord, vec4 random)
{
        vec3 v;

        coord += random.xyz * 1001.0;

        float a = 0.0;
        //float p = 4.0;
        float p = 8.0;

        for (int i = 0; i < 6; ++i) {
                v = coord * p;

                float ridged;

                ridged = 1.0 - abs(snoise(v));
                ridged /= float(i)+1.0;

                v = coord * p / 2.5;
                float k = (snoise(v)+1.0) / 2.0;

                v = coord * p;

                a += ridged * k;
                
                if (i >= 3) {
                        v = coord * p * 8.0;
                        float rolling = (snoise(v)+1.0) / 2.0;
                        a += (rolling) * (1.0-k) / float(50);
                }

                p *= 2.0;
        }

        a /= 1.6;

        return a;
}

"""


root = exports ? this
root.kosmosShaderHeightFunctions = hfunctions
