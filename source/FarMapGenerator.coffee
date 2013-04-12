root = exports ? this

class root.FarMapGenerator
	constructor: (mapResolution) ->
		# load shader
		@shader = xgl.loadProgram("farMapGenerator")
		#@shader.uniforms = xgl.getProgramUniforms(@shader, [])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aUV"])

		# initialize FBO
		@fbo = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		@fbo.width = mapResolution
		@fbo.height = mapResolution
		console.log("Initialized low resolution planet map generator FBO at #{@fbo.width} x #{@fbo.height}")

		# create and attach texture map as render target
		@heightMap = gl.createTexture()
		gl.bindTexture(gl.TEXTURE_2D, @heightMap)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @fbo.width, @fbo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, @heightMap, 0)
		#gl.generateMipmap(gl.TEXTURE_2D)

		gl.bindTexture(gl.TEXTURE_2D, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		# create fullscreen quad vertices
		buff = new Float32Array(2 * 4)
		buff.set([0, 0,  1, 0,  1, 1,  0, 1])

		@quadVerts = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@quadVerts.itemSize = 2
		@quadVerts.numItems = buff.length / @quadVerts.itemSize


	start: ->		
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)

		gl.useProgram(@shader)

		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		gl.viewport(0, 0, @fbo.width, @fbo.height)

		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)
		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)


	finish: ->
		gl.disableVertexAttribArray(@shader.attribs.aUV)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		gl.useProgram(null)

		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)


	generate: (seed) ->
		#gl.uniform3fv(@shader.uniforms.todo, todo)
		gl.drawArrays(gl.TRIANGLE_FAN, 0, @quadVerts.numItems);

		return @heightMap



