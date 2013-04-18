# MENU VIEW
# --------------------------------------------------------------------------
# Represents the top menu with links to all sub-views of the app like maps,
# settings, audit data, alerts and help overlay.

class System.MenuView extends System.BaseView

    height: 0                   # cached variable that holds the header height
    timerHideMenu: null         # timer to hide the menu after X milliseconds.

    $allMenus: null             # helper array containing all the menu items
    $menuCreateMap: null        # the "Create map" menu item
    $menuMaps: null             # the "Available maps" menu item
    $menuEntities: null         # the "Entities" menu item
    $menuAuditData: null        # the "Audit Data" menu item
    $menuAuditEvents: null      # the "Audit Events" menu item
    $menuSettings: null         # the "Settings" menu item
    $menuHelp: null             # the "Help" menu item
    $subMenuItems: null         # the div containing all sub menu items (which represents maps)
    $currentSub: null           # current selected map (sub-menu div)


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the menu view by settings the DOM, events, and creating the
    # submenu list with all available maps.
    initialize: =>
        @setDom()
        @setEvents()

    # Dispose the menu view.
    dispose: =>
        @$menuMaps.unbind "click"
        @$menuMaps.unbind "mouseover"
        @$menuMaps.unbind "mouseout"
        @$subMenuItems.unbind "mouseover"
        @$subMenuItems.unbind "mouseout"

        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#menu"

        @$menuCreateMap = $ "#menu-createmap"
        @$menuMaps = $ "#menu-maps"
        @$menuEntities = $ "#menu-entities"
        @$menuAuditData = $ "#menu-auditdata"
        @$menuAuditEvents = $ "#menu-auditevents"
        @$menuSettings = $ "#menu-settings"
        @$menuHelp = $ "#menu-help"

        @$allMenus = [@$menuCreateMap, @$menuMaps, @$menuEntities, @$menuAuditData,
                      @$menuAuditEvents, @$menuSettings, @$menuHelp]

        @$subMenuItems = $ "#submenu-items"

        @height = @$el.outerHeight()

    # Bind events to DOM and sub views.
    setEvents: =>
        @$menuCreateMap.click "click:createmap", @menuClick
        @$menuMaps.click "click:maps", @menuClick
        @$menuEntities.click "click:entities", @menuClick
        @$menuAuditData.click "click:auditdata", @menuClick
        @$menuAuditEvents.click "click:auditevents", @menuClick
        @$menuSettings.click "click:settings", @menuClick
        @$menuHelp.click "click:help", @menuClick

        @$menuMaps.click @showSubItems
        @$menuMaps.mouseover @showSubItems
        @$menuMaps.mouseout false, @showSubItems

        @$subMenuItems.mouseover true, @showSubItems
        @$subMenuItems.mouseout false, @showSubItems

        @listenTo System.App.Data.maps, "sync", @sortSubMenu
        @listenTo System.App.Data.maps, "add", @createSubMap
        @listenTo System.App.Data.maps, "remove", @removeSubMap
        @listenTo System.App.mapEvents, "load", @onMapLoad
        @listenTo System.App.menuEvents, "active:menu", @setActiveMenu
        @listenTo System.App.menuEvents, "active:map", @setActiveMap


    # MAP MENU AND SUBMENUS
    # ----------------------------------------------------------------------

    # When a [map](map.html) is loaded on the main [map view](mapView.html),
    # set the "Maps" menu to active.
    onMapLoad: (map) =>
        @setActiveMenu @$menuMaps

    # Add a single div to the `$subMenuItems`, which represents
    # a [Map](map.html). If firstBind is true, it means the menu hasn't been populated before,
    # otherwise it's a newly created [Map](map.html) being added.
    createSubMap: (map) =>
        if map.on?
            map.on "change", @updateMapInfo
            map.on "destroy", @removeSubMap

        # Map properties and date as cached variables.
        mapId = map.id
        mapName = map.name()
        dateCreated = map.dateCreated()
        now = new Date()

        # Create the map link.
        link = document.createElement "a"
        link = $ link
        link.attr "id", System.App.Settings.Menu.subPrefix + mapId
        link.attr "href", "#map/" + map.urlKey()
        link.addClass "menu-item"
        link.html mapName
        link.click @menuClick

        @$subMenuItems.append link

        # If map was created less than 5 minutes ago, then make it italic so
        # users can easily identify it on the list. The 5 minutes value is defined
        # on the [Settings](settings.html).
        if dateCreated? and (now - dateCreated) / 1000 < System.App.Settings.Map.isNewInterval
            link.addClass "italic"
            @setActiveMap map

    # Remove an exisiting div representing a [Map](map.html). Fired whenever
    # an item is removed from the main [Map Collection](data.html).
    removeSubMap: (map) =>
        try
            map.off()
            element = $ "#" + System.App.Settings.Menu.subPrefix + map.id
            element.remove() if element.length > 0
        catch ex
            console.warn "Could not remove menu map #{map.id}. Maybe it was already removed?", ex

    # Show or hide submenu items based on e.data, which can
    # be the source element, true to keep it shown, or false to force hide.
    # If e.data is the source element, then show the submenu items
    # which have that specific data type (datacenter, or machine, or host, or view...).
    showSubItems: (e) =>
        if @$menuMaps.hasClass "active"
            @toggleSubMenu false
            return

        if @timerHideMenu isnt null
            window.clearTimeout @timerHideMenu
            @timerHideMenu = null

        if e.data is false
            @timerHideMenu = window.setTimeout @toggleSubMenu, System.App.Settings.Menu.hideTimeout
            return

        if e.data is true
            return

        @$subMenuItems.css "left", @$menuMaps.offset().left
        @toggleSubMenu true

    # Show or hide the submenu items div, depending on the parameter `show`.
    toggleSubMenu: (show) =>
        if show? and show
            @$menuMaps.addClass "hover"
            @$subMenuItems.show()
        else
            @$menuMaps.removeClass "hover"
            @$subMenuItems.hide()

    # Sort the items on the map submenu.
    sortSubMenu: =>
        @sortList @$subMenuItems, "a"


    # MAP INTERACTIONS
    # ----------------------------------------------------------------------

    # When user clicks a menu button, trigger the event data
    # and hide all submenus.
    menuClick: (e) =>
        @toggleSubMenu false
        System.App.menuEvents.trigger e.data

    # Set the active menu item by making it look like a selected tab.
    setActiveMenu: (menu) =>
        item.removeClass("active") for item in @$allMenus
        menu.addClass "active"

    # Set the current active (highlighted) map on the menu.
    setActiveMap: (map) =>
        sub = $ "##{System.App.Settings.Menu.subPrefix}#{map.id}"
        @$currentSub?.removeClass "active"
        @$currentSub = sub

        if sub?
            sub.addClass "active"
            @setActiveMenu @$menuMaps

    # Triggered when a submenu item, representing a [Map](map.html),
    # has its name changed by the server or by the user.
    updateMapInfo: (map) =>
        link = $("#" + System.App.Settings.Menu.subPrefix + map.id)
        link.html map.name()
        link.attr "href", "#map/" + map.urlKey()