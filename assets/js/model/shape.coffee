# SHAPE MODEL
# --------------------------------------------------------------------------
# This model represents shapes on a map. Shapes will have their layout and
# properties defined depending on its related entity type.

class SystemApp.Shape extends SystemApp.BaseModel
    typeName: "Shape"
    defaults:
        background: SystemApp.Settings.Shape.background
        format: SystemApp.Settings.Shape.format
        fontSize: SystemApp.Settings.Shape.fontSize
        foreground: SystemApp.Settings.Shape.foreground
        opacity: SystemApp.Settings.Map.opacityStatic
        roundedCorners: SystemApp.Settings.Shape.roundedCorners
        sizeX: SystemApp.Settings.Shape.gridViewSizeX
        sizeY: SystemApp.Settings.Shape.gridViewSizeY
        stroke: SystemApp.Settings.Shape.stroke
        strokeWidth: SystemApp.Settings.Shape.strokeWidth
        titleForeground: SystemApp.Settings.Shape.titleForeground
        zIndex: SystemApp.Settings.Shape.zIndex


    # SYNC
    # ----------------------------------------------------------------------

    # Override the "save" method as we don't need to sync individual links with the server.
    save: (key, value, options) => @noSyncSave key, value, options

    # Override the "destroy" method as we don't need to sync individual links with the server.
    destroy: (options) => @noSyncDestroy options


    # MAIN PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the array of [AuditEvent](auditEvent.html) IDs.
    auditEventIds: (value) =>
        if value?
            @set "auditEventIds", value
        @get "auditEventIds"

    # Helper to set / set the shape background color.
    background: (value) =>
        if value?
            @set "background", value
        @get "background"

    # Helper to set / set the shape font size.
    fontSize: (value) =>
        if value?
            @set "fontSize", value
        @get "fontSize"

    # Helper to set / set the shape foreground (text) color.
    foreground: (value) =>
        if value?
            @set "foreground", value
        @get "foreground"

    # Helper to set / set the shape format, possible values are **rect** and **circle**.
    format: (value) =>
        if value?
            @set "format", value
        @get "format"

    # Helper to get / set the shape's icon.
    icon: (value) =>
        if value?
            @set "icon", value
        @get "icon"

    # Helper to get / set the shape opacity level, from 0.5 to 1;
    opacity: (value) =>
        if value?
            @set "opacity", value
        @get "opacity"

    # Helper to set / set the shape font size.
    roundedCorners: (value) =>
        if value?
            @set "roundedCorners", value
        @get "roundedCorners"

    # Helper to get / set the shape grid X size (for example 2 means it will be 2 blocks long).
    sizeX: (value)  =>
        if value?
            @set "sizeX", value
        @get "sizeX"

    # Helper to get / set the shape grid Y size (for example 3 means it will be 3 blocks high).
    sizeY: (value)  =>
        if value?
            @set "sizeY", value
        @get "sizeY"

    # Helper to set / set the shape stroke / border color.
    stroke: (value) =>
        if value?
            @set "stroke", value
        @get "stroke"

    # Helper to set / set the shape stroke / border width.
    strokeWidth: (value) =>
        if value?
            @set "strokeWidth", value
        @get "strokeWidth"

    # Helper to get / set the shape title.
    title: (value) =>
        if value?
            @set "title", value
        @get "title"

    # Helper to set / set the shape title foreground color.
    titleForeground: (value) =>
        if value?
            @set "titleForeground", value
        @get "titleForeground"

    # Helper to get / set the shape z-index, from 1 to 9.
    zIndex: (value)  =>
        if value?
            @set "zIndex", value
        @get "zIndex"


    # POSITION PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the X coordinate.
    x: (value) =>
        if value?
            @set "x", value

        result = @get "x"
        result = 0 if not result? or result < 0

        return result

    # Helper to get / set the Y coordinate.
    y: (value)  =>
        if value?
            @set "y", value

        result = @get "y"
        result = 0 if not result? or result < 0

        return result


    # LABEL PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get the shape's default text.
    defaultText: =>
        @textTitle()

    # Helper to get / set the shape title text.
    textTitle: (value) =>
        if value?
            @set "textTitle", value
        @get "textTitle"

    # Helper to get / set the shape central text.
    textCenter: (value) =>
        if value?
            @set "textCenter", value
        @get "textCenter"

    # Helper to get / set the shape left dynamic text.
    textLeft: (value) =>
        if value?
            @set "textLeft", value
        @get "textLeft"

    # Helper to get / set the shape top dynamic text.
    textTop: (value) =>
        if value?
            @set "textTop", value
        @get "textTop"

    # Helper to get / set the shape right dynamic text.
    textRight: (value) =>
        if value?
            @set "textRight", value
        @get "textRight"

    # Helper to get / set the shape bottom dynamic text.
    textBottom: (value) =>
        if value?
            @set "textBottom", value
        @get "textBottom"


    # ENTITY PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the entity type (DataCenter, Machine, Host, Service, etc).
    entityDefinitionId: (value) =>
        if value?
            @set "entityDefinitionId", value
        @get "entityDefinitionId"

    # Helper to get / set the entity ID.
    entityObjectId: (value) =>
        if value?
            @set "entityObjectId", value
        @get "entityObjectId"


# SHAPE COLLECTION
# --------------------------------------------------------------------------
# Base abstract collection for all shapes.

class SystemApp.ShapeCollection extends SystemApp.BaseCollection
    typeName: "ShapeCollection"
    model: SystemApp.Shape

    # Override the default "create" method, as we don't need to sync
    # Shape models directly with the server.
    create: (model, options) => @noSyncCreate model, options

    # Set the comparator function to order the shapes collection by z-index.
    comparator: (shape) -> return shape.zIndex()