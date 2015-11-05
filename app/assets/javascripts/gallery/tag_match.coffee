class @TagMatch
  @matchOne: (str) ->
    return null if str == ''

    for tag in Store.state.tags
      continue unless tag.label.toLowerCase().indexOf( str.toLowerCase() ) == 0
      return tag

    return null

  @matchMany: (str) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = Store.state.tags

    for tag in tags
      continue unless tag.label.toLowerCase() == str.toLowerCase()
      return [ {match: tag} ]

    results = []

    if str.indexOf(',') != -1
      parts = str.split /,\ */
    else
      parts = str.split( /\ +/ )

    for part in parts
      part = part.trim()
      continue if part == ""

      tag = @matchOne part
      if tag
        results.push
          match: tag
      else
        results.push
          miss: part

    results
