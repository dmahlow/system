# System ROUTES
# --------------------------------------------------------------------------
# Handle deep linking using the hashtag.
# Implemented using the Backbone Router.

class SystemApp.AppRoutes extends Backbone.Router

    routes:
        "": "openDefault"                   # the default route will change the view based on the last view state
        "map/:id": "openMap"                # open a map on the [Map View](mapView.html)
        "auditdata": "openAuditData"        # open the [Audit Data Manager](auditDataManagerView.html) overlay
        "auditevents": "openAuditEvents"    # open the [Audit Event Manager](auditEventManagerView.html) overlay
        "createmap": "openCreateMap"        # open the [Create Map](createMapView.html) overlay
        "entities": "openEntities"          # open the [Entity Manager](entityManagerView.html) overlay
        "help": "openHelp"                  # open the [Help](helpView.html) overlay
        "maps": "openStart"                 # open the [Start](startView.html) overlay
        "settings": "openSettings"          # open the [Settings](settingsView.html) overlay
        "start": "openStart"                # open the [Start](startView.html) overlay
        "variables": "openVariables"        # open the [Variables Manager](variableManagerView.html) overlay
        ":invalid": "openInvalid"           # default catch-all routes, display an "invalid path" to the user


    # ROUTER METHODS
    # ----------------------------------------------------------------------

    # The default route "/" will check if there's a map open. If there's none,
    # then open the [start view](startView.html).
    openDefault: =>
        if SystemApp.mapView.model?
            @showOverlay false
        else
            @openStart()

    # Show the specified map on the [Map View](mapView.html).
    # If the map is invalid, then show a [Footer Alert](alertView.html).
    openMap: (id) =>
        SystemApp.consoleLog "ROUTE", "openMap", id

        SystemApp.auditDataManagerView.hide()
        SystemApp.settingsView.hide()
        SystemApp.startView.hide()
        SystemApp.helpView.hide()

        # If no valid ID is specified, then clear the current map.
        if not id? or id is 0
            SystemApp.mapView.bind null
            return

        urlKey = SystemApp.DataUtil.getUrlKey id

        # Find map based on its friendly URL key. If no map is found, trying using the value as its ID.
        if SystemApp.Settings.map.enableLocalMap and id is SystemApp.Settings.map.localMapId
            map = new SystemApp.Map()
            map.initLocalMap()
        else
            map = _.find SystemApp.Data.maps.models, (item) -> item.urlKey() is urlKey
            map = SystemApp.Data.maps.get(id) if not map?

        if map?
            SystemApp.mapView.bind map
            SystemApp.menuEvents.trigger "active:map", map
            @showOverlay false
        else
            msg = SystemApp.Messages.errMapDoesNotExist
            SystemApp.alertEvents.trigger "footer", {isError: true, title: SystemApp.Messages.error, message: msg}
            SystemApp.toggleLoading false
            @navigate "", {trigger: false}

    # Show the [Audit Data Manager View](auditDataManagerView.html).
    openAuditData: =>
        SystemApp.consoleLog "ROUTE", "openAuditData"
        @showOverlay SystemApp.auditDataManagerView

    # Show the [Audit Event Manager View](auditDataManagerView.html).
    openAuditEvents: =>
        SystemApp.consoleLog "ROUTE", "openAuditEvents"
        @showOverlay SystemApp.auditEventManagerView

    # Show the [Create Map View](createMapView.html).
    openCreateMap: =>
        SystemApp.consoleLog "ROUTE", "openCreateMap"
        @showOverlay SystemApp.createMapView

    # Show the [Entity Manager View](entityManagerView.html).
    openEntities: =>
        SystemApp.consoleLog "ROUTE", "openEntities"
        @showOverlay SystemApp.entityManagerView

    # Show the [Help View](helpView.html).
    openHelp: =>
        SystemApp.consoleLog "ROUTE", "openHelp"
        @showOverlay SystemApp.helpView

    # Show the [Settings View](settingsView.html).
    openSettings: =>
        SystemApp.consoleLog "ROUTE", "openSettings"
        @showOverlay SystemApp.settingsView

    # Show the [Script Editor View](scriptEditorView.html).
    openScriptEditor: (model, propertyName) =>
        SystemApp.consoleLog "ROUTE", "openScriptEditor"
        @showOverlay SystemApp.scriptEditorView, model, propertyName

    # Show the [Start View](startView.html).
    openStart: =>
        SystemApp.consoleLog "ROUTE", "openStart"
        @showOverlay SystemApp.startView

    # Show the [Variables Manager View](variableManagerView.html).
    openVariables: =>
        SystemApp.consoleLog "ROUTE", "openVariables"
        @showOverlay SystemApp.variableManagerView

    # Open default page and show an alert with "invalid path" to the user.
    openInvalid: =>
        SystemApp.consoleLog "ROUTE", "openInvalid"

        errorTitle = SystemApp.Messages.invalidRoute
        errorMsg = SystemApp.Messages.errInvalidRoute
        SystemApp.alertEvents.trigger "tooltip", {isError: true, title: errorTitle, message: errorMsg}

        @openDefault()
        @navigate "", {trigger: false}


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Hide all overlays (if there's any open) and show the specified view.
    # The new overlay can receive up to 2 parameters.
    # TODO! Refactor and use events to properly hide the other overlays!
    showOverlay: (overlay, param1, param2) =>
        for view in [
            SystemApp.auditDataManagerView,
            SystemApp.auditEventManagerView,
            SystemApp.createMapView,
            SystemApp.entityManagerView,
            SystemApp.helpView,
            SystemApp.settingsView,
            SystemApp.scriptEditorView,
            SystemApp.startView,
            SystemApp.variableManagerView]
            view.hide() if overlay isnt view

        if overlay isnt false
            SystemApp.toggleLoading false
            overlay.show param1, param2

    # Refresh the page in X milliseconds. If milliseconds is more than 0, show an alert
    # which allows the user to cancel the refresh.
    refresh: (delay) =>
        refreshCallback = -> window.document.location.href = window.location.href

        if not delay? or delay < 1
            SystemApp.consoleLog "ROUTE", "Refresh current page now."
            refreshCallback()
        else
            SystemApp.consoleLog "ROUTE", "Refresh current page in #{delay} milliseconds."

            # Set refresh message and info.
            time = moment().add("ms", delay).format "HH:mm:ss"
            title = SystemApp.Messages.attention
            message = SystemApp.Messages.scheduledRefreshAlert.replace "#", time

            # Set timeout and handler to cancel using ESC.
            refreshTimer = setTimeout refreshCallback, delay
            clickAction = (e) ->
                if e.keyCode is 27
                    clearTimeout refreshTimer

            # Trigger the tooltip alert.
            SystemApp.alertEvents.trigger "tooltip", {title: title, message: message, delay: delay, clickAction: clickAction}