# System ROUTES
# --------------------------------------------------------------------------
# Handle deep linking using the hashtag.
# Implemented using the Backbone Router.

class SystemApp.AdminRoutes extends Backbone.Router

    routes:
        "": "openStatusTab"         # open the status tab by default
        "status": "openStatusTab"   # open the status tab
        "server": "openServerTab"   # open the server tab
        "client": "openClientTab"   # open the client tab
        "users": "openUsersTab"     # open the users tab
        "tools": "openToolsTab"     # open the tools tab


    # ROUTER METHODS
    # ----------------------------------------------------------------------

    # When user clicks a menu button, make it active and open the relevant tab.
    openTab: (menu) =>
        @$allMenus = $("a.menu-item") if not @$allMenus
        @$allTabs = $("div.admin-tab") if not @$allTabs

        @$allMenus.removeClass "active"
        $("#menu-#{menu}").addClass "active"
        @$allTabs.hide()
        $("#tab-#{menu}").show()

    # Show the "Status" tab.
    openStatusTab: =>
        @openTab "status"

    # Show the "Server Settings" tab.
    openServerTab: =>
        @openTab "server"

    # Show the "Client Settings" tab.
    openClientTab: =>
        @openTab "client"

    # Show the "Users and Roles" tab.
    openUsersTab: =>
        @openTab "users"

    # Show the "Tools" tab.
    openToolsTab: =>
        @openTab "tools"