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

	constructor: (aspectRatio) ->
		@aspect = aspectRatio
		@update()

	update: ->
		mat4.perspective(@projMat, @fov, @aspect, @near, @far)
		mat4.lookAt(@viewMat, @position, @target, @up)
