root = exports ? this

# This object lets you manage a number of content objects which are uniquely identifiable with some
# string or integer identifier in such a way that you can simply query them frequently and loading/unloading
# will be managed automatically (with old content unloaded when the cache "spills" with too many items)

class root.ContentCache
	# maxItems sets the maximum number of content items that may be loaded at any given time.
	# loaderCallback should accept a "contentId" value and return some content object as appropriate.
	constructor: (maxItems, loaderCallback) ->
		@loadedItems = {} # { contentId: [content, timestamp] }
		@loadedCount = 0
		@queuedItems = [] # list of contentIds pending load
		@maxItems = maxItems # the maximum number of items to cache before deleting old items
		@loaderCallback = loaderCallback


	# Call this as frequently as desired to get the loaded content object corresponding to contentId.
	# The object this returns should be identical in content to if you called loaderCallback(contentId),
	# with the performance difference that this manages a cache of already loaded content.
	getContent: (contentId) ->
		if @loadedItems[contentId] != undefined
			item = @loadedItems[contentId]
			item[1] = (new Date()).getTime()
			return item[0]
		@queuedItems.push(contentId)
		return null


	# The "getContent" method does not actually load or unload anything. It queues these jobs, so when
	# you call update() all the pending loads and unloads are performed. The parameter allows you to adjust
	# how many pending items at most may be loaded by this function call.
	update: (maxItemsToLoad = 1) ->
		@_evictOldItems()

		len = Math.min(@queuedItems.length, maxItemsToLoad)
		if len <= 0 then return

		for i in [0 .. len-1]
			contentId = @queuedItems.pop()
			if contentId != undefined and @loadedItems[contentId] == undefined
				console.log("Loading content: " + contentId)
				content = @loaderCallback(contentId)
				@loadedItems[contentId] = [content, (new Date()).getTime()]
				@loadedCount++


	_evictOldItems: ->
		if @loadedCount > @maxItems
			keys = Object.keys(@loadedItems)
			while @loadedCount > @maxItems
				lastUsedSeed = null
				lastUsed = null

				# find loaded item with min time
				for contentId in keys
					thisLastUsed = @loadedItems[contentId][1]
					if lastUsedSeed == null or thisLastUsed < lastUsed
						lastUsed = thisLastUsed
						lastUsedSeed = contentId

				#delete it
				console.log("Evicting content: " + lastUsedSeed)
				delete @loadedItems[lastUsedSeed]
				@loadedCount--


