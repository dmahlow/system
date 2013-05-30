# MAP CONTROLS VIEW
# --------------------------------------------------------------------------
# Contains all controls related to map manipulation, editing and filtering.

class SystemApp.MapControlsView extends SystemApp.BaseView

    # PROPERTIES, VARIABLES AND CHILD VIEWS
    # ----------------------------------------------------------------------

    mapTabView: null                # the [map tab](mapTabView.html) map control
    entitiesTabView: null           # the [entities tab](entitiesTabView.html) map control
    shapeTabView: null              # the [shape tab](shapeTabView.html) map control
    inspectorTabView: null          # the [events tab](inspectorTabView.html) map control


    # DOM ELEMENTS
    # ----------------------------------------------------------------------

    $chkEditable: null         # the "Edit enabled" checkbox
    $chkAutoUpdate: null       # the "Timer auto-update" checkbox
    $imgLock: null             # the top "Lock" icon
    $imgAutoUpdate: null       # the top "Timer auto-update" icon
    $imgFullscreen: null       # the top right "Fullscreen" icon
    $tabDivs: null             # the tab divs (each div is a tab)
    $tabHeaders: null          # to get each h4 element on the tab headers
    $tabInspectorHeader: null  # the "Inspector" tab header
    $tabEntitiesHeader: null   # the "Objects" tab header

    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init all map controls and call the `resize` method to set correct sizing.
    initialize: (parent) =>
        @baseInit parent
        @setDom()
        @setChildViews()
        @setEvents()
        @bindInitialState()

        @resize()
        @width = @$el.outerWidth()

    # Clear controls and unbind events.
    dispose: =>
        $(window).unbind "resize", @resize

        @mapTabView.dispose()
        @entitiesTabView.dispose()
        @shapeTabView.dispose()
        @inspectorTabView.dispose()

        @baseDispose()

    # Set the child map control views.
    setChildViews: =>
        @mapTabView = new SystemApp.MapControlsMapTabView this
        @entitiesTabView = new SystemApp.MapControlsEntitiesTabView this
        @shapeTabView = new SystemApp.MapControlsShapeTabView this
        @inspectorTabView = new SystemApp.MapControlsInspectorTabView this

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map-controls"

        @$tabDivs = @$el.children "div.tab"
        @$tabHeaders = $ "#map-ctl-tab-headers"
        @$chkEditable = $ "#map-ctl-editable"
        @$chkAutoUpdate = $ "#map-ctl-autoupdate"
        @$imgLock = $ "#top-img-lock"
        @$imgAutoUpdate = $ "#top-img-autoupdate"
        @$imgFullscreen = $ "#top-img-fullscreen"

        @$tabInspectorHeader = $ "#map-ctl-tab-header-inspector"
        @$tabEntitiesHeader = $ "#map-ctl-tab-header-entities"

    # Bind events to DOM and other controls.
    setEvents: =>
        $(window).resize @resize

        @$chkEditable.change @setEditEnabled
        @$chkAutoUpdate.change @setAutoUpdate
        @$imgFullscreen.click @toggleFullscreen

        # Bind click to tab headers.
        @$tabHeaders.children("h4").click @tabClick
        @$tabInspectorHeader.click @tabInspectorClick
        @$tabEntitiesHeader.click @tabEntitiesClick

        @listenTo SystemApp.mapEvents, "loaded", @bindMap
        @listenTo SystemApp.mapEvents, "edit:toggle", @editSetState

    # Bind the saved [User Settings](userSettings.html) and current [Data](data.html) to the map map controls.
    bindInitialState: =>
        @$chkAutoUpdate.prop "checked", SystemApp.Data.userSettings.mapAutoRefresh()

    # When window has loaded or resized, call this to resize the map controls accordingly.
    # TODO! Properly calculate the diff instead of using the hard coded value.
    resize: =>
        height = $(window).innerHeight() - $("#header").outerHeight() - $("#footer").outerHeight() - 1
        @$el.css "height", height
        @$tabDivs.css "height", height - 32

    # BIND INFORMATION
    # ----------------------------------------------------------------------

    # Bind the loaded [map](map.html) to the view.
    bindMap: (map) =>
        @model = map

    # Bind the selected shape details to the [Shape Details View](shapeTabView.html).
    bind: (views) =>
        @shapeTabView.bind views
        @inspectorTabView.bind views


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Is the "Show links" checkbox checked?
    isLinksVisible: =>
        @mapTabView.isLinksVisible()


    # SWITCHES, SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Set the "Edit" checkbox state when user toggles the edit mode on or off.
    editSetState: (value) =>
        @$chkEditable.prop "checked", not value

        if not value
            @$imgLock.attr "src", "images/ico-locked.png"
        else
            @$imgLock.attr "src", "images/ico-unlocked.png"

    # Enable or disable editing the current [Map](map.html).
    setEditEnabled: (value) =>
        if value isnt false and (value is undefined or value.data is null)
            value = not (@$chkEditable.prop "checked")

        # Get user permissions.
        hasPermission = SystemApp.Data.loggedUser.hasRole "mapedit"
        readOnly = @model.isReadOnly()
        isOwner = (@model.createdByUserId() is SystemApp.Data.loggedUser.id)

        # Make sure user has permissions to edit this map.
        if value is true
            if not hasPermission and not isOwner
                value = false
                errorMsg = SystemApp.Messages.errNoPermissionTo.replace "#", SystemApp.Messages.editThisMap
            else if readOnly
                value = false
                errorMsg = SystemApp.Messages.errMapIsReadOnly

            if not value
                SystemApp.alertEvents.trigger "tooltip", {isError: true, title: SystemApp.Messages.accessDenied, message: errorMsg}
                @$chkEditable.prop "checked", false

        SystemApp.mapEvents.trigger "edit:toggle", value
        SystemApp.consoleLog "MapControlsView.setEditEnabled", value

    # Enable or disable the [AuditData](auditData.html) timers to auto-update
    # the values of related labels on the map.
    setAutoUpdate: (value) =>
        if value isnt false and (value is undefined or value.data is null)
            value = not (@$chkAutoUpdate.prop "checked")

        @$chkAutoUpdate.prop "checked", not value

        if not value
            @$imgAutoUpdate.removeClass "disabled"
        else
            @$imgAutoUpdate.addClass "disabled"

        SystemApp.Data.autoUpdateEnabled = not value
        SystemApp.Data.userSettings.mapAutoRefresh SystemApp.Data.autoUpdateEnable

        if not value
            SystemApp.Data.startTimers()
        else
            SystemApp.Data.stopTimers()

    # Toggle the fullscreen mode on or off. While on fullscreen, the app [Menu](menuView.html)
    # and [Map Controls](controlsView.html) will be hidden.
    toggleFullscreen: (fullscreen) =>
        if not fullscreen? or fullscreen.originalEvent?
            fullscreen = $("#header").is(":visible")

        if fullscreen

            $("#header").hide()
            $("#footer").addClass("transparent")
            $("body").addClass "fullscreen"

            @$imgFullscreen.attr "src", "images/ico-showcontrols.png"
            @hide()

        else

            $("#header").show()
            $("#footer").removeClass("transparent")
            $("body").removeClass "fullscreen"

            @$imgFullscreen.attr "src", "images/ico-hidecontrols.png"
            @show()

            @mapDivWidth = $(window).innerWidth()
            @mapDivHeight = $(window).innerHeight() - $("#header").outerHeight() - $("#footer").outerHeight()
            @parentView.$el.css "width", @mapDivWidth
            @parentView.$el.css "height", @mapDivHeight

        # Save the current fullscreen state on the [User Settings](userSettings.html) model.
        SystemApp.Data.userSettings.mapFullscreen fullscreen

    # Hide the map controls and show the minimzed icon on the top right corner.
    hide: (e) =>
        @$el.hide()
        @width = 0

        # If an event object is passed then stop its propagation and default behaviour.
        e?.stopPropagation()
        e?.preventDefault()

    # Show the map controls and hide the minimzed icon.
    show: =>
        @$el.show()
        @width = @$el.outerWidth()


    # TABS HANDLING
    # ----------------------------------------------------------------------

    # Hide the map controls and show the minimzed icon on the top right corner.
    tabClick: (e) =>
        tabHeader = $ e.target
        tabDiv = $ tabHeader.data "tabid"

        @$tabHeaders.children("h4").removeClass "active"
        tabHeader.addClass "active"

        @$tabDivs.hide()
        tabDiv.show()

    # When user clicks the "Inspector" tab, call its `resize` handler.
    tabInspectorClick: =>
        @inspectorTabView.resize()

    # When user clicks the "Objects" tab, call its `resize` handler.
    tabEntitiesClick: =>
        @entitiesTabView.resize()