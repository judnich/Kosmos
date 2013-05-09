root = exports ? this

class root.NearMapGenerator
	constructor: (mapResolution) ->
		# load shaders
		@heightGenShader = []
		for i in [0 .. kosmosShaderHeightFunctions.length-1]
			@heightGenShader[i] = xgl.loadProgram("nearMapGenerator" + i)
			@heightGenShader[i].uniforms = xgl.getProgramUniforms(@heightGenShader[i], ["verticalViewport", "randomSeed"])
			@heightGenShader[i].attribs = xgl.getProgramAttribs(@heightGenShader[i], ["aUV", "aPos", "aTangent", "aBinormal"])

		@normalGenShader = xgl.loadProgram("normalMapGenerator")
		@normalGenShader.uniforms = xgl.getProgramUniforms(@normalGenShader, ["verticalViewport", "sampler"])
		@normalGenShader.attribs = xgl.getProgramAttribs(@normalGenShader, ["aUV", "aPos", "aTangent", "aBinormal"])

		# initialize FBO
		@fbo = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		@fbo.width = mapResolution
		@fbo.height = mapResolution
		console.log("Initialized high resolution planet map generator FBO at #{@fbo.width} x #{@fbo.height}")
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		# create fullscreen quad vertices
		buff = new Float32Array(6*6*11)
		i = 0
		tangent = [0, 0, 0]
		binormal = [0, 0, 0]
		for faceIndex in [0..5]
			for uv in [[0,0], [1,0], [0,1], [1,0], [1,1], [0,1]]
				pos = mapPlaneToCube(uv[0], uv[1], faceIndex)
				buff[i++] = uv[0]; buff[i++] = uv[1]
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


	# call this before making call(s) to generateSubMap
	start: ->		
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)

		gl.bindFramebuffer(gl.FRAMEBUFFER, @fbo)
		gl.viewport(0, 0, @fbo.width, @fbo.height)

		gl.enableVertexAttribArray(@normalGenShader.attribs.aUV)
		gl.enableVertexAttribArray(@normalGenShader.attribs.aPos)
		gl.enableVertexAttribArray(@normalGenShader.attribs.aBinormal)
		gl.enableVertexAttribArray(@normalGenShader.attribs.aTangent)

		gl.enable(gl.SCISSOR_TEST)


	# call this after making call(s) to generateSubMap
	finish: ->
		gl.disable(gl.SCISSOR_TEST)

		gl.disableVertexAttribArray(@normalGenShader.attribs.aUV)
		gl.disableVertexAttribArray(@normalGenShader.attribs.aPos)
		gl.disableVertexAttribArray(@normalGenShader.attribs.aBinormal)
		gl.disableVertexAttribArray(@normalGenShader.attribs.aTangent)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindFramebuffer(gl.FRAMEBUFFER, null)

		gl.useProgram(null)

		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)


	# Creates and returns a list of SEVEN opengl textures: six for each face of the planet cube, and one
	# for temporary heightmap storage before normal maps are generated for the finalized map.
	createMaps: ->
		maps = []
		for face in [0..6]
			maps[face] = gl.createTexture()
			gl.bindTexture(gl.TEXTURE_2D, maps[face])
			if face < 6
				#gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST)
				gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
				gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			else
				gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
				gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
			gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @fbo.width, @fbo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
		gl.bindTexture(gl.TEXTURE_2D, null)
		return maps


	# Takes the heightmap generated at maps[6] and outputs the final data map containing 
	# normals/color/height/etc. to maps[faceIndex]. This assumes generateSubMap() has finished
	# generating all of the heightmap for the SAME faceIndex (so generate only one face at a time
	# between the two function). Partial generation is allowed via start/endFraction ranging [0,1]
	generateSubFinalMap: (maps, seed, faceIndex, startFraction, endFraction) ->
		# select the normal map generation program
		gl.useProgram(@normalGenShader)
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)
		gl.vertexAttribPointer(@normalGenShader.attribs.aUV, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)
		gl.vertexAttribPointer(@normalGenShader.attribs.aPos, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *2)
		gl.vertexAttribPointer(@normalGenShader.attribs.aBinormal, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *5)
		gl.vertexAttribPointer(@normalGenShader.attribs.aTangent, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *8)

		# bind the heightmap input
		gl.activeTexture(gl.TEXTURE0)
		gl.bindTexture(gl.TEXTURE_2D, maps[6])
		gl.uniform1i(@normalGenShader.uniforms.sampler, 0);

		# bind the appropriate face map texture
		dataMap = maps[faceIndex]
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, dataMap, 0)

		# select the subset of the viewport to generate
		gl.viewport(0, @fbo.height * startFraction, @fbo.width, @fbo.height * (endFraction - startFraction))
		gl.scissor(0, @fbo.height * startFraction, @fbo.width, @fbo.height * (endFraction - startFraction))
		gl.uniform2f(@normalGenShader.uniforms.verticalViewport, startFraction, endFraction - startFraction);

		# run the generation shader
		indicesPerFace = @quadVerts.numItems / 6
		gl.drawArrays(gl.TRIANGLES, indicesPerFace * faceIndex, indicesPerFace);

		gl.bindTexture(gl.TEXTURE_2D, null)


	# generates a heightmap output to maps[6], for later processing by generateSubFinalMap
	# for face faceIndex. partial generation is allowed via start/endFraction ranging [0,1]
	generateSubMap: (maps, seed, faceIndex, startFraction, endFraction) ->
		# setup seed values
		rndStr = new RandomStream(seed)
		seeds = [rndStr.unit(), rndStr.unit(), rndStr.unit(), rndStr.unit()]
		shaderIndex = rndStr.intRange(0, kosmosShaderHeightFunctions.length-1)

		# set shader from seed
		gl.useProgram(@heightGenShader[shaderIndex])
		gl.bindBuffer(gl.ARRAY_BUFFER, @quadVerts)
		gl.vertexAttribPointer(@heightGenShader[shaderIndex].attribs.aUV, 2, gl.FLOAT, false, @quadVerts.itemSize*4, 0)
		gl.vertexAttribPointer(@heightGenShader[shaderIndex].attribs.aPos, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *2)
		gl.vertexAttribPointer(@heightGenShader[shaderIndex].attribs.aBinormal, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *5)
		gl.vertexAttribPointer(@heightGenShader[shaderIndex].attribs.aTangent, 3, gl.FLOAT, false, @quadVerts.itemSize*4, 4 *8)
		gl.uniform4fv(@heightGenShader[shaderIndex].uniforms.randomSeed, seeds)

		# bind the appropriate face map texture
		dataMap = maps[6]
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, dataMap, 0)

		# select the subset of the viewport to generate
		gl.viewport(0, @fbo.height * startFraction, @fbo.width, @fbo.height * (endFraction - startFraction))
		gl.scissor(0, @fbo.height * startFraction, @fbo.width, @fbo.height * (endFraction - startFraction))
		gl.uniform2f(@heightGenShader[shaderIndex].uniforms.verticalViewport, startFraction, endFraction - startFraction);

		# run the generation shader
		indicesPerFace = @quadVerts.numItems / 6
		gl.drawArrays(gl.TRIANGLES, indicesPerFace * faceIndex, indicesPerFace);



	# call this to finalize map generation
	finalizeMaps: (maps) ->
		# note: it seems generating mipmaps leads to some glitches either in intel HD 4000 or webgl,
		# causing MAJOR permanent lag for the remainder of the program, and this occurs RANDOMLY.
		# impossible to know when, and impossible to predict. so I've disabled this. FORTUNATELY,
		# it turns out for whatever reason, disabling mipmaps entirely looks great with no visible pixel
		# shimmer on my retina macbook at least, most likely because the high res maps are used only
		# when you're near the planet anyway, thus effectively being a sort of manual objectwide mipmap anyway.

		#for i in [0..5]
		#	gl.bindTexture(gl.TEXTURE_2D, maps[i])
		#	gl.generateMipmap(gl.TEXTURE_2D)
		#gl.bindTexture(gl.TEXTURE_2D, null)
		delete maps[6]


