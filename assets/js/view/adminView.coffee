# ADMIN VIEW
# --------------------------------------------------------------------------
# Represents the admin area.

class SystemApp.AdminView extends SystemApp.BaseView

    routes: null

    # Specific tab views.
    tabUser: null       # the "User and roles" tab view

    # DOM elements.
    $menu: null         # the menu wrapper on the top


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the admin view by settings the DOM and events.
    initialize: =>
        @tabUser = new SystemApp.AdminUserTabView()
        @routes = new SystemApp.AdminRoutes()
        @setDom()
        Backbone.history.start()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#wrapper"
        @$menu = $ "#menu"