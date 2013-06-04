# START VIEW
# --------------------------------------------------------------------------
# Represents the Start overlay which is shown automatically when the user
# opens the app for the first time.

class SystemApp.StartView extends SystemApp.OverlayView

    $mapList: null          # the UL containing all available maps
    $imgPreview: null       # the map image preview


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Start overlay view.
    initialize: =>
        @overlayInit "#start"
        @setDom()
        @setEvents()
        @bindMaps()

    # Dispose the Start overlay view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$menuItem = $ "#menu-maps"
        @$mapList = $ "#start-maps"
        @$imgPreview = $ "#start-map-preview"

    # Bind events to the DOM.
    setEvents: =>
        contents = @$el.children ".full-overlay-contents"
        contents.mousemove @wrapperMouseMove

    # Bind the map list.
    bindMaps: =>
        if SystemApp.Data.maps.fetching or SystemApp.Data.maps.models.length < 1
            _.delay @bindMaps, SystemApp.Settings.general.refetchDelay
            return

        if SystemApp.Settings.map.enableLocalMap
            map = new SystemApp.Map()
            map.initLocalMap()
            @addMapToList map

        @addMapToList item for item in SystemApp.Data.maps.models

    # Add a single [Map](map.html) to the `$mapList` element.
    addMapToList: (map) =>
        name = $(document.createElement "div")
        name.addClass "name"
        name.html map.name()
        name.click map.urlKey(), @mapClick

        info = $(document.createElement "div")
        info.addClass "info"
        info.html SystemApp.Messages.mapInfoStats.replace("#S", map.shapes().length).replace("#L", map.links().length)

        div = $(document.createElement "div")
        div.mouseenter map.id, @showMapPreview
        div.append(name).append(info)

        @$mapList.append div

    # When mouse moves around any part of the view BUT the individual map divs, hide the preview image.
    wrapperMouseMove: (e) =>
        src = $ e.target
        testCurrent = src.attr("id") isnt "start-map-preview"
        testParent = src.parent().attr("id") isnt "start-maps" and src.parent().parent().attr("id") isnt "start-maps"
        if testCurrent and testParent
            @$imgPreview.css "display", "none"

    # When user clicks on a map name, open the map by changing the current URL.
    mapClick: (e) =>
        SystemApp.routes.navigate "#map/" + e.data, {trigger: true}

    # Update the right image to show a preview of the current map under the mouse pointer.
    showMapPreview: (e) =>
        @$imgPreview.attr "src", SystemApp.Settings.map.thumbnailBaseUrl + e.data + ".png"
        @$imgPreview.css "display", ""
        e.preventDefault()
        e.stopPropagation()