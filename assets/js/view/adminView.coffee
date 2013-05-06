# ADMIN VIEW
# --------------------------------------------------------------------------
# Represents the admin area.

class SystemApp.AdminView extends SystemApp.BaseView

    routes: null

    tabUsers: null  # the "Users and roles" tab view
    tabTools: null  # the "Tools" tab view

    $menu: null     # the menu wrapper on the top


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the admin view by settings the DOM and events.
    initialize: =>
        @tabUsers = new SystemApp.AdminUsersTabView()
        @tabTools = new SystemApp.AdminToolsTabView()
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