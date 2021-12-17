class Tag < ApplicationRecord
  include Tag::TypeMethods
  include Tag::CacheMethods
  include Tag::RelatedTagMethods
  include Tag::ParseMethods
  include Tag::ApiMethods
  has_and_belongs_to_many :_posts, :class_name => "Post"
  has_many :tag_aliases, :foreign_key => "alias_id"

  TYPE_ORDER = CONFIG["tag_order"].each_with_index.reduce({}) do |memo, type|
    memo[type[0]] = type[1]
    memo
  end

  TAG_TYPE_INDEXES = CONFIG["tag_types"].values.uniq.sort.freeze

  def self.count_by_period(start, stop, options = {})
    options[:limit] ||= 50
    options[:exclude_types] ||= []

    tag_types_to_show = TAG_TYPE_INDEXES - options[:exclude_types]
    Tag.group(:name).joins(:_posts)
      .where(:posts => { :created_at => start..stop }, :tag_type => tag_types_to_show)
      .order("count_all DESC").limit(options[:limit])
      .count
      .map { |name, count| { "post_count" => count, "name" => name } }
  end

  def self.sort_by_type(tags, count_sorting = false)
    if tags.is_a? String
      tags = tags.split
    end

    if tags[0].is_a? String
      tags = where(:name => tags)
        .select([:name, :post_count, :id, :tag_type])
        .map { |t| [type_name_from_value(t.tag_type), t.name, t.post_count, t.id] }
    else
      case tags[0]
      when Hash
        tags.map! { |x| [x["name"], x["post_count"], nil] }
      when self
        tags.map! { |x| [x.name, x.post_count, x.id] }
      end

      tags_type = batch_get_tag_types(tags.map { |data| data[0] })
      tags.map! { |arr| arr.insert 0, tags_type[arr[0]] }
    end

    if count_sorting
      tags.sort_by { |a| [TYPE_ORDER[a[0]], -a[2].to_i, a[1]] }
    else
      tags.sort_by { |a| [TYPE_ORDER[a[0]], a[1]] }
    end
  end

  def pretty_name
    name
  end

  def self.find_or_create_by_name(name)
    # Reserve ` as a field separator for tag/summary.
    name = name.downcase.tr(" ", "_").gsub(/^[-~]+/, "").gsub(/`/, "")

    ambiguous = false
    tag_type = nil

    if name =~ /^ambiguous:(.+)/
      ambiguous = true
      name = Regexp.last_match[1]
    end

    if name =~ /^(.+?):(.+)$/ && CONFIG["tag_types"][Regexp.last_match[1]]
      tag_type = CONFIG["tag_types"][Regexp.last_match[1]]
      name = Regexp.last_match[2]
    end

    tag = find_by_name(name)

    if tag
      if tag_type
        tag.update(:tag_type => tag_type)
      end

      if ambiguous
        tag.update(:is_ambiguous => ambiguous)
      end

      return tag
    else
      create(:name => name, :tag_type => tag_type || CONFIG["tag_types"]["General"], :cached_related_expires_on => Time.now, :is_ambiguous => ambiguous)
    end
  end

  def self.select_ambiguous(tags)
    return [] if tags.blank?
    select_values_sql("SELECT name FROM tags WHERE name IN (?) AND is_ambiguous = TRUE ORDER BY name", tags)
  end

  def self.purge_tags
    sql =
      "DELETE FROM tags " \
      "WHERE post_count = 0 AND " \
      "id NOT IN (SELECT alias_id FROM tag_aliases UNION SELECT predicate_id FROM tag_implications UNION SELECT consequent_id FROM tag_implications)"
    execute_sql sql
  end

  def self.recalculate_post_count
    sql = "UPDATE tags SET post_count = (SELECT COUNT(*) FROM posts_tags pt, posts p WHERE pt.tag_id = tags.id AND pt.post_id = p.id AND p.status <> 'deleted')"
    execute_sql sql
  end

  def self.mass_edit(start_tags, result_tags, updater_id, updater_ip_addr)
    Post.find_by_tags(start_tags).each do |p|
      start = TagAlias.to_aliased(Tag.scan_tags(start_tags))
      result = TagAlias.to_aliased(Tag.scan_tags(result_tags))
      tags = (p.cached_tags.scan(/\S+/) - start + result).join(" ")
      p.update(:updater_user_id => updater_id, :updater_ip_addr => updater_ip_addr, :tags => tags)
    end
  end

  def self.find_suggestions(query)
    if query.include?("_") && query.index("_") == query.rindex("_")
      # Contains only one underscore
      search_for = query.split(/_/).reverse.join("_").to_escaped_for_sql_like
    else
      search_for = "%" + query.to_escaped_for_sql_like + "%"
    end

    Tag.where("name LIKE ? AND name <> ?", search_for, query).order("post_count DESC").limit(6).pluck(:name).sort
  end
end
