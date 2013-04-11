# CREATE MAP VIEW
# --------------------------------------------------------------------------
# Represents the "Create new map" overlay what shows up when user
# clicks a "Create new..." option on the sub menus.

class System.CreateMapView extends System.OverlayView

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
        System.App.footerView.setText null
        @$el.fadeOut System.App.Settings.General.fadeDelay

    # Show the view using a fade in effect and pass the entity type.
    onShow: =>
        $(document).keyup @keyUp
        System.App.footerView.setText System.App.Messages.createMapText
        @$el.fadeIn System.App.Settings.General.fadeDelay, @focus

        # Clear and set focus on the textbox.
        @$txtName.val ""
        @$txtName.focus()

        System.App.menuEvents.trigger "active:menu", @$menuItem

    # When user presses a key on the `txtName` field.
    keyUp: (e) =>
        if e.which is 27
            @hide e

        if e.which is 13
            newMapName = $.trim @$txtName.val()
            existing = System.App.Data.maps.where {name: newMapName}

            if existing.length > 0
                errTitle = System.App.Messages.errCreatingMap
                errMessage = System.App.Messages.errMapNameExists.replace "#", newMapName
                System.App.alertEvents.trigger "footer", {title: errTitle, message: errMessage, isError: true}
                @warnField @$txtName
                return

            map = System.App.Data.maps.create {dateCreated: new Date(), name: newMapName}

            @hide()

            # Change the URL using the new map key.
            System.App.routes.navigate "map/" + map.urlKey(), {trigger: true}