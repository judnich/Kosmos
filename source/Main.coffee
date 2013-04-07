# Disclaimer: ALL of this file right now is horrible spaghetti code to test random stuff

root = exports ? this

enableRetina = true
camera = null
starField = null

animating = true
cameraAngle = 0.0

mouseClick = (event) ->
	[x, y] = [event.x, event.y]
	x -= root.canvas.offsetLeft
	y -= root.canvas.offsetTop

root.kosmosMain = ->
	console.log("Initializing Kosmos Engine")

	# setup events
	root.canvas = document.getElementById("kosmosCanvas")
	canvas.addEventListener("mousedown", mouseClick, false);

	# set up canvas
	kosmosResize()
	root.gl = WebGLUtils.setupWebGL(canvas)

	# set up game
	camera = new Camera(canvas.width / canvas.height)
	#starField = new StarField(125, 250, 0.5, 0.005, 1.5)
	#starField = new StarField(200, 300, 0.5, 0.005, 1.5)
	starField = new StarField(200, 300, 1000.0, 10.0, 3000.0)

	camera.position = vec3.fromValues(0, 0, 0)
	camera.target = vec3.fromValues(0, 0, -1)
	camera.near = 0.001
	camera.far = 4000.0
	camera.update()

	animating = true
	tick()

root.kosmosResize = ->
	if not enableRetina then console.log("Note: Device pixel scaling (retina) is disabled.")
	devicePixelRatio = if enableRetina then window.devicePixelRatio || 1 else 1
	canvas.width  = canvas.clientWidth * devicePixelRatio
	canvas.height = canvas.clientHeight * devicePixelRatio
	console.log("Main framebuffer resolution #{canvas.width} x #{canvas.height}"
				"with device pixel ratio #{devicePixelRatio}")


gspeed = 0.0
tspeed = 0.0

root.kosmosSetSpeed = (speed) ->
	gspeed = speed

root.kosmosKill = ->
	lastTime = null
	animating = not animating
	if animating then tick()


lastTime = null
ttt = 0.0
smoothElapsed = 0.0

gridOffset = [0, 0, 0]

tick = ->
	if animating then window.requestAnimFrame(tick) # schedule next frame to run

	d = new Date()
	timeNow = d.getTime()
	if lastTime != null
		elapsed = (timeNow - lastTime) / 1000.0
	else
		elapsed = 0.0
	lastTime = timeNow

	smoothElapsed = elapsed * 0.1 + smoothElapsed * 0.9

	#cameraAngle += (elapsed * 10.0);
	#rmat = mat4.create()
	#mat4.rotateY(rmat, rmat, xgl.degToRad(cameraAngle))
	#vec3.transformMat4(camera.position, vec3.fromValues(0, 0, 1.0), rmat)
	#camera.update()
	
	tspeed = tspeed * 0.95 + 0.05 * gspeed

	camera.position[2] -= tspeed * smoothElapsed#elapsed

	camera.target[0] = camera.position[0]
	camera.target[1] = camera.position[1]
	camera.target[2] = camera.position[2] - 1.0
	camera.update()

	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0, 0, 0, 1)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	starField.render(camera, gridOffset)

	for i in [0..2]
		if camera.position[i] > starField.blockScale + 10
			camera.position[i] = -starField.blockScale
			gridOffset[i] += 2
		if camera.position[i] < -starField.blockScale - 10
			camera.position[i] = starField.blockScale
			gridOffset[i] -= 2


