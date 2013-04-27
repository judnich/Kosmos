root = exports ? this

# This object lets you manage a number of content objects which are uniquely identifiable with some
# string or integer identifier in such a way that you can simply query them frequently and loading/unloading
# will be managed automatically (with old content unloaded when the cache "spills" with too many items)
#
# Moreover, this allows progressive loading that may take multiple calls to the load function to "fully" load
# an item. This is handled by your loader function returning a pair of [finished, object], so only when 
# finished==true does the cache consider the object loaded and return it to the original requester.

class root.ContentCache
	# maxItems sets the maximum number of content items that may be loaded at any given time.
	# loaderCallback should accept two parameters (contentId, partialContent) and return a pair
	# [finished, object], where finished is a boolean true/false representing whether the returned
	# "object" is fully loaded. This allows you to implement progressive loading where several load steps 
	# should be spaced out across several frames. The first call to loaderCallback will provide the
	# partialContent parameter as null. If your callback returns "finished == false", then the loader
	# will be called again in the future. In each successive call to your callback, "partialContent" 
	# provides the "object" value returned from the last call to your callback. Only when 
	# "finished == true" will the "object" be considered valid, and returned to the requester via 
	# non-null return value of contentCache.getContent().
	constructor: (maxItems, loaderCallback) ->
		@loadedItems = {} # { contentId: [content, timestamp] }
		@loadedCount = 0
		@queuedItems = [] # list of [contentId, partialContent] pending load
		@queuedIdSet = {} # set of contentIds pending load (to prevent duplicate insertion)
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
		if not @queuedIdSet.hasOwnProperty(contentId)
			@queuedItems.push({contentId: contentId, partialContent: null})
			@queuedIdSet[contentId] = true
		return null


	# returns true if there is nothing more to load
	isUpToDate: ->
		return (@queuedItems.length == 0)


	# The "getContent" method does not actually load or unload anything. It queues these jobs, so when
	# you call update() all the pending loads and unloads are performed. The parameter allows you to adjust
	# how many pending items at most may be loaded by this function call.
	update: (maxItemsToLoad = 1) ->
		@_evictOldItems()

		len = Math.min(@queuedItems.length, maxItemsToLoad)
		if len <= 0 then return

		for i in [0 .. len-1]
			loadTask = @queuedItems.pop()
			if loadTask != undefined and @loadedItems[loadTask] == undefined
				[finished, loadedObject] = @loaderCallback(loadTask.contentId, loadTask.partialContent)
				if finished == true
					# loading has finished - add to the loaded item map
					@loadedItems[loadTask.contentId] = [loadedObject, (new Date()).getTime()]
					@loadedCount++
					delete @queuedIdSet[loadTask.contentId]
				else
					# loading hasn't finished - push the task back in the queue with the updated object
					loadTask.partialContent = loadedObject
					@queuedItems.push(loadTask)


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


