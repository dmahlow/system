# CREATE MAP VIEW
# --------------------------------------------------------------------------
# Represents the "Create new map" overlay what shows up when user
# clicks a "Create new..." option on the top menu.

class SystemApp.CreateMapView extends SystemApp.OverlayView

    $txtName: null      # the text field to enter the new map name
    $menuItem: null     # the top menu DOM element


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the "Create Map" overlay view.
    initialize: =>
        @overlayInit "#map-create-overlay"
        @setDom()
        @setEvents()

    # Clear contents and dispose the view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$txtName = $ "#map-create-overlay-name"
        @$menuItem = $ "#menu-createmap"

    # Bind events to DOM and other controls.
    setEvents: =>
        @$txtName.keyup @keyUp


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Hide the view using a fade out effect.
    onHide: =>
        $(document).unbind "keyup", @keyUp
        SystemApp.footerView.setText null
        @$el.fadeOut SystemApp.Settings.General.fadeDelay

    # Show the view using a fade in effect and pass the entity type.
    # If user has no "mapcreate" role, hide the view immediately.
    onShow: =>
        if not SystemApp.Data.loggedUser.hasRole "mapcreate"
            errorMsg = SystemApp.Messages.errNoPermissionTo.replace "#", SystemApp.Messages.createMaps
            SystemApp.alertEvents.trigger "tooltip", {isError: true, title: SystemApp.Messages.accessDenied, message: errorMsg}

            # Cancel the view and go to previous screen.
            cancelShow = =>
                @hide()
                window.history.back()
            setTimeout cancelShow, 10

            return

        $(document).keyup @keyUp
        SystemApp.footerView.setText SystemApp.Messages.createMapText
        @$el.fadeIn SystemApp.Settings.General.fadeDelay, @focus

        # Clear and set focus on the textbox.
        @$txtName.val ""
        @$txtName.focus()

        SystemApp.menuEvents.trigger "active:menu", @$menuItem

    # When user presses a key on the `txtName` field.
    keyUp: (e) =>
        if e.which is 27
            @hide e

        if e.which is 13
            newMapName = $.trim @$txtName.val()
            existing = SystemApp.Data.maps.where {name: newMapName}

            if existing.length > 0
                errTitle = SystemApp.Messages.errCreatingMap
                errMessage = SystemApp.Messages.errMapNameExists.replace "#", newMapName
                SystemApp.alertEvents.trigger "footer", {title: errTitle, message: errMessage, isError: true}
                @warnField @$txtName
                return

            map = SystemApp.Data.maps.create {dateCreated: new Date(), name: newMapName}

            @hide()

            # Change the URL using the new map key.
            SystemApp.routes.navigate "map/" + map.urlKey(), {trigger: true}