# ADMIN STATUS TAB VIEW
# --------------------------------------------------------------------------
# Represents the "STATUS" tab on the admin area.

class SystemApp.AdminStatusTabView extends SystemApp.BaseView

    $butSave: null      # the "Save user" button
    $userGrid: null     # the users grid



    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the admin view by settings the DOM and events.
    initialize: =>
        @setDom()
        @setEvents()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#tab-status"

    # Bind events to DOM.
    setEvents: =>
        console.warn "Events"


