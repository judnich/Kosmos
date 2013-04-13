# Disclaimer: ALL of this file right now is horrible spaghetti code to test random stuff

root = exports ? this


enableRetina = true
camera = null

starfield = null
planetfield = null

animating = false
cameraAngle = 0.0

originOffset = [0, 0, 0]

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
		console.log("Resumed animation")
		animating = true
		tick()

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
	starfield = new Starfield { 
		blockMinStars: 200, 
		blockMaxStars: 300, 
		blockScale: 100000.0, 
		starSize: 50.0, 
		viewRange: 300000.0
	}
	planetfield = new Planetfield {
		starfield: starfield,
		maxPlanetsPerSystem: 3,
		minOrbitScale: 15,
		maxOrbitScale: 30,
		planetSize: 1.0,
		nearRange: 100.0,
		farRange: 30000.0
	}

	# set up camera
	camera = new Camera()
	camera.aspect = canvas.width / canvas.height
	camera.position = vec3.fromValues(0, 0, 0)
	camera.fov = xgl.degToRad(90)

	# restore last location
	loadLocation()

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

	pitch = mouseY * 45
	yaw = mouseX * 58

	qPitch = quat.create()
	quat.setAxisAngle(qPitch, vec3.fromValues(-1, 0, 0), xgl.degToRad(pitch))

	qYaw = quat.create()
	quat.setAxisAngle(qYaw, vec3.fromValues(0, -1, 0), xgl.degToRad(yaw))

	quat.multiply(qYaw, qYaw, qPitch)
	quat.multiply(desiredRotation, smoothRotation, qYaw)

	quat.normalize(desiredRotation, desiredRotation)


root.saveLocation = ->
	# save to localstorage
	if typeof(Storage) != undefined
		localStorage["kosmosOffset" + i] = camera.position[i] for i in [0..2]
		localStorage["kosmosOrigin" + i] = originOffset[i] for i in [0..2]
		localStorage["kosmosRotation" + i] = desiredRotation[i] for i in [0..3]

	# update "share" URL
	if document.getElementById("shareMessage").style.display == "block"
		url = "http://judnich.github.io/KosmosAlpha/index.html#go"
		url += ":" + camera.position[i] for i in [0..2]
		url += ":" + originOffset[i] for i in [0..2]
		url += ":" + Math.round(desiredRotation[i] * 1000) / 1000 for i in [0..3]

		document.getElementById("shareLink").value = url


root.loadLocation = ->
	if not window.location.hash
		# load previously saved location from localStorage
		if typeof(Storage) != undefined
			camera.position[i] = parseFloat(localStorage["kosmosOffset" + i]) || 0.0 for i in [0..2]
			originOffset[i] = parseFloat(localStorage["kosmosOrigin" + i]) || 0.0 for i in [0..2]

			for i in [0..3]
				x = localStorage["kosmosRotation" + i]
				if x == undefined || x == NaN || not x then break
				desiredRotation[i] = parseFloat(x)
			quat.copy(smoothRotation, desiredRotation)

	else
		# set location from url hash
		if not parseLocationString(window.location.hash)
			# else, use a default location
			parseLocationString("#go:-25.552404403686523:-30.029766082763672:-63.47420883178711:-15872:5888:11008:0.036:0.687:0.683:0.247")

		# remove hash from URL
		history.pushState("", document.title, window.location.pathname + window.location.search)


root.parseLocationString = (hash) ->
	words = hash.split(":")
	if words[0] == "#go"
		camera.position[i] = parseFloat(words[i+1]) for i in [0..2]
		originOffset[i] = parseFloat(words[i+4]) for i in [0..2]
		desiredRotation[i] = parseFloat(words[i+7]) for i in [0..3]
		quat.copy(smoothRotation, desiredRotation)
		return true
	else
		return false


clearLocation = ->
	if typeof(Storage) != undefined
		localStorage.clear();


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
	render()

	# log frames per second
	fps++
	if (timeNow - lastFrameTime) >= 1000.0
		#console.log("FPS: " + fps)
		lastFrameTime = timeNow
		fps = 0
		saveLocation()

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

	blur = Math.abs(smoothSpeed) / 2000000.0
	blur -= 0.001
	if blur < 0 then blur = 0
	if blur > 1.0 then blur = 1.0

	if smoothSpeed < 0 then blur = -blur

	starfield.render(camera, originOffset, blur)
	planetfield.render(camera, originOffset, blur)

	updateCoordinateSystem()

updateCoordinateSystem = ->
	# wrap around coordinate system within one star block,
	# with originOffset coordinate to maintain continuous world
	localMax = 128
	for i in [0..2]
		if camera.position[i] > localMax + 10
			n = Math.floor(camera.position[i] / localMax)
			camera.position[i] -= n * localMax
			originOffset[i] += n * localMax

		if camera.position[i] < -localMax - 10
			n = Math.ceil(camera.position[i] / localMax)
			camera.position[i] -= n * localMax
			originOffset[i] += n * localMax


