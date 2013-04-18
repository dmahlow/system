# MAP CONTROLS: OPTIONS VIEW
# --------------------------------------------------------------------------
# Represents the "Shape properties" tab inside a [Map Controls View](controlsView.html).

class System.MapControlsMapTabView extends System.BaseView

    timerHideZIndex: null           # a timer to auto hide the z-index after user clicked the "Identify z-index" button

    $txtName: null            # the "Name" textbox
    $txtPaperSizeX: null      # the "X" paper size textbox
    $txtPaperSizeY: null      # the "Y" paper size textbox
    $txtGridSizeX: null       # the "X" grid size textbox
    $txtGridSizeY: null       # the "Y" grid size textbox
    $butDelete: null          # the "Delete map" button
    $butConfirmDelete: null   # the "Confirm delete!!!" button, appears after user clicks "Delete map"

    $selDisplayProps: null          # the property select box that holds all available shape display properties
    $chkShowLinks: null             # the "Show links" checkbox
    $zoomSpan: null                 # the zoom span
    $zoomIn: null                   # the zoom in icon
    $zoomOut: null                  # the zoom out icon
    $butInitScript: null            # the init script button
    $butZIndexIdentify: null        # the "Identify z-index" button
    $butExportSvg: null             # the "Export to SVG" button


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Inits the view. Parent will be the [Map Controls View](controlsView.html).
    initialize: (parent) =>
        @baseInit parent
        @setDom()
        @setEvents()
        @bindInitialState()
        @bindDisplayProps System.App.Settings.Map.displayProps

    # Dispose the map tab view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map-ctl-tab-map"

        @$txtName = $ "#map-ctl-name"
        @$txtPaperSizeX = $ "#map-ctl-papersize-x"
        @$txtPaperSizeY = $ "#map-ctl-papersize-y"
        @$txtGridSizeX = $ "#map-ctl-gridsize-x"
        @$txtGridSizeY = $ "#map-ctl-gridsize-y"
        @$butInitScript = $ "#map-ctl-init-script"
        @$butDelete = $ "#map-ctl-delete"
        @$butConfirmDelete = $ "#map-ctl-confirmdelete"

        @$selDisplayProps = $ "#map-ctl-displayprops"
        @$chkShowLinks = $ "#map-ctl-showlinks"
        @$zoomSpan = $ "#footer-zoom-span"
        @$zoomIn = $ "#footer-zoom-in"
        @$zoomOut = $ "#footer-zoom-out"
        @$butExportSvg = $ "#map-ctl-export-svg"
        @$butZIndexIdentify = $ "#map-ctl-zindex-identify"

    # Bind events to DOM and other controls.
    setEvents: =>
        @$txtName.blur @setName
        @$txtPaperSizeX.blur @setPaperSizeX
        @$txtPaperSizeY.blur @setPaperSizeY
        @$txtGridSizeX.blur @setGridSizeX
        @$txtGridSizeY.blur @setGridSizeY
        @$butInitScript.click @showInitScript
        @$butDelete.click @askDeleteMap
        @$butConfirmDelete.click @confirmDeleteMap

        @$selDisplayProps.change @onDisplayPropsChange
        @$chkShowLinks.change @onShowLinksChange
        @$zoomIn.click "in", @onZoom
        @$zoomOut.click "out", @onZoom
        @$butExportSvg.click @exportToSvg
        @$butZIndexIdentify.click @zIndexIdentify

        @listenTo System.App.mapEvents, "loaded", @bindMap
        @listenTo System.App.mapEvents, "zoom", @setZoomLabel
        @listenTo System.App.mapEvents, "edit:toggle", @setEnabled


    # Set the initial state of map options based on the [User Settings](userSettings.html)
    # saved on the browser's local storage.
    bindInitialState: =>
        @$selDisplayProps.val System.App.Data.userSettings.mapOverrideShapeTitle()
        @$chkShowLinks.prop "checked", System.App.Data.userSettings.mapShowLinks()


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Get the text of the current selected "Display property".
    currentDisplayProperty: =>
        (@$selDisplayProps.find "option:selected").val()

    # Is the "Show links" checkbox on?
    isLinksVisible: =>
        @$chkShowLinks.prop "checked"


    # EVENTS
    # ----------------------------------------------------------------------

    # Triggered whenever user changes the current shape's title property.
    onDisplayPropsChange: (e) =>
        val = @currentDisplayProperty()
        System.App.mapEvents.trigger "shapes:overridetitle", val
        System.App.Data.userSettings.mapOverrideShapeTitle val
        

    # Triggered whenever user toggles the "Show links" on or off.
    onShowLinksChange: (e) =>
        val = @isLinksVisible()
        System.App.mapEvents.trigger "links:toggle", val
        System.App.Data.userSettings.mapShowLinks val

    # When user clicks on the zoom icons, trigger the zoom event on the `mapEvents` dispatcher.
    onZoom: (e) =>
        System.App.mapEvents.trigger "zoom:#{e.data}"

    # Trigger whenever the current [Map](map.html) name has changed.
    setName: =>
        value = @$txtName.val()

        @model.name value if value.length > 0

    # Triggered whenever the current [Map](map.html) `paperSizeX` has changed, `$txtPaperSizeX` onBlur event.
    setPaperSizeX: =>
        @setSize @$txtPaperSizeX, @model.paperSizeX, System.App.Settings.Map.minPaperSize

    # Triggered whenever the current [Map](map.html) `paperSizeY` has changed, `$txtPaperSizeY` onBlur event.
    setPaperSizeY: =>
        @setSize @$txtPaperSizeY, @model.paperSizeY, System.App.Settings.Map.minPaperSize

    # Triggered whenever the current [Map](map.html) `gridSizeX` has changed, `$txtGridSizeX` onBlur event.
    setGridSizeX: =>
        @setSize @$txtGridSizeX, @model.gridSizeX, System.App.Settings.Map.minGridSize

    # Triggered whenever the current [Map](map.html) `gridSizeY` has changed, `$txtGridSizeY` onBlur event.
    setGridSizeY: =>
        @setSize @$txtGridSizeY, @model.gridSizeY, System.App.Settings.Map.minGridSize

    # Sets the "zoom" span, to display the current [Map View](mapView.html) zoom level.
    setZoomLabel: (zoomLevel) =>
        @$zoomSpan.html "Zoom " + (1 / zoomLevel).toFixed(2)

    # Update one of the current [Map](map.html) sizes, which can be paperSizeX, paperSizeY,
    # gridSizeX or gridSizeY. A text input field, property name and the minimum accepted
    # value must be passed. *Internal use only!*
    setSize: (textField, propertyName, minValue) =>
        size = textField.val()

        if $.isNumeric size
            size = Math.round size
        else
            size = propertyName()
            textField.val size

        size = minValue if size < minValue

        propertyName size

    # Enable or disable editing the current [Map](map.html) settings.
    setEnabled: (value) =>
        formElements = [@$el, @$txtName, @$txtPaperSizeX, @$txtPaperSizeY, @$txtGridSizeX, @$txtGridSizeY, @$butDelete]

        if not value
            for elm in formElements
                elm.attr("disabled", "disabled")
        else
            for elm in formElements
                elm.removeAttr("disabled")


    # BINDIND AND OPTIONS
    # ----------------------------------------------------------------------

    # Bind map to the control.
    bindMap: (map) =>
        @model = map
        @$txtName.val map.name()
        @$txtPaperSizeX.val map.paperSizeX()
        @$txtPaperSizeY.val map.paperSizeY()
        @$txtGridSizeX.val map.gridSizeX()
        @$txtGridSizeY.val map.gridSizeY()

    # Bind display properties to the select box (so user can change
    # what's displayed on the title of the shapes on the map).
    bindDisplayProps: (displayProps) =>
        @$selDisplayProps.empty()

        option = $(document.createElement "option")
        option.val ""
        option.html "default"
        @$selDisplayProps.append option

        # Each group of properties is separated by |.
        # For example name|internal_ip,lan_ip|external_ip,public_ip.
        # Please note that the commas are used below to separate similar properties.
        arr = displayProps.split "|"

        for value in arr

            # Similar properties are separated by commas.
            # For example name,hostname,server_name could all mean the name of the entity.
            splitValue = value.split ","
            option = $(document.createElement "option")
            option.val value

            if splitValue.length > 1
                option.html splitValue[0]
            else
                option.html value

            @$selDisplayProps.append option

    # Open the [script editor](scriptEditorView.html) to edit the map's init script.
    showInitScript: =>
        System.App.routes.openScriptEditor @model, "initScript"


    # EXPORT AND Z-INDEX
    # ----------------------------------------------------------------------

    # Briefly show a text with the z-index value on each of the current [Map](map.html)
    # shapes. The z-index texts will get hidden after a few seconds, or if the user
    # presses the "Esc" key.
    zIndexIdentify: =>
        System.App.mapEvents.trigger "zindex:toggle", true

        if @timerHideZIndex?
            clearTimeout @timerHideZIndex
            @timerHideZIndex = null

        @timerHideZIndex = setTimeout @zIndexHide, System.App.Settings.Map.zIndexHideTimeout

        $(document).keydown @zIndexKeyDown

    # When z-index is being shown and user presses a key, check if it is the
    # "Esc" key to hide the z-index identifiers.
    zIndexKeyDown: (e) =>
        @zIndexHide() if e.keyCode is 27

    # Triggers the event to hide the z-index identifiers.
    zIndexHide: =>
        $(document).unbind "keydown", @zIndexHide

        if @timerHideZIndex?
            clearTimeout @timerHideZIndex
            @timerHideZIndex = null

        System.App.mapEvents.trigger "zindex:toggle", false

    # Export to current [Map View](mapView.html) to a SVG image on a new browser window.
    exportToSvg: =>
        @parentView.parentView.setCurrentElement null
        newWindow = window.open "about:blank", "ExportSVG"
        newWindow.document.title = "Exported SVG: " + @model.name()
        newWindow.document.write @parentView.parentView.$el.html()
        newWindow.document.execCommand "SaveAs", true

        $(newWindow).keyup (e) -> this.close() if e.keyCode is 27

        return


    # DELETE MAP
    # ----------------------------------------------------------------------

    # When user clicks the "Delete map" button, show the "Confirm delete"
    # button. Map will be deleted only if user confirms
    # clicking the second button!
    askDeleteMap: =>
        $(document).mouseup @resetDelete
        @$butConfirmDelete.removeClass "hidden"

    # When user clicks the "Confirm delete" button, proceed with map deletion.
    confirmDeleteMap: (e) =>
        @model.destroy()
        @resetDelete e

    # Hide the "Confirm delete" button if user clicks anywhere on the page
    # while the button is visible, or after user confirms the deletion.
    resetDelete: =>
        $(document).unbind "mouseup", @resetDelete
        @$butConfirmDelete.addClass "hidden"