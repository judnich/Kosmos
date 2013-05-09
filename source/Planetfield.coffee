root = exports ? this

root.planetBufferSize = 100


root.planetColors = [
	[[0.9, 0.7, 0.4], [0.6, 0.4, 0.2]], # dry, hot, boring desert
	[[0.05, 0.0, 0.05], [0.5, 0.1, 0.5]], # dark purple gas
	[[0.2, 0.6, 0.3], [0.4, 0.3, 0.1]], # green jungles
	[[0.90, 0.95, 1.0], [0.5, 0.5, 0.5]], # gray moon
	[[0.0, -50.0, -50.0], [0.0, 10.0, 10.0]], # lava!!
	[[0.562, 0.225, 0.0], [0.375, 0.0, 0.0]], # red mars
]


class root.Planetfield
	constructor: ({starfield, maxPlanetsPerSystem, minOrbitScale, maxOrbitScale, planetSize, nearMeshRange, farMeshRange, spriteRange}) ->
		@_starfield = starfield
		@_planetBufferSize = root.planetBufferSize

		@nearMeshRange = nearMeshRange
		@farMeshRange = farMeshRange
		@spriteRange = spriteRange

		@planetSize = planetSize

		@maxPlanetsPerSystem = maxPlanetsPerSystem
		@minOrbitScale = minOrbitScale
		@maxOrbitScale = maxOrbitScale

		@closestPlanetDist = null
		@closestPlanet = null
		@closestStarDist = null
		@closestStar = null

		randomStream = new RandomStream(universeSeed)

		# load planet shader
		@shader = xgl.loadProgram("planetfield")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "spriteSizeAndViewRangeAndBlur"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aPos", "aUV"])

		# we just re-use the index buffer from the starfield because the sprites are indexed the same
		@iBuff = @_starfield.iBuff
		if @_planetBufferSize*6 > @iBuff.numItems
			console.log("Warning: planetBufferSize should not be larger than starBufferSize. Setting planetBufferSize = starBufferSize.")
			@_planetBufferSize = @iBuff.numItems

		# prepare vertex buffer
		@buff = new Float32Array(@_planetBufferSize * 4 * 6)
		j = 0
		for i in [0 .. @_planetBufferSize-1]
			randAngle = randomStream.range(0, Math.PI*2)

			for vi in [0..3]
				angle = ((vi - 0.5) / 2.0) * Math.PI + randAngle
				u = Math.sin(angle) * Math.sqrt(2) * 0.5
				v = Math.cos(angle) * Math.sqrt(2) * 0.5
				marker = if vi <= 1 then 1 else -1

				@buff[j+3] = u
				@buff[j+4] = v
				@buff[j+5] = marker
				j += 6

		@vBuff = gl.createBuffer()
		@vBuff.itemSize = 6
		@vBuff.numItems = @_planetBufferSize * 4

		# prepare to render geometric planet representations as well
		@farMesh = new PlanetFarMesh(8)
		@farMapGen = new FarMapGenerator(256) # low resolution maps for far planet meshes
		generateCallback = do (t = this) -> (seed, partial) -> return t.farGenerateCallback(seed, partial)
		@farMapCache = new ContentCache(16, generateCallback) 

		@nearMesh = new PlanetNearMesh(64, 4096)
		@nearMapGen = new NearMapGenerator(4096)
		generateCallback = do (t = this) -> (seed, partial) -> return t.nearGenerateCallback(seed, partial)
		@nearMapCache = new ContentCache(4, generateCallback)

		# generate planet detail map
		console.log("Generating detail maps")
		detailMapGen = new DetailMapGenerator(512)
		@detailMapTex = detailMapGen.generate()
		console.log("Done generating detail maps")

		# perform this many partial load steps per cube face map
		# larger means less load stutter, but longer load latency
		@progressiveLoadSteps = 128.0


	farGenerateCallback: (seed, partial) ->
		return [true, @farMapGen.generate(seed)]


	nearGenerateCallback: (seed, partial) ->
		if partial == null
			progress = 0.0
			maps = @nearMapGen.createMaps()
			face = 0
			console.log("Loading high res maps for planet #{seed}")
		else
			progress = partial.progress
			maps = partial.maps
			face = partial.face

		if progress < 1.0-0.0000001
			progressPlusOne = progress + (2.0 / @progressiveLoadSteps)
			if progressPlusOne > 1.0 then progressPlusOne = 1.0
			@nearMapGen.generateSubMap(maps, seed, face, progress, progressPlusOne)
		else
			progressPlusOne = progress + 16 * (2.0 / @progressiveLoadSteps)
			if progressPlusOne > 2.0 then progressPlusOne = 2.0
			@nearMapGen.generateSubFinalMap(maps, seed, face, progress-1.0, progressPlusOne-1.0)

		if progressPlusOne >= 2.0-0.0000001
			# we're done with this face
			face++
			progress = 0
		else
			# still more loading to do on this face
			progress = progressPlusOne

		if face >= 6
			@nearMapGen.finalizeMaps(maps)

			# all faces have been loaded! time to return the final maps
			console.log("Done loading high res maps for planet #{seed}!")
			return [true, maps]
		else
			# still more faces to load, so return a partial result			
			return [false, {maps: maps, progress: progress, face: face}]


	isLoadingComplete: ->
		return @nearMapCache.isUpToDate() and @farMapCache.isUpToDate()


	setPlanetSprite: (index, position) ->
		j = index * 6*4
		for vi in [0..3]
			@buff[j] = position[0]
			@buff[j+1] = position[1]
			@buff[j+2] = position[2]
			j += 6


	render: (camera, originOffset, blur) ->
		# get list of nearby stars, sorted from nearest to farthest
		@starList = @_starfield.queryStars(camera.position, originOffset, @spriteRange)
		@starList.sort( ([ax,ay,az,aw], [cx,cy,cz,cw]) -> (ax*ax + ay*ay + az*az) - (cx*cx + cy*cy + cz*cz) )

		# populate vertex buffer with planet positions, and track positions of mesh-range planets
		@generatePlanetPositions()

		# determine where the nearest light source is, for planet shader lighting calculations
		@calculateLightSource()

		# draw distant planets as sprite dots on the screen
		@renderSprites(camera, originOffset, blur)

		# draw medium range planets as a low res sphere
		@renderFarMeshes(camera, originOffset)

		# draw the full resolution planets when really close
		@renderNearMeshes(camera, originOffset)

		# load maps that were requested from the cache
		@farMapGen.start()
		@farMapCache.update(1)
		@farMapGen.finish()

		@nearMapGen.start()
		@nearMapCache.update(1)
		@nearMapGen.finish()


	# these functions return the closest distance, or null if no such object is populated
	getDistanceToClosestPlanet: -> Math.max(@closestPlanetDist - 1.0, 0.01) or @_starfield.viewRange
	getDistanceToClosestStar: -> Math.max(@closestStarDist - 100.0, 100) or @_starfield.viewRange
	getDistanceToClosestObject: -> Math.min(@getDistanceToClosestPlanet(), @getDistanceToClosestStar())
	getClosestStar: -> @closestStar
	getClosestPlanet: -> @closestPlanet


	generatePlanetPositions: ->
		randomStream = new RandomStream()
		@numPlanets = 0

		@meshPlanets = []
		numMeshPlanets = 0

		@closestPlanetDist = null
		@closestPlanet = null
		@closestStarDist = null
		@closestStar = null

		for [dx, dy, dz, w] in @starList
			randomStream.seed = Math.floor(w * 1000000)

			systemPlanets = randomStream.intRange(0, @maxPlanetsPerSystem)
			if @numPlanets + systemPlanets > @_planetBufferSize then break

			for i in [1 .. systemPlanets]
				radius = @_starfield.starSize * randomStream.range(@minOrbitScale, @maxOrbitScale)
				angle = randomStream.radianAngle()
				[x, y, z] = [dx + radius * Math.sin(angle), dy + radius * Math.cos(angle), dz + w * Math.sin(angle)]

				# store in @meshPlanets if this is close enough that it will be rendered as a mesh
				dist = Math.sqrt(x*x + y*y + z*z)
				alpha = 2.0 - (dist / @farMeshRange) * 0.5
				pw = randomStream.unit()
				if alpha > 0.001
					@meshPlanets[numMeshPlanets] = [x, y, z, pw, alpha]
					numMeshPlanets++

				# add this to the vertex buffer to render as a sprite
				@setPlanetSprite(@numPlanets, [x, y, z])
				@numPlanets++

				# keep track of closest planet (for autopilot stuff)
				if @closestPlanet == null or dist < @closestPlanetDist
					@closestPlanet = [x, y, z]
					@closestPlanetDist = dist

			# keep track of closest star (for autopilot stuff)
			starDist = Math.sqrt(dx*dx + dy*dy + dz*dz)
			if @closestStar == null or starDist < @closestStarDist
				@closestStar = [dx, dy, dz]
				@closestStarDist = starDist

		# sort the list of planets to render in depth order, since later we need to render farthest to nearest
		# because the depth buffer is not enabled yet (we're still rendering on massive scales, potentially)
		if @meshPlanets and @meshPlanets.length > 0
			@meshPlanets.sort( ([ax,ay,az,aw,ak], [cx,cy,cz,cw,ck]) -> (ax*ax + ay*ay + az*az) - (cx*cx + cy*cy + cz*cz) )


	calculateLightSource: ->
		if @starList.length < 1 then return

		# calculate weighted sum of up to three near stars within +-50% distance
		# to generate a approximate light source position to use in lighting calculations
		@lightCenter = vec3.fromValues(@starList[0][0], @starList[0][1], @starList[0][2])
		for i in [1..2]
			star = @starList[i]
			if not star? then break
			lightPos = vec3.fromValues(star[0], star[1], star[2])
			if Math.abs(1.0 - (vec3.distance(lightPos, @lightCenter) / vec3.length(@lightCenter))) < 0.5
				vec3.scale(@lightCenter, @lightCenter, 0.75)
				vec3.scale(lightPos, lightPos, 0.25)
				vec3.add(@lightCenter, @lightCenter, lightPos)


	renderFarMeshes: (camera, originOffset) ->
		if not @meshPlanets or @meshPlanets.length == 0 or @starList.length == 0 then return

		# update camera depth range
		camera.far = @farMeshRange * 5.0
		camera.near = @nearMeshRange * 0.00001
		camera.update()

		@farMesh.startRender()

		nearDistSq = @nearMeshRange*@nearMeshRange
		[localPos, globalPos, lightVec] = [vec3.create(), vec3.create(), vec3.create()]
		for i in [@meshPlanets.length-1 .. 0]
			[x, y, z, w, alpha] = @meshPlanets[i]
			seed = Math.floor(w * 1000000000)

			# far planet is visible if it's beyond the near planet range or if it's not the closest planet
			distSq = x*x + y*y + z*z
			visible = (distSq >= nearDistSq) or (i != 0)

			# however if the near planet isn't done loading, draw the far planet instead
			if not visible
				nearTextureMap = @nearMapCache.getContent(seed)
				if not nearTextureMap then visible = true

			if visible
				localPos = vec3.fromValues(x, y, z)
				vec3.add(globalPos, localPos, camera.position)

				vec3.subtract(lightVec, @lightCenter, localPos)
				vec3.normalize(lightVec, lightVec)

				textureMap = @farMapCache.getContent(seed)
				if textureMap
					colorIndex = seed % planetColors.length
					[planetColor1, planetColor2] = planetColors[colorIndex]
					@farMesh.renderInstance(camera, globalPos, lightVec, alpha, textureMap, planetColor1, planetColor2)

		@farMesh.finishRender()


	renderNearMeshes: (camera, originOffset) ->
		if not @meshPlanets or @meshPlanets.length == 0 or @starList.length == 0 then return

		@nearMesh.startRender()

		nearDistSq = @nearMeshRange*@nearMeshRange
		[localPos, globalPos, lightVec] = [vec3.create(), vec3.create(), vec3.create()]

		# for now we just allow one planet rendered high res at any given time, because we need to adjust
		# the z buffer range specifically for each planet (and it's preferred to not clear the z buffer multiple times)
		for i in [0] #[0 .. @meshPlanets.length-1]
			[x, y, z, w, alpha] = @meshPlanets[i]

			distSq = x*x + y*y + z*z
			if distSq < nearDistSq and i == 0
				# update camera depth range to perfectly accommodate the planet
				# NOTE: scaling by 1.733=sqrt(3) accounts for the fact that depths are frustum depths rather
				# than actual distances from the camera, and therefore the corners of the screen (frustum)
				# will be off by a factor as much as sqrt(3)
				dist = Math.sqrt(distSq)
				camera.far = dist * 1.733 + 1.0
				camera.near = dist / 1.733 - 1.0
				minNear = 0.000001 + Math.max(dist - 1.0, 0.0) * 0.1
				if camera.near <= minNear then camera.near = minNear
				camera.update()

				localPos = vec3.fromValues(x, y, z)
				vec3.add(globalPos, localPos, camera.position)

				vec3.subtract(lightVec, @lightCenter, localPos)
				vec3.normalize(lightVec, lightVec)

				seed = Math.floor(w * 1000000000)
				textureMap = @nearMapCache.getContent(seed)
				if textureMap
					colorIndex = seed % planetColors.length
					[planetColor1, planetColor2] = planetColors[colorIndex]
					@nearMesh.renderInstance(camera, globalPos, lightVec, alpha, textureMap, @detailMapTex, planetColor1, planetColor2)

				# in case the user linked directly to a high-res planet view, we want to cache the
				# low res representation as well so there's no stutter when backing away from the planet
				dummy = @farMapCache.getContent(seed)

		@nearMesh.finishRender()



	renderSprites: (camera, originOffset, blur) ->
		# return if nothing to render
		if @numPlanets <= 0 then return

		# update camera depth range
		camera.far = @spriteRange * 1.1
		camera.near = @farMeshRange * 0.9
		camera.update()

		# push render state
		@_startRenderSprites()

		# upload planet sprite vertices
		gl.bufferData(gl.ARRAY_BUFFER, @buff, gl.DYNAMIC_DRAW)

		# basic setup
		@vBuff.usedItems = Math.floor(@vBuff.usedItems)
		if @vBuff.usedItems <= 0 then return
		seed = Math.floor(Math.abs(seed))

		# planet sprite positions in the vertex buffer are relative to camera position, so the model matrix adds back
		# the camera position. the view matrix will then be composed which then reverses this, producing the expected resulting
		# view-space positions in the vertex shader. this may seem a little roundabout but the alternate would be to implement 
		# a "camera.viewMatrixButRotationOnlyBecauseIWantToDoViewTranslationInMyDynamicVertexBufferInstead".
		modelViewMat = mat4.create()
		mat4.translate(modelViewMat, modelViewMat, camera.position)
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		# set shader uniforms
		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform4f(@shader.uniforms.spriteSizeAndViewRangeAndBlur, @planetSize * 10.0, @farMeshRange, @spriteRange, blur)
		# NOTE: Size is multiplied by 10 because the whole sprite needs to be bigger because only the center area appears filled

		# issue draw operation
		gl.drawElements(gl.TRIANGLES, @numPlanets*6, gl.UNSIGNED_SHORT, 0)

		# pop render state
		@_finishRenderSprites()


	_startRenderSprites: ->
		gl.disable(gl.DEPTH_TEST)
		gl.disable(gl.CULL_FACE)
		gl.depthMask(false)
		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)

		gl.useProgram(@shader)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)

		gl.enableVertexAttribArray(@shader.attribs.aPos)
		gl.vertexAttribPointer(@shader.attribs.aPos, 3, gl.FLOAT, false, @vBuff.itemSize*4, 0)
		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 3, gl.FLOAT, false, @vBuff.itemSize*4, 4 *3)


	_finishRenderSprites: ->
		gl.disableVertexAttribArray(@shader.attribs.aPos)
		gl.disableVertexAttribArray(@shader.attribs.aUV)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)

		gl.useProgram(null)

		gl.disable(gl.BLEND)
		gl.depthMask(true)
		gl.enable(gl.DEPTH_TEST)
		gl.enable(gl.CULL_FACE)

