# MAP VIEW
# --------------------------------------------------------------------------
# Represents the map view. This is the most important view of the app!

class SystemApp.MapView extends SystemApp.BaseView

    paper: null                 # the Raphael paper object
    paperBg: null               # the paper background object or color string
    selectedShapes: null        # collection of selected [Shape Views](shapeView.html) on the map
    hoverShape: null            # the current shape pointed by the mouse
    lastPressedKey: null        # the last keyboard key pressed by the user

    zIndexMax: 100              # the maximum z-index of an element inside the map
    currentZoom: 1              # current map zoom
    currentPanX: 0              # current pan X position
    currentPanY: 0              # current pan Y position
    mousePosX: 0                # current or last mouse X position
    mousePosY: 0                # current or last mouse Y position
    mapDivWidth: 0              # cached value of the map DIV width
    mapDivHeight: 0             # cached value of the map DIV height
    overrideShapeTitle: null    # override the value / property name displayed of the shape's title

    editEnabled: false          # is the map in edit mode?
    isPanning: false            # true if user is moving the map, otherwise false
    isCreatingLink: false       # when creating new links (dragging the link connector), this will be set to true
    isLinksVisible: true        # are links visible or hidden on the map?

    controlsView: null          # a [Controls View](controlsView.html) to control and interact with map
    shapesMoverView: null       # a [Shapes Mover View](shapesMoverView.html) to move multiple shapes at once
    stackGroups: null           # holds 9 SVG "groups" elements, used to control shape's z-index
    shapeViews: null            # holds current map's ([Shape Views](shapeView.html))
    linkViews: null             # holds current map's ([Link Views](linkView.html))
    gridLines: null             # array, holds all grid lines (when toggled on)

    timerAfterZoom: null        # timer to trigger the `afterZoomSet` method


    # DOM ELEMENTS
    # ----------------------------------------------------------------------

    $footer: null          # the map footer wrapper
    $footerName: null      # the map name span (2)
    $footerShape: null     # the map current shape span (3)
    $panningIcon: null     # icon shown when map is panning / moving


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the map view.
    initialize: =>
        @setDom()
        @setPaper()
        @setEvents()

        # Child views.
        @controlsView = new SystemApp.MapControlsView this
        @shapesMoverView = new SystemApp.MapShapesMoverView this

        # Cached variable: are links visible?
        @isLinksVisible = @controlsView.isLinksVisible()

    # Clear the current map view, footer, and unbind all events.
    dispose: =>
        $(document).unbind "mouseup", @mouseUp
        $(document).unbind "keydown", @keyDown

        @clear()

        @controlsView?.dispose()
        @shapesMoverView?.dispose()

        @controlsView = null
        @shapesMoverView = null
        @shapeViews = null
        @linkViews = null

        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map"
        @$footer = $ "#footer-maps"
        @$footerName = $ "#footer-maps-name"
        @$footerShape = $ "#footer-maps-shape"
        @$panningIcon = $ "#map-panning-icon"

    # Bind events to the global app events, DOM elements and objects.
    setEvents: =>
        @listenTo SystemApp.mapEvents, "url:reset", @resetUrl
        @listenTo SystemApp.mapEvents, "background:toggle", @toggleBackground
        @listenTo SystemApp.mapEvents, "edit:toggle", @toggleEdit
        @listenTo SystemApp.mapEvents, "links:toggle", @toggleLinks
        @listenTo SystemApp.mapEvents, "shapes:overridetitle", @setOverrideShapeTitle
        @listenTo SystemApp.mapEvents, "zoom:in", @zoomIn
        @listenTo SystemApp.mapEvents, "zoom:out", @zoomOut
        @listenTo SystemApp.mapEvents, "selected:blink", @blinkSelectedShapes
        @listenTo SystemApp.dataEvents, "auditdata:refresh", @auditDataRefresh

        # Handle document events.
        $(document).bind "mouseup", @mouseUp
        $(document).bind "keydown", @keyDown

        # Handle map element events.
        @$el.bind "mousedown", @mouseDown
        @$el.bind "mousemove", @mouseMove
        @$el.bind "mousewheel", @mouseWheel
        @$el.bind "contextmenu", @contextMenu
        @$el.dblclick @doubleClick

    # Set the Raphael/SVG paper and its properties.
    setPaper: =>
        width = SystemApp.Settings.Map.paperSizeX
        height = SystemApp.Settings.Map.paperSizeY

        @selectedShapes = {}
        @paper = new Raphael "map", width, height

    # Count how many shapes are selected.
    countSelectedShapes: =>
        return Object.keys(@selectedShapes).length


    # RENDER THE CURRENT MAP
    # ----------------------------------------------------------------------

    # Clear the map (usually called when user changes the current [Map](map.html)).
    clear: =>
        @$el.find(".label-edit-view").remove()

        # Unbind and clear the [current map](map.html).
        if @model?
            @stopListening @model.shapes()
            @stopListening @model.links()
            @stopListening @model
            @model = null

        # Clear the current map background object.
        @paperBg?.remove()
        @gridLines?.remove()
        @paperBg = null

        # Remove the [Shapes Mover View](shapesMoverView.html).
        @shapesMoverView.remove()

        # Clear shapes and links.
        @clearSelectedShapes()
        @clearShapes()
        @clearLinks()

        _.each @stackGroups, (group) -> group.remove()
        @stackGroups = {}

        # Clear the paper.
        @paper?.clear()

    # CLear (remove!) all shapes on the map.
    clearShapes: =>
        _.each @shapeViews, (view) -> view.dispose()
        @shapeViews = {}

    # CLear (remove!) all links on the map.
    clearLinks: =>
        _.each @linkViews, (view) -> view.dispose()
        @linkViews = {}

    # Unselect all selected shapes (if any).
    clearSelectedShapes: =>
        count = 0
        for modelId, view of @selectedShapes
            view.unhighlight()
            count++

        # Reset the selected shapes object.
        @selectedShapes = {}
        @controlsView.bind()
        @setFooterShape()

        SystemApp.consoleLog "MapView.clearSelectedShapes", "Cleared #{count} shapes."

    # Bind a [Map](map.html) to the map. this will reset the map state!
    bind: (map) =>
        console.profile "MapView.bind" if SystemApp.Settings.General.profile
        SystemApp.consoleLog "MapView.bind", "#{map.name()}, #{map.shapes().length} shapes, #{map.links().length} links"

        @model?.save()
        @clear()

        # No map to bind? So stop here.
        if not map?
            SystemApp.toggleLoading false
            return

        @model = map

        # Set the current window title and footer details.
        @setTitle map.name()
        @setFooterName map.name()

        # Reset the SVG paper with the new map paper size.
        @paper.setSize map.paperSizeX(), map.paperSizeY()

        # Bind map data.
        @bindBg()
        @bindGroups()
        @bindShapes()
        @setViewBox()

        # Reset the [shapes mover view](shapesMovewView.html).
        @shapesMoverView.render()

        # Force refresh shape/link labels.
        @refreshLabels()

        # Generate the map thumbnail on the server.
        @generateThumbnail()

        # Check and run the init script.
        initScript = map.initScript()
        SystemApp.DataUtil.runEval initScript if initScript? and initScript isnt ""

        # The other views that a new map has loaded.
        SystemApp.mapEvents.trigger "loaded", map
        SystemApp.toggleLoading false

        # Finally bind map events.
        @bindEvents()

        console.profileEnd "MapView.bind" if SystemApp.Settings.General.profile

    # Bind event listeners to the current [Map](map.html).
    bindEvents: =>
        @listenTo @model, "sync", @mapSaved
        @listenTo @model, "destroy", @mapRemoved

        @listenTo @model, "change:name", @nameChanged
        @listenTo @model, "change:paperSizeX", @paperSizeChanged
        @listenTo @model, "change:paperSizeY", @paperSizeChanged
        @listenTo @model, "change:gridSizeX", @gridSizeChanged
        @listenTo @model, "change:gridSizeY", @gridSizeChanged

        @listenTo @model.shapes(), "reset", @resetShapes
        @listenTo @model.shapes(), "add", @addShape
        @listenTo @model.shapes(), "remove", @removeShape

        @listenTo @model.links(), "reset", @resetLinks
        @listenTo @model.links(), "add", @addLink
        @listenTo @model.links(), "remove", @removeLink

    # Set the paper background, which can be a URL to an image or a solid color.
    bindBg: =>
        @paperBg = @model.background()

        if @paperBg isnt undefined and @paperBg.indexOf(".") > 0
            @paperBg = @paper.image "images/#{@paperBg}", 0, 0, @paper.width, @paper.height
        else
            @paperBg = @paper.rect(0, 0, @paper.width, @paper.height).attr {fill: @paperBg}

        @paperBg.node.id = SystemApp.Settings.Map.id

    # Create the map groups using raphael.group.js plugin.
    bindGroups: =>
        i = 1
        while i < 10
            @stackGroups[i] = @paper.group()
            i++

    # Reset shapes on the map. This is mainly called when the map's `shapes` collection
    # triggers an reset event.
    resetShapes: =>
        return if not @model?

        @clearShapes()
        @bindShapes()

    # Reset links on the map. This is mainly called when the map's `links` collection
    # triggers an reset event.
    resetLinks: =>
        return if not @model?

        @clearLinks()
        @bindLinks()

    # Refresh current map's [Shape Labels](shapeLabelsView.html) and
    # [Link Labels](linkLabelsView.html). This will also update the [Shape Details View](shapeDetailsView.html)
    # to reflect the selected shape's active alerts. Refresh will be aborted if user is panning the map.
    refreshLabels: =>
        return if @isPanning

        _.each @shapeViews, (view) -> view.labelsView.bindAllLabelsData()
        _.each @linkViews, (view) -> view.labelsView.bindAllLabelsData()

        @controlsView.inspectorTabView.bindActiveAuditEvents()


    # MAP EVENTS
    # ----------------------------------------------------------------------

    # Save the current `filter` to the remote server.
    saveMap: =>
        @model.save() if @editEnabled and @model.hasChanged()

    # Display an alert whenever the current map has been saved to the server.
    mapSaved: (map) =>
        SystemApp.alertEvents.trigger "footer", {savedModel: map}

    # When user deletes (destroy) the current [Map](map.html), refresh the browser.
    mapRemoved: (map) =>
        SystemApp.alertEvents.trigger "footer", {removedModel: map}
        SystemApp.toggleLoading true

        reloadPage = -> window.open "/", "_self"
        setTimeout reloadPage, 1000


    # BINDING MAP SHAPES
    # ----------------------------------------------------------------------

    # Bind the current map's shapes (a [ShapeCollection](shape.html)) to the view.
    bindShapes: =>
        @addShape item for item in @model.shapes().models
        @bindLinks()
        @toggleGridLines @editEnabled

    # Create a [shape view](shapeView.html) based on the passed [shape model](shape.html)
    # and add it to the map. Make sure we don't add orphan shapes by checking if there's
    # an ID present.
    addShape: (shape, collection) =>
        return if not shape.id? or shape.id is ""

        view = new SystemApp.MapShapeView {model: shape}
        view.bindEntityObject()
        view.render this

        @shapeViews[shape.id] = view
        @stackGroups[shape.zIndex()].push view.svgs()

        # If a collection was passed, it means shape was added from the
        # [Shape Entity List](entityListView.html) panel, so set `save` to true,
        # unless map `silent` is true which means it might have been added via the API.
        save = collection? and not @model.silent()

        @setShapePosition view, shape.x(), shape.y(), save

        if save
            view.blink()
            @addToSelected view

    # Removes a shape from the map and delete its value from the `shapeViews`.
    removeShape: (model) =>
        view = @shapeViews[model.id]

        @removeFromSelected view
        @model.save()

        delete @shapeViews[model.id]

    # Unbind all shapes from the map.
    unbindShapes: =>
        _.each @shapeViews, (view) => view.dispose()
        @shapeViews = {}

    # Add the specified [Shape View](shapeView.html) or [Link View](linkView.html) to the list of selected
    # elements on the map. When holding "Ctrl", the `multiple` argument will be true and the shape will be
    # added to the selected list. Otherwise it will clear the list and add the element as the only selected.
    addToSelected: (view, multiple) =>
        return if not view?.model?

        @clearSelectedShapes()
        @selectedShapes[view.model.id] = view

        view.highlight()

        entityObject = view.model.entityObject
        textTitle = view.model.defaultText()
        selectedCount = @countSelectedShapes()

        # If multiple shapes are selected, add multiple text to the footer.
        # If the view's model has an `entityObject` property, means it has an
        # [Entity Object](entityObject.html) bound to it so show its title on the footer.
        # Otherwise show the shape's title text.
        if selectedCount > 1
            @controlsView.bind @selectedShapes
            @setFooterShape(selectedCount + " " + SystemApp.Messages.elementsSelected)
        else
            @controlsView.bind view
            if entityObject?
                @setFooterShape entityObject.title()
            else if textTitle? and textTitle isnt ""
                @setFooterShape textTitle
            else
                @setFooterShape view.model.id

        SystemApp.consoleLog "MapView.addToSelected", view.model.id

    # Remove the specified [Shape View](shapeView.html) or [Link View](linkView.html) from
    # the list of selected elements.
    removeFromSelected: (view) =>
        @selectedShapes[view.model.id]?.unhighlight()
        delete @selectedShapes[view.model.id]

        # Unbind shape if `selectedShapes` length is less than 1.
        @controlsView.bind() if @countSelectedShapes() < 1

        SystemApp.consoleLog "MapView.removeFromSelected", view.model.id

    # Set the current shape at which mouse is pointing. This is mainly used when creating links between shapes.
    setHoverShape: (shapeView) =>
        @hoverShape = shapeView

    # Set the property to be displayed inside the map shapes.
    setOverrideShapeTitle: (prop) =>
        SystemApp.consoleLog "MapView.setOverrideShapeTitle", prop

        # If `prop` is passed, then make sure we append the data binding key and the
        # entity object namespace before its value.
        if prop? and prop isnt ""
            prop = "#{SystemApp.Settings.General.dataBindingKey}#{SystemApp.Settings.EntityObject.bindingNamespace}.#{prop}"

        @overrideShapeTitle = prop
        _.each @shapeViews, (view) => view.labelsView.refreshTitle()


    # BINDING MAP LINKS
    # ----------------------------------------------------------------------

    # Bind shape links to the map.
    bindLinks: =>
        @addLink item for item in @model.links().models

    # Add a single link to the map.
    addLink: (item, collection) =>
        sourceView = @shapeViews[item.sourceId()]
        targetView = @shapeViews[item.targetId()]

        # Do not proceed if target or source shape is not valid.
        return if not sourceView? or not targetView?

        view = new SystemApp.MapLinkView {model: item}
        @linkViews[item.id] = view

        view.render this
        view.semiHide() if not @controlsView.isLinksVisible()
        @stackGroups[item.zIndex()].push view.svgs()

        # If a collection was passed, it means links was just created by the user
        # so set `save` to true, and save the [Current Map](map.html) in this case.
        save = collection?
        @model.save() if save

    # Remove a link from the map.
    removeLink: (link) =>
        delete @linkViews[link.id]
        @model.save()

    # Unbind element links from map
    unbindLinks: =>
        _.each @linkViews, (view) => view.dispose()
        @linkViews = {}

    # Get all [Link Views](linkView.html) related to the specified shape.
    getLinkViewsForShape: (shape) =>
        return _.filter @linkViews, (linkView) =>
            linkView.model.sourceId() is shape.id or linkView.model.targetId() is shape.id


    # MAP CONTROLS
    # ----------------------------------------------------------------------

    # User has clicked the mouse and started panning (moving) the map around.
    panningStart: (e) =>
        @$panningIcon.mousemove @panningMove
        @$el.css "cursor", "move"

        @mousePosX = e.pageX
        @mousePosY = e.pageY

        @isPanning = true

    # User is panning (moving) the map while holding the mouse button.
    # Please note that it is NOT possible to go outside the map bounds.
    panningMove: (e) =>
        @currentPanX -= (e.pageX - @mousePosX) * @currentZoom
        @currentPanY -= (e.pageY - @mousePosY) * @currentZoom
        sumWidth = @mapDivWidth - @controlsView.width

        # If there's a map bound, then check if the current pan X and Y values
        # are less than the maximum allowed values, which is the map's paper
        # width/height - the map's div `#map` width/height. This will ensure
        # that grid lines are always visible.
        if @model?
            maxPanX = @model.paperSizeX() - sumWidth * @currentZoom
            maxPanY = @model.paperSizeY() - @mapDivHeight * @currentZoom
            @currentPanX = maxPanX if @currentPanX > maxPanX
            @currentPanY = maxPanY if @currentPanY > maxPanY

        # Only show the "moving icon" when current map position has not reached its borders.
        if (@currentPanX > 0 and @currentPanX < maxPanX) or (@currentPanY > 0 and @currentPanY < maxPanY)
            @$panningIcon.css "display", ""
        else
            @$panningIcon.css "display", "none"

        # Set temporary mouse position variables.
        @mousePosX = e.pageX
        @mousePosY = e.pageY

        @setViewBox()

    # User has finished panning (moving) the map when mouse button is released.
    panningEnd: (e) =>
        @$panningIcon.unbind "mousemove"
        @$panningIcon.css "display", "none"
        @$el.css "cursor", "default"

        @isPanning = false

        e.stopPropagation()
        e.preventDefault()

    # Helper to get the paper `viewBox` object.
    getViewBox: =>
        return @paper.canvas.viewBox.baseVal

    # Set the current view box (zoom and panning) of the map.
    # The max and min zoom values are defined on the [Settings](settings.html).
    setViewBox: =>
        @currentZoom = SystemApp.Settings.Map.minZoom if @currentZoom < SystemApp.Settings.Map.minZoom
        @currentZoom = SystemApp.Settings.Map.maxZoom if @currentZoom > SystemApp.Settings.Map.maxZoom

        boxWidth = @paper.width * @currentZoom
        boxHeight = @paper.height * @currentZoom

        @currentPanX = 0 if @currentPanX < 0
        @currentPanY = 0 if @currentPanY < 0

        @paper.setViewBox(@currentPanX, @currentPanY, boxWidth, boxHeight, true)

        SystemApp.mapEvents.trigger "zoom", @currentZoom

    # Zoom in, with optional `amount` parameter.
    zoomIn: (amount) =>
        amount = SystemApp.Settings.Map.zoomStep if not amount?
        @zoomSet @currentZoom - amount

    # Zoom out, with optional `amount` parameter.
    zoomOut: (amount) =>
        amount = SystemApp.Settings.Map.zoomStep if not amount?
        @zoomSet @currentZoom + amount

    # Set the `currentZoom` variable and update the view.
    # Save zoom to the [user settings](userSettings.html).
    zoomSet: (value) =>
        @currentZoom = value
        @setViewBox()

        if @timerAfterZoom?
            clearTimeout @timerAfterZoom
        @timerAfterZoom = setTimeout @afterZoomSet, SystemApp.Settings.Map.zoomUpdateDelay

    # Delayed trigger to update font sizes on labels and save zoom to
    # the [user settings](userSettings.html), to achieve better performance.
    afterZoomSet: =>
        SystemApp.Data.userSettings.mapZoom @currentZoom
        SystemApp.mapEvents.trigger "zoom:set"

        @timerAfterZoom = null

    # Toggle the `editEnabled` on or off.
    toggleEdit: (enabled) =>
        @editEnabled = enabled
        @toggleGridLines enabled

    # Toggle the map background image (represented by the `paperBg` element, if there's one).
    toggleBackground: (enabled) =>
        if enabled
            @paperBg.show()
        else
            @paperBg.hide()

    # Toggle links on or off ([Link View](linkView.html) `show` and `semiHide` methods).
    # Please note that hiding links means setting their opacity to a very low value,
    # so they're almost invisible but not totally hidden.
    toggleLinks: (enabled) =>
        @isLinksVisible = enabled

        _.each @linkViews, (linkView) ->
            if not linkView?
                return
            if enabled
                linkView.show()
            else
                linkView.semiHide()

    # Toggle grid lines on or off. Usually grid lines will be toggled on when map is in
    # edit mode, and off when not editable.
    toggleGridLines: (enabled) =>
        if not @model?
            return

        sizeX = @model.gridSizeX()
        sizeY = @model.gridSizeY()

        lengthX = @paper.width / sizeX
        lengthY = @paper.height / sizeY

        @gridLines?.remove()
        pathString = ""

        if enabled
            i = 0
            while i++ < lengthX
                pathString += "M" + i * sizeX + " 0V" + @paper.height

            i = 0
            while i++ < lengthY
                pathString += "M0 " + i * sizeY + "H" + @paper.width

        @gridLines = @paper.path(pathString).attr("stroke", SystemApp.Settings.Map.gridStroke)
        @gridLines.toBack()

        @paperBg.toBack()

    # Send the map background and grid lines to back of the paper.
    toBack: =>
        @gridLines.toBack()
        @paperBg.toBack()

    # Set position of a shape view based on grid X and Y. The absolute size of the grid blocks
    # are defined on the [Settings](settings.html).
    setShapePosition: (view, x, y, save) =>
        save = true if not save?
        view.setPosition x * @model.gridSizeX(), y * @model.gridSizeY(), save

    # Regroup the specified [Shape View](shapeView.html) or [Link View](linkView.html) to the
    # value set in its model's `zIndex` property.
    regroupElement: (view) =>
        svgs = view.svgs()

        for svg in svgs
            try
                svg.node.parentNode.removeChild svg.node if svg?
            catch ex
                SystemApp.consoleLog "MapView.regroupElement", "Can't remove element from SVG group.", svg

        @stackGroups[view.model.zIndex()].push svgs

    # Get a [Shape}(shape.html) object with the first x/y free position on the map grid.
    # This method is called to position the shapes when they're added from
    # the [Entity List View](entityListView.html) overlay.
    getFirstAvailableShape: =>
        x = 0
        y = 0

        _.each @shapeViews, (view) =>
            posX = view.x()
            posY = view.y()

            if posX - x < SystemApp.Settings.Map.gridSizeX
                x += SystemApp.Settings.Map.gridSizeX

            if posY - y < SystemApp.Settings.Map.gridSizeY
                y += SystemApp.Settings.Map.gridSizeY

        return new SystemApp.Shape {x: x / SystemApp.Settings.Map.gridSizeX, y: y / SystemApp.Settings.Map.gridSizeY}


    # Blink the selected [Shape](shapeView.html) on the map.
    blinkSelectedShapes: =>
        view.blink() for modelId, view of @selectedShapes


    # KEYBOARD EVENTS
    # ----------------------------------------------------------------------

    # When user presses a key. Pressing "Ctrl+S" will save the current map,
    # and pressing "Esc" twice will unselect the any selected shapes.
    keyDown: (e) =>
        keyCode = e.keyCode

        # User pressed "Ctrl+S", so save everything.
        if e.ctrlKey and keyCode is 83
            @model.save()
            e.preventDefault()
            e.stopPropagation()

            # User pressed "Ctrl+E", so toggle the edit mode.
        else if e.ctrlKey and keyCode is 69
            SystemApp.mapEvents.trigger "edit:toggle", not @editEnabled
            e.preventDefault()
            e.stopPropagation()

            # User pressed "Esc" twice in a row, so deselect the current shape.
        else if keyCode is 27 and @lastPressedKey is 27
            @clearSelectedShapes()
            @lastPressedKey = null

            # User pressed "F11", go to fullscreen mode.
        else if e.ctrlKey and keyCode is 84
            @toggleFullscreen()
            e.preventDefault()
            e.stopPropagation()

        # Set the last pressed key code.
        @lastPressedKey = keyCode


    # MOUSE EVENTS
    # ----------------------------------------------------------------------

    # Triggered when user clicks the map. If clicking with left button, prepares map to pan.
    mouseDown: (e) =>
        src = e.target
        targetId = src.id

        # Temp variables to check where the user clicked.
        isBaseSvgTag = src.tagName isnt "svg"
        isMapTag = targetId isnt SystemApp.Settings.Map.id
        isGridLine = targetId.indexOf(SystemApp.Settings.Map.gridIdPrefix) < 0

        # If click wasn't on the map background or any of the grid lines, do not proceed with panning.
        if e.which > 1 or (@editEnabled and isBaseSvgTag and isMapTag and isGridLine)
            return

        # If user clicked on a blank area, deselect the current [Shape View](shapeView.html).
        if targetId is SystemApp.Settings.Map.id
            @shapesMoverView.hide()
            @clearSelectedShapes()

        # If pressing Shift, then start selecting multiple elements with the [Shapes Mover View](shapesMoverView.html).
        if @editEnabled and @isEventMultiple e
            @shapesMoverView.show e.pageX, e.pageY
        else
            @panningStart e

    # Triggered when user moves the mouse around the map. If `isPanning` is true
    # then pan the map with the amount of pixels from the mouse down location.
    mouseMove: (e) =>
        if @isPanning
            @panningMove e

    # Triggered when user releases mouse button on the map. Set `isPanning` to false
    # and restore the default mouse cursor.
    mouseUp: (e) =>
        if @isPanning
            @panningEnd e

    # Triggered when user scrolls the mouse wheel. Scrolling will change the map zoom.
    mouseWheel: (e) =>
        if @isPanning
            return

        delta = e.originalEvent.wheelDeltaY

        if delta > 0
            SystemApp.mapEvents.trigger "zoom:in"
        else
            SystemApp.mapEvents.trigger "zoom:out"

        e.stopPropagation()
        e.preventDefault()

    # Triggered when user right click the map. This will cancel the default context menu.
    contextMenu: =>
        return false

    # Triggered when user double clicks the map. This will reset the map position to top left corner.
    doubleClick: (e) =>
        src = e.target

        if src?.tagname isnt "rect" and src?.tagname isnt "path"
            return

        @currentPanX = 0
        @currentPanY = 0

        @zoomSet 1

        @isPanning = false
        e.stopPropagation()
        e.preventDefault()


    # MAP PROPERTY CHANGES
    # ----------------------------------------------------------------------

    # Triggered when the current [Map](map.html) `name` has changed.
    nameChanged: =>
        @model.save()

        @setFooterName @model.name()

    # Triggered when the current [Map](map.html) `paperSizeX` or `paperSizeY` has changed.
    paperSizeChanged: =>
        @model.save()

        @paper.setSize @model.paperSizeX(), @model.paperSizeY()

        @toggleGridLines true
        @setViewBox()

    # Triggered when the current [Map](map.html) `gridSizeX` or `gridSizeY` has changed.
    gridSizeChanged: =>
        @model.save()

        @toggleGridLines true
        @clearSelectedShapes()

        _.each @shapeViews, (shapeView) => shapeView.resetDimensions()
        _.each @linkViews, (linkView) => linkView.drag()

        @setViewBox()


    # AUDIT DATA AND ALERTS
    # ----------------------------------------------------------------------

    # When user deletes (destroy) an [AuditData](auditData.html), reload
    # the whole page.
    auditDataRemoved: (auditData) =>
        SystemApp.alertEvents.trigger "footer", {removedModel: auditData}
        _.delay location.reload, SystemApp.Settings.General.refetchDelay

    # When an [AuditData](auditData.html) has been refreshed, run it against
    # all registered [Audit Events](auditEvent.html).
    auditDataRefresh: (auditData) =>
        _.each SystemApp.Data.auditEvents.models, (alert) -> alert.run()

    # Trigger a "footer message" action.
    auditEventFooterMessage: (alertObj, action, matchedRules) =>
        SystemApp.alertEvents.trigger "footer", {title: "ALERT!!!", message: action.actionValue(), isError: true}


    # URL AND FOOTER PROPERTIES
    # ----------------------------------------------------------------------

    # Reset the URL to the current's map URL. This is triggered mainly when user closes
    # an open overlay, so we can properly keep track of page history.
    # This will NOT trigger the backbone route event - it only updates the URL.
    resetUrl: =>
        if @model?
            SystemApp.routes.navigate "map/" + @model.urlKey(), {trigger: false}
            SystemApp.consoleLog "MapView.resetUrl", "Current map's URL: " + @model.urlKey()
        else
            SystemApp.routes.navigate "", {trigger: false}

    # Bind the map name to the footer.
    setFooterName: (value) =>
        @$footerName.html value
        @$footerShape.empty()

    # Show the current selected shape name on the footer.
    setFooterShape: (shape) =>
        shape = SystemApp.Messages.noShapeSelected if shape is undefined or shape is null or shape is ""
        @$footerShape.html shape


    # THUMBNAILS
    # ----------------------------------------------------------------------

    # Post the SVG representation of the map to the server to
    # generate the SVG and PNG thumbnails.
    generateThumbnail: =>
        now = new Date()
        thumbnailDate = @model.thumbnailDate()

        if thumbnailDate?
            thumbnailDate = new Date thumbnailDate
        else
            thumbnailDate = new Date()

        # If a thumbnail was generated less than 5 minutes ago, do nothing.
        if now.getTime() - thumbnailDate.getTime() < SystemApp.Settings.Map.thumbnailExpires
            return

        # Update thumbnail date and generate new thumbnail using an AJAX post.
        @model.thumbnailDate now

        $.ajax
            url: SystemApp.Settings.Map.thumbnailBaseUrl + @model.id
            cache: false
            dataType: "json"
            type: "POST"
            data:
                svg: @$el.html()