root = exports ? this

class root.FarMapGenerator
	constructor: (mapResolution) ->
		# load shaders
		@shader = []
		for i in [0 .. kosmosShaderHeightFunctions.length-1]
			@shader[i] = xgl.loadProgram("farMapGenerator" + i)
			@shader[i].uniforms = xgl.getProgramUniforms(@shader[i], ["randomSeed"])
			@shader[i].attribs = xgl.getProgramAttribs(@shader[i], ["aUV", "aPos", "aTangent", "aBinormal"])

		# initialize FBO
		@fbo = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		@fbo.width = mapResolution * 6 # six cube faces all packed into this single texture
		@fbo.height = mapResolution
		console.log("Initialized low resolution planet map generator FBO at #{@fbo.width} x #{@fbo.height}")
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		# create fullscreen quad vertices
		buff = new Float32Array(6*6*11)
		i = 0
		tangent = [0, 0, 0]
		binormal = [0, 0, 0]
		for faceIndex in [0..5]
			for uv in [[0,0], [1,0], [0,1], [1,0], [1,1], [0,1]]
				pos = mapPlaneToCube(uv[0], uv[1], faceIndex)
				buff[i++] = (uv[0] + faceIndex) / 6.0; buff[i++] = uv[1]
				buff[i++] = pos[0]; buff[i++] = pos[1]; buff[i++] = pos[2]
				posU = mapPlaneToCube(uv[0]+1, uv[1], faceIndex)
				posV = mapPlaneToCube(uv[0], uv[1]+1, faceIndex)
				binormal = [posU[0]-pos[0], posU[1]-pos[1], posU[2]-pos[2]]
				tangent = [posV[0]-pos[0], posV[1]-pos[1], posV[2]-pos[2]]
				buff[i++] = binormal[0]; buff[i++] = binormal[1]; buff[i++] = binormal[2]
				buff[i++] = tangent[0]; buff[i++] = tangent[1]; buff[i++] = tangent[2]

		@quadVerts = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@quadVerts.itemSize = 11
		@quadVerts.numItems = buff.length / @quadVerts.itemSize


	start: ->		
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)

		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		gl.viewport(0, 0, @fbo.width, @fbo.height)

		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)

		gl.enableVertexAttribArray(@shader[0].attribs.aUV)
		gl.enableVertexAttribArray(@shader[0].attribs.aPos)
		gl.enableVertexAttribArray(@shader[0].attribs.aBinormal)
		gl.enableVertexAttribArray(@shader[0].attribs.aTangent)


	finish: ->
		gl.disableVertexAttribArray(@shader[0].attribs.aUV)
		gl.disableVertexAttribArray(@shader[0].attribs.aPos)
		gl.disableVertexAttribArray(@shader[0].attribs.aBinormal)
		gl.disableVertexAttribArray(@shader[0].attribs.aTangent)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		gl.useProgram(null)

		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)


	generate: (seed) ->
		# setup seed values
		rndStr = new RandomStream(seed)
		seeds = [rndStr.unit(), rndStr.unit(), rndStr.unit(), rndStr.unit()]
		shaderIndex = rndStr.intRange(0, kosmosShaderHeightFunctions.length-1)
		console.log("Using planet category " + shaderIndex)

		# set shader from seed
		gl.useProgram(@shader[shaderIndex])
		gl.vertexAttribPointer(@shader[shaderIndex].attribs.aUV, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)
		gl.vertexAttribPointer(@shader[shaderIndex].attribs.aPos, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *2)
		gl.vertexAttribPointer(@shader[shaderIndex].attribs.aBinormal, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *5)
		gl.vertexAttribPointer(@shader[shaderIndex].attribs.aTangent, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *8)
		gl.uniform4fv(@shader[shaderIndex].uniforms.randomSeed, seeds)

		# create and attach texture map as render target
		heightMap = gl.createTexture()
		gl.bindTexture(gl.TEXTURE_2D, heightMap)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @fbo.width, @fbo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
		gl.bindTexture(gl.TEXTURE_2D, null)

		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, heightMap, 0)

		gl.drawArrays(gl.TRIANGLES, 0, @quadVerts.numItems);

		return heightMap



