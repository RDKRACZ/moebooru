$ = jQuery

export default class RelatedTags
  constructor: ->
    $ @initialize


  recentTags: => @parseTags Cookies.get("recent_tags")

  myTags: => @parseTags Cookies.get("my_tags")

  artistSource: -> $("#post_source").val()

  source: -> $("#post_tags")

  target: -> $("#related")

  tagUrl: (tag) -> Moebooru.path "/post?tags=#{encodeURIComponent(tag)}"


  initialize: =>
    return unless @source().length && @target().length

    $("[data-toggle='related-tags']").click @run
    @target().on "click", "a", @toggleTag
    @source().on "input keyup", @highlightList

    $autoload = $(".js-related-tags--autoload")

    if $autoload.length
      $autoload.click()
    else
      @refreshList()


  parseTags: (tagsString) =>
    (tagsString || "").match(/\S+/g) || []


  getTags: =>
    source = @source()
    selectFrom = source[0].selectionStart
    selectTo = source[0].selectionEnd
    tags = source.val()

    if tags.length != 0 && selectFrom != 0 && selectFrom != tags.length
      selectionStart = tags.slice(0, selectFrom).lastIndexOf " "
      selectionEnd = tags.indexOf " ", selectTo
      selectionStart = 0 if selectionStart == -1
      selectionEnd = undefined if selectionEnd == -1
      tags = tags.slice selectionStart, selectionEnd

    tags


  refreshList: (extra) =>
    buf = @target().empty()

    if @myTags().length
      buf.append @buildList("My Tags", @myTags())

    if @recentTags().length
      buf.append @buildList("Recent Tags", @recentTags())

    for title, tags of extra
      buf.append @buildList(title, tags) if tags.length > 0

    @highlightList()


  highlightList: =>
    highlightedTags = {}
    highlightedTags[t] = true for t in @parseTags(@source().val())

    for tagLink in document.querySelectorAll('.js-related_tags--tag_link')
      if highlightedTags[tagLink.dataset.tag]?
        tagLink.classList.add 'highlighted'
      else
        tagLink.classList.remove 'highlighted'


  buildList: (title, tags) =>
    buf = $("<div>").addClass "tag-column"
    buf.append $("<h6>").text(title.replace /_/g, " ")
    tagsList = $("<ul>")

    for tag in tags.sort()
      tagName = tag.replace /_/g, " "
      $tagLink = $("<a>")
        .text(tagName)
        .attr(href: @tagUrl(tag))
        .attr('data-tag', tag)
        .addClass('js-related_tags--tag_link')
      tagsList.append $('<li>').append($tagLink)

    buf.append tagsList


  fetchStart: => @target().html $("<em>").text("Fetching...")


  fetchArtistSuccess: (data) =>
    @refreshList "Artist": (artist.name for artist in data)


  fetchSuccess: (data) =>
    tagsCollection = {}
    for name, tags of data
      tagsCollection[name] = (tag[0] for tag in tags)
    @refreshList tagsCollection


  toggleTag: (e) =>
    e.preventDefault()
    tagName = $(e.target).text().replace /\s/g, "_"
    currentTags = @source().val()
    jumpToEnd = @source()[0].selectionStart == currentTags.length

    if $(e.target).hasClass "highlighted"
      newVal = currentTags.replace(tagName, "")
    else
      newVal = "#{currentTags} #{tagName}"

    newVal = "#{newVal.trim().replace(/\s/g, " ")} "
    newVal = "" if newVal == " "

    @source().val(newVal)
    @source()[0].selectionStart = newVal.length if jumpToEnd
    @highlightList()
    @source().focus()


  run: (e) =>
    e.preventDefault()

    tags = @getTags()
    type = $(e.target).data("type")

    if type == "artist-url"
      source = @artistSource() || ""
      return unless source.length && source.match /^https?:\/\//

      url = Moebooru.path "/artist.json"
      data =
        url: source
        limit: 10
      doneCallback = @fetchArtistSuccess
    else
      type = null if type == "all"
      return unless tags.length

      url = Moebooru.path "/tag/related.json"
      data =
        type: type
        tags: tags
      doneCallback = @fetchSuccess

    @fetchStart()
    $.ajax url,
      data: data
    .done doneCallback
