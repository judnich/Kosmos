root = exports ? this

class root.DetailMapGenerator
	constructor: (mapResolution) ->
		# load shaders
		@shader = xgl.loadProgram("detailMapGenerator")
		#@shader.uniforms = xgl.getProgramUniforms(@shader, ["randomSeed"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aUV"])

		# initialize FBO
		@fbo = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		@fbo.width = mapResolution
		@fbo.height = mapResolution
		console.log("Initialized detail map generator FBO at #{@fbo.width} x #{@fbo.height}")
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		# create fullscreen quad vertices
		buff = new Float32Array(6*2)
		i = 0
		for uv in [[0,0], [1,0], [0,1], [1,0], [1,1], [0,1]]
			buff[i++] = uv[0]; buff[i++] = uv[1]

		@quadVerts = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@quadVerts.itemSize = 2
		@quadVerts.numItems = buff.length / @quadVerts.itemSize


	_start: ->		
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)

		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		gl.viewport(0, 0, @fbo.width, @fbo.height)

		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)

		gl.enableVertexAttribArray(@shader.attribs.aUV)


	_finish: ->
		gl.disableVertexAttribArray(@shader.attribs.aUV)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		gl.useProgram(null)

		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)


	generate: ->
		@_start()

		# set shader
		gl.useProgram(@shader)
		gl.vertexAttribPointer(@shader.attribs.aUV, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)

		# create and attach texture map as render target
		detailMap = gl.createTexture()
		gl.bindTexture(gl.TEXTURE_2D, detailMap)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @fbo.width, @fbo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
		gl.bindTexture(gl.TEXTURE_2D, null)

		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, detailMap, 0)

		gl.drawArrays(gl.TRIANGLES, 0, @quadVerts.numItems);

		@_finish()

		return detailMap



