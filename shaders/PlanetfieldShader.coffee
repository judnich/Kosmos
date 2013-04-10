
frag = """

precision mediump float;

varying vec3 vUVA;
varying vec4 vColor;

void main(void) {
	// compute planet color based on intensity = 1/dist^2 from center of sprite
	vec2 dv = vUVA.xy;
	float d = dot(dv, dv);
	float lum = clamp(1.0 / (d*100.0), 0.0, 1.0) * clamp(d*d*5000.0, vColor.a*vColor.a, 1.0);

	// fall off at a max radius, since 1/dist^2 goes on infinitely
	d = clamp(d * 4.0, 0.0, 1.0);
	lum *= 1.0 - d*d;

    gl_FragColor.xyz = vColor.xyz*lum * vUVA.z * vColor.a;
}

"""


vert = """

attribute vec3 aPos;
attribute vec3 aUV; // third component marks one vertex for blur extrusion

uniform mat4 projMat;
uniform mat4 modelViewMat;
uniform vec4 spriteSizeAndViewRangeAndBlur;
//uniform mat4 modelMat;
//uniform mat4 viewMat;

varying vec3 vUVA;
varying vec4 vColor;

void main(void) {
	// determine sprite size
	float spriteSize = spriteSizeAndViewRangeAndBlur.x;
	//spriteSize = spriteSize * (cos(aPos.w*1000.0) * 0.5 + 1.0); // modulate size by simple PRNG

	// compute vertex position so quad is always camera-facing
	vec4 pos = vec4(aPos.xyz, 1.0);
	vec2 offset = aUV.xy * spriteSize;

	//pos = viewMat * modelMat * pos;
	pos = modelViewMat * pos;
	pos.xy += offset;

   	// motion blur
	pos.z *= 1.0 + aUV.z * spriteSizeAndViewRangeAndBlur.w;

	// fade out distant sprites
	float dist = length(pos.xyz);
	float alpha = clamp( (1.0 - (dist / spriteSizeAndViewRangeAndBlur.z)) * 1.5, 0.0, 1.0 );
	alpha *= clamp( ((dist / spriteSizeAndViewRangeAndBlur.y) - 1.0) * 0.5, 0.0, 1.0);

    // the UV coordinates are used to render the actual sprite radial gradient,
    // and alpha is used to modulate intensity of distant sprites as they fade out
    vUVA = vec3(aUV.xy, alpha);

    // pass color to frag shader
    vColor.xyz = vec3(1.0, 1.0, 1.0);

	// dim sprites to account for extra motion blur lit pixels
	vColor.w = max(0.33, 1.0 - sqrt(abs(spriteSizeAndViewRangeAndBlur.w))*1.5);

	// red/blue shift
	vColor.xyz += vec3(-spriteSizeAndViewRangeAndBlur.w, -abs(spriteSizeAndViewRangeAndBlur.w), spriteSizeAndViewRangeAndBlur.w);

	// output position, or degenerate triangle if sprite is beyond view range
	if (alpha > 0.0) {
    	gl_Position = projMat * pos;

    	// fix subpixel flickering by adding slight screenspace size
    	gl_Position.xy += aUV.xy * max(0.0, gl_Position.z) / 100.0;
    }
    else {
    	gl_Position = vec4(0, 0, 0, 0);
    }
}
"""

xgl.addProgram("planetfield", vert, frag)
