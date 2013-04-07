root = exports ? this
root.xgl = {}

xgl.degToRad = (angle) -> Math.PI * angle / 180.0
xgl.radToDeg = (angle) -> 180.0 * angle / Math.PI

xgl.error = (msg) ->
	console.log(msg)
	alert(msg)

# given a <script> id, returns a compiled shader object
xgl.loadShader = (scriptId) ->
	shaderScript = document.getElementById(scriptId);
	if not shaderScript then return null

	str = ""
	k = shaderScript.firstChild
	while k
		if k.nodeType == 3 then str += k.textContent
		k = k.nextSibling

	if shaderScript.type == "x-shader/x-fragment" then shader = gl.createShader(gl.FRAGMENT_SHADER)
	else if shaderScript.type == "x-shader/x-vertex" then shader = gl.createShader(gl.VERTEX_SHADER)
	else return null

	gl.shaderSource(shader, str)
	gl.compileShader(shader)

	if not gl.getShaderParameter(shader, gl.COMPILE_STATUS)
		xgl.error(gl.getShaderInfoLog(shader))
		return null

	return shader;

# given vertex and fragment shader objects, returns a linked program object
xgl.createProgram = (vertexShader, fragmentShader) ->
	shaderProgram = gl.createProgram()
	gl.attachShader(shaderProgram, vertexShader)
	gl.attachShader(shaderProgram, fragmentShader)
	gl.linkProgram(shaderProgram)

	if not gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
		xgl.error("Error linking shaders \"#{vertexScriptId}\" and \"#{fragmentScriptId}\"")
		return null

	return shaderProgram

# given <script> ids for vertex and fragment shader source, returns a linked program object
xgl.loadProgram = (vertexScriptId, fragmentScriptId, attribList, uniformList) ->
	vertexShader = xgl.loadShader(vertexScriptId)
	fragmentShader = xgl.loadShader(fragmentScriptId)
	return xgl.createProgram(vertexShader, fragmentShader, attribList, uniformList)

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

