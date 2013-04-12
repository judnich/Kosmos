root = exports ? this

class root.FarMapGenerator
	constructor: (mapResolution) ->
		# load shader
		@shader = xgl.loadProgram("farMapGenerator")
		#@shader.uniforms = xgl.getProgramUniforms(@shader, [])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aXY", "aUVW"])

		# initialize FBO
		@fbo = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		@fbo.width = mapResolution * 6 # six cube faces all packed into this single texture
		@fbo.height = mapResolution
		console.log("Initialized low resolution planet map generator FBO at #{@fbo.width} x #{@fbo.height}")
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		# create fullscreen quad vertices
		buff = new Float32Array(6*6*5)
		i = 0
		for faceIndex in [0..5]
			for uv in [[0,0], [1,0], [0,1], [1,0], [1,1], [0,1]]
				pos = mapPlaneToCube(uv[0], uv[1], faceIndex)
				buff[i++] = (uv[0] + faceIndex) / 6.0; buff[i++] = uv[1]
				buff[i++] = pos[0]; buff[i++] = pos[1]; buff[i++] = pos[2]

		@quadVerts = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@quadVerts.itemSize = 5
		@quadVerts.numItems = buff.length / @quadVerts.itemSize


	start: ->		
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)

		gl.useProgram(@shader)

		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		gl.viewport(0, 0, @fbo.width, @fbo.height)

		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)
		gl.enableVertexAttribArray(@shader.attribs.aXY)
		gl.vertexAttribPointer(@shader.attribs.aXY, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)
		gl.enableVertexAttribArray(@shader.attribs.aUVW)
		gl.vertexAttribPointer(@shader.attribs.aUVW, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *2)


	finish: ->
		gl.disableVertexAttribArray(@shader.attribs.aXY)
		gl.disableVertexAttribArray(@shader.attribs.aUVW)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		gl.useProgram(null)

		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)


	generate: (seed) ->
		# create and attach texture map as render target
		heightMap = gl.createTexture()
		gl.bindTexture(gl.TEXTURE_2D, heightMap)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @fbo.width, @fbo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, heightMap, 0)
		#gl.generateMipmap(gl.TEXTURE_2D)

		#gl.uniform3fv(@shader.uniforms.todo, todo)
		gl.drawArrays(gl.TRIANGLES, 0, @quadVerts.numItems);

		gl.bindTexture(gl.TEXTURE_2D, null)

		return heightMap



