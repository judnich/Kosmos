
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
	animating = not animating
	if animating then tick()

root.kosmosMain = ->
	console.log("Initializing Kosmos Engine")
	if not enableRetina
		console.log("Note: Device pixel scaling (retina) is disabled.")

	root.canvas = document.getElementById("kosmosCanvas")
	canvas.addEventListener("mousedown", mouseClick, false);

	devicePixelRatio = if enableRetina then window.devicePixelRatio || 1 else 1
	canvas.width  = canvas.clientWidth * devicePixelRatio
	canvas.height = canvas.clientHeight * devicePixelRatio

	console.log("Main framebuffer resolution #{canvas.width} x #{canvas.height}"
				"with device pixel ratio #{devicePixelRatio}")

	root.gl = WebGLUtils.setupWebGL(canvas)

	camera = new Camera(canvas.width / canvas.height)
	#starField = new StarField(125, 250, 0.5, 0.005, 1.5)
	starField = new StarField(200, 300, 0.5, 0.005, 1.5)

	camera.position = vec3.fromValues(0, 0, 0)
	camera.target = vec3.fromValues(0, -0.5, -1)
	camera.near = 0.0001
	camera.update()

	animating = false
	tick()

lastTime = null

tick = ->
	if animating then window.requestAnimFrame(tick) # schedule next frame to run

	d = new Date()
	timeNow = d.getTime()
	if lastTime != null
		elapsed = (timeNow - lastTime) / 1000.0
	else
		elapsed = 0.0
	lastTime = timeNow

	cameraAngle += (elapsed * 10.0);
	rmat = mat4.create()
	mat4.rotateY(rmat, rmat, xgl.degToRad(cameraAngle))
	vec3.transformMat4(camera.position, vec3.fromValues(0, 0, 1.0), rmat)
	camera.update()
	
	#camera.position[2] += 0.01 * elapsed
	#camera.target[2] = camera.position[2] - 1
	#camera.update()

	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0, 0, 0, 1)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	starField.render(camera)

