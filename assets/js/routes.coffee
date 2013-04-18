# System ROUTES
# --------------------------------------------------------------------------
# Handle deep linking using the hashtag.
# Implemented using the Backbone Router.

class System.Routes extends Backbone.Router

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


    # ROUTER METHODS
    # ----------------------------------------------------------------------

    # The default route "/" will check if there's a map open. If there's none,
    # then open the [start view](startView.html).
    openDefault: =>
        if System.App.mapView.model?
            @showOverlay false
        else
            @openStart()

    # Show the specified map on the [Map View](mapView.html).
    # If the map is invalid, then show a [Footer Alert](alertView.html).
    openMap: (id) =>
        System.App.consoleLog "ROUTE", "openMap", id

        System.App.auditDataManagerView.hide()
        System.App.settingsView.hide()
        System.App.startView.hide()
        System.App.helpView.hide()

        # If no valid ID is specified, then clear the current map.
        if not id? or id is 0
            System.App.mapView.bindMap null
            return

        # Find map based on its friendly URL key. If no map is found, trying using the value as its ID.
        map = _.find System.App.Data.maps.models, (item) -> item.urlKey() is System.App.DataUtil.getUrlKey id
        map = System.App.Data.maps.get(id) if not map?

        if map?
            System.App.mapView.bindMap map
            System.App.menuEvents.trigger "active:map", map
            @showOverlay false
        else
            msg = System.App.Messages.errMapDoesNotExist
            System.App.alertEvents.trigger "footer", {isError: true, title: System.App.Messages.error, message: msg}
            @navigate "", {trigger: false}

    # Show the [Audit Data Manager View](auditDataManagerView.html).
    openAuditData: =>
        System.App.consoleLog "ROUTE", "openAuditData"
        @showOverlay System.App.auditDataManagerView

    # Show the [Audit Event Manager View](auditDataManagerView.html).
    openAuditEvents: =>
        System.App.consoleLog "ROUTE", "openAuditEvents"
        @showOverlay System.App.auditEventManagerView

    # Show the [Create Map View](createMapView.html).
    openCreateMap: =>
        System.App.consoleLog "ROUTE", "openCreateMap"
        @showOverlay System.App.createMapView

    # Show the [Entity Manager View](entityManagerView.html).
    openEntities: =>
        System.App.consoleLog "ROUTE", "openEntities"
        @showOverlay System.App.entityManagerView

    # Show the [Help View](helpView.html).
    openHelp: =>
        System.App.consoleLog "ROUTE", "openHelp"
        @showOverlay System.App.helpView

    # Show the [Settings View](settingsView.html).
    openSettings: =>
        System.App.consoleLog "ROUTE", "openSettings"
        @showOverlay System.App.settingsView

    # Show the [Script Editor View](scriptEditorView.html).
    openScriptEditor: (model, propertyName) =>
        System.App.consoleLog "ROUTE", "openScriptEditor"
        @showOverlay System.App.scriptEditorView, model, propertyName

    # Show the [Start View](startView.html).
    openStart: =>
        System.App.consoleLog "ROUTE", "openStart"
        @showOverlay System.App.startView


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Hide all overlays (if there's any open) and show the specified view.
    # The new overlay can receive up to 2 parameters.
    # TODO! Refactor and use events to properly hide the other overlays!
    showOverlay: (overlay, param1, param2) =>
        for view in [
            System.App.auditDataManagerView,
            System.App.auditEventManagerView,
            System.App.createMapView,
            System.App.entityManagerView,
            System.App.helpView,
            System.App.settingsView,
            System.App.scriptEditorView,
            System.App.startView]
            view.hide() if overlay isnt view

        if overlay isnt false
            System.App.toggleLoading false
            overlay.show param1, param2

    # Refresh the current view if it's specified on the event, or the whole
    # page if view is left unspecified.
    refresh: =>
        System.App.consoleLog "ROUTE", "Refresh current page"
        window.document.location.href = window.location.href