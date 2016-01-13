@NavBar = React.createClass
  getInitialState: ->
    hidden: false
    showSearchHelper: false

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

  toggleTags: ->
    Store.state.tagEditor = !Store.state.tagEditor
    Store.forceUpdate()

  onSelectMode: ->
    Store.state.selectMode = true
    Store.forceUpdate()

  onScroll: (e) ->
    top = window.pageYOffset

    if @prevTop?
      if @prevTop < top
        newHidden = true
      else if @prevTop > top
        newHidden = false
      else
        newHidden = @state.hidden

    # if we are within 100 pixels of the top, always show

    newHidden = false if top <= 100
    newHidden = false if @state.showSearchHelper

    if newHidden? && @state.hidden != newHidden
      @setState
        hidden: newHidden

    @prevTop = top

  onToggleSearchHelper: ->
    @setState
      showSearchHelper: !@state.showSearchHelper

  closeSearchHelper: ->
    @setState
      showSearchHelper: false

  siteIcon: ->
    return @_siteIcon if @_siteIcon?
    elem = document.querySelector 'link[rel=icon]'

    @_siteIcon = elem.href

  render: ->
    classes = ['navbar', 'navbar-default', 'navbar-fixed-top']
    if @state.hidden
      classes.push 'navbar-hidden'

    <div>
      <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      <nav id="main-navbar" className={classes.join ' '}>
        <div className="container-fluid">
          <a className="navbar-brand" href="#/">
            <img style={height: '20px'} src={@siteIcon()}/>
          </a>
          <a href="javascript:void(0)" onClick={@onToggleSearchHelper} className="btn navbar-btn btn-default search-button">
            <i className="fa fa-search fa-fw"/>
            {" #{Store.state.query} "}
            {
              if Store.state.resultCount != null
                <span className="badge">{Store.state.resultCount.toLocaleString()}</span>
            }
          </a>
          <a href="javascript:void(0)" className="btn navbar-btn dropdown-toggle pull-right" data-toggle="dropdown">
            <i className="fa fa-ellipsis-v fa-fw"/>
          </a>
          <ul className="dropdown-menu pull-right">
            <li><a onClick={@onSelectMode} href="javascript:void(0)">Select Mode</a></li>
            <li><a href="#/tags">Tags</a></li>
            <li>
              <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
            <li>
              <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
            </li>
          </ul>
          <Zoom/>
        </div>
      </nav>
      {
        if @state.showSearchHelper
          <div className="search-helper-float">
            <SearchHelper close={@closeSearchHelper}/>
          </div>
      }
    </div>
