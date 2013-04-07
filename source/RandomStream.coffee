root = exports ? this

modulus = 4294967291
multiplier = 279470273
offset = 65537


class root.RandomStream
	constructor: (seed) ->
		@rand = seed % modulus

	unit: ->
		@rand = ((@rand+offset) * multiplier) % modulus
		return @rand / modulus

	symmetric: ->
		return @unit() * 2.0 - 1.0

	range: (min, max) ->
		return (max - min) * @unit() + min

	intRange: (min, max) ->
		@rand = ((@rand+offset) * multiplier) % modulus
		return @rand % (max+1-min) + min


root.randomFromSeed = (number) ->
	number = ((number+offset) * multiplier) % modulus
	return number
