root = exports ? this

class root.Camera
	aspect: 1.0
	near: 0.1
	far: 1000.0
	fov: xgl.degToRad(90)

	position: vec3.fromValues(0, 0, 0)
	target: vec3.fromValues(0, 0, -1)
	up: vec3.fromValues(0, 1, 0)

	projMat: mat4.create()
	viewMat: mat4.create()
	viewprojMat: mat4.create()

	constructor: (aspectRatio) ->
		@aspect = aspectRatio
		@frustum = { near: null, far: null, left: null, right: null, top: null, bottom: null }
		@update()

	update: ->
		# update view/proj matrices
		mat4.perspective(@projMat, @fov, @aspect, @near, @far)
		mat4.lookAt(@viewMat, @position, @target, @up)
		mat4.mul(@viewprojMat, @projMat, @viewMat)

		# update culling frustums
		m = [[],[],[],[]]
		for j in [0..3]
			for i in [0..3]
				m[i][j] = @viewprojMat[i + j*4]

		@frustum.left = vec4.fromValues(m[3][0] + m[0][0], m[3][1] + m[0][1], m[3][2] + m[0][2], m[3][3] + m[0][3])
		@frustum.right = vec4.fromValues(m[3][0] - m[0][0], m[3][1] - m[0][1], m[3][2] - m[0][2], m[3][3] - m[0][3])
		@frustum.bottom = vec4.fromValues(m[3][0] + m[1][0], m[3][1] + m[1][1], m[3][2] + m[1][2], m[3][3] + m[1][3])
		@frustum.top =  vec4.fromValues(m[3][0] - m[1][0], m[3][1] - m[1][1], m[3][2] - m[1][2], m[3][3] - m[1][3])
		@frustum.near = vec4.fromValues(m[3][0] + m[2][0], m[3][1] + m[2][1], m[3][2] + m[2][2], m[3][3] + m[2][3])
		@frustum.far = vec4.fromValues(m[3][0] - m[2][0], m[3][1] - m[2][1], m[3][2] - m[2][2], m[3][3] - m[2][3])

		normalizePlane = (p) ->
			len = Math.sqrt(p[0]*p[0] + p[1]*p[1] + p[2]*p[2])
			if len > 0.0
				invLen = 1.0 / len
				p[0] *= invLen
				p[1] *= invLen
				p[2] *= invLen
				p[3] *= invLen
			return len

		p.normalizePlane() for p in @frustum

	isVisibleVertices: (verts) ->
		# test all vertices against the 6 frustum planes 
		for plane in [@frustum.near, @frustum.far, @frustum.left, @frustum.right, @frustum.bottom, @frustum.top]
			# check if all points are behind this plane
			behindPlane = true
			for point in verts
				dist = plane[0] * point[0] + plane[1] * point[1] + plane[2] * point[2] + plane[3]
				# if the point is NOT behind the plane...
				if dist >= 0
					behindPlane = false
					break

			# if all points are behind the plane, the object is not visible
			if behindPlane then return false

		# this could be a false positive for weird cases where long and skinny boxes
		# span diagonally near corners of the frustum, but this shouldn't happen for large
		# regions of renderables, and false positives are acceptable anyway (unlike false negative).
		return true


	isVisibleBox: (box, translate = null) ->
		verts = box.getCorners()
		if translate != null then vec3.add(v, v, translate) for v in verts
		return @isVisibleVertices(verts)

