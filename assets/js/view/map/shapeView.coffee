# SHAPE VIEW
# --------------------------------------------------------------------------
# Represents a shape on the map.

class SystemApp.MapShapeView extends SystemApp.BaseView

    linkViews: null         # holds the temporary link views when moving / editing shapes around
    labelsView: null        # holds the 5 editable / dynamic labels of the shape
    linkCreatorView: null   # holds the link creator view, in case user is linking this shape to another
    svg: null               # the main svg element for this shape
    svgIcon: null           # the custom svg icon / background of the shape
    svgLinker: null         # the svg "link" icon that appears on the center of the shape
    svgResizer: null        # the svg "resize" icon that appears on the bottom right corner of the shape
    svgZIndex: null         # a svg text displaying the current z-index value of the shape
    ox: 0                   # temporary X coordinates
    oy: 0                   # temporary Y coordinates
    ow: 0                   # temporary shape width when resizing
    oh: 0                   # temporary shape height when resizing
    ix: 0                   # initial X coordinates before dragging
    iy: 0                   # initial Y coordinates before dragging
    resizing: false         # is the shape being resized?
    dragging: false         # is the shape dragging?


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Base init for all shapes. Binds a background color change event to itself.
    initialize: =>
        @linkViews = new Object()

        @listenTo SystemApp.mapEvents, "edit:toggle", @toggleEdit
        @listenTo SystemApp.mapEvents, "zoom:set", @onZoom
        @listenTo SystemApp.mapEvents, "zindex:toggle", @toggleZIndexDisplay

        @listenTo @model, "change:background", @setBackground
        @listenTo @model, "change:titleForeground", @setTitleForeground
        @listenTo @model, "change:stroke", @setStroke
        @listenTo @model, "change:strokeWidth", @setStrokeWidth
        @listenTo @model, "change:fontSize", @setFontSize
        @listenTo @model, "change:opacity", @setOpacity
        @listenTo @model, "change:zIndex", @setZIndex
        @listenTo @model, "change:icon", @setIcon
        @listenTo @model, "change:iconFull", @setIconFull
        @listenTo @model, "change:roundedCorners", @setRoundedCorners

        @baseInit()

    # Base dispose for all shapes.
    dispose: =>
        @unhighlight()

        @labelsView?.dispose()
        @linkCreatorView?.dispose()
        @svg?.remove()
        @svgLinker?.remove()
        @svgResizer?.remove()
        @svgZIndex?.remove()
        @svgIcon.remove()

        _.each @linkViews, (view) -> view.removeFromMap()

        @linkCreatorView = null
        @svg = null
        @svgLinker = null
        @svgResizer = null
        @svgZIndex = null
        @svgIcon = null
        @linkViews = null

        @baseDispose()


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Return an array with all the SVG elements for this shape, inluding
    # labels, icons and shadows.
    svgs: =>
        result = [@svg, @svgIcon, @svgLinker, @svgResizer]
        result.push svg for svg in @labelsView.svgs() if @labelsView?

        return result

    # Helper to get the X position on the shape.
    x: =>
        if @model.format() is "circle"
            return @svg.attr "cx"
        else
            return @svg.attr "x"

    # Helper to get the Y position on the shape.
    y: =>
        if @model.format() is "circle"
            return @svg.attr "cy"
        else
            return @svg.attr "y"

    # Helper to get the X and Y of the center / middle of the shape.
    centerPoint: =>
        return {x: @x() + @width() / 2, y: @y() + @height() / 2}

    # Helper to get the Y position on the shape's title.
    titleY: =>
        if @model.format() is "circle"
            return @svgLabel.attr "cy"
        else
            return @svgLabel.attr "y"

    # Helper to get the shape width.
    width: =>
        v = @svg?.attrs.width
        v = @model.sizeX() * @parentView.model.gridSizeX() if v is undefined or v < 1
        return v

    # Helper to get the shape height.
    height: =>
        v = @svg?.attrs.height
        v = @model.sizeY() * @parentView.model.gridSizeY() if v is undefined or v < 1
        return v


    # VIEW UPDATE EVENTS
    # ----------------------------------------------------------------------

    # Get the shape's entity objet ID and set the referenced `entityObjectRef`
    # on its [shape model](shape.html).
    bindEntityObject: =>
        definitionId = @model.entityDefinitionId()
        objectId = @model.entityObjectId()

        entityDef = SystemApp.Data.entities.getByFriendlyId definitionId

        # Stop here if no entity definition is found.
        return if not entityDef?

        # Set the `entityObject` property on the shape model.
        entityObj = entityDef.data().get objectId
        @model.entityObject = entityObj

        SystemApp.consoleLog "MapShapeView.bindEntityObject", "#{definitionId}-#{objectId}", "Shape ID #{@model.id}"

    # Filter the related `mapView` links and set the `tempLinkViews` property.
    setLinkViews: =>
        @linkViews = @parentView.getLinkViewsForShape @model

    # Update the background color of the shape. If `forceValue` is passed, it will override
    # the model's background value.
    setBackground: (item, forceValue) =>
        if forceValue?
            @svg.attr {"fill": forceValue}
        else
            @svg.attr {"fill": @model.background()}

    # Update the border color of the shape. If `forceValue` is passed, it will override
    # the model's stroke value.
    setStroke: (item, forceValue) =>
        if forceValue?
            @svg.attr {"stroke": forceValue}
            @svgIcon.attr {"fill": forceValue}
        else
            @svg.attr {"stroke": @model.stroke()}
            @svgIcon.attr {"fill": @model.stroke()}
            _.delay @strokeUpdatedBackToSelected, SystemApp.Settings.Map.borderUpdatedDelay

    # Update the border width of the shape.
    setStrokeWidth: =>
        @svg.attr {"stroke-width": @model.strokeWidthComputed()}
        @svgLinker.attr @getLinkerPositionAtt(@x(), @y())
        @labelsView.setPosition()
        _.delay @strokeUpdatedBackToSelected, SystemApp.Settings.Map.borderUpdatedDelay

    # Update the font size of the shape labels.
    setFontSize: =>
        zoom = 1
        zoom = @parentView.currentZoom if @parentView.currentZoom > 1

        fontSize = @model.fontSize() * zoom
        fontSize = Math.round fontSize

    # Update the font size of the shape labels.
    setOpacity: =>
        @svg.attr {"fill-opacity": @model.opacity()}

    # Update the zIndex the shape by changing its position under the DOM tree.
    setZIndex: =>
        @parentView.regroupElement this

    # Set the shape's icon, shown on the top left of the shape.
    setIcon: =>
        icon = @model.icon()

        if icon? and icon isnt "" and icon isnt "0"
            @svgIcon.attr {"path": SystemApp.Vectors[icon]}
            @setIconGeometry()
        else
            @svgIcon.attr {"path": ""}

    # Toggle the full size icon ON or OFF. The shape's borders will be hidden
    # and its icon (if there's one) will be resized to the full size.
    setIconFull: =>
        if @model.hasFullIcon()
            @svg.attr {"fill-opacity": 0}
        else
            @svg.attr {"fill-opacity": @model.opacity()}

        @setStrokeWidth()
        @setIconGeometry()

    # Set the shape's corner style (squared if false, rounded if true).
    setRoundedCorners: =>
        if @model.roundedCorners()
            radius = SystemApp.Settings.Map.cornerRadius
        else
            radius = 0

        @svg.attr {"r": radius}

    # When the user changes border details (color or width), the shape will display the
    # new border for a period of time - default 1400ms, set on the
    # [Settings](settings.html) - and if after that period the
    # shape is still selected, then set its border back to the "selected" style
    # by calling the `highlight` method.
    strokeUpdatedBackToSelected: =>
        if @parentView.currentShape?.model.id is @model.id
            @highlight()


    # MOUSE EVENTS
    # ----------------------------------------------------------------------

    # When mouse is over the element, set it as the current hovered shape on the map.
    mouseOver: =>
        if @parentView?
            @parentView.setHoverShape this

    # Cancel the current hovered element on the map when mouse leaves the shape.
    mouseOut: =>
        if @parentView?
            @parentView.setHoverShape null if @parentView.hoverShape is this


    # SHAPE DRAG EVENTS
    # ----------------------------------------------------------------------

    # Set the temporary X and Y variables.
    setTempPosition: =>
        @ox = @x()
        @oy = @y()

    # User has started dragging, only proceed if editEnabled is true.
    dragStart: (x, y, e) =>
        @ix = @x()
        @iy = @y()

        @setLinkViews()
        @parentView.addToSelected this, e.ctrlKey or e.metaKey

        if not @parentView.editEnabled
            return

        # If using the "delete" key / mouse combination, then remove the shape.
        if @isEventDelete e
            @blinkAndRemove()
            return

        # Remove highlight, hide the "link creator" and "add label" icons when dragging the shape.
        @hideWhileDragging()
        @unhighlight()

        # Saves the current position to the `ox` and `oy` variables and set `dragging` to true.
        @setTempPosition()
        @dragging = true

        @svg.animate {"opacity": SystemApp.Settings.Map.opacityDrag}, SystemApp.Settings.Map.opacityInterval

    # When user is dragging a shape, check if it's a new link creation and
    # if not, reset link positions.
    dragMove: (dx, dy) =>
        if not @parentView.editEnabled or not @dragging
            return

        @setPosition @ox + dx * @parentView.currentZoom, @oy + dy * @parentView.currentZoom
        @resetLinks true

    # When user has finished dragging a shape, calculate the current position
    # and snaps the shape to the grid. If user was creating a new link
    # then proceed to `linkCreatorEnd()`. The optional `shadowColor` parameter
    # can be passed to set a custom shadow color of the shape after dragging.
    dragEnd: (e) =>
        if not @parentView.editEnabled
            return

        @svg?.animate {"opacity": @model.opacity()}, SystemApp.Settings.Map.opacityInterval

        # Stop here if `dragging` hasn't be triggered before.
        return if not @dragging

        # Unset `dragging`, save new position and reset links.
        @dragging = false
        pos = @getSnap()
        @setPosition pos.x, pos.y, true
        @resetLinks false

        # If shape moved, readd it to the `selectedShapes` on the map view.
        moved = @ix isnt @x() or @iy isnt @y()
        if not moved and @parentView.countSelectedShapes() > 1 and @parentView.selectedShapes[@model.id]?
            @parentView.removeFromSelected this
        else
            @highlight()

        # Show the "link creator" and "add label" icons again, and repaint the label text shadows.
        @showAfterDragging()

    # Get the correct "snapped" position based on the grid size, and return
    # a position object with an `x` and `y` value.
    getSnap: =>
        x = @x()
        y = @y()

        gridX = @parentView.model.gridSizeX()
        gridY = @parentView.model.gridSizeY()

        snapX = x - (gridX * Math.floor(x / gridX))
        snapY = y - (gridY * Math.floor(y / gridY))

        if snapX > gridX / 2
            snapX = gridX - snapX
        else
            snapX = snapX * -1

        if snapY > gridY / 2
            snapY = gridY - snapY
        else
            snapY = snapY * -1

        return {x: x + snapX, y: y + snapY}


    # SHAPE RESIZE EVENTS
    # ----------------------------------------------------------------------

    # User has started resizing the shape, only proceed if editEnabled is true.
    resizeStart: (x, y, e) =>
        @parentView.addToSelected this, e.ctrlKey or e.metaKey

        if not @parentView.editEnabled
            return

        # If using the "delete" key combination, then remove the shape.
        if @isEventDelete e
            @blinkAndRemove()
            return

        # Saves the current dimensions to the `ow` and `oh` variables and remove shadow.
        @ow = @width()
        @oh = @height()
        @unhighlight()

    # When user is dragging a shape, check if it's a new link creation and
    # if not, reset link positions.
    resizeMove: (dx, dy) =>
        if not @parentView.editEnabled
            return

        w = dx * @parentView.currentZoom + @ow
        h = dy * @parentView.currentZoom + @oh

        minWidth = SystemApp.Settings.Map.minGridSizeBlocks * @parentView.model.gridSizeX()
        minHeight = SystemApp.Settings.Map.minGridSizeBlocks * @parentView.model.gridSizeY()

        w = minWidth if w < minWidth
        h = minHeight if h < minHeight

        @resizing = true
        @setDimensions w, h
        @resetLinks true

    # When user has finished dragging a shape, calculate the current position
    # and snaps the shape to the grid. If user was creating a new link (Shift
    # pressed) then proceed to `linkCreatorEnd()`.
    resizeEnd: =>
        if not @parentView.editEnabled
            return

        if not @resizing
            return

        @resizing = false

        w = @width()
        h = @height()

        gridX = @parentView.model.gridSizeX()
        gridY = @parentView.model.gridSizeY()

        # Calculates the snap position based on grid size of the map.
        snapX = w - (gridX * Math.floor(w / gridX))
        snapY = h - (gridY * Math.floor(h / gridY))

        if snapX > gridX / 2
            snapX = gridX - snapX
        else
            snapX = snapX * -1

        if snapY > gridY / 2
            snapY = gridY - snapY
        else
            snapY = snapY * -1

        @setDimensions w + snapX, h + snapY, true
        @resetLinks false

        _.delay @highlight, SystemApp.Settings.Map.shadowDelay


    # LINKS AND CONNECTIONS
    # ----------------------------------------------------------------------

    # Starts linking two elements when user is holding the "Create" key / mouse combination.
    linkCreatorStart: =>
        if not @parentView.editEnabled
            return

        # Tell the [Map View](mapView.html) that we're creating a new link.
        @parentView.isCreatingLink = true

        @setTempPosition()

        @linkCreatorView = new SystemApp.MapLinkCreatorView {model: new SystemApp.Link {sourceId: @model.id}}
        @linkCreatorView.render this

    # Move the end of the temporary link while moving the mouse.
    # If the mouse goes over another shape, it will call
    # `highlight()` to temporary highlight it.
    linkCreatorMove: (dx, dy) =>
        if not @parentView.editEnabled
            return

        posX = @ox + dx * @parentView.currentZoom
        posY = @oy + dy * @parentView.currentZoom
        pointedShape =  @parentView.hoverShape

        @linkCreatorView.setPosition posX, posY

        if pointedShape is this
            return

        if @linkCreatorView.target isnt pointedShape
            @linkCreatorView.target?.unhighlight()
            @linkCreatorView.target = pointedShape
            @linkCreatorView.target?.highlight SystemApp.Settings.Map.refShadowColor

    # Destroy the temporary link and if a current reference element
    # is highlighted, create and save the new link.
    linkCreatorEnd: (e) =>
        if not @parentView.editEnabled
            return

        # We're done with link creation, set the [Map View](mapView.html) `isCreatingLink` to false.
        @parentView.isCreatingLink = false

        e.stopPropagation()
        e.preventDefault()

        existingLink = @hasLink @linkCreatorView.target
        @linkCreatorSave() if @linkCreatorView?.target isnt null and existingLink is false

        @linkCreatorView?.target?.unhighlight()
        @linkCreatorView?.dispose()
        @linkCreatorView = null

    # Saves the new link to the map.
    linkCreatorSave: =>
        if not @parentView.editEnabled
            return

        @linkCreatorView.model.targetId @linkCreatorView.target.model.id
        @linkCreatorView.model.generateId()

        @parentView.model.links().add @linkCreatorView.model



    # Check if there's a link to the specified shape already,
    # and if so, return the link view.
    hasLink: (shape) =>
        result = false

        if not shape?
            return false

        @setLinkViews()

        _.each @linkViews, (view) =>
            if view.model.sourceId() is shape.model.id or view.model.targetId() is shape.model.id
                result = view

        return result

    # Reset all link positions, this is called when user is dragging shapes around.
    # If `forceVisible` is set to false and the current [Map View](mapView.html)
    # has the "Show links" option set to false, then hide the link. Usually while
    # dragging and moving shapes `forceVisible` will be true, but after dragged/resized
    # it will be false.
    resetLinks: (forceVisible) =>
        forceVisible = true if not forceVisible?

        if @linkViews?.length > 0
            _.each @linkViews, (link) =>
                link.drag()
                link.semiHide() if not forceVisible and not @parentView.isLinksVisible

    # RENDER AND POSITIONING
    # ----------------------------------------------------------------------

    # Render the svg on the [Map View](mapView.html).
    render: (mapView) =>
        iconSize = SystemApp.Settings.Map.icoActionsSize
        iconOpacity = SystemApp.Settings.Map.icoActionsOpacity

        @parentView = mapView if mapView?

        @zIndexHide()

        if not @svg?
            @svg = @parentView.paper.rect 0, 0, @width(), @height(), 0
            @svg.drag @dragMove, @dragStart, @dragEnd
            @bindSvgDefaults @svg
            @setElement @svg

        if not @svgIcon?
            @svgIcon = @parentView.paper.path()
            @svgIcon.drag @dragMove, @dragStart, @dragEnd
            @bindSvgDefaults @svgIcon

        if not @svgLinker?
            @svgLinker = @parentView.paper.image SystemApp.Settings.Map.icoLinkerUrl, 0, 0, iconSize, iconSize
            @svgLinker.drag @linkCreatorMove, @linkCreatorStart, @linkCreatorEnd
            @svgLinker.mouseover @linkerMouseOver
            @svgLinker.mouseout @linkerMouseOut
            @bindSvgDefaults @svgLinker

        if not @svgResizer?
            @svgResizer = @parentView.paper.image SystemApp.Settings.Map.icoResizeUrl, 0, 0, iconSize, iconSize
            @svgResizer.drag @resizeMove, @resizeStart, @resizeEnd
            @bindSvgDefaults @svgResizer

        if not @labelsView?
            @labelsView = new SystemApp.MapShapeLabelsView(model: @model)

        @svg.attr {"fill": @model.background(), "stroke": @model.stroke(), "stroke-width": @model.strokeWidthComputed()}
        @svg.attr {"fill-opacity": @model.opacity(), "cursor": "move"}
        @svgIcon.attr {"cursor": "pointer", "fill": @model.stroke(), "stroke": "none"}
        @svgLinker.attr {"cursor": "pointer", "title": SystemApp.Messages.tooltipLinker, "opacity": iconOpacity}
        @svgResizer.attr {"cursor": "nw-resize", "title": SystemApp.Messages.tooltipResize}

        @labelsView.render this

        @toggleEdit @parentView.editEnabled
        @setIcon()
        @setRoundedCorners()

        return this

    # Remove the shape from the map and dispose its contents.
    removeFromMap: =>
        @setLinkViews()
        @dispose()
        @model.destroy()

    # Blink and remove the shape (so the user gets the attention of what's being removed).
    blinkAndRemove: =>
        @svg.undrag()
        @blink 2, @removeFromMap

    # Bind defaults (data and events) to the shape's SVG element(s).
    bindSvgDefaults: (svg) =>
        svg.data "viewRef", this
        svg.mouseover @mouseOver
        svg.mouseout @mouseOut

    # Show the shape on the map (set opacity to the model's defined opacity).
    show: (interval) =>
        if not @svg?
            return

        interval = SystemApp.Settings.Map.blinkInterval if not interval?

        bgOpacity = {"opacity": @model.opacity()}
        opacity = {"opacity": 1}

        @svg.animate bgOpacity, interval
        @svgIcon.animate bgOpacity, interval
        @svgLinker.animate opacity, interval
        @svgResizer.animate opacity, interval

    # Show the "add link" icon and the labels inside the [Shape Labels View](shapeLabelsView.html),
    # and repaint the label text shadows.
    showAfterDragging: =>
        @svgLinker.show()
        @labelsView.show()

    # Hide the shape on the map (set opacity to 0). If no interval is set, it will use
    # the default blinkInterval from the [Settings](settings.html).
    hide: (interval) =>
        if not @svg?
            return

        interval = SystemApp.Settings.Map.blinkInterval if not interval?

        opacity = {"opacity": 0}
        @svg.animate opacity, interval
        @svgIcon.animate opacity, interval
        @svgLinker.animate opacity, interval
        @svgResizer.animate opacity, interval

    # Hide the "add link" icon and the labels inside the [Shape Labels View](shapeLabelsView.html),
    # and remove the label shadows.
    hideWhileDragging: =>
        @svgLinker.hide()
        @labelsView.hideIcons()

    # Set the shape absolute dimensions passing the width and height, and set the relative grid
    # dimensions based on the current [Map](map.html) `gridSizeX` and `gridSizeY`.
    # If `save` is true, it will save the new shape dimensions to the current map.
    setDimensions: (w, h, save) =>
        @svg.attr { width: w, height: h }

        @model.sizeX Math.round(w / @parentView.model.gridSizeX())
        @model.sizeY Math.round(h / @parentView.model.gridSizeY())

        @setPosition()

        if save
            @model.save()
            @parentView.model.save()

    # Reset the shape dimensions based on current values. This is usually
    # called when the user changes the current [Map](map.html) `gridSizeX` or `gridSizeY`.
    resetDimensions: =>
        @svg.attr "x", @model.x() * @parentView.model.gridSizeX()
        @svg.attr "y", @model.y() * @parentView.model.gridSizeY()

        w = @model.sizeX() * @parentView.model.gridSizeX()
        h = @model.sizeY() * @parentView.model.gridSizeY()

        @setDimensions w, h

    # Set the shape position on the map. If `save` is true, it will save
    # the new shape position to the current map.
    # If no parameters are passed (for example, the call inside `setDimensions`)
    # it will use the current `x` and `y` values.
    setPosition: (posX, posY, save) =>
        posX = @x() if not posX?
        posY = @y() if not posY?

        maximumX = @parentView.model.paperSizeX() - @width()
        maximumY = @parentView.model.paperSizeY() - @height()

        if posX < 0
            posX = 0
        else if posX > maximumX
            posX = maximumX

        if posY < 0
            posY = 0
        else if posY > maximumY
            posY = maximumY

        @svg.attr @getBoxPositionAtt posX, posY
        @svgLinker.attr @getLinkerPositionAtt posX, posY
        @svgResizer.attr @getResizerPositionAtt posX, posY
        @svgZIndex?.attr @getZIndexLabelPositionAtt posX, posY
        @labelsView.setPosition posX, posY

        @setIconGeometry posX, posY

        @model.x posX / @parentView.model.gridSizeX()
        @model.y posY / @parentView.model.gridSizeY()

        if save
            @resetLinks false
            @model.save()
            @parentView.model.save()
            @svg.paper.safari()

    # Set the positon and scale of the shape's icon. The values depend
    # if shape is in `fullSizeIcon`.
    setIconGeometry: (posX, posY) =>
        if @model.hasFullIcon()
            posX = @x() if not posX?
            posY = @y() if not posY?
            scaleW = ((@width() - 2) / @svgIcon.getBBox(true).width).toFixed(2)
            scaleH = ((@height() - 2) / @svgIcon.getBBox(true).height).toFixed(2)
            iconX = posX - 16 + @width() / 2
            iconY = posY - 18 + @height() / 2
        else
            posX = @x() if not posX?
            posY = @y() if not posY?
            scaleW = 0.6
            scaleH = 0.6
            iconX = posX - 8
            iconY = posY - 26

        @svgIcon.transform "T#{iconX},#{iconY}S#{scaleW},#{scaleH}"

    # Get the box position attribute based on the X and Y values.
    getBoxPositionAtt: (posX, posY) =>
        if @model.format() is "circle"
            return { cx: posX, cy: posY }
        else
            return { x: posX, y: posY }

    # Get the title text position attribute based on the X and Y values.
    # Should be at the very top of the shape.
    getTitlePositionAtt: (posX, posY) =>
        posX += @width() / 2 - 1
        posY -= SystemApp.Settings.Map.titleOffsetY
        return { x: posX, y: posY }

    # Get the link creator circle position attribute based on the X and Y values.
    # Should be around the right-middle center of the shape.
    getLinkerPositionAtt: (posX, posY) =>
        posX += @width() - @model.strokeWidthComputed() - SystemApp.Settings.Map.icoActionsSize
        posY += @model.strokeWidthComputed()
        return { x: posX, y: posY }

    # Get the "z-index identifier" text position. This SVG element is shown
    # when user clicks the "Identify z-index" button on the [map options](mapOptionsView.html).
    getZIndexLabelPositionAtt: (posX, posY) =>
        posX += @width() / 2
        posY += @height() / 2
        return { x: posX, y: posY }

    # Get the image resizer position attribute based on the X and Y values.
    # Should be the bottom right corner of the shape.
    getResizerPositionAtt: (posX, posY) =>
        posX += @width() - SystemApp.Settings.Map.icoActionsSize
        posY += @height() - SystemApp.Settings.Map.icoActionsSize
        return { x: posX, y: posY }

    # Bring the shape and its associated elements (title, label, etc) to front.
    # If `saveZIndex` is true, it will reorder and save the current [Map](map.html) shape collection.
    toFront: (saveZIndex) =>
        @svg.toFront()
        @svgIcon.toFront()
        @svgLinker.toFront()
        @svgResizer.toFront()
        @labelsView.toFront()

        if saveZIndex? and saveZIndex
            @parentView.model.shapes().remove(@parentView.model.shapes().get(@model.id), {silent: true})
            @parentView.model.shapes().push(@model, {silent: true})
            @parentView.model.save()

    # Send the shape and its associated elements (title, label, etc) to back.
    # If `saveZIndex` is true, it will reorder and save the current [Map](map.html) shape collection.
    toBack: (saveZIndex) =>
        @labelsView.toBack()
        @svgResizer.toBack()
        @svgLinker.toBack()
        @svgIcon.toBack()
        @svg.toBack()

        @parentView.toBack()

        if saveZIndex? and saveZIndex
            @parentView.model.shapes().remove(@parentView.model.shapes().get(@model.id), {silent: true})
            @parentView.model.shapes().unshift(@model, {silent: true})
            @parentView.model.save()

    # When user put map on "Edit Mode", show the resizer icon and the link creator circle.
    # If in locked mode, hide them.
    toggleEdit: (enabled) =>
        if enabled
            @svgLinker.show()
            @svgResizer.show()
        else
            @svgLinker.hide()
            @svgResizer.hide()

    # When user zooms in or out, resize the shape title accordingly.
    onZoom: =>
        @setFontSize()

    # Toggles the text showing the z-index (stack level) of the shape, represented
    # by the element `svgZIndex`. If the parameter ``visible`` is not passed, then
    # assume it is "true".
    toggleZIndexDisplay: (visible) =>
        visible = true if not visible?

        if visible
            @zIndexShow()
        else
            @zIndexHide()

    # Show the z-index (stack level) of the shape.
    zIndexShow: =>
        if not @svgZIndex?
            @svgZIndex = @parentView.paper.text 0, 0, @model.zIndex()
            @svgZIndex.insertAfter @svgResizer
        else
            @svgZIndex.attr {"text": @model.zIndex()}

        pos = @getZIndexLabelPositionAtt @x(), @y()

        @svgZIndex.attr pos
        @svgZIndex.attr {"fill": @model.background(), "stroke": @model.stroke(), "font-size": @model.sizeY() * 13}

        @svg.mousedown

    # Hide the z-index (stack level) of the shape.
    zIndexHide: =>
        if not @svgZIndex?
            return

        @svgZIndex.remove()
        @svgZIndex = null


    # HIGHLIGHT AND SHADOW
    # ----------------------------------------------------------------------

    # When user hovers the mouse over an "linker" icon, set its opacity to 1.
    linkerMouseOver: =>
        @svgLinker?.attr {"opacity": 1}

    # When mouse leaves an "linker" icon, set its opacity to the value set on the [Settings](settings.html).
    linkerMouseOut: =>
        @svgLinker?.attr {"opacity": SystemApp.Settings.Map.icoActionsOpacity}

    # Create a shadow behind the shape, with optional color and strength.
    highlight: (color, strength) =>
        color = SystemApp.Settings.Map.shadowColor if not color?
        strength = SystemApp.Settings.Map.shadowStrength if not strength?

        @svg.attr {"stroke": color, "stroke-width": strength}

    # Remove the shadow from the shape (if there's one present).
    unhighlight: =>
        @svg?.attr {"stroke": @model.stroke(), "stroke-width": @model.strokeWidthComputed()}

    # Blink the entire shape with optional amount of times (default is 2). This is a recursive function.
    # If times is 1 and the `callback` is specified, call it when it has finished blinking.
    blink: (times, callback) =>
        times = 2 if not times? or times is ""
        extraMs = 15

        @hide()
        _.delay(@show, SystemApp.Settings.Map.blinkInterval + extraMs)
        _.delay(@blink, SystemApp.Settings.Map.blinkInterval * 2 + extraMs * 2, times - 1, callback) if times > 1
        _.delay(callback, SystemApp.Settings.Map.blinkInterval * 2 + extraMs * 4) if times is 1 and callback?

    # Slowly blink the entire shape with optional amount of times (default is 2). This is a recursive function.
    # If times is 1 and the `callback` is specified, call it when it has finished blinking.
    slowBlink: (times, callback) =>
        times = 2 if not times? or times is ""

        @hide(SystemApp.Settings.Map.blinkSlowInterval)
        _.delay(@show, SystemApp.Settings.Map.blinkSlowInterval, SystemApp.Settings.Map.blinkSlowInterval)
        _.delay(@slowBlink, SystemApp.Settings.Map.blinkSlowInterval * 2, times - 1, callback) if times > 1
        _.delay(callback, SystemApp.Settings.Map.blinkSlowInterval * 3) if times is 1 and callback?