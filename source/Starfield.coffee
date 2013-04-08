root = exports ? this

universeSeed = 31415
starBufferSize = 10000

class root.Starfield
	constructor: (blockMinStars, blockMaxStars, blockScale, starSize, viewRange) ->
		@blockMinStars = blockMinStars
		@blockMaxStars = blockMaxStars
		@blockScale = blockScale
		@viewRange = viewRange
		@starSize = starSize

		@randomStream = new RandomStream(universeSeed)

		console.log("Generating stars...")

		# load star shader
		@shader = xgl.loadProgram("starfield")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "starSizeAndViewRangeAndBlur"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aPos", "aUV"])

		# generate star positions
		@starPositions = []
		for i in [0 .. starBufferSize-1]
			pos = [@randomStream.unit(), @randomStream.unit(), @randomStream.unit(), @randomStream.unit()]
			@starPositions[i] = pos

		# generate vertex buffer
		buff = new Float32Array(starBufferSize * 4 * 7)
		j = 0
		for i in [0 .. starBufferSize-1]
			[x, y, z, w] = @starPositions[i]

			# each quad's vertices are randomly rotated for the specific reason of randomizing the effect of the
			# motion blur effect in the vertex shader, because it works in a "hacky" way - it displaces some
			# of the star's vertices to create a streaked look. it's not actually "real" motion blue. however
			# the disadvantage is that based on orientation this streaked look may cause the quad to go flat 
			# against the camera's perspective, creating obvious aliasing look. this randomizes that effect
			# so overall it looks fine.
			randAngle = @randomStream.range(0, Math.PI*2)

			for vi in [0..3]
				angle = ((vi - 0.5) / 2.0) * Math.PI + randAngle
				u = Math.sin(angle) * Math.sqrt(2) * 0.5
				v = Math.cos(angle) * Math.sqrt(2) * 0.5
				marker = if vi <= 1 then 1 else -1

				buff[j] = x
				buff[j+1] = y
				buff[j+2] = z
				buff[j+3] = w
				buff[j+4] = u
				buff[j+5] = v
				buff[j+6] = marker
				j += 7

		@vBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		@vBuff.itemSize = 7
		@vBuff.numItems = starBufferSize * 4

		# generate index buffer
		buff = new Uint16Array(starBufferSize * 6)
		for i in [0 .. starBufferSize-1]
			[j, k] = [i * 6, i * 4]

			buff[j] = k + 0
			buff[j+1] = k + 1
			buff[j+2] = k + 2
			buff[j+3] = k + 0
			buff[j+4] = k + 2
			buff[j+5] = k + 3

		@iBuff = gl.createBuffer()
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		@iBuff.itemSize = 1
		@iBuff.numItems = starBufferSize * 6

		if @iBuff.numItems >= 0xFFFF
			xgl.error("Index buffer too large for StarField")

		console.log("All stars generated.")


	render: (camera, gridOffset, blur) ->
		@_startRender()
		@blur = blur

		[ci, cj, ck] = [Math.floor(camera.position[0]/@blockScale),
						Math.floor(camera.position[1]/@blockScale),
						Math.floor(camera.position[2]/@blockScale)]
		r = Math.ceil(@viewRange / @blockScale)

		for i in [ci-r .. ci+r]
			for j in [cj-r .. cj+r]
				for k in [ck-r .. ck+r]
					bpos = vec3.fromValues((i+0.5)*@blockScale, (j+0.5)*@blockScale, (k+0.5)*@blockScale)
					minDist = vec3.distance(camera.position, bpos) - @blockScale*0.8660254 #sqrt(3)/2
					if minDist <= @viewRange
						#seed = ((i + gridOffset[0])*3559) + ((j + gridOffset[1])*65537) + ((k + gridOffset[2])+257)
						seed = randomFromSeed(randomFromSeed(randomFromSeed(i + gridOffset[0]) + (j + gridOffset[1])) + (k + gridOffset[2]))
						rstr = new root.RandomStream(seed)
						@_renderBlock(camera, seed, rstr.range(@blockMinStars, @blockMaxStars), i,j,k)

		@_finishRender()


	_startRender: ->
		gl.disable(gl.DEPTH_TEST)
		gl.disable(gl.CULL_FACE)
		gl.depthMask(false)
		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)

		gl.useProgram(@shader)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff)
		gl.enableVertexAttribArray(@shader.attribs.aPos)
		gl.vertexAttribPointer(@shader.attribs.aPos, 4, gl.FLOAT, false, @vBuff.itemSize*4, 0)
		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 3, gl.FLOAT, false, @vBuff.itemSize*4, 4 *4)

		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)


	_finishRender: ->
		gl.disableVertexAttribArray(@shader.attribs.aPos)
		gl.disableVertexAttribArray(@shader.attribs.aUV)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)
		gl.useProgram(null)
		gl.enable(gl.CULL_FACE)
		gl.enable(gl.DEPTH_TEST)
		gl.depthMask(true)
		gl.disable(gl.BLEND)


	_renderBlock: (camera, seed, starCount, i, j, k) ->
		# return without rendering if invisible
		box = new Box()
		box.min = vec3.fromValues(i*@blockScale, j*@blockScale, k*@blockScale)
		box.max = vec3.fromValues((i+1)*@blockScale, (j+1)*@blockScale, (k+1)*@blockScale)
		if not camera.isVisibleBox(box) then return

		# basic setup
		if starCount <= 0 then return
		starCount = Math.floor(starCount)
		seed = Math.floor(Math.abs(seed))

		# ensure we're not drawing too many stars
		if starCount*6 > @iBuff.numItems
			starCount = @iBuff.numItems/6
			console.log("Warning: Too many stars requested of starfield block render operation")

		# choose a slice of the vertex buffer randomly based on the seed value
		if starBufferSize > starCount
			offset = ((seed + 127) * 65537) % (1 + starBufferSize - starCount)
		else
			offset = 0

		# calculate model*view matrix based on block i,j,k position and block scale
		modelViewMat = mat4.create()
		#mat4.translate(modelViewMat, modelViewMat, vec3.fromValues(i*@blockScale, j*@blockScale, k*@blockScale))
		mat4.scale(modelViewMat, modelViewMat, vec3.fromValues(@blockScale, @blockScale, @blockScale))
		mat4.translate(modelViewMat, modelViewMat, vec3.fromValues(i, j, k))
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		# set shader uniforms
		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform3f(@shader.uniforms.starSizeAndViewRangeAndBlur, @starSize, @viewRange, @blur)

		# issue draw operation
		gl.drawElements(gl.TRIANGLES, starCount*6, gl.UNSIGNED_SHORT, 2*6*offset)



