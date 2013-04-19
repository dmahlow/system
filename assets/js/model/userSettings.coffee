# USER SETTINGS
# --------------------------------------------------------------------------
# Contains customizable user settings, which are saved on the browser's
# Local Storage. This model is currently NOT sync'd with MongoDB!

class System.UserSettings extends System.BaseModel
    typeName: "UserSettings"
    defaults:
        mapAutoRefresh: true
        mapShowBackground: true
        mapFullSizeIcons: false
        mapShowLinks: true
        mapFullscreen: false
        mapOverrideShapeTitle: false
        mapZoom: 1
        mapLabelRefreshInterval: System.App.Settings.Map.labelRefreshInterval
        modifierDelete: System.App.Settings.User.modifierDelete
        modifierMultiple: System.App.Settings.User.modifierMultiple
        modifierToBack: System.App.Settings.User.modifierToBack
        slowDevice: false


    # MAP OPTIONS
    # ----------------------------------------------------------------------

    # Helper to get / set the "Audit data auto update" map option.
    mapAutoRefresh: (value) =>
        if value?
            @set "mapAutoRefresh", value
        @get "mapAutoRefresh"

    # Helper to get / set the "Show background" map option.
    mapShowBackground: (value) =>
        if value?
            @set "mapShowBackground", value
        @get "mapShowBackground"

    # Helper to get / set the "Full size icons" map option.
    mapFullSizeIcons: (value) =>
        if value?
            @set "mapFullSizeIcons", value
        @get "mapFullSizeIcons"

    # Helper to get / set the "Show links" map option.
    mapShowLinks: (value) =>
        if value?
            @set "mapShowLinks", value
        @get "mapShowLinks"

    # Helper to get / set the "Fullscreen view" map option.
    mapFullscreen: (value) =>
        if value?
            @set "mapFullscreen", value
        @get "mapFullscreen"

    # Helper to get / set the "Shape's title" map option.
    mapOverrideShapeTitle: (value) =>
        if value?
            @set "mapOverrideShapeTitle", value
        @get "mapOverrideShapeTitle"

    # Helper to get / set the map zoom.
    mapZoom: (value) =>
        if value?
            @set "mapZoom", value
        @get "mapZoom"

    # Helper to get / set the "Map labels refresh interval".
    mapLabelRefreshInterval: (value) =>
        if value?
            @set "mapLabelRefreshInterval", value
        @get "mapLabelRefreshInterval"


    # MODIFIER KEYS
    # ----------------------------------------------------------------------

    # Helper to get / set the "Delete" modifier combination keys. Default is "Ctrl + Left Click".
    modifierDelete: (value) =>
        if value?
            @set "modifierDelete", value
        @get "modifierDelete"

    # Helper to get / set the "Multiple" modifier combination keys. Default is "Shift".
    modifierMultiple: (value) =>
        if value?
            @set "modifierMultiple", value
        @get "modifierMultiple"

    # OBSOLETE!!! Helper to get / set the "To Back" modifier combination keys.
    modifierToBack: (value) =>
        if value?
            @set "modifierToBack", value
        @get "modifierToBack"


    # OTHER OPTIONS
    # ----------------------------------------------------------------------

    # Helper to get / set the slowDevice setting - will be true on slow devices.
    slowDevice: (value) =>
        if value?
            @set "slowDevice", value
        @get "slowDevice"


    # OVERRIDE SYNC
    # ----------------------------------------------------------------------

    # Override the `fetch` method. We don't need to sync user settings with the server.
    fetch: (options) => @fetchLocal()

    # Override the `save` method. We don't need to sync user settings with the server.
    save: (options) => @saveLocal()