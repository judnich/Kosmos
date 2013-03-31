
root = exports ? this

enableRetina = true
camera = null
starVol = null

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
	starVol = new StarVolume()

	camera.position = vec3.fromValues(0, 0, 10)
	camera.target = vec3.fromValues(0, 0, 0)
	camera.update()

	tick()

tick = ->
	#window.requestAnimFrame(tick) # schedule next frame to run

	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0, 0, 0, 1)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	starVol.render(camera)


kosmosMain()
