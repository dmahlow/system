# LINK MODEL
# --------------------------------------------------------------------------
# Represents a link (connection) between two shapes on the map.
# Extends [Shape](shape.html).

class System.Link extends System.BaseModel
    typeName: "Link"
    defaults:
        arrowSource: System.App.Settings.Link.arrowSource
        arrowTarget: System.App.Settings.Link.arrowTarget
        fontSize: System.App.Settings.Link.fontSize
        foreground: System.App.Settings.Link.foreground
        labelOpacity: System.App.Settings.Link.labelOpacity
        opacity: System.App.Settings.Link.opacity
        smooth: System.App.Settings.Link.smooth
        stroke: System.App.Settings.Link.stroke
        strokeWidth: System.App.Settings.Link.strokeWidth
        zIndex: System.App.Settings.Link.zIndex


    # SYNC
    # ----------------------------------------------------------------------

    # Override the "save" method as we don't need to sync individual links with the server.
    save: (key, value, options) => @noSyncSave key, value, options

    # Override the "destroy" method as we don't need to sync individual links with the server.
    destroy: (options) => @noSyncDestroy options


    # MAIN PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to set / get the link's arrow source (0, 1 or 2).
    arrowSource: (value) =>
        if value?
            @set "arrowSource", value
        @get "arrowSource"

    # Helper to set / get the link's arrow target (0, 1 or 2).
    arrowTarget: (value) =>
        if value?
            @set "arrowTarget", value
        @get "arrowTarget"

    # Helper to set / get the link's font size.
    fontSize: (value) =>
        if value?
            @set "fontSize", value
        @get "fontSize"

    # Helper to set / get the link's label stroke.
    foreground: (value) =>
        if value?
            @set "foreground", value
        @get "foreground"

    # Helper to set / get the link's label opacity.
    labelOpacity: (value) =>
        if value?
            @set "labelOpacity", value
        @get "labelOpacity"

    # Helper to set / get the link opacity.
    opacity: (value) =>
        if value?
            @set "opacity", value
        @get "opacity"

    # Helper to set / get the link smooth (true or false).
    smooth: (value) =>
        if value?
            @set "smooth", value
        @get "smooth"

    # Helper to set / get the link stroke or border color.
    stroke: (value) =>
        if value?
            @set "stroke", value
        @get "stroke"

    # Helper to set / get the link stroke width.
    strokeWidth: (value) =>
        if value?
            @set "strokeWidth", value
        @get "strokeWidth"

    # Helper to get / set the link z-index value.
    zIndex: (value) =>
        if value?
            @set "zIndex", value
        @get "zIndex"


    # LABEL PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get the shape's default text.
    defaultText: =>
        @id

    # Helper to get / set the link text at the start of the link path.
    textStart: (value) =>
        if value?
            @set "textStart", value
        @get "textStart"

    # Helper to get / set the link text at the middle of the link path.
    textMiddle: (value) =>
        if value?
            @set "textMiddle", value
        @get "textMiddle"

    # Helper to get / set the link text at the end of the link path.
    textEnd: (value) =>
        if value?
            @set "textEnd", value
        @get "textEnd"


    # SOURCE / TARGET PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to set / get the source [Shape](shape.html) id.
    sourceId: (value)  =>
        if value?
            @set "sourceId", value
        @get "sourceId"

    # Helper to set / get the target [Shape](shape.html) id.
    targetId: (value)  =>
        if value?
            @set "targetId", value
        @get "targetId"


# LINK COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of links.

class System.LinkCollection extends System.BaseCollection
    typeName: "LinkCollection"
    model: System.Link

    # Override the default "create" method, as we don't need to sync
    # Shape models directly with the server.
    create: (model, options) => @noSyncCreate model, options

    # Set the comparator function to order the links collection by z-index.
    comparator: (link) -> return link.zIndex()