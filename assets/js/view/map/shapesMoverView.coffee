# SHAPES MOVER VIEW
# --------------------------------------------------------------------------
# Overlay that is shown whenever the user is selecting and moving multiple shapes on the map.

class SystemApp.MapShapesMoverView extends SystemApp.BaseView

    svg: null           # the main SVG rectangle
    svgCount: null      # the SVG count / text
    shapeViews: null    # array containing all shape views being moved
    ox: 0               # temporary X coordinates
    oy: 0               # temporary Y coordinates


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the label edit view and set its parent view.
    initialize: (parent) =>
        @baseInit parent


    # Base dispose for all shapes.
    dispose: =>
        @remove()
        @baseDispose()


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get the X position on the rectangle.
    x: =>
        return @svg.attr "x"

    # Helper to get the Y position on the rectangle.
    y: =>
        return @svg.attr "y"

    # Helper to get the X position on the rectangle.
    width: =>
        return @svg.attr "width"

    # Helper to get the Y position on the rectangle.
    height: =>
        return @svg.attr "height"


    # RENDER AND BIND
    # ----------------------------------------------------------------------

    # Render the shapes mover rectangle on the specified parent [Map View](mapView.html).
    render: =>
        @hide()
        @remove()

        @svg = @parentView.paper.rect(0, 0, 0, 0, 0)
        @svg.attr {"fill": SystemApp.Settings.MapMover.background, "opacity": 0, "cursor": "move"}

        @setElement @svg

        return this

    # Remove the element from the document and set `svg` to null.
    remove: =>
        if @svg?
            try
                @svg.undrag()
                @svg.remove()
            catch ex
                console.error "MapShapesMoverView.remove", "Could not remove element, maybe it was already cleared?", ex

        @svg = null

    # Show the view on the specified `x` and `y` position.
    # Will set the opacity to the value defined on the [Settings](settings.html).
    show: (x, y) =>
        @ox = x
        @oy = y - 30

        @setSize 1, 1
        @setPosition x, y

        @svg.attr {"opacity": SystemApp.Settings.MapMover.opacity}
        @svg.toFront()

        $(document).mousemove @mouseMoveResize
        $(document).mouseup @mouseUpResize
        $(document).keyup @documentKeyUp

    # Hide the view (user has finished moving, or pressed the "Esc" key).
    # This will also force removing the selected [Shape Views](shapeView.html)
    # shadows and unbind mouse and keyboard events.
    hide: =>
        if @svg?
            @svg.undrag()
            @svg.toBack()
            @svg.attr {"opacity": 0}
            @setSize 0, 0

        if @shapeViews?.length > 0
            @parentView.model.save()
            view.unhighlight() for view in @shapeViews

        @shapeViews = null

        $(document).off "mousemove", @mouseMoveResize
        $(document).off "mouseup", @mouseUpResize
        $(document).off "keyup", @documentKeyUp

    # Stop resizing and select all elements inside the selected area.
    selectShapes: =>
        @shapeViews = []

        _.each @parentView.shapeViews, (view) =>
            shapeCenter = view.centerPoint()
            box = @svg.getBBox()

            if Raphael.isPointInsideBBox box, shapeCenter.x, shapeCenter.y
                @shapeViews.push view
                view.highlight SystemApp.Settings.MapMover.shadowColor

        # If shapes were selected then set the drag handlers, otherwise hide the rectangle.
        if @shapeViews.length > 0
            @setDrag()
        else
            @hide()

    # When user presses a key while the map mover view is visible.
    # Pressing "Esc" will hide the view.
    documentKeyUp: (e) =>
        if e.which is 27
            @hide()


    # RESIZING AND POSITIONING
    # ----------------------------------------------------------------------

    # Resize the rectangle passing a `width` and `height`.
    setSize: (width, height) =>
        width = width * @parentView.currentZoom
        height = height * @parentView.currentZoom

        @svg.attr {"width": width, "height": height}

    # Set the rectangle position, passing a `x` and `y`. If absolute is false, it will also
    # consider the current [Map View](mapView.html) view box to calculate the real positioning.
    setPosition: (x, y, absolute) =>
        if not absolute
            viewBox = @parentView.getViewBox()
            x = x * @parentView.currentZoom + viewBox.x
            y = y * @parentView.currentZoom + viewBox.y

        @svg.attr {"x": x, "y": y}

    # When user is moving the mouse while the view is visible, calculate size and call `resize`.
    mouseMoveResize: (e) =>
        w = e.pageX - @ox
        h = e.pageY - @oy - 40
        x = @ox
        y = @oy

        if w < 0
            w = w * -1
            x = e.pageX

        if h < 0
            h = h * -1
            y = e.pageY - 40

        @setSize w, h
        @setPosition x, y, false

    # When user releases the mouse button, stop resizing the view and select all shapes inside it.
    mouseUpResize: (e) =>
        $(document).off "mousemove", @mouseMoveResize
        $(document).off "mouseup", @mouseUpResize

        @selectShapes()


    # DRAGGING AND MOVING
    # ----------------------------------------------------------------------

    # Prepare the rectangle to be draggable after shapes were selected.
    setDrag: =>
        @svg.drag @dragMove, @dragStart, @dragEnd

    # User has started dragging the rectangle.
    dragStart: (x, y, e) =>
        @ox = @x()
        @oy = @y()

        if @isEventDelete e
            @hide()
            return

        # Set the temporary `ox` and `oy` on all shape views and bind their [Link Views](linkView.html).
        for view in @shapeViews
            view.dragStart x, y, e

        @parentView.addToSelected null

    # When user is dragging the rectangle, change its positiong and the position
    # of all selected [Shape Views](shapeView.html).
    dragMove: (dx, dy) =>
        posX = @ox + dx * @parentView.currentZoom
        posY = @oy + dy * @parentView.currentZoom

        @setPosition posX, posY, true

        # Set shape views and links position.
        for view in @shapeViews
            view.dragMove dx, dy

    # Recreate all selected [Shape Views](shapeView.html) shadows, and bring the rectangle to front.
    dragEnd: (e) =>
        for view in @shapeViews
            view.dragEnd e, SystemApp.Settings.MapMover.shadowColor

        @svg.toFront()
