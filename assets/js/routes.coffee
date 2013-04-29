# System ROUTES
# --------------------------------------------------------------------------
# Handle deep linking using the hashtag.
# Implemented using the Backbone Router.

class SystemApp.Routes extends Backbone.Router

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
            SystemApp.mapView.bindMap null
            return

        # Find map based on its friendly URL key. If no map is found, trying using the value as its ID.
        map = _.find SystemApp.Data.maps.models, (item) -> item.urlKey() is SystemApp.DataUtil.getUrlKey id
        map = SystemApp.Data.maps.get(id) if not map?

        if map?
            SystemApp.mapView.bindMap map
            SystemApp.menuEvents.trigger "active:map", map
            @showOverlay false
        else
            msg = SystemApp.Messages.errMapDoesNotExist
            SystemApp.alertEvents.trigger "footer", {isError: true, title: SystemApp.Messages.error, message: msg}
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

    # Refresh the current view if it's specified on the event, or the whole
    # page if view is left unspecified.
    refresh: =>
        SystemApp.consoleLog "ROUTE", "Refresh current page"
        window.document.location.href = window.location.href