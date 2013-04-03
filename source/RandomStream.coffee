root = exports ? this

modulus = 4294967291
multiplier = 279470273

class root.RandomStream
	constructor: (seed) ->
		@rand = seed % modulus

	unit: ->
		@rand = (@rand * multiplier) % modulus
		return @rand / modulus

	symmetric: ->
		return unit() * 2.0 - 1.0

	range: (min, max) ->
		return (max - min) * unit() + min

