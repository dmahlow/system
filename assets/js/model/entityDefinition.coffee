# ENTITY DEFINITION MODEL
# --------------------------------------------------------------------------
# Represents a single entity definition and structure. The entity objects
# are represented by the [EntityObject](entityObject.html) model.

class System.EntityDefinition extends System.BaseModel
    typeName: "EntityDefinition"
    defaults:
        objectIdAttribute: SystemApp.Settings.EntityDefinition.objectIdAttribute
        objectTitleAttribute: SystemApp.Settings.EntityDefinition.objectTitleAttribute
        refreshInterval: SystemApp.Settings.EntityDefinition.refreshInterval
        shapeBackground: SystemApp.Settings.Shape.background
        shapeFormat: SystemApp.Settings.Shape.format
        shapeFontSize: SystemApp.Settings.Shape.fontSize
        shapeForeground: SystemApp.Settings.Shape.foreground
        shapeOpacity: SystemApp.Settings.Map.opacityStatic
        shapeRoundedCorners: SystemApp.Settings.Shape.roundedCorners
        shapeSizeX: SystemApp.Settings.Shape.gridViewSizeX
        shapeSizeY: SystemApp.Settings.Shape.gridViewSizeY
        shapeStroke: SystemApp.Settings.Shape.stroke
        shapeStrokeWidth: SystemApp.Settings.Shape.strokeWidth
        shapeTitleForeground: SystemApp.Settings.Shape.titleForeground
        shapeZIndex: SystemApp.Settings.Shape.zIndex

    relations:
        data: System.EntityObjectCollection


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the entity objects data.
    data: (value) =>
        if value?
            value = new System.EntityObjectCollection value if not value.typeName?
            @set "data", value
        @get "data"

    # Helper to get / set the description of the entity.
    description: (value) =>
        if value?
            @set "description", value
        @get "description"

    # Helper to get / set the id attribute.
    objectIdAttribute: (value) =>
        if value?
            @set "objectIdAttribute", value
        @get "objectIdAttribute"

    # Helper to get / set the title attribute(s).
    # More than one value can be set, separated by commas.
    # For example: "name,title,details"
    objectTitleAttribute: (value) =>
        if value?
            @set "objectTitleAttribute", value
        @get "objectTitleAttribute"

    # Helper to get / set the refresh interval.
    refreshInterval: (value) =>
        if value?
            @set "refreshInterval", value
        @get "refreshInterval"

    # Helper to get / set the entity data source URL.
    sourceUrl: (value) =>
        if value?
            @set "sourceUrl", value
        @get "sourceUrl"


    # SHAPE TEMPLATE PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the shape template background.
    shapeBackground: (value) =>
        if value?
            @set "shapeBackground", value
        @get "shapeBackground"

    # Helper to get / set the shape template font size.
    shapeFontSize: (value) =>
        if value?
            @set "shapeFontSize", value
        @get "shapeFontSize"

    # Helper to get / set the shape template label colour.
    shapeForeground: (value) =>
        if value?
            @set "shapeForeground", value
        @get "shapeForeground"

    # Helper to get / set the shape icon.
    shapeIcon: (value) =>
        if value?
            @set "shapeIcon", value
        @get "shapeIcon"

    # Helper to get / set the shape opacity (0.0 to 1.0).
    shapeOpacity: (value) =>
        if value?
            @set "shapeOpacity", value
        @get "shapeOpacity"

    # Helper to get / set the shape rounded corners (true or false).
    shapeRoundedCorners: (value) =>
        if value?
            @set "shapeRoundedCorners", value
        @get "shapeRoundedCorners"

    # Helper to get / set the shape template size X.
    shapeSizeX: (value) =>
        if value?
            @set "shapeSizeX", value
        @get "shapeSizeX"

    # Helper to get / set the shape template size Y.
    shapeSizeY: (value) =>
        if value?
            @set "shapeSizeY", value
        @get "shapeSizeY"

    # Helper to get / set the shape template border colour.
    shapeStroke: (value) =>
        if value?
            @set "shapeStroke", value
        @get "shapeStroke"

    # Helper to get / set the shape template border width.
    shapeStrokeWidth: (value) =>
        if value?
            @set "shapeStrokeWidth", value
        @get "shapeStrokeWidth"

    # Helper to get / set the shape template title colour.
    shapeTitleForeground: (value) =>
        if value?
            @set "shapeTitleForeground", value
        @get "shapeTitleForeground"

    # Helper to get / set the shape z-index / stack lavel.
    shapeZIndex: (value) =>
        if value?
            @set "shapeZIndex", value
        @get "shapeZIndex"


    # METHODS
    # ----------------------------------------------------------------------

    # Refresh the entity objects collection by fetching the specified
    # `sourceUrl` and updating the `data` property.
    # Only fetch external data if there's a URL specified.
    refreshData: =>
        url = @sourceUrl()
        if url? and url.length > 0
            @data().fetch {update: true}


# ENTITY COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of entity definitions.

class System.EntityDefinitionCollection extends System.BaseCollection
    typeName: "EntityDefinitionCollection"
    model: System.EntityDefinition
    url: SystemApp.Settings.EntityDefinition.url

    # Set the comparator function to order the entity definitions by friendlyId.
    comparator: (entityDef) -> return entityDef.friendlyId()