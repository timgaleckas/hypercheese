@Item = React.createClass
  onSelect: (e) ->
    if e.ctrlKey || e.shiftKey
      e.stopPropagation()
      return @onClick(e)

    e.stopPropagation()
    @props.setLastSelection @props.item.id
    Store.toggleSelection @props.item.id

  onClick: (e) ->
    if e.ctrlKey
      e.preventDefault()
      if Store.state.selection[@props.item.id]
        Store.state.rangeStart = null
      else
        Store.state.rangeStart = @props.item.id
      Store.toggleSelection @props.item.id
    else if e.shiftKey
      e.preventDefault()
      Store.selectRange @props.item.id

    true

  render: ->
    item = @props.item
    selected = Store.state.selection[item.id]

    imageStyle =
      width: "#{@props.imageWidth}px"
      height: "#{@props.imageHeight}px"

    if item.id?
      squareImage = "/data/resized/square/#{item.id}.jpg"
    else
      squareImage = "/images/loading.png"

    classes = ["item"]
    classes.push 'is-selected' if selected
    classes.push 'highlight' if @props.highlight == item.id

    maxFit = @props.imageWidth / 33
    tags = item.tag_ids || []
    tagCount = tags.length
    numberToShow = maxFit
    numberToShow-- if item.has_comments
    if tagCount > numberToShow
      numberToShow--
    firstTags = tags.slice 0, numberToShow
    extraTags = tags.slice numberToShow
    extraTagsLabels = []
    for tagId in extraTags
      tag = Store.state.tagsById[tagId]
      if tag
        extraTagsLabels.push tag.label


    <div className={classes.join ' '} key="#{item.index}">
      <a href={"#/items/#{@props.item.id}"} onClick={@onClick}>
        <img className="thumb" style={imageStyle} src={squareImage}/>
      </a>
      <a href="javascript:void(0)" onClick={@onSelect} className="checkmark">&#x2714;</a>
      <div className="tagbox">
        {
          if item.has_comments
            <img src="/images/comment.png" key="comments"/>
        }
        {
          firstTags.map (tagId) ->
            tag = Store.state.tagsById[tagId]
            if tag
              tagIconUrl = "/data/resized/square/#{tag.icon}.jpg"
              <img title={tag.label} className="tag-icon" key={tagId} src={tagIconUrl}/>
        }
        {
          if extraTags.length > 0
            <div className="extra-tags" title={extraTagsLabels.join ', '} key="extras">{'+' + extraTags.length}</div>
        }
      </div>
    </div>
