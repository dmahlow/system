# SHAPE LABELS VIEW
# --------------------------------------------------------------------------
# Represents all editable / dynamic labels available on a [Shape View](shapeView.html).
# Each shape can have only one MapShapeLabelsView, but each MapShapeLabelsView can have up
# to 5 editable labels (left, top, right, bottom, center).

class SystemApp.MapShapeLabelsView extends SystemApp.BaseView

    visible: true                       # cached variable to check if labels are visible or hidden
    currentEditingPosition: null        # holds the position which is being currently edited by the user
                                        # (Title, Center, Left. Top, Right, Bottom)
    labelEditView: null                 # holds a [Label Edit View](labelEditView.html), used to change label values
    svgTitle: null                      # the title svg editable label element
    svgCenter: null                     # the central svg editable label element
    svgLeft: null                       # the left svg editable label element
    svgTop: null                        # the top editable label element
    svgRight: null                      # the right svg editable label element
    svgBottom: null                     # the bottom svg editable label element
    svgIconTitle: null                  # the title svg label icon element
    svgIconCenter: null                 # the central svg label icon element
    svgIconLeft: null                   # the left svg label icon element
    svgIconTop: null                    # the top label icon element
    svgIconRight: null                  # the right svg label icon element
    svgIconBottom: null                 # the bottom svg label icon element
    currentTextTitle: null              # holds the current text of the title, used for performance opts
    currentTextCenter: null              # holds the current text of the center label, used for performance opts
    currentTextLeft: null               # holds the current text of the left label, used for performance opts
    currentTextTop: null                # holds the current text of the top label, used for performance opts
    currentTextRight: null              # holds the current text of the right label, used for performance opts
    currentTextBottom: null             # holds the current text of the bottom label, used for performance opts
    activeAuditEvents: null             # object containing all (if any!) [Audit Events](auditEvent.html)
                                        # which triggered actions on the [Shape View](shapeView.html)


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the label edit view and set its parent view.
    initialize: =>
        @baseInit()
        @setEvents()
        @activeAuditEvents = {}

    # Base dispose for all shapes.
    dispose: =>
        @svgTitle?.remove()
        @svgCenter?.remove()
        @svgLeft?.remove()
        @svgTop?.remove()
        @svgRight?.remove()
        @svgBottom?.remove()
        @svgIconTitle?.remove()
        @svgIconCenter?.remove()
        @svgIconLeft?.remove()
        @svgIconTop?.remove()
        @svgIconRight?.remove()
        @svgIconBottom?.remove()
        @labelEditView?.dispose()

        # Set all SVG elements to null.
        @svgTitle = null
        @svgCenter = null
        @svgLeft = null
        @svgTop = null
        @svgRight = null
        @svgBottom = null
        @svgIconTitle = null
        @svgIconCenter = null
        @svgIconLeft = null
        @svgIconTop = null
        @svgIconRight = null
        @svgIconBottom = null
        @labelEditView = null
        @activeAuditEvents = null
        @mapView = null

        @baseDispose()

    # Bind event listeners to the view.
    setEvents: =>
        @listenTo SystemApp.mapEvents, "edit:toggle", @toggleEdit
        @listenTo SystemApp.mapEvents, "zoom:set", @onZoom

        @listenTo @model, "change:titleForeground", @setTitleForeground
        @listenTo @model, "change:foreground", @setAllForeground
        @listenTo @model, "change:fontSize", @setAllFontSizes


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Return an array with all the SVG elements (labels and icons).
    svgs: =>
        return [@svgTitle, @svgCenter, @svgLeft, @svgTop, @svgRight, @svgBottom,
                @svgIconTitle, @svgIconCenter, @svgIconLeft, @svgIconTop, @svgIconRight, @svgIconBottom]

    # Return an array with label SVG elements.
    svgsLabels: =>
        return [@svgTitle, @svgCenter, @svgLeft, @svgTop, @svgRight, @svgBottom]

    # Return an array with icon SVG elements.
    svgsIcons: =>
        return [@svgIconTitle, @svgIconCenter, @svgIconLeft, @svgIconTop, @svgIconRight, @svgIconBottom]

    # Get the shape title value. This will check if the [map view](mapView.html) has any
    # value set for `overrideShapeTitle`. If it doesn't, use the default value set on
    # the model's `textTitle`.
    getTitleValue: =>
        if @mapView.overrideShapeTitle? and @mapView.overrideShapeTitle isnt ""
            return @mapView.overrideShapeTitle
        else
            return @model.textTitle()


    # RENDER AND POSITIONING
    # ----------------------------------------------------------------------

    # Render all label SVG elements on the map.
    render: (parent, position) =>
        if parent?
            @parentView = parent
            @mapView = parent.parentView

        if not position?
            renderAll = true
        else
            renderAll = false

        # Title might have its value overriden by the selected "Shape's title" on the map controls.
        if renderAll or position is "Title"
            title = @renderLabel @getTitleValue(), @svgTitle, @svgIconTitle, "Title"
            @svgTitle = title[0]
            @svgIconTitle = title[1]

        if renderAll or position is "Center"
            center = @renderLabel @model.textCenter(), @svgCenter, @svgIconCenter, "Center"
            @svgCenter = center[0]
            @svgIconCenter = center[1]

        if renderAll or position is "Left"
            left = @renderLabel @model.textLeft(), @svgLeft, @svgIconLeft, "Left"
            @svgLeft = left[0]
            @svgIconLeft = left[1]

        if renderAll or position is "Top"
            top = @renderLabel @model.textTop(), @svgTop, @svgIconTop, "Top"
            @svgTop = top[0]
            @svgIconTop = top[1]

        if renderAll or position is "Right"
            right = @renderLabel @model.textRight(), @svgRight, @svgIconRight, "Right"
            @svgRight = right[0]
            @svgIconRight = right[1]

        if renderAll or position is "Bottom"
            bottom = @renderLabel @model.textBottom(), @svgBottom, @svgIconBottom, "Bottom"
            @svgBottom = bottom[0]
            @svgIconBottom = bottom[1]

        @toggleEdit @mapView.editEnabled

        @setPosition()

        return this

    # Render a single label, passing a value, the target label SVG, and the overlay SVG
    # in case the value is empty. The position tells the location of the label related
    # to its parent [Shape View](shapeView.html).
    renderLabel: (value, svg, iconSvg, position) =>
        x = 0
        y = 0
        text = value
        iconSize = SystemApp.Settings.Map.icoActionsSize

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

            if position is "Title"
                foreground = @model.titleForeground()
            else
                foreground = @model.foreground()

            if position is "Left"
                textAnchor = "start"
            else if position is "Right"
                textAnchor = "end"
            else
                textAnchor = "middle"

            svg = @mapView.paper.text 0, 0, text
            svg.attr {"x": x, "y": y, "fill": foreground, "font-size": @model.fontSize()}
            svg.attr {"cursor": "pointer", "text-anchor": textAnchor}
            svg.click @click

            $(svg.node).data "labelPosition", position
            @parentView.bindSvgDefaults svg

        else

            iconSvg = @mapView.paper.image SystemApp.Settings.Map.icoAddLabelUrl, 0, 0, iconSize, iconSize
            iconSvg.attr {"x": x, "y": y, cursor: "pointer", opacity: SystemApp.Settings.Map.icoActionsOpacity}
            iconSvg.click @click
            iconSvg.mouseover @iconMouseOver
            iconSvg.mouseout @iconMouseOut

            $(iconSvg.node).data "labelPosition", position
            @parentView.bindSvgDefaults iconSvg

        return [svg, iconSvg]

    # Show the shape labels and icons.
    show: =>
        @visible = true

        # Set opacity 1 on all labels.
        opacity = {"opacity": 1}
        svgs = @svgsLabels()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

        # Set the opacity defined on the [Settings](settings.html), on all add label icons.
        opacity = {"opacity": SystemApp.Settings.Map.icoActionsOpacity}
        svgs = @svgsIcons()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Hide the shape labels and icons.
    hide: =>
        @visible = false
        @currentEditingPosition = null

        opacity = {"opacity": 0}
        svgs = @svgs()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Hide only the icons (where no label text has been defined).
    hideIcons: =>
        opacity = {"opacity": 0}
        svgs = @svgsIcons()
        s?.animate(opacity, SystemApp.Settings.Map.blinkInterval) for s in svgs

    # Set the label positions on the map, based on the specified left `posX`
    # and top `posY` parameters. Please note that if the labels are not visible
    # then this method will stop immediately.
    setPosition: (posX, posY) =>
        if not @visible
            return

        posX = @parentView.x() if not posX?
        posY = @parentView.y() if not posY?

        parentWidth = @parentView.width()
        parentHeight = @parentView.height()
        iconSize = SystemApp.Settings.Map.icoActionsSize
        iconHalfSize = iconSize / 2
        border = @model.strokeWidth() + SystemApp.Settings.Map.labelPadding

        # Set default positioning objects.
        title = {"x": posX + parentWidth / 2, "y": posY - iconHalfSize}
        center = {"x": posX + parentWidth / 2, "y": posY + parentHeight / 2}
        left = {"x": posX + border + 2, "y": posY + parentHeight / 2}
        top = {"x": posX + parentWidth / 2, "y": posY + iconHalfSize + border}
        right = {"x": posX + parentWidth - border - 2, "y": posY + parentHeight / 2}
        bottom = {"x": posX + parentWidth / 2, "y": posY + parentHeight - iconHalfSize - border}

        # Set label positions.
        @svgTitle?.attr title
        @svgCenter?.attr center
        @svgLeft?.attr left
        @svgTop?.attr top
        @svgRight?.attr right
        @svgBottom?.attr bottom

        # Recalculate the horizontal and vertical alignments for icons, as the X is related
        # their left offset and not their center point, and Y is their top offset and
        # not their middle.
        title.x -= iconHalfSize
        title.y -= iconHalfSize
        center.x -= iconHalfSize
        center.y -= iconHalfSize
        left.y -= iconHalfSize
        top.x -= iconHalfSize
        top.y -= iconHalfSize
        right.x -= iconSize
        right.y -= iconHalfSize
        bottom.x -= iconHalfSize
        bottom.y -= iconHalfSize

        # Set icon positions.
        @svgIconTitle?.attr title
        @svgIconCenter?.attr center
        @svgIconLeft?.attr left
        @svgIconTop?.attr top
        @svgIconRight?.attr right
        @svgIconBottom?.attr bottom

    # Bring the labels to the front of the map. Usually called after changing
    # the selected shape on the current [Map View](mapView.html).
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
        return if not svg?

        # Do not bind undefined values!
        value = "" if value is "undefined"

        if svg is @svgTitle
            changed = (value isnt @currentTextTitle)
            @currentTextTitle = value
        if svg is @svgCenter
            changed = (value isnt @currentTextCenter)
            @currentTextCenter = value
        if svg is @svgLeft
            changed = (value isnt @currentTextLeft)
            @currentTextLeft = value
        if svg is @svgTop
            changed = (value isnt @currentTextTop)
            @currentTextTop = value
        if svg is @svgRight
            changed = (value isnt @currentTextRight)
            @currentTextRight = value
        if svg is @svgBottom
            changed = (value isnt @currentTextBottom)
            @currentTextBottom = value

        # Only update value if text has changed!
        svg.attr {"text": value} if changed

    # Refresh the shape's title. This is mainly called when user selects a "Shape's title" option
    # on the map controls, so it will override the title displayed on top of the shapes.
    refreshTitle: =>
        @bindLabelData @svgTitle, @getTitleValue()

    # Binds values from [Audit Data items](auditData.html) and [Variables](variable.html) to
    # the related shape labels, and then check for any matching [Audit Events](auditEvent.html).
    bindAllLabelsData: =>
        @bindLabelData @svgTitle, @getTitleValue()
        @bindLabelData @svgCenter, @model.textCenter()
        @bindLabelData @svgLeft, @model.textLeft()
        @bindLabelData @svgTop, @model.textTop()
        @bindLabelData @svgRight, @model.textRight()
        @bindLabelData @svgBottom, @model.textBottom()

        @checkAuditEvents()

    # Get the binding value which can come from an [AuditData](auditData.html) or
    # a [Variable](variable.html) and set it to the specified label.
    bindLabelData: (svg, value) =>
        return if not svg?

        if not value? or value is ""
            newValue = ""
        else
            newValue = SystemApp.DataUtil.getDataBindingValue value, @parentView

        @setLabelValue svg, newValue


    # AUDIT ALERTS
    # ----------------------------------------------------------------------

    # Check if the [Shape](shape.html) has any [Audit Events](auditEvent.html) attached,
    # and if so, run these alerts.
    checkAuditEvents: =>
        eventIds = @model.auditEventIds()

        if eventIds? and eventIds.length > 0
            @testAuditEvent SystemApp.Data.auditEvents.get(id) for id in eventIds

    # Test a single [AuditEvent](auditEvent.html) against the shape's labels.
    testAuditEvent: (auditEvent) =>
        return if not auditEvent?

        labelValues =
            center: @svgCenter?.attr("text")
            left: @svgLeft?.attr("text")
            top: @svgTop?.attr("text")
            right: @svgRight?.attr("text")
            bottom: @svgBottom?.attr("text")
            title: @svgTitle?.attr("text")

        matchedRules = auditEvent.run labelValues

        # If rules were matched, run all [Alert Actions](eventAction.html) and
        # bind the nevessary `clear` events.
        if matchedRules.length > 0
            @activeAuditEvents[auditEvent.id] = auditEvent
            @runEventAction auditEvent, eventAction for eventAction in auditEvent.actions().models
        else
            @clearAuditEvent auditEvent

    # When an [Audit ALert](auditEvent.html) has triggered an [Action](eventAction.html),
    # call this to change the [Shape View](shapeView.html) appearance.
    runEventAction: (event, action) =>
        SystemApp.consoleLog "MapShapeLabelsView.runEventAction", "Audit Event " + event.friendlyId(), action.toString()

        switch action.actionType()
            when "blink"
                value = action.actionValue()
                value = SystemApp.Settings.AuditEvent.blinkTimes if not value? or value is ""
                @parentView.slowBlink value
            when "colorBg"
                value = action.actionValue()
                value = SystemApp.Settings.AuditEvent.defaultColor if not value? or value is ""
                @parentView.setBackground this, value
            when "colorBorder"
                value = action.actionValue()
                value = SystemApp.Settings.AuditEvent.defaultColor if not value? or value is ""
                @parentView.setStroke this, value

    # When an [AuditEvent](auditEvent.html) is not active anymore, clear it from the current
    # view and reset the shape's original appearance, but ONLY if no other alerts with similar
    # [Actions](eventAction.html) are enabled.
    clearAuditEvent: (auditEvent) =>
        if not @activeAuditEvents[auditEvent.id]?
            return

        colorBgCount = 0
        colorBorderCount = 0

        # Count how many actions of each type we have on the active [Audit Events](auditEvent.html).
        _.each @activeAuditEvents, (itemAlert) =>
            if itemAlert.id isnt auditEvent.id
                _.each itemAlert.actions(), (itemAction) =>
                    if itemAction.actionType() is "colorBg"
                        colorBgCount++
                    else if itemAction.actionType() is "colorBorder"
                        colorBorderCount++

        # Only reset parameters when no other actions are changing the [Shape View](shapeView.html)
        # appearance. For example if this alert has a `colorBg` action, but another active alert
        # also has, then do not clear the background.
        _.each auditEvent.actions().models, (action) =>
            switch action.actionType()
                when "colorBg"
                    @parentView.setBackground() if colorBgCount < 1
                when "colorBorder"
                    @parentView.setStroke() if colorBorderCount < 1

        delete @activeAuditEvents[auditEvent.id]


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
        @mapView.setCurrentElement @parentView

        if @mapView.editEnabled
            if @isEventDelete e
                @parentView.blinkAndRemove()
            else
                @showEditLabel e

        e.preventDefault()
        e.stopPropagation()

    # Start editing one of the shape labels. This will create a temporary textbox on the map where
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
        @mapView.model.save()

        @render @parentView, @currentEditingPosition
        @bindAllLabelsData()

        @currentEditingPosition = null


    # TEXT SIZE AND ZOOM
    # ----------------------------------------------------------------------

    # When user zooms in or out, resize the labels accordingly.
    onZoom: =>
        @setAllFontSizes()

    # The the foreground color for the specified label.
    setForeground: (svg, color) =>
        svg?.attr {"fill": color}

    # The the font size for the specified label. Usually called when user is zooming
    # the map in or out.
    setFontSize: (svg, fontSize) =>
        svg?.attr {"font-size": fontSize}

    # The the foreground color for the title label.
    setTitleForeground: =>
        @setForeground @svgTitle, @model.titleForeground()

    # Set the foreground color all labels except the title.
    setAllForeground: =>
        @setForeground svg, @model.foreground() for svg in [@svgCenter, @svgLeft, @svgTop, @svgRight, @svgBottom]

    # Set the font size for ALL labels.
    setAllFontSizes: =>
        zoom = 1
        zoom = @mapView.currentZoom if @mapView.currentZoom > 1

        fontSize = @model.fontSize() * zoom
        fontSize = Math.round fontSize

        @setFontSize(svg, fontSize) for svg in [@svgTitle, @svgCenter, @svgLeft, @svgTop, @svgRight, @svgBottom]