root = exports ? this

class root.StarVolume
	constructor: ->
		@shader = xgl.loadProgram("shader-vs", "shader-fs")
		@shader.uniforms = xgl.getProgramUniforms(@shader, ["modelViewMat", "projMat"])
		@shader.attribs = xgl.getProgramAttribs(@shader, ["inPos"])

		@vPosBuff = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vPosBuff);
		vertices = [
			# Front face
			-1.0, -1.0,  1.0,
			1.0, -1.0,  1.0,
			1.0,  1.0,  1.0,
			-1.0,  1.0,  1.0,

			# Back face
			-1.0, -1.0, -1.0,
			-1.0,  1.0, -1.0,
			1.0,  1.0, -1.0,
			1.0, -1.0, -1.0,

			# Top face
			-1.0,  1.0, -1.0,
			-1.0,  1.0,  1.0,
			1.0,  1.0,  1.0,
			1.0,  1.0, -1.0,

			# Bottom face
			-1.0, -1.0, -1.0,
			1.0, -1.0, -1.0,
			1.0, -1.0,  1.0,
			-1.0, -1.0,  1.0,

			# Right face
			1.0, -1.0, -1.0,
			1.0,  1.0, -1.0,
			1.0,  1.0,  1.0,
			1.0, -1.0,  1.0,

			# Left face
			-1.0, -1.0, -1.0,
			-1.0, -1.0,  1.0,
			-1.0,  1.0,  1.0,
			-1.0,  1.0, -1.0
		]
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
		@vPosBuff.itemSize = 3
		@vPosBuff.numItems = 24

		@iBuff = gl.createBuffer()
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)
		cubeVertexIndices = [
			0, 1, 2,      0, 2, 3,    # Front face
			4, 5, 6,      4, 6, 7,    # Back face
			8, 9, 10,     8, 10, 11,  # Top face
			12, 13, 14,   12, 14, 15, # Bottom face
			16, 17, 18,   16, 18, 19, # Right face
			20, 21, 22,   20, 22, 23  # Left face
		]
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(cubeVertexIndices), gl.STATIC_DRAW)
		@iBuff.itemSize = 1
		@iBuff.numItems = 36

	render: (camera) ->
		modelMat = mat4.create()
		modelViewMat = mat4.create()
		mat4.mul(modelViewMat, modelMat, camera.viewMat)

		gl.useProgram(@shader)

		gl.uniformMatrix4fv(@shader.uniforms.projMat, false, camera.projMat)
		gl.uniformMatrix4fv(@shader.uniforms.modelViewMat, false, modelViewMat)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vPosBuff)
		gl.enableVertexAttribArray(@shader.attribs.inPos)
		gl.vertexAttribPointer(@shader.attribs.inPos, @vPosBuff.itemSize, gl.FLOAT, false, 0, 0)

		#gl.bindBuffer(gl.ARRAY_BUFFER, @vColorBuff)
		#gl.enableVertexAttribArray(@shader.attribs.inColor)
		#gl.vertexAttribPointer(@shader.attribs.inColor, @vColorBuff.itemSize, gl.FLOAT, false, 0, 0)

		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @iBuff)
		gl.drawElements(gl.TRIANGLES, @iBuff.numItems, gl.UNSIGNED_SHORT, 0);



