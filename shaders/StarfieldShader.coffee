
frag = """

precision mediump float;

varying vec3 vUVA;
varying vec3 vColor;

void main(void) {
	// compute star color based on intensity = 1/dist^2 from center of sprite
	vec2 dv = vUVA.xy;
	float d = dot(dv, dv);
	float lum = 1.0 / (d*100.0);

	// fall off at a max radius, since 1/dist^2 goes on infinitely
	d = clamp(d * 4.0, 0.0, 1.0);
	lum *= 1.0 - d*d;

    gl_FragColor.xyz = clamp(vColor*lum, 0.0, 1.0) * vUVA.z;
}

"""


vert = """

attribute vec4 aPos;
attribute vec3 aUV; // third component marks one vertex for blur extrusion

uniform mat4 projMat;
uniform mat4 modelViewMat;
uniform vec3 starSizeAndViewRangeAndBlur;
//uniform mat4 modelMat;
//uniform mat4 viewMat;

varying vec3 vUVA;
varying vec3 vColor;

void main(void) {
	// determine star size
	float starSize = starSizeAndViewRangeAndBlur.x;
	//starSize = starSize * (cos(aPos.w*1000.0) * 0.5 + 1.0); // modulate size by simple PRNG

	// compute vertex position so quad is always camera-facing
	vec4 pos = vec4(aPos.xyz, 1.0);
	vec2 offset = aUV.xy * starSize;

	//pos = viewMat * modelMat * pos;
	pos = modelViewMat * pos;
	pos.xy += offset;

   	// motion blur
   	float blur = aUV.z * starSizeAndViewRangeAndBlur.z;
	pos.z *= 1.0 + blur;

	// fade out distant stars
	float dist = length(pos.xyz);
	float alpha = clamp((1.0 - (dist / starSizeAndViewRangeAndBlur.y)) * 3.0, 0.0, 1.0);

    // the UV coordinates are used to render the actual star radial gradient,
    // and alpha is used to modulate intensity of distant stars as they fade out
    vUVA = vec3(aUV.xy, alpha);

    // compute star color parameter
    // this is just an arbitrary hand-tweaked interpolation between blue/white/red
    // favoring mostly blue and white with some red
    vColor = vec3(
    	1.0 - aPos.w,
    	aPos.w*2.0*(1.0-aPos.w),
    	4.0 * aPos.w
    ) * 0.5 + 0.5;

	// output position, or degenerate triangle if star is beyond view range
	if (alpha > 0.0) {
    	gl_Position = projMat * pos;

    	// fix subpixel flickering by adding slight screenspace size
    	gl_Position.xy += aUV.xy * max(0.0, gl_Position.z) / 300.0;
    }
    else {
    	gl_Position = vec4(0, 0, 0, 0);
    }
}
"""

xgl.addProgram("starfield", vert, frag)
