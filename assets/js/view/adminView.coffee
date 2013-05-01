# ADMIN VIEW
# --------------------------------------------------------------------------
# Represents the admin area.

class SystemApp.AdminView extends SystemApp.BaseView

    $menu: null         # the menu wrapper on the top
    $allMenus: null     # array with all menu items
    $userGrid: null    # the users grid


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the admin view by settings the DOM and events.
    initialize: =>
        @setDom()
        @setEvents()

        SystemApp.Data.users.onFetchCallback = @bindUsers
        SystemApp.Data.users.fetch()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#wrapper"
        @$menu = $ "#menu"
        @$allMenus = @$menu.find "a.menu-item"

        @$userGrid = $ "#user-grid"

    # Bind events to DOM.
    setEvents: =>
        @$allMenus.click @menuClick


    # MENU
    # ----------------------------------------------------------------------

    # When user clicks a menu button, make it active.
    menuClick: (e) =>
        @$allMenus.removeClass "active"
        $(e.target).addClass "active"


    # USERS AND ROLES
    # ----------------------------------------------------------------------

    # Bind registered users to the users grid.
    bindUsers: =>
        for u in SystemApp.Data.users.models
            console.warn u
            username = $(document.createElement "span")
            username.html u.username()
            @$userGrid.append username