root = exports ? this

class root.PlanetMapCache
	constructor: (maxItems) ->
		@loadedItems = {} # { seed: [content, timestamp] }
		@queuedItems = [] # list of seeds pending load
		@maxItems = maxItems # the maximum number of items to cache before deleting old items
		@maxLoadsPerFrame = 1


	# returns [heightMap, colorMap, normalMap] or null if not loaded yet
	getMaps: (seed) ->
		if seed in @loadedItems
			item = @loadedItems[seed]
			item[1] = Date.timeNow()
			return item[0]
		@queuedItems.push(seed)
		return null


	# loads newly requested content and evicts/unloads old unused content
	update: ->
		_evictOldItems()

		len = Math.min(@queuedItems.length, @maxLoadsPerFrame)
		for i in [0 .. len-1]
			seed = @queuedItems.pop()
			content = _loadContent(seed)
			@loadedItems[seed] = [content, Date.timeNow]


	_evictOldItems: ->
		while @loadedItems.length > @maxItems
			_evictItem()


	_evictItem: ->
		lastUsedSeed = null
		lastUsed = null

		# find loaded item with min time
		for seed in @loadedItems
			thisLastUsed = @loadedItems[seed][1]
			if lastUsedSeed == null or thisLastUsed < lastUsed
				lastUsed = thisLastUsed
				lastUsedSeed = seed

		#delete it
		delete @loadedItems[lastUsedSeed]


	_loadContent: (seed) ->
		