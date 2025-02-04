class Search
  def initialize query
    @query = query
    @pluckable = true
  end

  def items
    execute
    @items
  end

  def ids
    items
    if @pluckable
      items.pluck :id
    else
      items.map { |item| item.id }
    end
  end

  def execute
    return if @executed

    items = Item.where deleted: false

    case @query[:orientation]
    when 'landscape'
      items = items.where 'height < width'
    when 'portrait'
      items = items.where 'height > width'
    when 'square'
      items = items.where 'height = width'
    else
    end

    if @query[:type]
      items = items.where variety: @query[:type].to_s
    end

    hidden_tag = Tag.hidden
    if hidden_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    tag_ids = (@query[:tags] || []).map(&:to_i)
    delete_tag = Tag.deleted
    if delete_tag && !tag_ids.member?( delete_tag.id )
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end
    @items = Item.none

    if @query[:any]
      items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', descendants(tag_ids)
    else
      tag_ids.each do |id|
        items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', descendants([id])
      end
    end

    if @query[:only]
      items = items.where 'id not in ( select item_id from item_tags where tag_id not in (?) )', tag_ids
    end

    if @query[:not]
      tag = Tag.find_by_label @query[:not]
      if tag
        items = items.where 'id not in ( select item_id from item_tags where tag_id in (?))', descendants([tag.id]) - tag_ids
      end
    end

    if @query[:has_comments]
      items = items.where 'id in ( select item_id from comments )'
    end

    if @query[:comment]
      items = items.where ['id in ( select item_id from comments where text like ? )', "%#{@query[:comment]}%" ]
    end

    if @query[:untagged]
      items = items.where 'id not in ( select item_id from item_tags )'
    end

    if @query[:unjudged]
      items = items.where 'id not in ( select item_id from ratings where user_id = ? )', @query[:unjudged].to_i
    end

    if @query[:starred]
      items = items.where 'id in ( select item_id from stars where user_id = ? )', @query[:starred].to_i
    end

    if @query[:source]
      sources = @query[:source].map do |s|
        source = Source.where( label: s.to_s ).first
        source ||= Source.where( path: s.to_s ).first
      end
      sources = sources.compact

      unless sources.empty?
        query = []
        sources.size.times do
          query << "path like ?"
        end
        sources.map! { |_| "#{_.path}/%" }
        items = items.where "id in ( select item_id from item_paths where #{query.join ' or '})", sources
      end
    end

    if @query[:item]
      ids = expand_list @query[:item]
      items = items.where 'id in (?)', ids
    end

    if @query[:shared]
      share = Share.find_by_code( @query[:shared].to_s )
      items = items.where "id in (?)", share.item_ids
    end

    if @query[:path]
      items = items.where [ 'id in ( select item_id from item_paths where path like ? )', "%#{@query[:path]}%" ]
    end

    if @query[:year]
      items = items.where "strftime('%Y', taken) in (?)", @query[:year]
    end

    if @query[:month]
      items = items.where "CAST(strftime('%m', taken) AS decimal) in (?)", @query[:month]
    end

    if @query[:age]
      tag = Tag.where(id: tag_ids).where.not(birthday: nil).order('birthday desc').first
      age = @query[:age].to_i
      if tag
        birthday = tag.birthday
        start = birthday + age.years
        finish = start + 1.years
        items = items.where('taken between ? AND ?', start, finish)
      end
    end

    raise "Invalid 'by'" if @query[:sort] && @query[:sort] !~ /\A\w+\Z/
    @query[:sort] = 'rand()' if @query[:sort] == 'random'

    if @query[:sort] == 'age'
      age = "timestampdiff( second, (
          select tags.birthday
          from tags join item_tags on tags.id = item_tags.tag_id
          where item_id = items.id
            and birthday is not null
          order by tags.birthday desc limit 1
        ), items.taken) AS age
      "
      items = items.select("*, #{age}").having( "age is not null and age >= 0" )
      @query[:reverse] = !@query[:reverse]
      @pluckable = false
    end

    @query[:sort] ||= "taken"

    unless @query[:reverse]
      @query[:sort] += " desc"
    end

    items = items.order @query[:sort]

    @items = items
    @executed = true
  end

  def expand_list groups
    ids = []
    groups.each do |seq|
      start, finish = seq.split '-'
      finish ||= start

      ids.concat (start.to_i..finish.to_i).to_a
    end
    ids
  end

  def descendants tag_ids
    if !@descendants
      @descendants = Hash.new { |h, k| h[k] = [] }
      Tag.all.each do |tag|
        parent = tag
        while parent = parent.parent
          @descendants[parent.id] << tag.id
        end
      end
    end
    tag_ids + tag_ids.map { |_| @descendants[_] || [] }.flatten
  end
end
