
root = exports ? this

enableRetina = true
camera = null
starField = null

cameraAngle = 0.0

kosmosMain = ->
	console.log("Initializing Kosmos Engine")
	if not enableRetina
		console.log("Note: Device pixel scaling (retina) is disabled.")

	root.canvas = document.getElementById("kosmosCanvas")

	devicePixelRatio = if enableRetina then window.devicePixelRatio || 1 else 1
	canvas.width  = window.innerWidth * devicePixelRatio
	canvas.height = window.innerHeight * devicePixelRatio

	console.log("Main framebuffer resolution #{canvas.width} x #{canvas.height}"
				"with device pixel ratio #{devicePixelRatio}")

	root.gl = WebGLUtils.setupWebGL(canvas)
	
	camera = new Camera(canvas.width / canvas.height)
	starField = new StarField(100000)

	camera.position = vec3.fromValues(0.5, 0.5, 0.5)
	camera.target = vec3.fromValues(0, 0, 0)
	camera.near = 0.01
	camera.update()

	tick()

lastTime = 0

tick = ->
	#window.requestAnimFrame(tick) # schedule next frame to run

	d = new Date()
	timeNow = d.getTime()
	elapsed = (timeNow - lastTime) / 1000.0
	lastTime = timeNow

	#cameraAngle += (elapsed * 100.0);
	#rmat = mat4.create()
	#mat4.rotateY(rmat, rmat, xgl.degToRad(cameraAngle))
	#vec3.transformMat4(camera.position, vec3.fromValues(0, 0, 0.5), rmat)
	#camera.update()

	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0, 0, 0, 1)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	starField.render(camera)

	console.log(cameraAngle)


kosmosMain()
