# Copyright (C) 2013 John Judnich
# Released under The MIT License - see "LICENSE" file for details.

root = exports ? this

root.xgl = {}
xgl.programs = {}

xgl.degToRad = (angle) -> Math.PI * angle / 180.0
xgl.radToDeg = (angle) -> 180.0 * angle / Math.PI

xgl.error = (msg) ->
	console.log(msg)
	#alert(msg)

# use this to add program sources to a main dictionary
xgl.addProgram = (name, vSrc, fSrc) ->
	shaderSrc = { "vertex" : vSrc, "fragment" : fSrc }
	xgl.programs[name] = shaderSrc

# given a shader source and type, returns a compiled shader object
xgl.loadShader = (source, isVertex) ->
	if isVertex
		shader = gl.createShader(gl.VERTEX_SHADER)
	else
		shader = gl.createShader(gl.FRAGMENT_SHADER)

	gl.shaderSource(shader, source)
	gl.compileShader(shader)

	if not gl.getShaderParameter(shader, gl.COMPILE_STATUS)
		xgl.error(gl.getShaderInfoLog(shader))
		return null

	return shader;

# given vertex and fragment shader objects, returns a linked program object or null if failed
xgl.createProgram = (vertexShader, fragmentShader) ->
	shaderProgram = gl.createProgram()
	gl.attachShader(shaderProgram, vertexShader)
	gl.attachShader(shaderProgram, fragmentShader)
	gl.linkProgram(shaderProgram)

	if not gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
		return null

	return shaderProgram

# given <script> ids for vertex and fragment shader source, returns a linked program object
xgl.loadProgram = (programName) ->
	shaderSrc = xgl.programs[programName]
	if not shaderSrc
		xgl.error("Sources for program \"#{programName}\" not found in xgl.programs.")
		return null

	vertexShader = xgl.loadShader(shaderSrc.vertex, true)
	if vertexShader == null
		xgl.error("Error loading vertex shader for \"#{programName}\"")
		return null

	fragmentShader = xgl.loadShader(shaderSrc.fragment, false)
	if fragmentShader == null
		xgl.error("Error loading fragment shader for \"#{programName}\"")
		return null

	prog = xgl.createProgram(vertexShader, fragmentShader)
	if prog == null then xgl.error("Error linking program \"#{programName}\"")

	return prog

# given a program object and list of attribute names, returns a mapping from attribute names to their index
xgl.getProgramAttribs = (programObject, attribNameList) ->
	attribs = {}
	for attrib in attribNameList
		index = gl.getAttribLocation(programObject, attrib)
		if index == -1 then xgl.error("Could not find attribute \"#{attrib}\"")
		else attribs[attrib] = index
	return attribs

# given a program object and list of uniform names, returns a mapping from uniform names to their WebGLUniformLocation
xgl.getProgramUniforms = (programObject, uniformNameList) ->
	uniforms = {}
	for uniform in uniformNameList
		ptr = gl.getUniformLocation(programObject, uniform)
		if ptr == null then xgl.error("Could not find uniform \"#{uniform}\"")
		else uniforms[uniform] = ptr
	return uniforms

