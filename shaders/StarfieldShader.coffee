
frag = """

precision mediump float;

varying vec3 vUVA;
varying vec3 vColor;

void main(void) {
	// compute star color based on intensity = 1/dist^2 from center of sprite
	vec2 dv = vUVA.xy - vec2(0.5, 0.5);
	float d = dot(dv, dv);
	float lum = 1.0 / (d*100.0);
	//float c = 1.0 / (d*10.0);
	//c = clamp(0.5 - d, 0.0, 1.0) * c;

	d = clamp(d * 4.0, 0.0, 1.0);
	lum *= 1.0 - d*d;

	vec4 pColor = vec4(clamp(lum*vColor.x, 0.0, 1.0), clamp(lum*vColor.y, 0.0, 1.0), clamp(lum*vColor.z, 0.0, 1.0), 1.0);
    gl_FragColor = pColor * vUVA.z;
}

"""


vert = """

attribute vec4 aPos;
attribute vec2 aUV;

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
	vec2 offset = (aUV - 0.5) * starSize;

	//pos = viewMat * modelMat * pos;
	pos = modelViewMat * pos;
	pos.xy += offset;

	// fade out distant stars
	float dist = length(pos.xyz);
	float alpha = clamp((1.0 - (dist / starSizeAndViewRangeAndBlur.y)) * 3.0, 0.0, 1.0);

    // the UV coordinates are used to render the actual star radial gradient,
    // and alpha is used to modulate intensity of distant stars as they fade out
    vUVA = vec3(aUV, alpha);

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
    	gl_Position.xy += (aUV - 0.5) * max(0.0, gl_Position.z) / 300.0;

    	// motion blur
    	float blur = (1.0 - aUV.x) * (1.0 - aUV.y) * starSizeAndViewRangeAndBlur.z;
		gl_Position.w *= 1.0 + blur;
    }
    else {
    	gl_Position = vec4(0, 0, 0, 0);
    }
}
"""

xgl.addProgram("starfield", vert, frag)
