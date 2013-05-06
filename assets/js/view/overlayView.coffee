# OVERLAY VIEW
# --------------------------------------------------------------------------
# Abstract overlay view containing helper methods for closing and tabs.
# Used by all the overlays (Settings, Help, Audit Data Manager, etc...).

class SystemApp.OverlayView extends SystemApp.BaseView

    closeOnFirstEsc: false  # when false, overlay will close on "double Esc", otherwise a single press will do it
    currentSettings: null   # define the settings container
    lastPressedKey: null    # holds the last pressed key (while the overlay is shown)
    fullWidth: true         # overlay takes the full width (true) or only the map area (false)

    $box: null              # the overlay wrapper / box, which is in fact the first child div
    $close: null            # the close icon
    $title: null            # the title is the H2 element
    $leftCol: null          # the left column
    $rightCol: null         # the right column
    $menuItem: null         # menu item corresponding to this overlay
    $modelsList: null       # used by some overlays to show a list of models
    $tabHeaders: null       # the tab header divs (used only for tabbed overlays)
    $tabContents: null      # the tav content divs (used only for tabbed overlays)


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the overlay view.
    overlayInit: (overlaySelector) =>
        @setElement $ overlaySelector

        @setOverlayDom()
        @setOverlayEvents()

    # Set the DOM elements cache.
    setOverlayDom: =>
        @$box = @$el.children ".full-overlay-contents"
        @$close = @$box.children ".close"
        @$title = @$box.children "h2"

        # Set tabs (some overlays might have no tabs).
        @$tabHeaders = @$el.find(".tab-headers").children("label")
        @$tabContents = @$el.find("div.tab")

        # Set left and right columns (some overlays might have no left / right columns).
        @$leftCol = @$el.find ".left-col"
        @$rightCol = @$el.find ".right-col"

    # Bind events to the DOM.
    setOverlayEvents: =>
        @$close.click @hide
        @$tabHeaders.click @tabClick


    # TABS
    # ----------------------------------------------------------------------

    # Hide the tabs wrapper.
    hideTabs: =>
        @$tabHeaders.hide()

    # Show the tab wrapper. This is called whenever the user starts editing
    # a model, or if the overlay has no models to be edited (and thus
    # tabs are always shown).
    showTabs: =>
        @$tabHeaders.show()

    # When user clicks on a tab header, add the `active` class and show the
    # corresponding help div.
    tabClick: (e) =>
        src = $ e.currentTarget

        @$tabHeaders.removeClass "active"
        @$tabContents.hide()
        @$tabContents.filter(src.data("tab")).show()

        src.addClass "active"


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Show the overlay using a "fade in" effect. The fade time is defined
    # at the [Settings](settings.html). Prior to showing, the overlay box will
    # be resized to fit the map area.
    # Arguments will be passed over to the 'onShow' callback.
    show: (e) =>
        $(document).keyup @overlayKeyUp
        $(window).resize @resize

        @resize()

        # Hide right column if list with models is present on the left
        # and no item has been selected.
        @$rightCol.hide() if @$modelsList?

        @lastPressedKey = null
        @$el.show()

        # Set the footer text to the title of the overlay.
        # TODO! Stop calling footer view directly, use events instead.
        SystemApp.footerView.setText @$el.find("h2:first").html()

        # Change the view based on what properties are set.
        @$menuItem.addClass("active") if @$menuItem?
        @hideTabs() if @$modelsList?
        @onShow.apply this, arguments if @onShow?

    # Hide the overlay using a "fade out" effect. The fade time is defined
    # at the [Settings](settings.html).
    # Arguments will be passed over to the 'onHide' callback.
    hide: (e) =>
        $(document).unbind "keyup", @overlayKeyUp
        $(window).unbind "resize", @resize

        @lastPressedKey = null
        @$el.hide()

        # Change the view based on what properties are set.
        @$menuItem.removeClass("active") if @$menuItem?
        @onHide.apply this, arguments if @onHide?

        # If the hide is called via mouse or keyboard action, reset the URL to the
        # current loaded map's URL.
        SystemApp.mapEvents.trigger "url:reset" if e?.currentTarget?


    # RESIZE AND KEYBOARD EVENTS
    # ----------------------------------------------------------------------

    # Resize the overlay to match the window width and height.
    resize: =>
        horizontalDiff = 30
        horizontalDiff = horizontalDiff + SystemApp.mapView.controlsView.width if not @fullWidth
        verticalDiff = 29 + SystemApp.footerView.height + SystemApp.menuView.height

        # Calculate total dimensions.
        totalWidth = $(window).innerWidth() - horizontalDiff
        totalHeight = $(window).innerHeight() - verticalDiff
        colHeight = totalHeight - 56

        # Resize the box and columns.
        @$box.width totalWidth
        @$box.height totalHeight
        @$leftCol.height colHeight
        @$rightCol.height colHeight

        # Resize the models list.
        if @$modelsList?
            @$modelsList.css "max-height", colHeight - 116

    # When user presses a key while the help overlay is visible, check if it's Esc to close it.
    overlayKeyUp: (e) =>
        keyCode = e.keyCode

        if keyCode is 27
            if @closeOnFirstEsc or @lastPressedKey is 27
                @hide e
                return

        @lastPressedKey = keyCode


    # MODELS LIST AND EDITOR
    # ----------------------------------------------------------------------

    # Helper method to add models to the models list on the left.
    # Used on the entity / audit data / audit events overlays.
    # If `options` is passed, means it's a newly created model
    # so auto select it in the end.
    addToModelsList: (item, collection, options) =>
        wrapper = $(document.createElement "div")
        wrapper.attr "id", @currentSettings.rowListPrefix + item.id
        wrapper.data "DataItem", item
        wrapper.addClass "row"

        row = $(document.createElement "div")

        # The textbox defines the `friendlyId` property of the model.
        id = $(document.createElement "input")
        id.data "propertyname", "friendlyId"
        id.attr "type", "text"
        id.attr "title", SystemApp.Messages.tooltipItemId
        id.prop "readonly", true
        id.addClass "id"
        id.val item.friendlyId()
        id.change @inputOnChange

        # The edit icon on the right of the row.
        editIcon = $(document.createElement "div")
        editIcon.attr "title", SystemApp.Messages.tooltipEditItem
        editIcon.addClass "edit"
        editIcon.click item, @clickEditIcon

        # The delete icon on the right of the row.
        delIcon = $(document.createElement "div")
        delIcon.attr "title", SystemApp.Messages.tooltipDeleteItem
        delIcon.addClass "delete"
        delIcon.click item, @clickDeleteIcon

        # Append to the document.
        row.append id
        row.append editIcon
        row.append delIcon
        wrapper.append row
        @$modelsList.append wrapper

        # Just created by the user? So auto bind it.
        @bindModel item if options?

    # Remove the specified model from the `$modelsList`.
    removeFromModelsList: (item) =>
        row = $("#" + @currentSettings.rowListPrefix + item.id)
        @modelElementRemove row

    # When user clicks on the edit icon on a row, call the `selectModel` method.
    clickEditIcon: (e) =>
        e.stopPropagation()
        @bindModel e.data

    # When user clicks the "delete" icon, make it red
    # so user can click again to confirm the deletion.
    clickDeleteIcon: (e) =>
        e.preventDefault()
        e.stopPropagation()

        src = $ e.currentTarget

        # If the icon is red, then confirm the deletion by removing the row's associated model
        # from the [data store](data.html).
        if src.hasClass "delete-red"
            e.data.destroy()
        else
            src.addClass "delete-red"

        @lastPressedKey = null

    # Selects a row on the `$modelsList` representing a model
    # and bind its information to the right form.
    bindModel: (item) =>
        if item?
            row = $ "#" + @currentSettings.rowListPrefix + item.id
            clear = row.hasClass "active"
        else
            clear = true

        # Remove readonly property from the selected row.
        @$modelsList.find("div.active").removeClass "active"
        @$modelsList.find("input.id").prop "readonly", true

        if clear
            @model = null
            @$rightCol.hide()
        else
            @model = item
            @$rightCol.show()
            row.addClass "active"
            row.find("input.id").prop "readonly", false

        # Show editing tabs.
        @showTabs()

        # Call the underlying `onBindModel`.
        @onBindModel()

    # When user changes the value of any input field then set the value straight away.
    inputOnChange: (e) =>
        src = $ e.currentTarget
        inputType = src.attr "type"
        propertyName = src.data "propertyname"

        # Get the input value based on its type.
        if inputType is "checkbox"
            value = src.prop "checked"
        else
            value = src.val()

        # If the `data` is passed to the event, then save the property to the
        # data instead of the main view model.
        if e.data?
            e.data.set propertyName, value
        else
            @model.set propertyName, value

        @model.save()


    # KEYBOARD EVENTS
    # ----------------------------------------------------------------------

    # When user presses a key while the overlay is visible, pressing "Esc" will
    # once will cancel any pending actions (hide delete icons or unselect current model).
    hasModelListKeyUp: (e) =>
        keyCode = e.keyCode
        deleteRedIcons = $ ".delete-red"

        if keyCode is 27
            if deleteRedIcons.length > 0
                deleteRedIcons.removeClass "delete-red"
            else
                @bindModel null