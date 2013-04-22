# LINK VIEW
# --------------------------------------------------------------------------
# Represents a link creator view, used to create [links](link.html) between shapes.

class System.MapLinkCreatorView extends System.MapLinkView

    source: null        # the source view (usually got from mapView)
    target: null        # the target view (usually got from the mapView)
    svgConnector: null  # the svg connector element that follows the mouse (a ghost "copy" of the source shape)


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the link creator view.
    initialize: =>
        @svg = null

    # Dispose the link creator view.
    dispose: =>
        @svg?.remove()
        @svgConnector?.remove()

        @svg = null
        @svgConnector = null

        @baseDispose()


    # RENDER AND ANIMATE
    # ----------------------------------------------------------------------

    # Render the link creator on the map passing the source [Shape View](shapeView.html).
    render: (parentView) =>
        x = parentView.x()
        y = parentView.y()
        stroke = SystemApp.Settings.Link.creatorStroke
        width = SystemApp.Settings.Link.creatorWidth

        # When first rendering the link creator, a `parentView` will be passed and used
        # to set the source [shape view](shapeView.html) and the parent
        # [map view](mapView.html).
        if parentView?
            @source = parentView
            @parentView = parentView.parentView

        @svgConnector = @parentView.paper.circle 0, 0, SystemApp.Settings.Map.icoActionsSize / 2 if @svgConnector is null
        @svgConnector.attr {"stroke": stroke, "stroke-width": width}
        @svgConnector.toFront()

        @setPosition x, y

        # Set the link options.
        stroke = SystemApp.Settings.Link.creatorStroke
        width = SystemApp.Settings.Link.creatorWidth
        text = SystemApp.Messages.newLink
        smooth = SystemApp.Settings.Link.smooth
        options = {stroke: stroke, width: width, labelStroke: stroke, text: text, smooth: smooth}

        # Create the link with the desired path and options.
        @svg = @parentView.paper.link @source.svg, @svgConnector, options

    # Change the current position of the svg connector while dragging. This is the
    # top left position, so we still need to add half the width of the source
    # shape plus half the width of the connector itself.
    setPosition: (posX, posY) =>
        posX = posX + @source.width() - SystemApp.Settings.Map.icoActionsSize / 2
        posY = posY + SystemApp.Settings.Map.icoActionsSize / 2

        pos = { cx: posX, cy: posY }

        @svgConnector.attr pos

        @drag()