# Disclaimer: ALL of this file right now is horrible spaghetti code to test random stuff

root = exports ? this


enableRetina = true
camera = null
starfield = null

animating = false
cameraAngle = 0.0

gridOffset = [0, 0, 0]

timeNow = null
lastTime = null
deltaTime = 0.0

lastFrameTime = 0.0
fps = 0

desiredSpeed = 0.0
smoothSpeed = 0.0

desiredRotation = quat.create()
smoothRotation = quat.create()
#rotationAccel = 0.0

mouseIsDown = false
mouseX = 0
mouseY = 0


resumeAnimating = ->
	if not animating
		animating = true
		tick()
		console.log("Resumed animation")

pauseAnimating = ->
	if animating
		lastTime = null
		animating = false
		console.log("Paused animation")

mouseDown = (event) ->
	mouseIsDown = true
	mouseMove(event)

mouseUp = (event) ->
	mouseIsDown = false

mouseMove = (event) ->
	[x, y] = [event.x, event.y]
	rightPanel = document.getElementById("rightbar")
	x = (x - rightPanel.offsetLeft - 1) / canvas.clientWidth
	y = (y - rightPanel.offsetTop - 1) / canvas.clientHeight

	mouseX = (x - 0.5) * 2
	mouseY = (y - 0.5) * 2

	if mouseIsDown then resumeAnimating()

root.kosmosMain = ->
	console.log("Initializing Kosmos Engine")

	# setup events
	root.canvas = document.getElementById("kosmosCanvas")
	canvas.addEventListener("mousedown", mouseDown, false);
	canvas.addEventListener("mouseup", mouseUp, false);
	canvas.addEventListener("mousemove", mouseMove, false);

	# set up canvas
	kosmosResize()
	root.gl = WebGLUtils.setupWebGL(canvas, undefined, () ->
			document.getElementById("glErrorMessage").style.display = "block"
		)
	if not root.gl then return

	# set up game
	#starfield = new Starfield(200, 300, 1000.0, 10.0, 3000.0)
	starfield = new Starfield(200, 300, 1000.0, 5.0, 3000.0)

	# set up camera
	camera = new Camera()
	camera.aspect = canvas.width / canvas.height
	camera.position = vec3.fromValues(0, 0, 0)
	camera.target = vec3.fromValues(0, 0, -1)
	camera.near = 0.001
	camera.far = 4000.0

	resumeAnimating()

root.kosmosKill = ->
	pauseAnimating()

root.kosmosResize = ->
	if not enableRetina then console.log("Note: Device pixel scaling (retina) is disabled.")
	devicePixelRatio = if enableRetina then window.devicePixelRatio || 1 else 1
	canvas.width  = canvas.clientWidth * devicePixelRatio
	canvas.height = canvas.clientHeight * devicePixelRatio
	console.log("Main framebuffer resolution #{canvas.width} x #{canvas.height}"
				"with device pixel ratio #{devicePixelRatio}")

	if camera
		camera.aspect = canvas.width / canvas.height
		resumeAnimating()

root.kosmosSetSpeed = (speed) ->
	desiredSpeed = speed
	resumeAnimating()


updateTickElapsed = ->
	d = new Date()
	timeNow = d.getTime()
	if lastTime != null
		elapsed = (timeNow - lastTime) / 1000.0
	else
		elapsed = 0.0
	lastTime = timeNow

	deltaTime = elapsed * 0.1 + deltaTime * 0.9

updateMouse = ->
	if not mouseIsDown then return

	pitch = mouseY * 40
	yaw = mouseX * 52

	qPitch = quat.create()
	quat.setAxisAngle(qPitch, vec3.fromValues(-1, 0, 0), xgl.degToRad(pitch))

	qYaw = quat.create()
	quat.setAxisAngle(qYaw, vec3.fromValues(0, -1, 0), xgl.degToRad(yaw))

	quat.multiply(qYaw, qYaw, qPitch)
	quat.multiply(desiredRotation, smoothRotation, qYaw)

	quat.normalize(desiredRotation, desiredRotation)


tick = ->
	# keep track of time
	updateTickElapsed()

	# process inputs
	updateMouse()

	# update camera speed with smoothing
	smoothSpeed = smoothSpeed * 0.90 + 0.10 * desiredSpeed

	# move camera
	moveVec = vec3.fromValues(0, 0, -smoothSpeed * deltaTime)
	vec3.transformQuat(moveVec, moveVec, smoothRotation)
	vec3.add(camera.position, camera.position, moveVec)

	# rotate camera
	quat.slerp(smoothRotation, smoothRotation, desiredRotation, 0.05)
	camera.setRotation(smoothRotation)

	# render
	camera.update()
	render()

	# log frames per second
	fps++
	if (timeNow - lastFrameTime) >= 1000.0
		console.log("FPS: " + fps)
		lastFrameTime = timeNow
		fps = 0

	sleepIfIdle()

	# schedule next frame to run
	if animating then window.requestAnimFrame(tick)


sleepIfIdle = ->
	idle = true
	epsilon = 0.0000000001

	potentialSpeed = Math.max(Math.abs(desiredSpeed), Math.abs(smoothSpeed))
	if potentialSpeed > epsilon then idle = false

	quatDist = 0
	for i in [0..3]
		d = desiredRotation[i] - smoothRotation[i]
		quatDist += d*d

	if quatDist > epsilon then idle = false

	if idle
		pauseAnimating()

render = ->
	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0, 0, 0, 1)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	blur = Math.abs(smoothSpeed) / 20000.0
	blur -= 0.001
	if blur < 0 then blur = 0
	if blur > 2.0 then blur = 2.0

	starfield.render(camera, gridOffset, blur)

	updateCoordinateSystem()

updateCoordinateSystem = ->
	# wrap around coordinate system within one star block,
	# while integer block coordinate to maintain continuous world
	blockScale = starfield.blockScale
	for i in [0..2]
		if camera.position[i] > blockScale + 10
			camera.position[i] -= blockScale*2
			gridOffset[i] += 2
		if camera.position[i] < -blockScale - 10
			camera.position[i] += blockScale*2
			gridOffset[i] -= 2

		# in case the user is traveling more than one block per frame
		if camera.position[i] > blockScale + 10
			camera.position[i] = -blockScale
			gridOffset[i] += 2
		if camera.position[i] < -blockScale - 10
			camera.position[i] = blockScale
			gridOffset[i] -= 2


