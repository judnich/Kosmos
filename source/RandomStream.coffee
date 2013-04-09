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

	symmetric: ->
		return @unit() * 2.0 - 1.0

	range: (min, max) ->
		return (max - min) * @unit() + min

	intRange: (min, max) ->
		@seed = ((@seed+offset) * multiplier) % modulus
		return @seed % (max+1-min) + min


root.randomIntFromSeed = (number) ->
	number = ((number+offset) * multiplier) % modulus
	return number
