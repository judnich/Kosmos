root = exports ? this

universeSeed = 31415

class root.StarField
	constructor: (maxStarsPerBlock, blockScale, starSize) ->
		@maxBlockStars = maxStarsPerBlock
		@blockScale = blockScale
		@viewRange = @blockScale * 2
		@starSize = starSize

		@randomStream = new RandomStream(universeSeed)

		console.log("Generating stars...")

		# load star shader
		@shader = xgl.loadProgram("starfield-vs", "starfield-fs")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "starSizeAndViewRange"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aPos", "aUV"])

		# generate star positions
		@starPositions = []
		for i in [0 .. @maxBlockStars-1]
			pos = [@randomStream.unit(), @randomStream.unit(), @randomStream.unit(), @randomStream.unit()]
			@starPositions[i] = pos

		# generate vertex buffer
		buff = new Float32Array(@maxBlockStars * 4 * 6)
		j = 0
		for i in [0 .. @maxBlockStars-1]
			[x, y, z, w] = @starPositions[i]
			for uv in [[0,0], [0,1], [1,0], [1,1]]
				buff[j] = x
				buff[j+1] = y
				buff[j+2] = z
				buff[j+3] = w
				buff[j+4] = uv[0]
				buff[j+5] = uv[1]
				j += 6

		@vBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		@vBuff.itemSize = 6
		@vBuff.numItems = @maxBlockStars * 4

		# generate index buffer
		buff = new Uint16Array(@maxBlockStars * 6)
		for i in [0 .. @maxBlockStars-1]
			[j, k] = [i * 6, i * 4]
			buff[j] = k+0
			buff[j+1] = k+1
			buff[j+2] = k+2
			buff[j+3] = k+1
			buff[j+4] = k+3
			buff[j+5] = k+2

		@iBuff = gl.createBuffer()
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		@iBuff.itemSize = 1
		@iBuff.numItems = @maxBlockStars * 6

		if @iBuff.numItems >= 0xFFFF
			xgl.error("Index buffer too large for StarField")

		console.log("All stars generated.")


	render: (camera) ->
		@_startRender()

		[ci, cj, ck] = [Math.floor(camera.position[0]/@blockScale),
						Math.floor(camera.position[1]/@blockScale),
						Math.floor(camera.position[2]/@blockScale)]
		r = Math.floor(@viewRange / @blockScale)

		for i in [ci-r .. ci+r]
			for j in [cj-r .. cj+r]
				for k in [ck-r .. ck+r]
					bpos = vec3.fromValues((i+0.5)*@blockScale, (j+0.5)*@blockScale, (k+0.5)*@blockScale)
					minDist = vec3.distance(camera.position, bpos) - @blockScale*0.8660254 #sqrt(3)/2
					if minDist <= @viewRange
						@_renderBlock(camera, 0, 1000, i,j,k)

		@_finishRender()


	_startRender: ->
		gl.disable(gl.DEPTH_TEST)
		gl.depthMask(false)
		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)

		gl.useProgram(@shader)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff)
		gl.enableVertexAttribArray(@shader.attribs.aPos)
		gl.vertexAttribPointer(@shader.attribs.aPos, 4, gl.FLOAT, false, @vBuff.itemSize*4, 0)
		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 2, gl.FLOAT, false, @vBuff.itemSize*4, 4 *4)

		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)


	_finishRender: ->
		gl.disableVertexAttribArray(@shader.attribs.aPos)
		gl.disableVertexAttribArray(@shader.attribs.aUV)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)
		gl.useProgram(null)
		gl.enable(gl.DEPTH_TEST)
		gl.depthMask(true)
		gl.disable(gl.BLEND)


	_renderBlock: (camera, seed, starCount, i, j, k) ->
		# ensure we're not drawing too many stars
		if starCount*6 > @iBuff.numItems
			starCount = @iBuff.numItems/6
			console.log("Warning: Too many stars requested of starfield block render operation")

		# choose a slice of the vertex buffer randomly based on the seed value
		if @maxBlockStars > starCount
			offset = ((Math.floor(seed) + 127) * 65537) % (1 + @maxBlockStars - starCount)
		else
			offset = 0

		# calculate model*view matrix based on block i,j,k position
		modelViewMat = mat4.create()
		mat4.translate(modelViewMat, modelViewMat, vec3.fromValues(i*@blockScale, j*@blockScale, k*@blockScale))
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		# set shader uniforms
		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform2f(@shader.uniforms.starSizeAndViewRange, @starSize, @viewRange)

		# issue draw operation
		gl.drawElements(gl.TRIANGLES, starCount*6, gl.UNSIGNED_SHORT, 2*6*offset)



