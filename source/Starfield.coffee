root = exports ? this

root.universeSeed = 31415
root.starBufferSize = 10000

class root.Starfield
	constructor: ({blockMinStars, blockMaxStars, blockScale, starSize, viewRange}) ->
		@blockMinStars = blockMinStars
		@blockMaxStars = blockMaxStars
		@blockScale = blockScale
		@viewRange = viewRange
		@starSize = starSize
		@_starBufferSize = root.starBufferSize

		randomStream = new RandomStream(universeSeed)

		console.log("Generating star data...")

		# load star shader
		@shader = xgl.loadProgram("starfield")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "starSizeAndViewRangeAndBlur"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aPos", "aUV"])

		# generate random positions
		starPositions = []
		for i in [0 .. @_starBufferSize-1]
			pos = [randomStream.unit(), randomStream.unit(), randomStream.unit(), randomStream.unit()]
			starPositions[i] = pos

		# generate vertex buffer
		buff = new Float32Array(@_starBufferSize * 4 * 7)
		j = 0
		for i in [0 .. @_starBufferSize-1]
			[x, y, z, w] = starPositions[i]

			# each quad's vertices are randomly rotated for the specific reason of randomizing the effect of the
			# motion blur effect in the vertex shader, because it works in a "hacky" way - it displaces some
			# of the star's vertices to create a streaked look. it's not actually "real" motion blue. however
			# the disadvantage is that based on orientation this streaked look may cause the quad to go flat 
			# against the camera's perspective, creating obvious aliasing look. this randomizes that effect
			# so overall it looks fine.
			randAngle = randomStream.range(0, Math.PI*2)

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
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@vBuff.itemSize = 7
		@vBuff.numItems = @_starBufferSize * 4

		# generate index buffer
		buff = new Uint16Array(@_starBufferSize * 6)
		for i in [0 .. @_starBufferSize-1]
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
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)
		@iBuff.itemSize = 1
		@iBuff.numItems = @_starBufferSize * 6

		if @iBuff.numItems >= 0xFFFF
			xgl.error("Index buffer too large for StarField")

		# catalog stars for fast realtime lookup
		@_catalogStars(starPositions)

		console.log("Generated.")


	_catalogStars: (starPositions) ->
		# catalog star positions into a 3D array for fast lookup in realtime
		# each block in the array stores a list of [index, x, y, z, w] where
		# index is the index from the original vertex buffer
		@starPosTableSize = 5 # 5x5x5 grid of blocks
		@starPosTable = []
		for i in [0..@starPosTableSize-1]
			@starPosTable[i] = []
			for j in [0..@starPosTableSize-1]
				@starPosTable[i][j] = []
				for k in [0..@starPosTableSize-1]
					@starPosTable[i][j][k] = []

		for index in [0 .. @_starBufferSize-1]
			[x, y, z, w] = starPositions[index]
			i = Math.floor(x * @starPosTableSize)
			j = Math.floor(y * @starPosTableSize)
			k = Math.floor(z * @starPosTableSize)
			list = @starPosTable[i][j][k]
			list[list.length] = [index, x, y, z, w]


	# This function returns a list of stars within the given radius from 
	# position+originOffset but only up to maxStars of them at most.
	# Each star returned is of the form [dx, dy, dz, w], where [dx,dy,dz] is
	# the star's absolute location relative to (minus) the camera's absolute location.
	queryStars: (position, originOffset, radius) ->
		queryResult = []

		# convert position+originOffset in block space
		[ti, tj, tk] = [originOffset[0]/@blockScale + position[0]/@blockScale,
						originOffset[1]/@blockScale + position[1]/@blockScale,
						originOffset[2]/@blockScale + position[2]/@blockScale]

		# compute global index of star block the position is in
		[ci, cj, ck] = [Math.floor(ti), Math.floor(tj), Math.floor(tk)]

		# compute the local (block space) offset of the viewer within the center block
		[li, lj, lk] = [ci-ti, cj-tj, ck-tk]

		# try rendering all blocks within the view radius
		randStream = new root.RandomStream()
		r = Math.ceil(radius / @blockScale)
		for i in [-r .. +r]
			for j in [-r .. +r]
				for k in [-r .. +r]
					# position of lowest corner, relative to the camera
					[x, y, z] = [i + li, j + lj, k + lk]

					# check if block falls in view range
					bpos = vec3.fromValues((x+0.5)*@blockScale, (y+0.5)*@blockScale, (z+0.5)*@blockScale)
					minDist = vec3.distance(position, bpos) - @blockScale*0.8660254 #sqrt(3)/2
					if minDist <= radius
						# query block
						seed = randomIntFromSeed(randomIntFromSeed(randomIntFromSeed(i + ci) + (j + cj)) + (k + ck))
						randStream.seed = seed
						partialQuery = @_queryBlock(seed, randStream.intRange(@blockMinStars, @blockMaxStars), [x, y, z], radius/@blockScale)
						queryResult = queryResult.concat(partialQuery)

		return queryResult


	_queryBlock: (seed, starCount, blockOffset, blockRadius) ->
		queryResult = []
		blockSize = 1.0 / @starPosTableSize

		# determine what region of the vertex buffer to render 
		[offset, starCount] = @_getStarBufferOffsetAndCount(seed, starCount)
		[beginI, endI] = [offset, offset + starCount - 1]

		# scan star position table for nearby stars
		radiusSq = blockRadius * blockRadius
		for i in [0..@starPosTableSize-1]
			for j in [0..@starPosTableSize-1]
				for k in [0..@starPosTableSize-1]
					bpos = [(i+0.5)*blockSize + blockOffset[0],
							(j+0.5)*blockSize + blockOffset[1],
							(k+0.5)*blockSize + blockOffset[2]]
					minDist = vec3.length(bpos) - blockSize*0.8660254 #sqrt(3)/2
					if minDist <= blockRadius
						starList = @starPosTable[i][j][k]
						for [index, x, y, z, w] in starList
							if index >= beginI and index <= endI
								dx = (x + blockOffset[0])
								dy = (y + blockOffset[1])
								dz = (z + blockOffset[2])
								distSq = dx*dx + dy*dy + dz*dz
								if distSq <= radiusSq
									queryResult[queryResult.length] = [dx * @blockScale, dy * @blockScale, dz * @blockScale, w]

		return queryResult

	render: (camera, originOffset, blur) ->
		@_startRender()
		@blur = blur

		# compute global index of star block the viewer is in
		[ci, cj, ck] = [Math.floor(camera.position[0]/@blockScale + originOffset[0]/@blockScale),
						Math.floor(camera.position[1]/@blockScale + originOffset[1]/@blockScale),
						Math.floor(camera.position[2]/@blockScale + originOffset[2]/@blockScale)]

		# compute the local (block space) offset of the viewer within the center block
		[li, lj, lk] = [ci - originOffset[0]/@blockScale,
						cj - originOffset[1]/@blockScale,
						ck - originOffset[2]/@blockScale]

		# try rendering all blocks within the view radius
		randStream = new root.RandomStream()
		r = Math.ceil(@viewRange / @blockScale)
		for i in [-r .. +r]
			for j in [-r .. +r]
				for k in [-r .. +r]
					# position of lowest corner relative to camera
					[x, y, z] = [i+li, j+lj, k+lk]

					# check if block falls in view range
					bpos = vec3.fromValues((x+0.5)*@blockScale, (y+0.5)*@blockScale, (z+0.5)*@blockScale)
					minDist = vec3.distance(camera.position, bpos) - @blockScale*0.8660254 #sqrt(3)/2
					if minDist <= @viewRange
						# render block
						seed = randomIntFromSeed(randomIntFromSeed(randomIntFromSeed(i + ci) + (j + cj)) + (k + ck))
						randStream.seed = seed
						@_renderBlock(camera, seed, randStream.intRange(@blockMinStars, @blockMaxStars), x, y, z)

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


	# This returns [offset, count] corresponding to the vertex buffer range to render for the desired
	# number of stars (if possible) and random seed value. The returned [offset, count] will be ints in range.
	_getStarBufferOffsetAndCount: (seed, starCount) ->
		starCount = Math.floor(starCount)
		if starCount <= 0 then return
		seed = Math.floor(Math.abs(seed))

		# ensure we're not drawing too many stars
		if starCount*6 > @iBuff.numItems
			starCount = @iBuff.numItems/6
			console.log("Warning: Too many stars requested of starfield block render operation")

		# choose a slice of the vertex buffer randomly based on the seed value
		if @_starBufferSize > starCount
			offset = ((seed + 127) * 65537) % (1 + @_starBufferSize - starCount)
		else
			offset = 0

		return [offset, starCount]


	_renderBlock: (camera, seed, starCount, i, j, k) ->
		# return without rendering if invisible
		box = new Box()
		box.min = vec3.fromValues(i*@blockScale, j*@blockScale, k*@blockScale)
		box.max = vec3.fromValues((i+1)*@blockScale, (j+1)*@blockScale, (k+1)*@blockScale)
		if not camera.isVisibleBox(box) then return

		# determine what region of the vertex buffer to render 
		[offset, starCount] = @_getStarBufferOffsetAndCount(seed, starCount)

		# calculate model*view matrix based on block i,j,k position and block scale
		modelViewMat = mat4.create()
		mat4.scale(modelViewMat, modelViewMat, vec3.fromValues(@blockScale, @blockScale, @blockScale))
		mat4.translate(modelViewMat, modelViewMat, vec3.fromValues(i, j, k))
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		# set shader uniforms
		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform3f(@shader.uniforms.starSizeAndViewRangeAndBlur, @starSize, @viewRange, @blur)

		# issue draw operation
		gl.drawElements(gl.TRIANGLES, starCount*6, gl.UNSIGNED_SHORT, 2*6*offset)



