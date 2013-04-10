root = exports ? this

class root.PlanetLowresGeometry
	constructor: (geomRes) ->
		@geomRes = geomRes

		# load planet shader
		#@shader = xgl.loadProgram("lowresPlanet")
		#@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "spriteSizeAndViewRangeAndBlur"])
		#@shader.attribs = xgl.getProgramAttribs(@shader, ["aPos", "aUV"])

		# build vertex buffer (subdivided cube, normalized to be spherical)
		buff = new Float32Array(6*@geomRes*@geomRes * 5)
		n = 0
		for face in [0..5]
			for j in [0..@geomRes-1]
				for i in [0..@geomRes-1]
					[u, v] = [i / @geomRes, j / @geomRes]
					pos = mapPlaneToCube(u, v, face)
					vec3.normalize(pos, pos)
					buff[n] = pos[0]
					buff[n+1] = pos[1]
					buff[n+2] = pos[2]
					buff[n+3] = u
					buff[n+4] = v
					n += 5

		@vBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@vBuff.itemSize = 5
		@vBuff.numItems = buff.length / @vBuff.itemSize

		# build index buffer
		buff = new Uint16Array(6*(@geomRes-1)*(@geomRes-1) * 6)
		n = 0
		for face in [0..5]
			faceOffset = @geomRes*@geomRes * face
			for j in [0..@geomRes-2]
				for i in [0..@geomRes-2]
					[v00, v01] = [i + j*@geomRes + faceOffset, i + (j+1)*geomRes + faceOffset]
					[v10, v11] = [v00 + 1, v01 + 1]

					buff[n] = v00
					buff[n+1] = v10
					buff[n+2] = v11
					buff[n+3] = v00
					buff[n+4] = v11
					buff[n+5] = v01
					n += 6

		@iBuff = gl.createBuffer()
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)
		@iBuff.itemSize = 1
		@iBuff.numItems = buff.length / @iBuff.itemSize

		if @iBuff.numItems >= 0xFFFF
			xgl.error("Index buffer too large in low res planet geometry")



