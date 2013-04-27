root = exports ? this

class root.PlanetNearMesh
	constructor: (chunkRes, maxRes) ->
		@chunkRes = chunkRes
		@maxLevels = Math.floor(Math.log(maxRes) / Math.log(chunkRes))

		# load planet shader
		@shader = xgl.loadProgram("planetNearMesh")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "cubeMat", "alpha", "lightVec", "sampler"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aUV"])

		# build vertex buffer (chunk grid with edge wall vertices)
		buff = new Float32Array((@chunkRes+1)*(@chunkRes+1) * 2)
		n = 0
		for j in [0..@chunkRes]
			for i in [0..@chunkRes]
				[u, v] = [i / @chunkRes, j / @chunkRes]
				buff[n] = u
				buff[n+1] = v
				n += 2

		@vBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@vBuff.itemSize = 2
		@vBuff.numItems = buff.length / @vBuff.itemSize

		# build index buffer
		buff = new Uint16Array((@chunkRes)*(@chunkRes) * 6)
		n = 0
		for j in [0..@chunkRes-1]
			for i in [0..@chunkRes-1]
				[v00, v01] = [i + j*(@chunkRes+1), i + (j+1)*(@chunkRes+1)]
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


	# WARNING: be sure to call startRender first and endRender after done calling this
	renderInstance: (camera, posVec, lightVec, alpha, textureMaps) ->
		modelViewMat = mat4.create()
		mat4.translate(modelViewMat, modelViewMat, posVec)
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform3fv(@shader.uniforms.lightVec, lightVec)
		gl.uniform1f(@shader.uniforms.alpha, alpha)

		gl.activeTexture(gl.TEXTURE0)
		gl.uniform1i(@shader.uniforms.sampler, 0);

		for cubeFace in [0..5]
			gl.bindTexture(gl.TEXTURE_2D, textureMaps[cubeFace])
			gl.uniformMatrix3fv(@shader.uniforms.cubeMat, false, cubeFaceMatrix[cubeFace])
			gl.drawElements(gl.TRIANGLES, @iBuff.numItems, gl.UNSIGNED_SHORT, 0)

		gl.bindTexture(gl.TEXTURE_2D, null)


	startRender: ->
		#gl.enable(gl.BLEND)
		#gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		gl.useProgram(@shader)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)

		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 2, gl.FLOAT, false, @vBuff.itemSize*4, 0)


	finishRender: ->
		gl.disableVertexAttribArray(@shader.attribs.aUV)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)

		gl.useProgram(null)

		#gl.disable(gl.BLEND)




