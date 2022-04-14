import PreloadContainer from './preload_container'

export default class PostLoader
  constructor: ->
    @xhr = new Set
    document.on 'viewer:need-more-thumbs', @need_more_post_data
    document.on 'viewer:perform-search', @perform_search
    UrlHash.observe 'tags', @hashchange_tags
    @cached_posts = new Hash
    @cached_pools = new Hash
    @sample_preload_container = null
    @preloading_sample_for_post_id = null
    @load results_mode: 'center-on-current'
    return

  need_more_post_data: =>

    # We'll receive this message often once we're close to needing more posts.  Only
    # start loading more data the first time.
    if @loaded_extended_results
      return
    @load extending: true
    return

  # This is a response time optimization.  If we know the sample URL of what we want to display,
  # we can start loading it from the server without waiting for the full post.json response
  # to come back and tell us.  This saves us the time of a round-trip before we start loading the
  # image.  The common case is if the user was on post and clicked on a link with "use
  # post browser" enabled.  This allows us to start loading the image immediately, without waiting
  # for any other network activity.
  #
  # We only do this for the sample image, to get a head-start loading it.  This is safe because
  # the image URLs are immutable (or effectively so).  The rest of the post information isn't cached.
  preload_sample_image: ->
    post_id = UrlHash.get('post-id')
    if @preloading_sample_for_post_id == post_id
      return
    @preloading_sample_for_post_id = post_id
    if @sample_preload_container
      @sample_preload_container.destroy()
      @sample_preload_container = null
    if !post_id?
      return

    # If this returns null, the browser doesn't support this.
    cached_sample_urls = Post.get_cached_sample_urls()
    if !cached_sample_urls?
      return
    if !(String(post_id) of cached_sample_urls)
      return
    sample_url = cached_sample_urls[String(post_id)]

    # If we have an existing preload_container, just add to it and allow any other
    # preloads to continue.
    console.debug 'Advance preloading sample image for post ' + post_id
    @sample_preload_container = new PreloadContainer
    @sample_preload_container.preload sample_url
    return

  server_load_pool: ->
    return if !@result.pool_id?

    if !@result.disable_cache
      pool = @cached_pools.get(@result.pool_id)
      if pool
        @result.pool = pool
        @request_finished()
        return

    xhr = jQuery.ajax '/pool/show.json',
      data:
        id: @result.pool_id
      dataType: 'json'
    .done (resp) =>
      @result.pool = resp
      @cached_pools.set @result.pool_id, @result.pool
    .always =>
      @xhr.delete xhr
      @request_finished()

    @xhr.add xhr

    return

  server_load_posts: ->
    tags = @result.tags
    # Put holds:false at the beginning, so the search can override it.  Put limit: at
    # the end, so it can't.
    search = "holds:false #{tags} limit:#{@result.post_limit}"

    if !@result.disable_cache
      results = @cached_posts.get(search)
      if results
        @result.posts = results

        # Don't Post.register the results when serving out of cache.  They're already
        # registered, and the data in the post registry may be more current than the
        # cached search results.
        @request_finished()
        return

    xhr = jQuery.ajax '/post.json',
      data:
        tags: search
        api_version: 2
        filter: 1
        include_tags: 1
        include_votes: 1
        include_pools: 1
      dataType: 'json'
    .done (resp) =>
      @result.posts = resp.posts
      Post.register_resp resp
      @cached_posts.set search, @result.posts
    .fail (xhr, status) ->
      error = resp.responseJSON?.reason ? "error #{status}"
      notice "Error loading posts: #{error}"
      @result.error = true
    .always =>
      @xhr.delete xhr
      @request_finished()

    @xhr.add xhr

    return

  request_finished: ->
    if @xhr.size > 0
      return

    # Event handlers for the events we fire below might make requests back to us.  Save and
    # clear this.result before firing the events, so that behaves properly.
    result = @result
    @result = null

    # If server_load_posts hit an error, it already displayed it; stop.
    if result.error?
      return

    # If we have no search tags (result.tags == null, result.posts == null), then we're just
    # displaying a post with no search, eg. "/post/browse#12345".  We'll still fire off the
    # same code path to make the post display in the view.
    new_post_ids = []
    if result.posts?
      i = 0
      while i < result.posts.length
        new_post_ids.push result.posts[i].id
        ++i
    document.fire 'viewer:displayed-pool-changed', pool: result.pool
    document.fire 'viewer:searched-tags-changed', tags: result.tags

    # Tell the thumbnail viewer whether it should allow scrolling over the left side.
    can_be_extended_further = true

    # If we're reading from a pool, we requested a large block already.
    if result.pool
      can_be_extended_further = false

    # If we're already extending, don't extend further.
    if result.load_options.extending
      can_be_extended_further = false

    # If we received fewer results than we requested we're at the end of the results,
    # so don't waste time requesting more.
    if new_post_ids.length < result.post_limit
      console.debug 'Received posts fewer than requested (' + new_post_ids.length + ' < ' + result.post_limit + '), clamping'
      can_be_extended_further = false

    # Now that we have the result, update the URL hash.  Firing loaded-posts may change
    # the displayed post, causing the post ID in the URL hash to change, so use set_deferred
    # to help ensure these happen atomically.
    UrlHash.set_deferred tags: result.tags
    document.fire 'viewer:loaded-posts',
      tags: result.tags
      post_ids: new_post_ids
      pool: result.pool
      extending: result.load_options.extending
      can_be_extended_further: can_be_extended_further
      load_options: result.load_options
    return

  # If extending is true, load a larger set of posts.
  load: (load_options) ->
    if !load_options
      load_options = {}
    disable_cache = load_options.disable_cache
    extending = load_options.extending
    tags = load_options.tags
    if !tags?
      tags = UrlHash.get('tags')

    # If neither a search nor a post-id is specified, set a default search.
    if !extending and (!tags?) and (!UrlHash.get('post-id')?)
      UrlHash.set tags: ''

      # We'll receive another hashchange message for setting "tags".  Don't load now or we'll
      # end up loading twice.
      return
    console.debug 'PostLoader.load(' + extending + ', ' + disable_cache + ')'
    @preload_sample_image()
    @loaded_extended_results = extending

    # Discard any running AJAX requests.
    @xhr.forEach (xhr) => xhr?.abort()
    @xhr.clear()
    @result =
      load_options: load_options
      tags: tags
      disable_cache: disable_cache

    if !@result.tags?
      # If no search is specified, don't run one; return empty results.
      @request_finished()
      return

    # See if we have a pool search.  This only checks for pool:id searches, not pool:*name* searches;
    # we want to know if we're displaying posts only from a single pool.
    pool_id = null
    @result.tags.split(' ').each (tag) ->
      m = tag.match(/^pool:(\d+)/)
      if !m
        return
      pool_id = parseInt(m[1])
      return

    # If we're loading from a pool, load the pool's data.
    @result.pool_id = pool_id

    # Load the posts to display.  If we're loading a pool, load all posts (up to 1000);
    # otherwise set a limit.
    limit = if extending then 1000 else 100
    if pool_id?
      limit = 1000
    @result.post_limit = limit

    # Make sure that request_finished doesn't consider this request complete until we've
    # actually started every request.
    @xhr.add null
    @server_load_pool()
    @server_load_posts()
    @xhr.delete null
    @request_finished()
    return

  hashchange_tags: =>
    tags = UrlHash.get('tags')
    if tags == @last_seen_tags
      return
    @last_seen_tags = tags
    console.debug 'changed tags'
    @load()
    return

  perform_search: (event) =>
    tags = event.memo.tags
    @last_seen_tags = tags
    results_mode = event.memo.results_mode or 'center-on-first'
    console.debug 'do search: ' + tags
    @load
      tags: tags
      results_mode: results_mode
    return
