# DEFAULT APP CLIENT SETTINGS
# --------------------------------------------------------------------------
# All default settings should be available here. Please DOT NOT edit
# this file unless you know excatly what you're doing. To overwrite settings,
# please edit (or create) the `settings.json` file on the same directory.

SystemApp.Settings =

    # GENERAL
    # ----------------------------------------------------------------------
    General:
        # Force set the debug mode. If true, most actions will be logged to the console.
        # If not set, it will be `false` on production environments and `true` on all other environments.
        debug: null
        # Set the profile mode. If true, performance profiles will be triggered automatically.
        profile: false
        # The title of the app.
        appTitle: "Zalando System"
        # Auto refresh the browser window at the specified time.
        autoRefreshTime: "0700"
        # The base url where to get JSON data (default is "json/").
        baseJsonUrl: "json/"
        # The special key / character used for data bindings.
        dataBindingKey: "#"
        # Interval when blinking a form or HTMl field.
        elementBlinkInterval: 150
        # Time in ms to fade in / out when using the show / hide methods of views.
        fadeDelay: 200
        # Time in ms to fade out removed elements on the view.
        fadeRemoveDelay: 800
        # Refresh the browser if the page has been idle for more than X minutes.
        idleRefreshMinutes: 60
        # The idle timer interval (tick every X milliseconds).
        idleTimerInterval: 60000
        # How many milliseconds to compare when checking local storage expiry date.
        localDataLifespan: 120000
        # How many parallels tasks can run by default? For example when refreshing shape labels.
        maxParallelTasks: 10
        # Pool time to watch for the fetching property of data collections.
        refetchDelay: 600
        # The url to the proxy downloader (used to download external files).
        remoteDownloaderUrl: "downloader/"
        # Minimum time in ms between saves to the remote MongoDB database.
        # Please note that all data will ALWAYS be saved locally.
        saveInterval: 2000
        # If true, only updated info will be saved to the server, otherwise
        # the whole model will be sent.
        savePatch: false
        # Delay when using a text field to search, on the EntityListView for example.
        searchDelay: 300


    # ENTITY DEFINITIONS
    # ----------------------------------------------------------------------
    EntityDefinition:
        # The default URL where to get entities from.
        url: "json/entitydefinition"
        # Maximum allowed refresh interval for entities, in seconds.
        maxRefreshInterval: 864000
        # Minimum allowed refresh interval for entities, in seconds.
        minRefreshInterval: 30
        # The default attribute which defines the ID of entity objects.
        objectIdAttribute: "id"
        # The default attribute which defines the title or name of entity objects.
        objectTitleAttribute: "name"
        # The default interval to refresh entity objects, in seconds.
        refreshInterval: 600
        # Prefix of DOM IDs set on each row representing an item on the EntityDefinitionView.
        rowListPrefix: "list-entitydefinition-"
        # The URL served as proxy between the server and the entity source URL.
        sourceUrlProxy: "json/entitydata/"


    # ENTITY OBJECTS
    # ----------------------------------------------------------------------
    EntityObject:
        # The default URL where to get entities from.
        url: "json/entityobject"
        # The namespace used for data binding.
        bindingNamespace: "obj"
        # The default attribute which defines the ID of entity objects.
        objectIdAttribute: "id"
        # The default interval to refresh entity objects, in seconds.
        refreshInterval: 3600
        # The default attribute which defines the title or name of entity objects.
        objectTitleAttribute: "name"


    # MAP
    # ----------------------------------------------------------------------
    Map:
        # The id of the map background element.
        id: "map-bg"
        # The url to the map(s) JSON.
        url: "json/map"
        # The default background color or image.
        background: "#000000"
        # Shape or link blink internval in ms.
        blinkInterval: 50
        # Shape or link blink internval in ms.
        blinkSlowInterval: 250
        # How long to display the updated border on the map,
        # before it resets to the "selected shape" border style.
        borderUpdatedDelay: 1400
        # Radius of rounded shape corners. Used only for rounded shapes.
        cornerRadius: 8
        # Name of the default colour palette when no palette is selected.
        defaultPalette: "Outliner"
        # Properties available to be shown on map options. Separated by |, and equivalent properties
        # separated by commas.
        displayProps: "name,hostname|internal_ip|external_ip,service_ip|memory,assigned_memory"
        # The URL to the background SVG editor.
        editBgUrl: "svg-edit/svg-editor.html"
        # On the "Entity List" DOM, add this prefix to each entity list item.
        entityListPrefix: "map-entity-list-"
        # All grid path elements will have this prefix + line number as ID.
        gridIdPrefix: "map-grid-"
        # The default shape width in pixels.
        gridSizeX: 18
        # The default shape height in pixels.
        gridSizeY: 14
        # The default grid stroke color.
        gridStroke: "#303030"
        # The opacity of action icons when mouse is NOT over them.
        icoActionsOpacity: 0.4
        # Size of the shape action icons (add label, link).
        icoActionsSize: 20
        # The URL to the shape "add label" icon.
        icoAddLabelUrl: "images/ico-shape-label.png"
        # The URL to the shape "linker" icon.
        icoLinkerUrl: "images/ico-shape-link.png"
        # The URL to the shape "resizer" icon.
        icoResizeUrl: "images/ico-shape-resize.png"
        # The shape label Y offset relative to the parent shape.
        labelOffsetY: 22
        # The default font size for shape labels.
        labelFontSize: 12
        # The refresh interval to update shapes, links and label values.
        labelRefreshInterval: 5000
        # Maximum zoom amount allowed.
        maxZoom: 1.80
        # Minimum grid size in pixels (distance between grid lines).
        minGridSize: 10
        # Minimum size of shapes when resizing, whereas 3 means shapes can't be smaller than 2 grid blocks.
        minGridSizeBlocks: 3
        # The minimum map paper size (width and height) in pixels.
        minPaperSize: 500
        # Minimum zoom amount allowed.
        minZoom: 0.50
        # For how long a mao is considered "new" (for example on the top menu),
        # value is defined in seconds. Default is 5 minutes.
        isNewInterval: 300
        # The opacity of map shapes when dragging.
        opacityDrag: 0.32
        # The opacity interval when animating map shapes, in milliseconds.
        opacityInterval: 200
        # The static opacity for map objects.
        opacityStatic: 0.9
        # The default map paper X size.
        paperSizeX: 1920
        # The default map paper Y size.
        paperSizeY: 1080
        # The reference (or target) shape shadow color when creating links.
        refShadowColor: "#FFFF33"
        # The default shape shadow color.
        shadowColor: "#FF6633"
        # Delay to show the shadow (to make sure it will have the correct size after snaping the shape to the grid).
        shadowDelay: 90
        # The default shape shadow opacity.
        shadowOpacity: 0.75
        # The default shape shadow strength.
        shadowStrength: 5
        # The default padding to apply to labels inside shapes (does not include the border).
        labelPadding: 5
        # The base URL where map thumbnails are located.
        thumbnailBaseUrl: "images/mapthumbs/"
        # The maximum age of the map's thumbnail before it's allowed to generate a new thumbnail again, in ms.
        thumbnailExpires: 60000
        # The default shape title color is white.
        titleColor: "#FFFFFF"
        # The default shape title shadow color is black.
        titleShadowColor: "#000000"
        # The shape title Y offset, upwards (so in this case 10 pixels on top of the shape).
        titleOffsetY: 10
        # How many milliseconds to wait before auto hiding the z-index identifiers on shapes.
        zIndexHideTimeout: 5000
        # Zoom step while zooming (0.10 means will zoom in or out 10%).
        zoomStep: 0.10
        # How long to wait before updating labels whem zooming, in milliseconds.
        zoomUpdateDelay: 400
        # Properties to ignore on the shape details tab.
        ignoreDisplayProps: "0,format,background,foreground,fontSize,stroke,strokeWidth," +
                            "map_position_x,map_position_y,physical_machine,sizeX,sizeY,roundedCorners,zIndex"


    # MAP MOVER
    # ----------------------------------------------------------------------
    MapMover:
        # The map shapes mover background.
        background: "#77AAFF"
        # The map shapes mover opacity.
        opacity: 0.25
        # The shape shadow color when moving multiple shapes.
        shadowColor: "#77AAFF"


    # SHAPES
    # ----------------------------------------------------------------------
    Shape:
        # The default shape background color.
        background: "#060606"
        # The namespace used for data binding.
        bindingNamespace: "shape"
        # ID of custom shapes.
        customId: "custom"
        # Text of custom shapes.
        customText: "Custom"
        # The default shape format (rect or circle).
        format: "rect"
        # The default label font size.
        fontSize: 10
        # The foreground color user for the shape's texts.
        foreground: "#FFFFFF"
        # Use rounded corners?
        roundedCorners: false
        # The default shape X size relative to the grid.
        gridViewSizeX: 4
        # The default shape Y size relative to the grid.
        gridViewSizeY: 4
        # The default shape opacity.
        opacity: 0.9
        # The default shape stroke / border color.
        stroke: "#F0F0F0"
        # The default shape stroke width.
        strokeWidth: 2
        # The default shape title color.
        titleForeground: "#FFFFFF"
        # The default z-index of shapes.
        zIndex: 5


    # LINK
    # ----------------------------------------------------------------------
    Link:
        # Default arrow size.
        arrowSize: 12
        # Default source arrow. 0 = no arrow, 1 = filled arrow, 2 = open arrow
        arrowSource: 0
        # Default target arrow. 0 = no arrow, 1 = filled arrow, 2 = open arrow
        arrowTarget: 0
        # The opacity of the circle that appear on shapes to create links.
        creatorOpacity: 0.2
        # The new link stroke color.
        creatorStroke: "#FF6666"
        # The new link width / strength.
        creatorWidth: 2
        # The label font size.
        fontSize: 12
        # The color of the link labels.
        foreground: "#CCEEFF"
        # The default link label opacity.
        labelOpacity: 0.9
        # The default link opacity.
        opacity: 0.9
        # Are links smooth by default? smooth = true, straight = false.
        smooth: true
        # The link stroke color.
        stroke: "#55EE88"
        # The link width / strength.
        strokeWidth: 3
        # The default z-index of links.
        zIndex: 3


    # LABEL EDITING
    # ----------------------------------------------------------------------
    LabelEdit:
        # CSS class name of the label edit view wrapper.
        className: "label-edit-view"
        # If eval fails, show the error message on the textbox for X milliseconds.
        evalErrorTimeout: 1500
        # Minimum size of the edit textbox (textbox size property).
        minTxtSize: 45
        # The opacity interval when showing or hiding a labelEditView.
        opacityInterval: 200


    # AUDIT DATA
    # ----------------------------------------------------------------------
    AuditData:
        # The url to the audit data(s) JSON.
        url: "json/auditdata"
        # The namespace used for data binding.
        bindingNamespace: "audit"
        # Alert the user if the data could not be refreshed for 6 times in a row.
        alertOnErrorCount: 6
        # Default interval to save the current data, in ms.
        dataSaveInterval: 60000
        # Round numbers to a maximum number of decimal cases.
        decimalCases: 0
        # What text to show when an audit data value is still being loaded.
        loadingText: "..."
        # Maximum allowed value for the refreshInterval, in seconds.
        maxRefreshInterval: 864000
        # Minimum allowed value for the refreshInterval, in seconds.
        minRefreshInterval: 3
        # Default interval to refresh the data from its sourceUrl, in ms.
        refreshInterval: 5
        # Prefix of DOM IDs set on each row representing an item on the AuditDataManagerView.
        rowListPrefix: "list-auditdata-"
        # Delay to start the audit data refresh timers when the app is loaded.
        startTimersDelay: 2000
        # Data will be considered outdated after X times the value of its refreshInterval.
        outdatedMultiplier: 3


    # AUDIT ALERT
    # ----------------------------------------------------------------------
    AuditEvent:
        # The url to the audit event(s) JSON.
        url: "json/auditevent"
        # The namespace used for data binding.
        bindingNamespace: "event"
        # How many times to blink if no value is specified on the alert action.
        blinkTimes: 2
        # The context special key used to test shape or link labels agains an [AuditEvent](auditEvent.html).
        contextSpecialKey: "@"
        # The color to use if no background/border color is specified on the alert action.
        defaultColor: "#FF6666"
        # Prefix of DOM IDs set on each row representing an item on the EntityDefinitionView.
        rowListPrefix: "list-auditevent-"
        # The prefix of action rows on the `$gridActions` grid of the [Audit Events View](auditEventManagerView.html).
        rowActionPrefix: "list-auditevent-action-"
        # The prefix of rule rows on the `$gridRules` grid of the [Audit Events View](auditEventManagerView.html).
        rowRulePrefix: "list-auditevent-rule-"
        # The checkbox group name (DOM) of the alerts manager for a specific shape.
        shapeCheckboxName: "shape-alerts-enabled"


    # AUDIT ALERT
    # ----------------------------------------------------------------------
    Variable:
        # The url to the variable(s) JSON.
        url: "json/variable"
        # The namespace used for data binding.
        bindingNamespace: "var"
        # Prefix of DOM IDs set on each row representing an item on the VariableManagerView.
        rowListPrefix: "list-variable-"


    # USER SETTINGS
    # ----------------------------------------------------------------------
    User:
        # The url to the user's JSON.
        url: "json/user"
        # The url to the logged user's JSON.
        loggedUrl: "json/user/logged"
        # Default key combination to delete shapes and links.
        modifierDelete: "ctrl rightclick"
        # Default key combination to select multiple shapes or items.
        modifierMultiple: "shift leftclick"
        # Default key combination to send shapes and links to the back of the map.
        modifierToBack: "rightclick"
        # Prefix of each row representing a user on a list or grid.
        rowListPrefix: "list-user-"


    # MENU
    # ----------------------------------------------------------------------
    Menu:
        # Timeout to hide submenus when mouse leaves them.
        hideTimeout: 400
        # Prefix of the ID of submenu items.
        subPrefix: "menu-filter-"


    # ALERT
    # ----------------------------------------------------------------------
    Alert:
        # How long should the alerts stay shown.
        hideDelay: 3000
        # How long it takes to fade in / out alerts.
        opacityInterval: 300
        # Minimum time between similar alerts to be shown.
        # For example if you save a map twice in less than 8 seconds, then just show the alert once.
        similarTimeout: 9000


    # FOOTER
    # ----------------------------------------------------------------------
    Footer:
        # How long it takes to fade in / out footer information.
        opacityInterval: 400


    # SOCKET SETTINGS
    # ----------------------------------------------------------------------
    Sockets:
        # Default "clients:refresh" command is 60 seconds.
        clientRefreshSeconds: 60