# ADMIN VIEW
# --------------------------------------------------------------------------
# Represents the admin area.

class SystemApp.AdminView extends SystemApp.BaseView

    $menu: null         # the menu wrapper on the top
    $allMenus: null     # array with all menu items

    tabUser: null       # the "User and roles" tab view


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the admin view by settings the DOM and events.
    initialize: =>
        @setDom()
        @setEvents()
        @tabUser = new SystemApp.AdminUserTabView()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#wrapper"
        @$menu = $ "#menu"
        @$allMenus = @$menu.find "a.menu-item"

    # Bind events to DOM.
    setEvents: =>
        @$allMenus.click @menuClick


    # MENU
    # ----------------------------------------------------------------------

    # When user clicks a menu button, make it active.
    menuClick: (e) =>
        @$allMenus.removeClass "active"
        $(e.target).addClass "active"