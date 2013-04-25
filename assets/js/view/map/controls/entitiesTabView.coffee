# MAP CONTROLS: ENTITY LIST VIEW
# --------------------------------------------------------------------------
# The overlay view containing the list of shapes available to be added to the
# map. The overlay is shown only when the map is in edit mode.

class SystemApp.MapControlsEntitiesTabView extends SystemApp.BaseView

    # Holds the timer to trigger the `search` method, so when user
    # changs the value of the `$txtSearch` it will actually search only
    # after a few miliseconds.
    timerSearch: null


    # DOM ELEMENTS
    # ----------------------------------------------------------------------
    # Sets the wrapper element and the list container.

    $list: null           # the "Ul" element containing the entity items
    $txtSearch: null      # the "Search" input field
    $shapeDragger: null   # represents a copy of the current shape being dragged to the map


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Inits the view. Parent will be the [Map Controls View](controlsView.html).
    initialize: (parent) =>
        @baseInit parent

        @mapView = parent.parentView

        @setDom()
        @setEvents()
        @addCustomShapeToList()
        @searchBlur()

    # Dispose the view.
    dispose: =>
        @timerSearch = null
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map-ctl-tab-entities"
        @$list = @$el.children "ul"
        @$txtSearch = $ "#map-entity-list-search"

    # Bind events to DOM and other controls.
    setEvents: =>
        $(window).resize @resize

        @$txtSearch.focus @searchFocus
        @$txtSearch.blur @searchBlur
        @$txtSearch.keyup @prepareSearch

        # When map is loaded on the [map view](mapView.html), bind it here.
        @listenTo SystemApp.mapEvents, "loaded", @bindMap
        @listenTo SystemApp.mapEvents, "edit:toggle", @setEnabled

        # Keep [entities](entityDefinition.html) in sync.
        @listenTo SystemApp.Data.entities, "add", @entityAdded
        @listenTo SystemApp.Data.entities, "remove", @entityRemoved

    # Enable or disable adding shapes to the current [Map](map.html).
    setEnabled: (value) =>
        formElements = [@$list]

        if not value
            elm.attr "disabled", "disabled" for elm in formElements
            @$list.addClass "disabled"
        else
            elm.removeAttr "disabled" for elm in formElements
            @$list.removeClass "disabled"

    # Toggles the visibility on or off, using a fade effect.
    toggleVisibility: (visible) =>
        if visible
            @$el.fadeIn SystemApp.Settings.Map.opacityInterval
        else
            @$el.fadeOut SystemApp.Settings.Map.opacityInterval

    # When window has loaded or resized, set the height to the parent's height.
    resize: =>
        @$list.css "height", @$el.parent().innerHeight() - 74


    # ENTITY SYNC
    # ----------------------------------------------------------------------

    # When a new [Entity Definition](entityDefinition.html) is added on the
    # global [data](data.html), parse it and add its [objects](entityObject.html)
    # to the `$list`.
    entityAdded: (entityDef) =>
        @listenTo entityDef, "change:data", @entityDataChanged
        @listenTo entityDef.data(), "add", @entityDataAdded
        @listenTo entityDef.data(), "remove", @entityDataRemoved

        @entityDataAdded obj for obj in entityDef.data().models

        SystemApp.consoleLog "MapControlsEntitiesTabView.entityAdded", entityDef

    # When an [Entity Definition](entityDefinition.html) is removed from the global
    # [data](data.html), also remove its related [objects](entityObject.html) from
    # the `$list`.
    entityRemoved: (entityDef) =>
        @stopListening entityDef.data()
        className = entityDef.friendlyId().toLowerCase()
        $(".#{className}").remove()

        SystemApp.consoleLog "MapControlsEntitiesTabView.entityRemoved", entityDef

    # When the entity's [data collection](entityObject.html) gets changed.
    # This will effectively remove and re-add all entity objects to the list.
    entityDataChanged: (entityDef) =>
        className = entityDef.friendlyId().toLowerCase()
        $(".#{className}").remove()
        @addToList obj for obj in entityDef.data().models

        SystemApp.consoleLog "MapControlsEntitiesTabView.entityDataChanged", entityDef

    # When the entity's [data](entityObject.html) gets new entity objects, add them
    # to the `$list`.
    entityDataAdded: (entityObject) =>
        @addToList entityObject

    # When the entity's [data](entityObject.html) has entity objects deleted, remove them
    # from the `$list`.
    entityDataRemoved: (entityObject) =>
        li = $ SystemApp.Settings.Map.entityListPrefix + entityObject.entityDefinitionId() + "-" + entityObject.id
        li.remove()


    # BINDING AND OPTIONS
    # ----------------------------------------------------------------------

    # Removes all entity objects from the `$list`.
    clear: =>
        @$list.empty()

    # Bind map to control. Listen to the `add` and `remove` events on the
    # current map's shapes collection, and set the entity count.
    bindMap: (map) =>
        @model = map
        @resize()
        @resetListCount()

        @model.shapes().off "add", @increaseListCount
        @model.shapes().off "remove", @subtractListCount
        @model.shapes().on "add", @increaseListCount
        @model.shapes().on "remove", @subtractListCount

    # Add the "custom shape" to the top of the entity list. This shape
    # is NOT bound to any entity, thus its values are totally customizable.
    addCustomShapeToList: =>
        li = $(document.createElement "li")
        li.attr "id", SystemApp.Settings.Map.entityListPrefix + "0"
        li.html SystemApp.Settings.Shape.customText
        li.addClass "custom"

        # Add an empty span which represents the entity's count.
        spanCount = $(document.createElement "span")
        spanCount.addClass "count"

        li.append spanCount

        @addListItem li

    # Bind a single entity to the `$list` element.
    addToList: (obj) =>
        obj = obj.model if obj.model?
        definitionId = obj.entityDefinitionId()
        definitionId = SystemApp.Settings.Shape.customId if not definitionId?

        li = $(document.createElement "li")
        li.attr "id", SystemApp.Settings.Map.entityListPrefix + definitionId + "-" + obj.id
        li.attr "title", obj.title()
        li.html obj.title()
        li.data "entity", obj
        li.addClass definitionId.toLowerCase()

        # Add a small text showing the type of entity (set by the `entityDefinitionId`).
        defSpan = $(document.createElement "span")
        defSpan.html definitionId
        defSpan.addClass "type"

        # Add an empty span which represents the entity's count.
        spanCount = $(document.createElement "span")
        spanCount.addClass "count"

        li.append spanCount
        li.append defSpan

        @addListItem li

    # Add a list item to the `$list` entitiies list, and fade it into view.
    addListItem: (li) =>
        li.css "display", "none"
        li.mousedown @dragStart
        @$list.append li
        li.fadeIn SystemApp.Settings.Map.opacityInterval

    # Helper method to get the entity counter element based on a map shape.
    # Return the default "Custom Shape" list item in case no items are found for the
    # specified [Shape](shape.html).
    getSpanCountElement: (shape) =>
        entityDefId = shape.entityDefinitionId()
        entityObjId = shape.entityObjectId()

        li = $ "#" + SystemApp.Settings.Map.entityListPrefix + entityDefId + "-" + entityObjId
        li = $ "#" + SystemApp.Settings.Map.entityListPrefix + "0" if li.length < 1

        return li.find "span.count"

    # Reset the shape's count. This will clear all the `span` elements inside each list
    # item, and reset their values to the correct count based on the current map.
    resetListCount: =>
        @$list.find("li > span.count").html ""
        _.each @model.shapes().models, (shape) => @updateListCount shape

    # When shape is added to the map, check its entity type and update
    # its "count" to the current value + 1 on the `$list`.
    updateListCount: (shape, subtract) =>
        spanCount = @getSpanCountElement shape

        # Check the current count, or consider 0 if the span is empty.
        if spanCount.text().length > 0
            count = parseInt spanCount.text()
        else
            count = 0

        # Subtract - 1 if the `subtract` parameter is true, otherwise add + 1.
        if subtract? and subtract
            count--
        else
            count++

        # Update the span value.
        if count > 0
            spanCount.html count
        else
            spanCount.html ""

    # When shape is added to the map, check its entity definition ID and update
    # its "count" to the current value + 1 on the `$list`. If no item is found,
    # consider it being a Custom Shape.
    increaseListCount: (shape) =>
        @updateListCount shape

    # When shape is removed from the map, check its entity definition ID and update
    # its "count" to the current value - 1 on the `$list`. If no item is found,
    # consider it being a Custom Shape.
    subtractListCount: (shape) =>
        @updateListCount shape, true

    # Add a shape to the current map. If `x` and `y` are passed,
    # shape will be added on that specific position on the map.
    addShapeToMap: (entityObj, x, y) =>
        viewBox = @mapView.getViewBox()

        shapeOptions = {}

        x = (x * @mapView.currentZoom + viewBox.x) / (@model.gridSizeX())
        x = Math.round x

        y = (y * @mapView.currentZoom + viewBox.y) / (@model.gridSizeY())
        y = Math.round y

        if entityObj?
            entityDefinition = entityObj.collection.parentModel

            # Build the title property text, which should look similar to "#obj.name".
            title = entityDefinition.objectTitleAttribute()
            sep = title.indexOf ","
            title = title.substring(0, sep) if title.indexOf(",") > 0
            title = SystemApp.Settings.General.dataBindingKey + SystemApp.Settings.EntityObject.bindingNamespace + "." + title

            # Set shape options based on the [entity definition](entityDefinition) template.
            shapeOptions.textTitle = title
            shapeOptions.entityObjectId = entityObj.id
            shapeOptions.entityDefinitionId = entityObj.entityDefinitionId()
            shapeOptions.background = entityDefinition.shapeBackground()
            shapeOptions.fontSize = entityDefinition.shapeFontSize()
            shapeOptions.foreground = entityDefinition.shapeForeground()
            shapeOptions.icon = entityDefinition.shapeIcon()
            shapeOptions.opacity = entityDefinition.shapeOpacity()
            shapeOptions.roundedCorners = entityDefinition.shapeRoundedCorners()
            shapeOptions.sizeX = entityDefinition.shapeSizeX()
            shapeOptions.sizeY = entityDefinition.shapeSizeY()
            shapeOptions.stroke = entityDefinition.shapeStroke()
            shapeOptions.strokeWidth = entityDefinition.shapeStrokeWidth()
            shapeOptions.titleForeground = entityDefinition.shapeTitleForeground()
            shapeOptions.zIndex = entityDefinition.shapeZIndex()

        shapeOptions.x = x
        shapeOptions.y = y

        @model.shapes().create shapeOptions


    # DRAGGING SHAPES
    # ----------------------------------------------------------------------

    # When user starts dragging a shape from the `$list`, clone it to the `$shapeDragger` variable.
    dragStart: (e) =>
        if not @mapView.editEnabled
            return

        li = $ e.target
        entity = li.data "entity"
        background = SystemApp.Settings.Shape.background
        foreground = SystemApp.Settings.Shape.foreground
        sizeX = SystemApp.Settings.Shape.gridViewSizeX
        sizeY = SystemApp.Settings.Shape.gridViewSizeY

        @$shapeDragger = li.clone false
        @$shapeDragger.addClass "shape-dragger"

        if entity?
            entityDef = entity.collection.parentModel
            background = entityDef.get "shapeBackground"
            foreground = entityDef.get "shapeForeground"
            sizeX = entityDef.get "shapeSizeX"
            sizeY = entityDef.get "shapeSizeY"
            @$shapeDragger.data "entity", entity

        @$shapeDragger.css "background-color", background
        @$shapeDragger.css "color", foreground
        @$shapeDragger.css "width", sizeX * @model.gridSizeX() * (1 / @mapView.currentZoom) - 30
        @$shapeDragger.css "height", sizeY * @model.gridSizeY() * (1 / @mapView.currentZoom) - 10

        li.parent().append @$shapeDragger

        @dragMove e

        $(window).mousemove @dragMove
        $(window).mouseup @dragStop

    # When user is moving the mouse while dragging a shape, set its absolute position.
    dragMove: (e) =>
        @$shapeDragger.css "left", e.pageX - 1
        @$shapeDragger.css "top", e.pageY - 1

        e.preventDefault()
        e.stopPropagation()

    # When user releases the mouse button, check if the `$shapeDragger` was dragged
    # a SVG element (which means, to the map). If so, call the `addShapeToMap`.
    # Finally destroy the `$shapeDragger`.
    dragStop: (e) =>
        $(window).unbind "mousemove", @dragMove
        $(window).unbind "mouseup", @dragStop

        entity = @$shapeDragger.data "entity"
        @$shapeDragger?.remove()
        @$shapeDragger = null

        target = document.elementFromPoint e.pageX, e.pageY
        tag = target?.tagName

        if tag is "svg" or tag is "rect" or tag is "circle" or tag is "path"
            @addShapeToMap entity, e.pageX, e.pageY - 45

        e.preventDefault()
        e.stopPropagation()


    # SEARCH AND FILTER
    # ----------------------------------------------------------------------

    # When the search input field gets focus, remove its watermark (if there's one).
    searchFocus: =>
        value = @$txtSearch.val()

        if value is SystemApp.Messages.searchWatermark
            @$txtSearch.removeClass "watermark"
            @$txtSearch.val ""

    # When the search input field lots focus, add a watermark in case its text value is empty.
    searchBlur: =>
        value = @$txtSearch.val()

        if value.replace(" ", "") is ""
            @$txtSearch.addClass "watermark"
            @$txtSearch.val SystemApp.Messages.searchWatermark

    # Reset the `timerSearch`, which will be triggered in X miliseconds
    # defined on the [Settings](settings.html). Pressing the Esc key
    # will clear the search text field.
    prepareSearch: (e) =>
        if e.keyCode is 27
            @$txtSearch.val ""

        window.clearTimeout @timerSearch if @timerSearch isnt null
        @timerSearch = window.setTimeout @search, SystemApp.Settings.General.searchDelay

    # Filter the elements being shown on the entity list based on the `$txtSearch` value.
    # The "Custom shape..." is always shown on the results.
    search: =>
        @timerSearch = null
        value = @$txtSearch.val()
        items = @$list.children "li"

        # If value is empty, show everything.
        if $.trim(value) is ""
            items.css "display", "block"
            return

        prop = ""
        quantity = null
        value = value.replace "==", "="

        # Search for a valid eval separator.
        i = value.indexOf "="
        i = value.indexOf "<" if i < 0
        i = value.indexOf ">" if i < 0

        # If the separator is the first character, then search based on the quantity.
        # For example =2 will show all entities which are added twice to the map,
        # and >4 will show all entities which are added more than 4 times to the map.

        if i is 0
            separator = value.substring 0, 1
            quantity = value.substring 1
            quantity = "" if quantity is "0"
        else if i > 0
            separator = value.substring i, i + 1
            prop = value.substring 0, i
            value = value.substring i + 1

        _.each items, (li) =>
            li = $ li
            display = "block"
            entity = li.data "entity"
            spanQuantity = li.children("span.count").html()

            if entity?
                text = entity.title()

                # If the `prop` variable is empty, do a normal value comparison against the
                # text, otherwise it means it's an evaluation so do a dirty `eval()`
                # against the object's property. For example the value "db" will return all
                # entities which have "db" on its name, while value "internal_ip>10.1.1.1"
                # will return entities which have the property "internal_id" higher than
                # "10.1.1.1".
                if quantity?
                    if separator is "=" and spanQuantity isnt quantity
                        display = "none"
                    else if separator is ">" and spanQuantity <= quantity
                        display = "none"
                    else if separator is "<" and spanQuantity >= quantity
                        display = "none"
                else
                    try
                        if prop is "" and text?.search(new RegExp(value, "i")) < 0
                            display = "none"
                        else if prop isnt "" and not eval("entity.get('#{prop}')#{separator}'#{value}'")
                            display = "none"
                    catch ex
                        if text?.indexOf(value) < 0
                            display = "none"


            li.css "display", display