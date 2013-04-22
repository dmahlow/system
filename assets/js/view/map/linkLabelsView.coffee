# LINK LABELS VIEW
# --------------------------------------------------------------------------
# Represents all editable / dynamic labels available on a [Link View](linkView.html).
# Each link can have only one MapLinkLabelsView, but each MapLinkLabelsView can have up
# to 3 editable labels (start, middle, end).

class SystemApp.MapLinkLabelsView extends SystemApp.BaseView

    currentEditingPosition: null        # holds the position which is being currently edited (Start, Center. End)
    labelEditView: null                 # holds a [Label Edit View](labelEditView.html), used to change label values
    svgStart: null                      # the label on the start of the link path
    svgMiddle: null                     # the label on the middle of the link path
    svgEnd: null                        # the label on the end of the link path
    svgIconStart: null                  # the icon (used if text is empty) on the start of the link path
    svgIconMiddle: null                 # the icon (used if text is empty) on the middle of the link path
    svgIconEnd: null                    # the icon (used if text is empty) on the end of the link path


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the label edit view and set its parent view.
    initialize: =>
        @baseInit()
        @setEvents()

    # Base dispose for links labels.
    dispose: =>
        # Remove all labels and icons from the DOM.
        @svgStart?.remove()
        @svgMiddle?.remove()
        @svgEnd?.remove()
        @svgIconStart?.remove()
        @svgIconMiddle?.remove()
        @svgIconEnd?.remove()

        # Force delete the link view's properties.
        @svgStart = null
        @svgMiddle = null
        @svgEnd = null
        @svgIconStart = null
        @svgIconMiddle = null
        @svgIconEnd = null
        @labelEditView = null

        @baseDispose()

    # Bind event listeners to the view.
    setEvents: =>
        @listenTo SystemApp.mapEvents, "edit:toggle", @toggleEdit
        @listenTo SystemApp.mapEvents, "zoom:in", @onZoom
        @listenTo SystemApp.mapEvents, "zoom:out", @onZoom

        @listenTo @model, "change:foreground", @setAllForeground
        @listenTo @model, "change:fontSize", @setAllFontSizes


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Return an array with all the SVG elements (labels and icons).
    svgs: =>
        return [@svgStart, @svgMiddle, @svgEnd, @svgIconStart, @svgIconMiddle, @svgIconEnd]

    # Return an array with label SVG elements.
    svgsLabels: =>
        return [@svgStart, @svgMiddle, @svgEnd]

    # Return an array with icon SVG elements.
    svgsIcons: =>
        return [@svgIconStart, @svgIconMiddle, @svgIconEnd]


    # RENDER AND POSITIONING
    # ----------------------------------------------------------------------

    # Render all label SVG elements on the map.
    render: (parent, position) =>
        if parent?
            @parentView = parent

        if not position? or position is "Start"
            left = @renderLabel @model.textStart(), @svgStart, @svgIconStart, "Start"
            @svgStart = left[0]
            @svgIconStart = left[1]

        if not position? or position is "Middle"
            center = @renderLabel @model.textMiddle(), @svgMiddle, @svgIconMiddle, "Middle"
            @svgMiddle = center[0]
            @svgIconMiddle = center[1]

        if not position? or position is "End"
            top = @renderLabel @model.textEnd(), @svgEnd, @svgIconEnd, "End"
            @svgEnd = top[0]
            @svgIconEnd = top[1]

        @toggleEdit @parentView.parentView.editEnabled

        @setPosition()
        @onZoom()

        return this

    # Render a single label, passing a value, the target label SVG, and the overlay SVG
    # in case the value is empty. The position tells the location of the label related
    # to its parent [Link View](linkView.html).
    renderLabel: (value, svg, iconSvg, position) =>
        x = 0
        y = 0
        text = value
        iconSize = SystemApp.Settings.Map.icoActionsSize

        # If label has an [AuditData](auditData.html) value bound or if it's an evaluation,
        # then show "..." before binding the values
        text = SystemApp.Settings.AuditData.loadingText if SystemApp.DataUtil.hasDataBindingValue value

        if svg?

            # If there's a label present already, copy its current position and text
            # before recreating it on a new label.
            x = svg.attr "x"
            y = svg.attr "y"
            text = svg.attr "text"

            svg.unclick()
            svg.removeData()
            svg.remove()
            svg = null

        if iconSvg?

            # If there's an icon present already, copy its current position
            # before recreating it on a new icon.
            x = iconSvg.attr "x"
            y = iconSvg.attr "y"

            iconSvg.unclick()
            iconSvg.unmouseover()
            iconSvg.unmouseout()
            iconSvg.removeData()
            iconSvg.remove()
            iconSvg = null

        if value? and value isnt ""

            svg = @parentView.parentView.paper.text 0, 0, text
            svg.attr {"x": x, "y": y, "fill": @parentView.model.foreground(), "font-size": @parentView.model.fontSize()}
            svg.attr {"cursor": "pointer", "text-anchor": "middle"}
            svg.click @click

            $(svg.node).data "labelPosition", position

        else

            iconSvg = @parentView.parentView.paper.image SystemApp.Settings.Map.icoAddLabelUrl, 0, 0, iconSize, iconSize
            iconSvg.attr {"x": x, "y": y, cursor: "pointer", opacity: SystemApp.Settings.Map.icoActionsOpacity}
            iconSvg.click @click
            iconSvg.mouseover @iconMouseOver
            iconSvg.mouseout @iconMouseOut

            $(iconSvg.node).data "labelPosition", position

        return [svg, iconSvg]

    # Show the link labels and icons.
    show: =>
        # Set opacity 1 on all labels.
        opacity = {"opacity": 1}
        svgs = @svgsLabels()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

        # Set the opacity defined on the [Settings](settings.html), on all add label icons.
        opacity = {"opacity": SystemApp.Settings.Map.icoActionsOpacity}
        svgs = @svgsIcons()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Hide the link labels and icons.
    hide: =>
        @currentEditingPosition = null

        opacity = {"opacity": 0}
        svgs = @svgs()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Hide only the icons (where no label text has been defined).
    hideIcons: =>
        opacity = {"opacity": 0}
        svgs = @svgsIcons()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Set the label positions on the map. Please note that if the parent link
    # is not visible then this method will stop immediately.
    setPosition: =>
        iconSize = SystemApp.Settings.Map.icoActionsSize
        iconHalfSize = iconSize / 2

        path = @parentView.svg.svgLine
        lineLength = path.getTotalLength()

        # We need to check if line is long enough! Otherwise add the start and
        # end icons on the very start and very end of the line, without adding the padding
        # of 1.5 times the iconSize.
        if lineLength > iconSize * 2
            startPos = path.getPointAtLength(iconSize + iconHalfSize)
            endPos = path.getPointAtLength(lineLength - iconSize - iconHalfSize)
        else
            startPos = path.getPointAtLength(iconHalfSize)
            endPos = path.getPointAtLength(lineLength - iconHalfSize)

        middlePos = path.getPointAtLength(lineLength / 2)

        # Set label positions.
        @svgStart?.attr startPos
        @svgMiddle?.attr middlePos
        @svgEnd?.attr endPos

        # Recalculate the horizontal and vertical alignments for icons, as the X is related
        # their left offset and not their center point, and Y is their top offset and
        # not their middle.
        startPos.x -= iconHalfSize
        startPos.y -= iconHalfSize
        middlePos.x -= iconHalfSize
        middlePos.y -= iconHalfSize
        endPos.x -= iconHalfSize
        endPos.y -= iconHalfSize

        # Set icon positions.
        @svgIconStart?.attr startPos
        @svgIconMiddle?.attr middlePos
        @svgIconEnd?.attr endPos



    # Bring the labels to the front of the map. Usually called after changing
    # the selected link on the current [Map View](mapView.html).
    toFront: =>
        svgs = @svgs()
        s?.toFront() for s in svgs

    # Bring the labels to the back of the current [Map View](mapView.html).
    toBack: =>
        svgs = @svgs()
        s?.toBack() for s in svgs

    # When user hovers the mouse over an "add label" icon, set its opacity to 1,
    # unless the `isCreatingLink` property of the [Map View](mapView.html) is true.
    iconMouseOver: ->
        return if SystemApp.mapView.isCreatingLink
        @attr {"opacity": 1}

    # When mouse leaves an "add label" icon, set its opacity to the value set on the [Settings](settings.html),
    # unless the `isCreatingLink` property of the [Map View](mapView.html) is true.
    iconMouseOut: ->
        return if SystemApp.mapView.isCreatingLink
        @attr {"opacity": SystemApp.Settings.Map.icoActionsOpacity}

    # When user put map on "Edit Mode", show the label icons. If in locked mode, hide them.
    toggleEdit: (enabled) =>
        svgs = @svgsIcons()

        if enabled
            svg?.show() for svg in svgs
        else
            svg?.hide() for svg in svgs


    # LABEL DATA BINDING
    # ----------------------------------------------------------------------

    # Set the value of the specified label.
    setLabelValue: (svg, value) =>
        if not svg? or not value?
            return

        svg.attr {"text": value}

    # Binds values from [Audit Data items](auditData.html) to
    # the related link labels.
    bindAllLabelsData: =>
        @bindLabelData @svgStart, @model.textStart()
        @bindLabelData @svgMiddle, @model.textMiddle()
        @bindLabelData @svgEnd, @model.textEnd()

    # Get the binding value which can come from an [AuditData](auditData.html) or
    # a [Variable](variable.html) and set it to the specified label.
    bindLabelData: (svg, value) =>
        if not svg?
            return

        newValue = SystemApp.DataUtil.getDataBindingValue value
        @setLabelValue svg, newValue


    # LABEL EDIT
    # ----------------------------------------------------------------------

    # When user clicks a label, check if the "Delete" key modifier is being pressed and
    # proceed with removing the label, or show the textbox for edition (call `showEditLabel`).
    click: (e) =>
        src = $ e.target
        data = src.data "labelPosition"

        if not data? or data is ""
            src = src.parent()
            data = src.data "labelPosition"

        @currentEditingPosition = data

        # Set the current selected element on the [Map View](mapView.html).
        @parentView.parentView.setCurrentElement @parentView

        if @parentView.parentView.editEnabled
            if @isEventDelete e
                @parentView.blinkAndRemove()
            else
                @showEditLabel e

        e.preventDefault()
        e.stopPropagation()

    # Start editing one of the link labels. This will create a temporary textbox on the map where
    # the user can edit or bind values from an [AuditData](auditData.html) to the label text.
    showEditLabel: (e) =>
        if not @labelEditView?
            @labelEditView = new SystemApp.MapLabelEditView()
            @labelEditView.render this
            @labelEditView.on "save", @saveEditLabel

        src = e.target
        src = src.parentElement if not src.getBBox?
        pos = src.getBBox()

        # Make sure text is never undefined or null!
        text = @model.get "text#{@currentEditingPosition}"
        text = "" if not text?

        # We need to remove half the width and height to properly get the center values (and not the offset).
        @labelEditView.show text, pos.x + pos.width / 2, pos.y + pos.height

    # Save the edited value of the [Label Edit View](labelEditView.html) to the
    # `text` property of the model.
    saveEditLabel: (view, value) =>
        @model.set "text#{@currentEditingPosition}", value
        @model.save()
        @parentView.parentView.model.save()

        @render @parentView, @currentEditingPosition

        @bindAllLabelsData()

        @currentEditingPosition = null


    # TEXT SIZE AND ZOOM
    # ----------------------------------------------------------------------

    # When user zooms in or out, check the current zoom level and resize
    # the labels accordingly. Fonts size will increase when zooming out,
    # but won't decrease when zooming in (zoom more than 1).
    onZoom: (e) =>
        if @parentView.parentView.currentZoom < 1
            return

        @setAllFontSizes e

    # Set the foreground color ALL labels.
    setAllForeground: (e) =>
        @setForeground(svg, @parentView.foreground()) for svg in [@svgStart, @svgMiddle, @svgEnd]

    # The the foreground color for the specified label.
    setForeground: (svg, color) =>
        if not svg?
            return

        svg.attr {"fill": color}

    # Set the font size for ALL labels.
    setAllFontSizes: (e) =>
        zoom = 1
        zoom = @parentView.parentView.currentZoom if @parentView.parentView.currentZoom > 1

        fontSize = @model.fontSize() * zoom
        fontSize = Math.round fontSize

        @setFontSize(svg, fontSize) for svg in [@svgStart, @svgMiddle, @svgEnd]

    # The the font size for the specified label. Usually called when user is zooming
    # the map in or out.
    setFontSize: (svg, fontSize) =>
        if not svg?
            return

        svg.attr {"font-size": fontSize}