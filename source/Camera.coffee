root = exports ? this

class root.Camera
	aspect: 1.6
	near: 0.1
	far: 1000.0
	fov: xgl.degToRad(90)

	position: vec3.fromValues(0, 0, 0)
	target: vec3.fromValues(0, 0, -1)
	up: vec3.fromValues(0, 1, 0)

	projMat: mat4.create()
	viewMat: mat4.create()
	viewprojMat: mat4.create()

	constructor: () ->
		@update()

	setRotation: (quat) ->
		# this allows you to alternately set camera rotation with a quaternion rather
		# than with the traditional target/lookat and up vectors.

		lookVec = vec3.fromValues(0, 0, -100)
		vec3.transformQuat(lookVec, lookVec, quat)
		vec3.add(@target, @position, lookVec)

		@up = vec3.fromValues(0, 100, 0)
		vec3.transformQuat(@up, @up, quat)

	update: ->
		# update view/proj matrices
		mat4.perspective(@projMat, @fov, @aspect, @near, @far)
		mat4.lookAt(@viewMat, @position, @target, @up)
		mat4.mul(@viewprojMat, @projMat, @viewMat)

	isVisibleVertices: (verts) ->
		# transform the vertices from world space into screen space
		tverts = []
		i = 0

		for v in verts
			tv = vec4.fromValues(v[0], v[1], v[2], 1.0)
			vec4.transformMat4(tv, tv, @viewMat)
			vec4.transformMat4(tv, tv, @projMat)
			tv[0] /= tv[3]
			tv[1] /= tv[3]
			tv[2] /= tv[3]
			tverts[i] = tv
			i++

		# test all vertices against the 6 frustum planes
		for i in [0..2]
			behindPlane = true
			for point in tverts
				if point[i] >= -1.0
					behindPlane = false
					break
			if behindPlane then return false

		for i in [0..2]
			behindPlane = true
			for point in tverts
				if point[i] <= 1.0
					behindPlane = false
					break
			if behindPlane then return false

		return true

	isVisibleBox: (box, translate = null) ->
		verts = box.getCorners()
		if translate != null then vec3.add(v, v, translate) for v in verts
		return @isVisibleVertices(verts)

