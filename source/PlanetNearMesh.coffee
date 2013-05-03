root = exports ? this

class root.PlanetNearMesh
	constructor: (chunkRes, maxRes) ->
		@chunkRes = chunkRes
		#@maxLevels = Math.floor(Math.log(maxRes) / Math.log(chunkRes))
		@minRectSize = chunkRes / maxRes
		@maxLodError = 0.020

		# load planet shader
		@shader = xgl.loadProgram("planetNearMesh")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat", "cubeMat", "lightVec", "sampler", "vertSampler", "uvRect"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["aUV"])

		# build vertex buffer (chunk grid)
		buff = new Float32Array( ((@chunkRes+1)*(@chunkRes+1) + (@chunkRes+1)*4) * 3 )
		n = 0
		for j in [0..@chunkRes]
			for i in [0..@chunkRes]
				[u, v] = [i / @chunkRes, j / @chunkRes]
				[buff[n], buff[n+1], buff[n+2]] = [u, v, 0.0]
				n += 3

		# edge wall vertices
		for j in [0, @chunkRes]
			for i in [0..@chunkRes]
				[u, v] = [i / @chunkRes, j / @chunkRes]
				[buff[n], buff[n+1], buff[n+2]] = [u, v, 1.0]
				n += 3
		for i in [0, @chunkRes]
			for j in [0..@chunkRes]
				[u, v] = [i / @chunkRes, j / @chunkRes]
				[buff[n], buff[n+1], buff[n+2]] = [u, v, 1.0]
				n += 3

		@vBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff);
		gl.bufferData(gl.ARRAY_BUFFER, buff, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		@vBuff.itemSize = 3
		@vBuff.numItems = buff.length / @vBuff.itemSize

		# build index buffer
		buff = new Uint16Array(((@chunkRes)*(@chunkRes) + @chunkRes*4) * 6)
		n = 0
		for j in [0..@chunkRes-1]
			for i in [0..@chunkRes-1]
				[v00, v01] = [i + j*(@chunkRes+1), i + (j+1)*(@chunkRes+1)]
				[v10, v11] = [v00 + 1, v01 + 1]
				[buff[n], buff[n+1], buff[n+2], buff[n+3], buff[n+4], buff[n+5]] = [v00, v10, v11, v00, v11, v01]
				n += 6

		# edge wall indices
		wallStart = (@chunkRes+1)*(@chunkRes+1)
		for j in [0, 1]
			for i in [0..@chunkRes-1]
				[v00, v01] = [i + j*(@chunkRes)*(@chunkRes+1), wallStart + i + j*(@chunkRes+1)]
				[v10, v11] = [v00 + 1, v01 + 1]
				if j == 1
					[buff[n], buff[n+1], buff[n+2], buff[n+3], buff[n+4], buff[n+5]] = [v00, v10, v11, v00, v11, v01]
				else 
					[buff[n], buff[n+1], buff[n+2], buff[n+3], buff[n+4], buff[n+5]] = [v11, v10, v00, v01, v11, v00]
				n += 6
		for j in [0, 1]
			for i in [0..@chunkRes-1]
				[v00, v01] = [j*@chunkRes + i*(@chunkRes+1), wallStart + i + (j+2)*(@chunkRes+1)]
				[v10, v11] = [v00 + (@chunkRes+1), v01 + 1]
				if j == 0
					[buff[n], buff[n+1], buff[n+2], buff[n+3], buff[n+4], buff[n+5]] = [v00, v10, v11, v00, v11, v01]
				else 
					[buff[n], buff[n+1], buff[n+2], buff[n+3], buff[n+4], buff[n+5]] = [v11, v10, v00, v01, v11, v00]
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
	renderInstance: (camera, planetPos, lightVec, alpha, textureMaps) ->
		modelViewMat = mat4.create()
		mat4.translate(modelViewMat, modelViewMat, planetPos)
		mat4.mul(modelViewMat, camera.viewMat, modelViewMat)

		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)
		gl.uniform3fv(@shader.uniforms.lightVec, lightVec)
		gl.uniform1f(@shader.uniforms.alpha, alpha)

		gl.activeTexture(gl.TEXTURE0)
		gl.uniform1i(@shader.uniforms.sampler, 0);
		gl.uniform1i(@shader.uniforms.vertSampler, 0);

		fullRect = new Rect()

		for cubeFace in [0..5]
			gl.bindTexture(gl.TEXTURE_2D, textureMaps[cubeFace])
			gl.uniformMatrix3fv(@shader.uniforms.cubeMat, false, cubeFaceMatrix[cubeFace])

			@renderChunkRecursive(camera, planetPos, cubeFace, fullRect)

		gl.bindTexture(gl.TEXTURE_2D, null)


	mapToSphere: (face, point, height) ->
		pos = mapPlaneToCube(point[0], point[1], face)
		vec3.normalize(pos, pos)
		vec3.scale(pos, pos, 0.99 + height * 0.01)
		return pos


	renderChunkRecursive: (camera, planetPos, face, rect) ->
		rectSize = rect.max[0] - rect.min[0]

		# generate bounding convex hull and check visibility
		corners = rect.getCorners()
		mid = rect.getCenter()
		boundingHull = []

		# The top vertex is placed above the center the top of the convex volume. This top point is computed as essentially the 
		# intersection of the tangent planes extending out from each top vertex of the bounding box, tangent to the sphere surface 
		# normal. This intersection point is then guaranteed to produce a bounding volume convex hull in addition to the other 12
		# that contains every possible terrain range, even with the curved surface of the planet.
		center = @mapToSphere(face, mid, 1.0)
		corner = @mapToSphere(face, corners[0], 1.0)
		topPointRadius = 1.0 / vec3.dot(center, corner);

		# add vertices for "corners" of the chunk
		for i in [0..7]
			p = @mapToSphere(face, corners[i%4], (i < 4))
			if i < 4 then vec3.scale(p, p, topPointRadius)
			boundingHull[i] = p

		# add vertices at midpoints along each edge of the chunk
		for i in [0..3]
			[a, b] = [ corners[i%4], corners[(i+1)%4] ]
			c = vec2.create()
			vec2.lerp(c, a, b, 0.5)
			p = @mapToSphere(face, c, 1);
			vec3.scale(p, p, topPointRadius)
			boundingHull[i+8] = p

		# top vertex
		p = @mapToSphere(face, mid, 1.0)
		vec3.scale(p, p, topPointRadius)
		boundingHull[12] = p

		# translate bounding box into world space
		for v in boundingHull
			vec3.add(v, v, planetPos)

		# return (don't render) if not visible
		if not camera.isVisibleVertices(boundingHull)
			return

		# determine distance to nearest point of the chunk
		vec3.add(center, center, planetPos)
		vec3.sub(center, center, camera.position)
		dist = vec3.length(center)
		dist -= rectSize * 0.5
		if dist < 0.0000000001 then dist = 0.0000000001

		# compute screen space error and subdivide if beyond tolerated threshold
		screenSpaceError = (rectSize / @chunkRes) / dist
		if screenSpaceError < @maxLodError or rectSize < @minRectSize*0.99
			@renderChunk(face, rect)
		else
			for i in [0..3]
				@renderChunkRecursive(camera, planetPos, face, rect.getQuadrant(i))


	renderChunk: (face, rect) ->
		gl.uniform4f(@shader.uniforms.uvRect, rect.min[0], rect.min[1], (rect.max[0]-rect.min[0]), (rect.max[1]-rect.min[1]))
		gl.drawElements(gl.TRIANGLES, @iBuff.numItems, gl.UNSIGNED_SHORT, 0)


	startRender: ->
		#gl.enable(gl.BLEND)
		#gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
		#gl.disable(gl.CULL_FACE)

		gl.useProgram(@shader)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vBuff)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)

		gl.enableVertexAttribArray(@shader.attribs.aUV)
		gl.vertexAttribPointer(@shader.attribs.aUV, 3, gl.FLOAT, false, @vBuff.itemSize*4, 0)


	finishRender: ->
		gl.disableVertexAttribArray(@shader.attribs.aUV)

		gl.bindBuffer(gl.ARRAY_BUFFER, null)
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null)

		gl.useProgram(null)

		#gl.disable(gl.BLEND)




