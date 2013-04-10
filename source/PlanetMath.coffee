root = exports ? this

root.cubeFaceQuaternion = []


# Maps plane coordinates (where top left = [0,0] and bottom right = [1,1])
# to a coordinates on a unit cube (corners at [-1,-1,-1] and [+1,+1,+1]), based on
# which face of the cube the coordinates belong to.

root.mapPlaneToCube = (u, v, faceIndex) ->
	pos = vec3.fromValues(u * 2 - 1, v * 2 - 1, 1)
	vec3.transformQuat(pos, pos, cubeFaceQuaternion[faceIndex])
	return pos


initialize = ->
	root.cubeFaceQuaternion[i] = quat.create() for i in [0..5]
	unitX = vec3.fromValues(1, 0, 0)
	unitY = vec3.fromValues(0, 1, 0)
	quat.setAxisAngle(root.cubeFaceQuaternion[1], vec3.fromValues(unitY), xgl.degToRad(180))
	quat.setAxisAngle(root.cubeFaceQuaternion[2], vec3.fromValues(unitY), xgl.degToRad(-90))
	quat.setAxisAngle(root.cubeFaceQuaternion[3], vec3.fromValues(unitY), xgl.degToRad(90))
	quat.setAxisAngle(root.cubeFaceQuaternion[4], vec3.fromValues(unitX), xgl.degToRad(90))
	quat.setAxisAngle(root.cubeFaceQuaternion[5], vec3.fromValues(unitX), xgl.degToRad(-90))


initialize()

