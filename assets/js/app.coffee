# System APP
# -----------------------------------------------------------------------------
# This is the base app controller.

#= require app.instance.coffee

# LIBS
# -----------------------------------------------------------------------------
#= require lib/jquery.js
#= require lib/jquery.localdata.js
#= require lib/jquery.cookie.js
#= require lib/jquery.joyride.js
#= require lib/jquery.tinycolourpicker.js
#= require lib/jsonpath.js
#= require lib/lodash.js
#= require lib/backbone.js
#= require lib/async.js
#= require lib/raphael.js
#= require lib/raphael.link.js
#= require lib/raphael.group.js

# APP UTILS AND MANAGERS
# -----------------------------------------------------------------------------
#= require settings.default.coffee
#= require settings.coffee
#= require messages.coffee
#= require vectors.coffee
#= require routes.coffee
#= require dataUtil.coffee

# APP MODELS
# -----------------------------------------------------------------------------
#= require model/base.coffee
#= require model/entityObject.coffee
#= require model/entityDefinition.coffee
#= require model/shape.coffee
#= require model/link.coffee
#= require model/map.coffee
#= require model/auditData.coffee
#= require model/eventRule.coffee
#= require model/eventAction.coffee
#= require model/auditEvent.coffee
#= require model/variable.coffee
#= require model/userSettings.coffee

# APP DATA, SOCKETS, TUTORIAL
# -----------------------------------------------------------------------------
#= require data.coffee
#= require sockets.coffee
#= require tutorial.coffee

# MAIN LAYOUT VIEWS
# -----------------------------------------------------------------------------
#= require view/baseView.coffee
#= require view/overlayView.coffee
#= require view/menuView.coffee
#= require view/footerView.coffee
#= require view/alertView.coffee

# OVERLAY AND MANAGERS VIEWS
# -----------------------------------------------------------------------------
#= require view/overlayView.coffee
#= require view/startView.coffee
#= require view/createMapView.coffee
#= require view/entityManagerView.coffee
#= require view/auditDataManagerView.coffee
#= require view/auditEventManagerView.coffee
#= require view/settingsView.coffee
#= require view/helpView.coffee
#= require view/scriptEditorView.coffee

# MAP, MAP CONTROLS AND SHAPES VIEWS
# -----------------------------------------------------------------------------
#= require view/map/labelEditView.coffee
#= require view/map/shapesMoverView.coffee
#= require view/map/shapeLabelsView.coffee
#= require view/map/shapeView.coffee
#= require view/map/linkLabelsView.coffee
#= require view/map/linkView.coffee
#= require view/map/linkCreatorView.coffee
#= require view/map/controls/mapTabView.coffee
#= require view/map/controls/entitiesTabView.coffee
#= require view/map/controls/shapeTabView.coffee
#= require view/map/controls/inspectorTabView.coffee
#= require view/map/controlsView.coffee
#= require view/mapView.coffee

# PUBLIC API
# -----------------------------------------------------------------------------
#= require api/api.coffee
#= require api/api.entity.coffee
#= require api/api.map.coffee
#= require api/api.auditData.coffee
#= require api/api.auditEvent.coffee
#= require api/api.variable.coffee
#= require api/api.view.coffee
#= require api/api.server.coffee


# APP VARIABLES
# -----------------------------------------------------------------------------
# To enable editing (inserting, updating, deleting) data on the app the
# user must access with the special querystring: ?godmode=true.
# To enable debugging messages, use ?debug=true.
# The `startDate` tells when the app was started (page loaded).
System.App.godMode = false
System.App.startDate = new Date()


# ROUTES
# -----------------------------------------------------------------------------
# All routes should be defined inside the [Routes](routes.html) file.
System.App.routes = null


# EVENT DISPATCHERS
# -----------------------------------------------------------------------------
# Holds Backbone objects to dispatch events on a global scope.
# Trigger events: `System.App.DISPATCHER.trigger "eventname", data`.
# List to events: `System.App.DISPATCHER.on "eventname", method`.
# Unbind events `System.App.DISPATCHER.off "eventname", method`.
System.App.alertEvents = null
System.App.dataEvents = null
System.App.mapEvents = null
System.App.menuEvents = null
System.App.serverEvents = null


# IDLE TIMER
# -----------------------------------------------------------------------------
# This is used to detect fow how long the app has been idle, so it can execute
# idle based actions (for example, refresh the browser every 12 hours).
System.App.idleTime = 0
System.App.timerIdleUpdate = null


# VIEWS
# -----------------------------------------------------------------------------
# Define all the app views.
System.App.alertView = null
System.App.auditDataManagerView = null
System.App.auditEventManagerView = null
System.App.createMapView = null
System.App.entityManagerView = null
System.App.footerView = null
System.App.helpView = null
System.App.mapView = null
System.App.menuView = null
System.App.settingsView = null
System.App.scriptEditorView = null
System.App.startView = null


# LOADING
# -----------------------------------------------------------------------------

# The "loading" image (DOM) which gets visible whenever the app
# has any major view state change.
System.App.$loading = null


# INIT AND DISPOSE
# -----------------------------------------------------------------------------

# Inits the app. First prepare the views, them set the DOM cache,
# load data to the Data object, init the menu and finally init the footer.
System.App.init = ->
    window.onerror = System.App.onError

    # Create the Backbone "Routes" object.
    System.App.routes = new System.Routes()

    # Init events and data.
    System.App.setEvents()
    System.App.Data.init()

    # Set views and idle timer.
    System.App.setDom()
    System.App.setViews()
    System.App.setIdleTimer()

    # Load data collections.
    System.App.Data.fetch()

    # Start the Socket.IO communcations.
    System.App.Sockets.start()

    # Apply user settings to the UI.
    System.App.initUserSettings()

    # Init the API, bind it to the "api" variable on the window.
    System.Api.init()

# Change the app UI based on the current user settings.
# Things like fullscreen, zoom, etc.
System.App.initUserSettings = ->
    if System.App.Data.userSettings.mapFullscreen()
        System.App.mapView.toggleFullscreen true
    if System.App.Data.userSettings.mapZoom() isnt 1
        System.App.mapView.zoomSet System.App.Data.userSettings.mapZoom()

# Set the DOM cache.
System.App.setDom = ->
    System.App.$loading = $ "#loading"

# Init the menu, footer and settings.
System.App.setViews = ->
    System.App.alertView = new System.AlertView()
    System.App.auditDataManagerView = new System.AuditDataManagerView()
    System.App.auditEventManagerView = new System.AuditEventManagerView()
    System.App.createMapView = new System.CreateMapView()
    System.App.entityManagerView = new System.EntityManagerView()
    System.App.footerView = new System.FooterView()
    System.App.helpView = new System.HelpView()
    System.App.mapView = new System.MapView()
    System.App.menuView = new System.MenuView()
    System.App.settingsView = new System.App.SettingsView()
    System.App.scriptEditorView = new System.ScriptEditorView()
    System.App.startView = new System.StartView()

# Create event dispatchers. Bind and listen to app events.
System.App.setEvents = ->
    $(document).keydown System.App.suppressBackspace
    $(document).keypress System.App.suppressBackspace

    System.App.alertEvents = _.clone(Backbone.Events)
    System.App.dataEvents = _.clone(Backbone.Events)
    System.App.mapEvents = _.clone(Backbone.Events)
    System.App.menuEvents = _.clone(Backbone.Events)
    System.App.serverEvents = _.clone(Backbone.Events)

    System.App.dataEvents.on "load", System.App.start

# Start the app after all major data has been loaded.
# First add a timeout to hide the `loading` overlay, then start backbone's history.
# If the hashtag is empty, show the [Start View](startView.html) automatically.
System.App.start = ->
    now = new Date()
    console.log "#{System.App.Settings.General.appTitle} START: #{now}"

    System.App.checkGodMode()

    # Start listening to model updates.
    System.App.alertView.listenToModels true
    
    Backbone.history.start()

# Dispose the app (called when user leaves the page).
System.App.dispose = ->
    System.App.Sockets.stop()
    System.App.alertView?.dispose()
    System.App.auditEventManagerView?.dispose()
    System.App.auditDataManagerView?.dispose()
    System.App.createMapView?.dispose()
    System.App.entityManagerView?.dispose()
    System.App.footerView?.dispose()
    System.App.helpView?.dispose()
    System.App.mapView?.dispose()
    System.App.menuView?.dispose()
    System.App.settingsView?.dispose()
    System.App.startView?.dispose()


# SECURITY
# -----------------------------------------------------------------------------

# Called on init to check if user has entered the special ?godmode=1 query string,
# or if the app is running under the localhost domain.
# Users can create and update data with no restrictions when in God Mode.
System.App.checkGodMode = ->
    godEnable = location.href.indexOf("?godmode=1") >= 0 or location.hostname is "localhost"

    if godEnable > 0 or not System.App.Settings.General.restrictedMode
        System.App.godMode = true
        return

    # Add a style to hide the delete and add icons.
    headStyle = ".full-overlay-contents .delete, .full-overlay-contents .add, .addrow{display:none !important}"
    $("<style type='text/css'>#{headStyle}</style>").appendTo("head")

    # Hide the locker div on the header and the "Delete map" button.
    $("div.lock").hide()
    $("#map-ctl-delete").hide()

    # Hide the Audit Data / Audit Event overlay buttons and inputs.
    $(".delete").hide()

    # Bind a function to hide input fields when data is loaded to the Audit Data / Audit Events overlay.
    $("#auditdata").find("input,select,textarea").prop("disabled", true).attr("readonly", true)
    $("#auditevents").find("input,select,textarea").prop("disabled", true).attr("readonly", true)
    $("#entitymanager").find("input,select,textarea").prop("disabled", true).attr("readonly", true)
    $("#map-ctl-init-script").prop("disabled", true)


# IDLE TIMER AND ACTIONS
# -----------------------------------------------------------------------------

# Start the idle timer handlers and bind the `resetIdleTime` to
# the mouse move event on the document.
System.App.setIdleTimer = ->
    System.App.timerIdleUpdate = setInterval System.App.idleTimerTick, System.App.idleTimerInterval
    $(document).mousemove System.App.resetIdleTime

# Tick the idle timer. This will increase the idleTime value by
# X milliseconds - value defined at the [Settings](settings.html).
System.App.idleTimerTick = ->
    System.App.idleTime += System.App.idleTimerInterval

    # Check if page needs to be refreshed based on the `idleRefreshMinutes`
    # value on the [Settings](settings.html).
    idleMinutes = System.App.idleTime / 60000
    if idleMinutes >= System.App.Settings.idleRefreshMinutes
        System.App.routes.refresh()

# Reset the idle time counter by setting the variable `idleTime` to 0.
System.App.resetIdleTime = ->
    System.App.idleTime = 0


# LOADING ICON METHODS
# -----------------------------------------------------------------------------

# Toggle the loading icon on or off (parameter enabled).
# A fade in/out effect is applied.
System.App.toggleLoading = (enabled) ->
    enabled = false if not enabled?

    if enabled
        System.App.$loading.fadeIn System.App.Settings.General.fadeDelay
    else
        System.App.$loading.fadeOut System.App.Settings.General.fadeDelay


# HELPERS
# -----------------------------------------------------------------------------

# Prevent accidental use of backspace which could trigger a `history.back()` on the page.
System.App.suppressBackspace = (e) ->
    if e.keyCode is 8 and not /input|textarea/i.test(e.target.nodeName)
        e.preventDefault()
        e.stopPropagation()
        return false


# DEBUGGING AND ERROR LOGGING
# -----------------------------------------------------------------------------

# Helper method to log to the console, but only if `debug` is set to true.
System.App.consoleLog = (method, message, obj) ->
    if System.App.Settings.General.debug
        if obj isnt undefined
            console.log method, message, obj
        else
            console.log method, message

# When an error occurs, log to the browser console and show the error message
# on the footer - [Alert View](alertView.html).
System.App.onError = (msg, url, line) ->
    try
        console.error msg, url, line
        System.App.alertEvents.trigger "footer", {title: "ERROR!", message: "#{msg} (line #{line})", isError: true}
    catch ex
        console.error "FATAL ERROR!", ex
    return false


# STARTING
# -----------------------------------------------------------------------------
$(document).ready ->
    System.App.init()