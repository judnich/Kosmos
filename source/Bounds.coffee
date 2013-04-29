root = exports ? this

class root.Box
	constructor: (x0 = 0, y0 = 0, z0 = 0, x1 = 1, y1 = 1, z1 = 1) ->
		@min = vec2.fromValues(x0, y0, z0)
		@max = vec2.fromValues(x1, y1, z1)

	normalize: ->
		for i in [0..2]
			if @min[i] > @max[i]
				[@min[i], @max[i]] = [@max[i], @min[i]]

	getCenter: ->
		center = vec3.create()
		vec3.add(center, @min, @max)
		vec3.scale(center, center, 0.5)
		return center

	getRadius: ->
		cross = vec3.create()
		vec3.sub(cross, @max, @min)
		return vec3.len(cross) * 0.5

	getCorners: ->
		corners = []
		corners[0] = vec3.fromValues(@max[0], @max[1], @max[2])
		corners[1] = vec3.fromValues(@min[0], @max[1], @max[2])
		corners[2] = vec3.fromValues(@min[0], @min[1], @max[2])
		corners[3] = vec3.fromValues(@max[0], @min[1], @max[2])
		corners[4] = vec3.fromValues(@max[0], @max[1], @min[2])
		corners[5] = vec3.fromValues(@min[0], @max[1], @min[2])
		corners[6] = vec3.fromValues(@min[0], @min[1], @min[2])
		corners[7] = vec3.fromValues(@max[0], @min[1], @min[2])
		return corners

	getCorner: (i) ->
		if i == 0
			return vec3.fromValues(@max[0], @max[1], @max[2])
		else if i == 1
			return vec3.fromValues(@min[0], @max[1], @max[2])
		else if i == 2
			return vec3.fromValues(@min[0], @min[1], @max[2])
		else if i == 3
			return vec3.fromValues(@max[0], @min[1], @max[2])
		else if i == 4
			return vec3.fromValues(@max[0], @max[1], @min[2])
		else if i == 5
			return vec3.fromValues(@min[0], @max[1], @min[2])
		else if i == 6
			return vec3.fromValues(@min[0], @min[1], @min[2])
		else if i == 7
			return vec3.fromValues(@max[0], @min[1], @min[2])
		else
			return null

	getOctant: (i) ->
		b = new Box()
		b.min = @getCenter()
		b.max = @getCorner(i)
		if b.max == null then return null
		b.normalize()
		return b

class root.Rect
	constructor: (x0 = 0, y0 = 0, x1 = 1, y1 = 1) ->
		@min = vec2.fromValues(x0, y0)
		@max = vec2.fromValues(x1, y1)

	normalize: ->
		for i in [0..1]
			if @min[i] > @max[i]
				[@min[i], @max[i]] = [@max[i], @min[i]]

	getCenter: ->
		center = vec2.create()
		vec2.add(center, @min, @max)
		vec2.scale(center, center, 0.5)
		return center

	getRadius: ->
		cross = vec2.create()
		vec2.sub(cross, @max, @min)
		return vec2.len(cross) * 0.5

	getCorners: ->
		corners = []
		corners[0] = vec2.fromValues(@max[0], @max[1])
		corners[1] = vec2.fromValues(@min[0], @max[1])
		corners[2] = vec2.fromValues(@min[0], @min[1])
		corners[3] = vec2.fromValues(@max[0], @min[1])
		return corners

	getCorner: (i) ->
		if i == 0
			return vec2.fromValues(@max[0], @max[1])
		else if i == 1
			return vec2.fromValues(@min[0], @max[1])
		else if i == 2
			return vec2.fromValues(@min[0], @min[1])
		else if i == 3
			return vec2.fromValues(@max[0], @min[1])
		else
			return null

	getQuadrant: (i) ->
		b = new Rect()
		b.min = @getCenter()
		b.max = @getCorner(i)
		if b.max == null then return null
		b.normalize()
		return b

