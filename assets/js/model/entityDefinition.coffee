# ENTITY DEFINITION MODEL
# --------------------------------------------------------------------------
# Represents a single entity definition and structure. The entity objects
# are represented by the [EntityObject](entityObject.html) model.

class SystemApp.EntityDefinition extends SystemApp.BaseModel
    typeName: "EntityDefinition"
    defaults:
        objectIdAttribute: SystemApp.Settings.entityDefinition.objectIdAttribute
        objectTitleAttribute: SystemApp.Settings.entityDefinition.objectTitleAttribute
        refreshInterval: SystemApp.Settings.entityDefinition.refreshInterval
        shapeBackground: SystemApp.Settings.shape.background
        shapeFormat: SystemApp.Settings.shape.format
        shapeFontSize: SystemApp.Settings.shape.fontSize
        shapeForeground: SystemApp.Settings.shape.foreground
        shapeOpacity: SystemApp.Settings.map.opacityStatic
        shapeRoundedCorners: SystemApp.Settings.shape.roundedCorners
        shapeSizeX: SystemApp.Settings.shape.gridViewSizeX
        shapeSizeY: SystemApp.Settings.shape.gridViewSizeY
        shapeStroke: SystemApp.Settings.shape.stroke
        shapeStrokeWidth: SystemApp.Settings.shape.strokeWidth
        shapeTitleForeground: SystemApp.Settings.shape.titleForeground
        shapeZIndex: SystemApp.Settings.shape.zIndex

    relations:
        data: SystemApp.EntityObjectCollection


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the entity objects data.
    # If a collection is already set, only updated its models.
    data: (value) =>
        if value?
            currentValue = @get "data"
            if currentValue?.typeName?
                value = value.models if value.typeName?
                currentValue.set value
            else
                value = new SystemApp.EntityObjectCollection(value) if not value.typeName?
                value.parentModel = this
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

class SystemApp.EntityDefinitionCollection extends SystemApp.BaseCollection
    typeName: "EntityDefinitionCollection"
    model: SystemApp.EntityDefinition
    url: SystemApp.Settings.entityDefinition.url

    # Set the comparator function to order the entity definitions by friendlyId.
    comparator: (entityDef) -> return entityDef.friendlyId()