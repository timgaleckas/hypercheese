App.SearchController = Ember.Controller.extend
  queryParams: ['q']
  q: ''

  imageSize: 200
  margin: 1
  overdraw: 3

  window: App.Window

  newTags: ''
  tags: []
  init: ->
    @store.find('tag').then (tags) =>
      @set 'tags', tags.sortBy('count').toArray().reverse()

  columnWidth: Ember.computed 'imageSize', 'margin', ->
    @get('imageSize') + @get('margin') * 2

  rowHeight: Ember.computed 'imageSize', 'margin', ->
    @get('imageSize') + @get('margin') * 2

  imagesPerRow: Ember.computed 'window.width', 'rowHeight', ->
    Math.floor @get('window.width') / @get('rowHeight')

  rowCount: Ember.computed 'content.length', 'imagesPerRow', ->
    Math.ceil @get('content.length') / @get('imagesPerRow') + @overdraw * 2

  resultsStyle: Ember.computed 'rowHeight', 'rowCount', ->
    "height: #{@get('rowHeight') * @get('rowCount')}px"

  viewPortStartRow: Ember.computed 'window.scrollTop', 'rowHeight', ->
    val = Math.floor @get('window.scrollTop') / @get('rowHeight') - @overdraw
    val = 0 if val < 0
    val

  viewPortStyle: Ember.computed 'viewPortStartRow', 'rowHeight', ->
    "top: #{@get('viewPortStartRow') * @get('rowHeight')}px"

  viewPortRowCount: Ember.computed 'window.height', 'rowHeight', ->
    Math.ceil @get('window.height') / @get('rowHeight') + @overdraw

  # Return items that are within visible viewport
  viewPortItems: Ember.computed 'model.loadCount', 'imagesPerRow', 'viewPortStartRow', 'viewPortRowCount', ->
    startIndex = @get('viewPortStartRow') * @get('imagesPerRow')
    endIndex = startIndex + @get('viewPortRowCount') * @get('imagesPerRow')

    console.log "Should show #{startIndex} to #{endIndex}"

    items = []
    len = @get('model.length')
    for i in [startIndex...endIndex]
      if i > 0 && i < len
        item = @get('model').objectAt(i)
        items.pushObject item
    items

    Ember.ArrayProxy.create
      content: items

  selected: []


  toggleSelection: (itemId) ->
    @store.find('item', itemId).then (item) =>
      if item.get('isSelected')
        item.set 'isSelected', false
        @get('selected').removeObject item
      else
        item.set 'isSelected', true
        @get('selected').addObject item

  matchOne: (str) ->
    return null if str == ''

    for tag in @get('tags')
      continue unless tag.get('label').toLowerCase().indexOf( str.toLowerCase() ) == 0
      return tag

    return null

  matchMany: (str) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = @get('tags')

    for tag in tags
      continue unless tag.get('label').toLowerCase() == str.toLowerCase()
      return [tag]

    # attempt to split by comma
    matches = []
    for part in str.split( /,\ */ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    # attempt to split by whitespace
    for part in str.split( /\ +/ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    return []


  tagMatches: Ember.computed 'tags', 'newTags', ->
    Ember.ArrayProxy.create
      content: @matchMany( @get('newTags') )

  tagsOfSelected: Ember.computed.uniq('selectedTags')

  selectedTags: Ember.computed 'selected.@each.tags', ->
    tags = []
    @get('selected').forEach (item) ->
      tags.addObjects item.get('tags')
    tags

  actions:
    imageClick: (itemId) ->
      if @get('selected.length') > 0
        @toggleSelection itemId
      else
        @transitionToRoute 'item', itemId

    imageLongPress: (itemId) ->
      console.log 'controller long press'
      @toggleSelection itemId

    saveNewTags: ->
      itemIds = @get('selected').mapBy 'id'
      tagIds = @matchMany( @get('newTags') ).mapBy 'id'

      App.Item.saveTags itemIds, tagIds
