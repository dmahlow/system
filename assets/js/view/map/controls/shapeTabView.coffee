# MAP CONTROLS: SHAPE DETAILS VIEW
# --------------------------------------------------------------------------
# Represents the "Shape properties" tab inside a [Map Controls View](controlsView.html).

class SystemApp.MapControlsShapeTabView extends SystemApp.BaseView

    currentBoundViews: null # holds the current shape being shown

    # DOM ELEMENTS
    # ----------------------------------------------------------------------

    $topDescription: null           # the "H6" element on top of the tab
    $txtBackground: null            # the "Background" text field
    $txtForeground: null            # the "Label color" text field
    $txtTitleForeground: null       # the "Title color" text field
    $txtStroke: null                # the "Border color" text field
    $selIcon: null                  # the "Icon" select field
    $selStrokeWidth: null           # the "Border width" select field
    $selFontSize: null              # the "Font size" select field
    $selOpacity: null               # the "Opacity" select field
    $selArrowSource: null           # the "Source arrow style" select field
    $selArrowTarget: null           # the "Target arrow style" select field
    $selOpacity: null               # the "Opacity" select field
    $chkIconFull: null              # the "Full size icon" toggle
    $chkRoundedCorners: null        # the "Rounded corners" toggle
    $chkSmoothLink: null            # the "Smooth link" toggle
    $zIndexDiv: null                # the "Stack level/z-index" wrapper
    $butDeleteShape: null           # the "Remove shape" button
    $butConfirmDeleteShape: null    # the "Confirm" button to remove a shape from the map


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Inits the view. Parent will be the [Map Controls View](controlsView.html).
    initialize: (parent) =>
        @baseInit parent
        @setDom()
        @setEvents()
        @bindInitial()

    # Dispose the shape details view control.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map-ctl-tab-shape"

        @$topDescription = @$el.find "h6"

        @$selIcon = $ "#map-ctl-shape-icon"
        @$txtBackground = $ "#map-ctl-shape-background"
        @$txtForeground = $ "#map-ctl-shape-foreground"
        @$txtTitleForeground = $ "#map-ctl-shape-title-foreground"
        @$txtStroke = $ "#map-ctl-shape-stroke"
        @$selStrokeWidth = $ "#map-ctl-shape-strokewidth"
        @$selFontSize = $ "#map-ctl-shape-fontsize"
        @$selOpacity = $ "#map-ctl-shape-opacity"
        @$selArrowSource = $ "#map-ctl-link-arrow-source"
        @$selArrowTarget = $ "#map-ctl-link-arrow-target"
        @$selOpacity = $ "#map-ctl-shape-opacity"
        @$chkIconFull = $ "#map-ctl-shape-icon-full"
        @$chkRoundedCorners = $ "#map-ctl-shape-roundedcorners"
        @$chkSmoothLink = $ "#map-ctl-link-smooth"

        @$zIndexDiv = $ "#map-ctl-shape-zindex"

        @$butDeleteShape = $ "#map-ctl-shape-delete"
        @$butConfirmDeleteShape = $ "#map-ctl-shape-confirmdelete"

        # Set propertyName data on all editable fields.
        @$txtBackground.data "propertyName", "background"
        @$txtForeground.data "propertyName", "foreground"
        @$txtTitleForeground.data "propertyName", "titleForeground"
        @$txtStroke.data "propertyName", "stroke"
        @$selStrokeWidth.data "propertyName", "strokeWidth"
        @$selFontSize.data "propertyName", "fontSize"
        @$selOpacity.data "propertyName", "opacity"
        @$selArrowSource.data "propertyName", "arrowSource"
        @$selArrowTarget.data "propertyName", "arrowTarget"
        @$selIcon.data "propertyName", "icon"
        @$chkIconFull.data "propertyName", "iconFull"
        @$chkRoundedCorners.data "propertyName", "roundedCorners"
        @$chkSmoothLink.data "propertyName", "smooth"

        # Hide editable forms initially.
        @toggleForms false

    # Bind events to DOM and other controls.
    setEvents: =>
        @listenTo SystemApp.mapEvents, "edit:toggle", @setEnabled

        fields = [@$txtBackground, @$txtForeground, @$txtTitleForeground, @$txtStroke]
        for elm in fields
            elm.keyup @editablePropertyKeyUp
            elm.blur @editablePropertySave

        selects = [@$selIcon, @$selStrokeWidth, @$selFontSize, @$selOpacity, @$selArrowSource, @$selArrowTarget,
                   @$chkIconFull, @$chkRoundedCorners, @$chkSmoothLink]
        for elm in selects
            elm.change @editablePropertySave

        @$zIndexDiv.children("div").click @zIndexSave
        @$butDeleteShape.click @deleteShapeClick
        @$butConfirmDeleteShape.click @confirmDeleteShapeClick

        # Disable the "full icon" toggle when no icon is selected.
        @$selIcon.change @selIconChanged

    # Enable or disable editing the current [Shape](shape.html) properties.
    setEnabled: (value) =>
        fields = [@$selIcon, @$txtBackground, @$txtForeground, @$txtTitleForeground, @$txtStroke, @$selStrokeWidth,
                  @$selFontSize, @$selOpacity, @$selArrowSource, @$selArrowTarget,
                  @$chkRoundedCorners, @$chkSmoothLink, @$zIndexDiv, @$butDeleteShape]

        if not value
            elm.attr("disabled", "disabled").addClass("disabled") for elm in fields
        else
            elm.removeAttr("disabled").removeClass("disabled") for elm in fields


    # BINDING AND CLEARING
    # ----------------------------------------------------------------------

    # When the view is first loaded, bind the initial and default values.
    bindInitial: =>
        @$selIcon.append $(document.createElement "option").val("0").text(SystemApp.Messages.noIcon)
        _.each SystemApp.Vectors, (item, key) => @$selIcon.append $(document.createElement "option").val(key).text(key)

    # Bind one or more [Shape Views](shapeView.html) or [Link Views](linkView.html) to the control
    # and display its editable properties. If multiple shapes are bound, show an alert that changes
    # will affect all selected shapes.
    bind: (views) =>
        @currentBoundViews = views

        @$butDeleteShape.removeClass "hidden"

        @bindProperties()
        @resetDeleteShape()

    # Show or hide forms depending on what's selected on the map.
    toggleForms: (visible) =>
        if visible
            @$el.find("h5,.panel").show()
        else
            @$el.find("h5,.panel").hide()
            @$topDescription.text SystemApp.Messages.noShapeSelected
            @$topDescription.show()


    # SHAPE EDITING TAB
    # ----------------------------------------------------------------------

    # Bind all editable properties of the current [Shape](shape.html)
    # or [Link](link.html) to the "Element properties" tab.
    bindProperties: =>
        if @currentBoundViews?

            # If only one view is bound, show its properties, otherwise show empty boxes
            # so user can edit multiple selected elements.
            if @currentBoundViews.model?.id?

                @$topDescription.hide()

                @$txtForeground.val @currentBoundViews.model.foreground()
                @$txtForeground.keyup()
                @$txtStroke.val @currentBoundViews.model.stroke()
                @$txtStroke.keyup()
                @$selStrokeWidth.val @currentBoundViews.model.strokeWidth()
                @$selFontSize.val @currentBoundViews.model.fontSize()
                @$selOpacity.val @currentBoundViews.model.opacity()

                # If the selected item is a shape, then hide all "only-for-links" properties.
                if @currentBoundViews.constructor is SystemApp.MapShapeView
                    @$selIcon.val @currentBoundViews.model.icon()
                    @$txtBackground.val @currentBoundViews.model.background()
                    @$txtBackground.keyup()
                    @$txtTitleForeground.val @currentBoundViews.model.titleForeground()
                    @$txtTitleForeground.keyup()
                    @$chkIconFull.prop "checked", @currentBoundViews.model.iconFull()
                    @$chkRoundedCorners.prop "checked", @currentBoundViews.model.roundedCorners()
                    @$el.find(".only-for-links").hide()
                    @$el.find(".not-for-links").show()
                    @$butDeleteShape.html SystemApp.Messages.removeShape
                # If selected item is a link, then hide all "not-for-links" properties.
                else
                    @$selArrowSource.val @currentBoundViews.model.arrowSource()
                    @$selArrowTarget.val @currentBoundViews.model.arrowTarget()
                    @$chkSmoothLink.prop "checked", @currentBoundViews.model.smooth()
                    @$el.find(".not-for-links").hide()
                    @$el.find(".only-for-links").show()
                    @$butDeleteShape.html SystemApp.Messages.removeLink

                @$zIndexDiv.children("div").removeClass("active").eq(@currentBoundViews.model.zIndex() - 1).addClass "active"

            else

                @$topDescription.text SystemApp.Messages.multipleShapesSelected
                @$topDescription.show()

                @$txtForeground.val()
                @$txtStroke.val()
                @$selStrokeWidth.val()
                @$selFontSize.val()
                @$selOpacity.val()

            # Show all editable panels.
            @toggleForms true

        else

            # No shape(s) selected, so hide panels and show the h6 element with the "no shapes selected text".
            @toggleForms false

    # When user is pressing keys on any of the editable text fields, check for
    # the pressed key and if it's Enter, save the value to the model.
    editablePropertyKeyUp: (e) =>
        if e.keyCode is 13
            @editablePropertySave e
            return

        src = $ e.target
        preview = src.next()

        if preview?.hasClass "preview"
            preview.css "background-color", src.val()

    # When a text field of the editable properties losts focus, changes or gets clicked,
    # saves the new value to the current [Shape](shape.html) model.
    editablePropertySave: (e) =>
        if not @currentBoundViews?
            return

        src = $ e.target
        propertyName = src.data "propertyName"

        if src.attr("type") is "checkbox"
            value = src.prop "checked"
        else
            value = src.val()
            if not isNaN(value)
                # Make sure numeric values are saved as numbers, not string.
                value = parseFloat value

        if value? and value isnt ""
            @currentBoundViews.model.set propertyName, value
            @currentBoundViews.model.save()
            @parentView.model.save()
        else
            src.val @currentBoundViews.model.get propertyName

    # When user selects no icon, disable the "full icon" toggle.
    selIconChanged: =>
        if @$selIcon.val().toString() is "0"
            @$chkIconFull.attr("disabled", "disabled").addClass "disabled"
        else
            @$chkIconFull.removeAttr("disabled").removeClass "disabled"

    # Saves the selected stack lavel (z-index) to the current
    # [Shape](shape.html).
    zIndexSave: (e) =>
        if not @parentView.parentView?.editEnabled
            return

        src = $ e.target
        @$zIndexDiv.children("div").removeClass "active"
        src.addClass "active"

        @currentBoundViews.model.set "zIndex", parseInt src.html()
        @currentBoundViews.model.save()
        @parentView.model.save()

    # Clicks the "Remove shape" button, show the "Confirm" button
    # right next to it so user can confirm the shape removal.
    deleteShapeClick: =>
        $(document).mouseup @resetDeleteShape
        @$butConfirmDeleteShape.removeClass "hidden"

    # User clicks the "Confirm" button, so proceed with shape removal.
    confirmDeleteShapeClick: (e) =>
        @currentBoundViews.blinkAndRemove()
        @resetDeleteShape e

    # Hide the "Confirm" shape removal button if user clicks anywhere on the page
    # while the button is visible, or after user confirms the deletion.
    resetDeleteShape: =>
        $(document).unbind "mouseup", @resetDeleteShape
        @$butConfirmDeleteShape.addClass "hidden"