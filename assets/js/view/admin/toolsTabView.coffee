# ADMIN TOOLS TAB VIEW
# --------------------------------------------------------------------------
# Represents the "Tools" tab on the admin area.

class SystemApp.AdminToolsTabView extends SystemApp.BaseView

    $butRefresh: null   # the "Refresh clients" button


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the user tab view by settings the DOM and events.
    initialize: =>
        @setDom()
        @setEvents()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#tab-tools"
        @$butRefresh = $ "#tools-but-refresh"

    # Bind events to DOM.
    setEvents: =>
        @$butRefresh.click @refreshClients


    # TOOLS
    # ----------------------------------------------------------------------

    # Trigger a command to force refresh all client windows (browsers).
    refreshClients: =>
        SystemApp.Sockets.sendClientsRefresh()