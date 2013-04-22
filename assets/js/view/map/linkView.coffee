# LINK VIEW
# --------------------------------------------------------------------------
# Represents a link on the map, that might contain an attached label to it.

class System.MapLinkView extends System.BaseView

    visible: true          # cached variable to check if link is currently visible
    labelsView: null       # holds the 3 editable / dynamic labels of the link
    svg: null              # the link svg object (raphael.link.js)
    svgSourceArrow: null   # the svg arrow pointing to the source element (optional)
    svgTargetArrow: null   # the svg arrow pointing to the target element (optional)
    source: null           # the source view (usually taken from the parentView)
    target: null           # the target view (usually taken from the parentView)
    blinking: false        # is it blinking?


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Initialize the link view and bind model events.
    initialize: =>
        @listenTo SystemApp.mapEvents, "zoom:in", @onZoom
        @listenTo SystemApp.mapEvents, "zoom:out", @onZoom

        @listenTo @model, "change", @render
        @listenTo @model, "change:stroke", @setStroke
        @listenTo @model, "change:strokeWidth", @setStroke
        @listenTo @model, "change:zIndex", @setZIndex

    # Dispose the link view.
    dispose: =>
        @removeShadow()

        @labelsView?.dispose()
        @svg?.remove()

        @svg = null
        @source = null
        @target = null

        @baseDispose()


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Return an array with all the SVG elements for this link.
    svgs: =>
        result = [@svg.svgLine]
        result.push svg for svg in @labelsView.svgs() if @labelsView?

        return result


    # RENDER AND ANIMATE
    # ----------------------------------------------------------------------

    # Render the link on the map. If smoothLine is true it will render a
    # curved line, otherwise a straight one. You can also pass a parentView
    # to attach this link to.
    render: (parentView) =>
        @parentView = parentView if parentView?.shapeViews?

        source = @parentView.shapeViews[@model.sourceId()]
        target = @parentView.shapeViews[@model.targetId()]

        options =
            arrowSize: SystemApp.Settings.Link.arrowSize
            arrowSource: @model.arrowSource()
            arrowTarget: @model.arrowTarget()
            opacity: @model.opacity()
            smooth: @model.smooth()
            stroke: @model.stroke()
            width: @model.strokeWidth()

        if not @svg?
            options.onClick = @lineClick
            @svg = @parentView.paper.link source.svg, target.svg, options
            @setElement @svg
        else
            @parentView.paper.link @svg, options

        if not @labelsView?
            @labelsView = new System.MapLinkLabelsView {model: @model}

        @labelsView.render this

        return this

    # Remove the link from the map and dispose its contents.
    removeFromMap: =>
        @dispose()
        @model.destroy()

    # Blink and remove the link (so the user gets the attention of what's being removed).
    blinkAndRemove: =>
        @blink 2, @removeFromMap

    # When user clicks the link path, bring it to front or to back, depending on the
    # mouse button and on the current modifier keys for the user.
    lineClick: (e) =>
        # If using the "delete" key / mouse combination, then remove the shape.
        if @isEventDelete e
            @blinkAndRemove()
        else
            @parentView.setCurrentElement this

    # Send the link to the back of the current [Map View](r.html).
    toBack: =>
        @svg.toBack()
        @parentView.toBack()

    # Send the link to the front of the current [Map View](mapView.html).
    toFront: =>
        @svg.toFront()

    # Show the link on the map using a "fade in" effect.
    show: =>
        @svg.show SystemApp.Settings.Map.blinkInterval
        @labelsView.show()
        @visible = true

    # Hide the link on the map using a "fade out" effect.
    hide: =>
        @svg.hide SystemApp.Settings.Map.blinkInterval
        @labelsView.hide()
        @visible = false

    # Fade the link opacity to 0.1, so it's almost hidden.
    semiHide: =>
        @svg.semiHide SystemApp.Settings.Map.blinkInterval
        @labelsView.hide()
        @visible = false

    # Make the link smooth (curved) if the parameter `enabled` is true, or straight if false.
    smooth: (enabled) =>
        @parentView.paper.link @svg, {smooth: enabled}

    # Set the link drag handler.
    drag: =>
        @parentView.paper.link @svg
        @labelsView?.setPosition()


    # VIEW UPDATE EVENTS
    # ----------------------------------------------------------------------

    # Update the stroke (color and width) of the link.
    setStroke: =>
        @svg.svgLine.attr {"stroke": @model.stroke(), "stroke-width": @model.strokeWidth()}
        _.delay @strokeUpdatedBackToSelected, SystemApp.Settings.Map.borderUpdatedDelay

    # Update the zIndex the link by changing its position under the DOM tree.
    setZIndex: =>
        @parentView.regroupElement this

    # When user zooms in or out, check the current zoom level and resize
    # the link label accordingly. Font size will increase when zooming out,
    # but won't decrease when zooming in (zoom more than 1).
    onZoom: =>
        if @parentView.currentZoom < 1
            return

        fontSize = @model.fontSize() * @parentView.currentZoom
        fontSize = Math.round fontSize

        @svg.label?.attr {"font-size": fontSize}

    # When the user changes border details (color or width), the link will display the
    # new border for a period of time - default 1400ms, set on the
    # [Settings](settings.html) - and if after that period the
    # shape is still selected, then set its border back to the "selected" style
    # by calling the `createShadow` method.
    strokeUpdatedBackToSelected: =>
        if @parentView.currentShape?.model.id is @model.id
            @createShadow()


    # SHADOW AND HIGHLIGHT
    # ----------------------------------------------------------------------

    # Blink the link with optional amount of times (default is 2). This is a recursive function.
    # If times is 1 and the `callback` is specified, call it when it has finished blinking.
    blink: (times, callback) =>
        times = 2 if not times?
        extraMs = 15

        @hide()
        _.delay(@show, SystemApp.Settings.Map.blinkInterval + extraMs)
        _.delay(@blink, SystemApp.Settings.Map.blinkInterval * 2 + extraMs * 2, times - 1, callback) if times > 1
        _.delay(callback, SystemApp.Settings.Map.blinkInterval * 2 + extraMs * 4) if times is 1 and callback?

    # Create a shadow behind the link, with optional color and strength.
    createShadow: (color, strength) =>
        color = SystemApp.Settings.Map.shadowColor if not color?
        strength = SystemApp.Settings.Map.shadowStrength if not strength?

        @svg.svgLine.attr {"stroke": color, "stroke-width": strength}

    # Remove the shadow from the link (if there's one present).
    removeShadow: =>
        @svg?.svgLine.attr {"stroke": @model.stroke(), "stroke-width": @model.strokeWidth()}