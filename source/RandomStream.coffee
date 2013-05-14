# Copyright (C) 2013 John Judnich
# Released under The MIT License - see "LICENSE" file for details.

root = exports ? this

modulus = 4294967291
multiplier = 279470273
offset = 65537


class root.RandomStream
	constructor: (seed = 0) ->
		@seed = seed % modulus

	unit: ->
		@seed = ((@seed+offset) * multiplier) % modulus
		return @seed / modulus

	intRange: (min, max) ->
		@seed = ((@seed+offset) * multiplier) % modulus
		return @seed % (max+1-min) + min

	symmetric: -> @unit() * 2.0 - 1.0
	range: (min, max) -> (max - min) * @unit() + min
	radianAngle: -> @range(0, 2.0 * Math.PI)


root.randomIntFromSeed = (number) ->
	number = ((number+offset) * multiplier) % modulus
	return number
