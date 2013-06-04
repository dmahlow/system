# MAPFILTER MODEL
# --------------------------------------------------------------------------
# Represents a map containing a collection of [Shapes](shape.html)
# and [Links](link.html), and specific sizes and colours.

class SystemApp.Map extends SystemApp.BaseModel
    typeName: "Map"
    defaults:
        createdByUserId: null
        background: SystemApp.Settings.map.background
        paperSizeX: SystemApp.Settings.map.paperSizeX
        paperSizeY: SystemApp.Settings.map.paperSizeY
        gridSizeX: SystemApp.Settings.map.gridSizeX
        gridSizeY: SystemApp.Settings.map.gridSizeY
        thumbnailDate: new Date(2000, 1, 1)
        silent: false
        isReadOnly: false

    relations:
        links: SystemApp.LinkCollection
        shapes: SystemApp.ShapeCollection


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the ID of user who created the map.
    createdByUserId: (value) =>
        if value?
            @set "createdByUserId", value
        @get "createdByUserId"

    # Helper to get / set the map name.
    name: (value) =>
        if value?
            @set "name", value
        @get "name"

    # Helper to get / set the map creation date.
    dateCreated: (value) =>
        if value?
            @set "dateCreated", value
        @get "dateCreated"

    # Helper to get / set the map background: a color or image url.
    background: (value) =>
        if value?
            @set "background", value
        @get "background"

    # Helper to get / set the map paper X size, in pixels.
    paperSizeX: (value) =>
        if value?
            @set "paperSizeX", value
        @get "paperSizeX"

    # Helper to get / set the map paper Y size, in pixels.
    paperSizeY: (value) =>
        if value?
            @set "paperSizeY", value
        @get "paperSizeY"

    # Helper to get / set the map grid X size, in pixels. This represents the distance between vertical lines.
    gridSizeX: (value) =>
        if value?
            @set "gridSizeX", value
        @get "gridSizeX"

    # Helper to get / set the map grid Y size, in pixels. This represents the distance between horizontal lines.
    gridSizeY: (value) =>
        if value?
            @set "gridSizeY", value
        @get "gridSizeY"

    # Helper to get / set the map init script.
    initScript: (value) =>
        if value?
            @set "initScript", value
        @get "initScript"

    # Helper to get / set map isLocal flag.
    isLocal: (value) =>
        if value?
            @set "isLocal", value
        @get "isLocal"

    # Helper to get / set map read only flag.
    isReadOnly: (value) =>
        if value?
            @set "isReadOnly", value
        @get "isReadOnly"

    # Helper to get / set the map silent mode.
    silent: (value) =>
        if value?
            @set "silent", value
        @get "silent"

    # Helper to get / set the shapes and their positions on the map. This must set as a [ShapeCollection](shape.html).
    shapes: (value) =>
        if value?
            value = new SystemApp.ShapeCollection value if not value.typeName?
            @set "shapes", value
        @get "shapes"

    # Helper to get / set the links between shapes on the map. This must set as a [LinkCollection](link.html).
    links: (value) =>
        if value?
            value = new SystemApp.LinkCollection value if not value.typeName?
            @set "links", value
        @get "links"

    # Helper to get / set the last date when the map's thumbnail was generated.
    thumbnailDate: (value) =>
        if value?
            @set "thumbnailDate", value
        @get "thumbnailDate"

    # Helper to get the map's URL key based on its name: replace all spaces and special characters.
    urlKey: =>
        if @isLocal()
            return SystemApp.Settings.map.localMapId
        return SystemApp.DataUtil.getUrlKey @name()


    # LOCAL MAPS
    # ----------------------------------------------------------------------

    # Helper to get data from local storage and set map as local.
    initLocalMap: =>
        @id = SystemApp.Settings.map.localMapId
        @set "id", SystemApp.Settings.map.localMapId
        @set "isLocal", true
        @fetch()

        currentName = @name()

        if not currentName? or currentName is ""
            @name SystemApp.Messages.localMapName

        return @name()


    # VALIDATE
    # ----------------------------------------------------------------------

    # All validation rules should be put inside this method.
    validate: (attrs) =>

        # Name must be set.
        if not attrs.name? or attrs.name is ""
            return SystemApp.Messages.valNameIsRequired

        # Grid size X can't be too low.
        if not attrs.gridSizeX? or attrs.gridSizeX < SystemApp.Settings.map.minGridSize
            return SystemApp.Messages.valGridSizeTooSmall

        # Grid size Y can't be too low.
        if not attrs.gridSizeY? or attrs.gridSizeY < SystemApp.Settings.map.minGridSize
            return SystemApp.Messages.valGridSizeTooSmall

        # Paper size X can't be too low.
        if not attrs.paperSizeX? or attrs.paperSizeX < SystemApp.Settings.map.minPaperSize
            return SystemApp.Messages.valPaperSizeTooSmall

        # Paper size Y can't be too low.
        if not attrs.paperSizeY? or attrs.paperSizeY < SystemApp.Settings.map.minPaperSize
            return SystemApp.Messages.valPaperSizeTooSmall


    # SHAPE AND LINK METHODS
    # ----------------------------------------------------------------------

    # Removes a [Shape](shape.html) from the `shapes` collection.
    removeShape: (shape) =>
        @shapes().remove @shapes().get shape.id
        @removeShapeLinks shape

        @save()

    # Removes a all links related to the specified [Shape](shape.html) from the `links` collection.
    removeShapeLinks: (shape) =>
        _.each @links, (link) =>
            if link.sourceId() is shape.id or link.targetId() is shape.id
                @removeLink link

    # Remove a [Link](link.html) from the `links` collection.
    removeLink: (link) =>
        @links().remove @links().get link.id
        @save()

    # Clear all links which have invalid `sourceId` or `targetId`.
    clearInvalidLinks: =>
        removeLinks = []
        _.each @links().models, (link) =>
            if @shapes().where({id: link.sourceId()}).length < 1 or @shapes().where({id: link.targetId()}).length < 1
                removeLinks.push link.id

        for linkId in removeLinks
            @links().remove(@links().get linkId, {silent: true})

        @save()


# MAP COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of maps.

class SystemApp.MapCollection extends SystemApp.BaseCollection
    typeName: "MapCollection"
    model: SystemApp.Map
    url: SystemApp.Settings.map.url

    # Set the comparator function to order the maps collection by name.
    comparator: (map) -> return map.name()