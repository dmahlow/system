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
#= require lib/moment.js

# APP MODULES
# -----------------------------------------------------------------------------
#= require settings.coffee
#= require messages.coffee
#= require vectors.coffee
#= require dataUtil.coffee
#= require routes/appRoutes.coffee

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
#= require model/user.coffee
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
#= require view/variableManagerView.coffee
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
# The `startDate` tells when the app was started (page loaded).
SystemApp.startDate = new Date()


# ROUTES
# -----------------------------------------------------------------------------
# All routes should be defined inside the [Routes](routes.html) file.
SystemApp.routes = null


# EVENT DISPATCHERS
# -----------------------------------------------------------------------------
# Holds Backbone objects to dispatch events on a global scope.
# Trigger events: `SystemApp.DISPATCHER.trigger "eventname", data`.
# List to events: `SystemApp.DISPATCHER.on "eventname", method`.
# Unbind events `SystemApp.DISPATCHER.off "eventname", method`.
SystemApp.alertEvents = null
SystemApp.dataEvents = null
SystemApp.mapEvents = null
SystemApp.menuEvents = null
SystemApp.serverEvents = null


# IDLE TIMER
# -----------------------------------------------------------------------------
# This is used to detect fow how long the app has been idle, so it can execute
# idle based actions (for example, refresh the browser every 12 hours).
SystemApp.idleTime = 0
SystemApp.timerIdleUpdate = null


# VIEWS
# -----------------------------------------------------------------------------
# Define all the app views.
SystemApp.alertView = null
SystemApp.auditDataManagerView = null
SystemApp.auditEventManagerView = null
SystemApp.createMapView = null
SystemApp.entityManagerView = null
SystemApp.footerView = null
SystemApp.helpView = null
SystemApp.mapView = null
SystemApp.menuView = null
SystemApp.settingsView = null
SystemApp.scriptEditorView = null
SystemApp.startView = null
SystemApp.variableManagerView = null


# DOM CACHE
# -----------------------------------------------------------------------------

# The "loading" image (DOM) which gets visible whenever the app
# has any major view state change, and the "debug" notice element.
SystemApp.$loading = null
SystemApp.$debug = null


# INIT AND DISPOSE
# -----------------------------------------------------------------------------

# Inits the app. First prepare the views, them set the DOM cache,
# load data to the Data object, init the menu and finally init the footer.
SystemApp.init = ->
    window.onerror = SystemApp.onError

    # Create the Backbone "Routes" object.
    SystemApp.routes = new SystemApp.AppRoutes()

    # Init events and data.
    SystemApp.setEvents()
    SystemApp.Data.init()

    # Set views, options via querystrings and idle timer.
    SystemApp.setDom()
    SystemApp.setViews()
    SystemApp.setIdleTimer()

    # Load data collections.
    SystemApp.Data.fetch()

    # Start the Socket.IO communcations.
    SystemApp.Sockets.start()

    # Set UI options based on user settings and querystrings.
    SystemApp.setUiOptions()

    # Init the API, bind it to the "api" variable on the window.
    SystemApp.Api.init()

# Set the DOM cache.
SystemApp.setDom = ->
    SystemApp.$loading = $ "#loading"
    SystemApp.$debug = $ "#footer-debug"

# Init the menu, footer and settings.
SystemApp.setViews = ->
    SystemApp.alertView = new SystemApp.AlertView()
    SystemApp.auditDataManagerView = new SystemApp.AuditDataManagerView()
    SystemApp.auditEventManagerView = new SystemApp.AuditEventManagerView()
    SystemApp.createMapView = new SystemApp.CreateMapView()
    SystemApp.entityManagerView = new SystemApp.EntityManagerView()
    SystemApp.footerView = new SystemApp.FooterView()
    SystemApp.helpView = new SystemApp.HelpView()
    SystemApp.mapView = new SystemApp.MapView()
    SystemApp.menuView = new SystemApp.MenuView()
    SystemApp.settingsView = new SystemApp.SettingsView()
    SystemApp.scriptEditorView = new SystemApp.ScriptEditorView()
    SystemApp.startView = new SystemApp.StartView()
    SystemApp.variableManagerView = new SystemApp.VariableManagerView()

# Create event dispatchers. Bind and listen to app events.
SystemApp.setEvents = ->
    $(document).keydown SystemApp.suppressBackspace
    $(document).keypress SystemApp.suppressBackspace

    SystemApp.alertEvents = _.clone(Backbone.Events)
    SystemApp.dataEvents = _.clone(Backbone.Events)
    SystemApp.mapEvents = _.clone(Backbone.Events)
    SystemApp.menuEvents = _.clone(Backbone.Events)
    SystemApp.serverEvents = _.clone(Backbone.Events)

    SystemApp.dataEvents.on "load", SystemApp.start

# Toggle app options based on user settings and passed querystrings.
SystemApp.setUiOptions = ->
    query = location.href.substring location.href.indexOf "?"
    qDebug = query.indexOf("debug=") + 6
    qDebug = query.substring qDebug, qDebug + 1
    qFullscreen = query.indexOf("fullscreen=") + 11
    qFullscreen = query.substring qFullscreen, qFullscreen + 1
    qDemo = (query.indexOf("demo=1") > 0)

    if qDebug is "1"
        SystemApp.toggleDebug true
    else if qDebug is "0"
        SystemApp.toggleDebug false

    # Set fullscreen if `fullscreen` querystring is set, or if
    # the `mapFullscreen` option is defined on the [user settings](userSettings.html).
    if qFullscreen is "1"
        SystemApp.mapView.controlsView.toggleFullscreen true
    else if qFullscreen is "0"
        SystemApp.mapView.controlsView.toggleFullscreen false
    else if SystemApp.Data.userSettings.mapFullscreen()
        SystemApp.mapView.controlsView.toggleFullscreen true

    # If `demo=1`, hide the icon to toggle fullscreen mode and the "online user count".
    # Used on the mini demo site.
    if qDemo
        $("#top-img-fullscreen").hide()
        $("#footer-online-users").hide()
    
    if SystemApp.Data.userSettings.mapZoom() isnt 1
        SystemApp.mapView.zoomSet SystemApp.Data.userSettings.mapZoom()

# Start the app after all major data has been loaded.
# First add a timeout to hide the `loading` overlay, then start backbone's history.
# If the hashtag is empty, show the [Start View](startView.html) automatically.
SystemApp.start = ->
    now = new Date()
    console.log "#{SystemApp.Settings.General.appTitle} START: #{now}"

    # Disabled editing by default.
    SystemApp.mapEvents.trigger "edit:toggle", false

    # Start listening to model updates.
    SystemApp.alertView.listenToModels true
    
    Backbone.history.start()

# Dispose the app (called when user leaves the page).
SystemApp.dispose = ->
    SystemApp.Sockets.stop()
    SystemApp.alertView?.dispose()
    SystemApp.auditEventManagerView?.dispose()
    SystemApp.auditDataManagerView?.dispose()
    SystemApp.createMapView?.dispose()
    SystemApp.entityManagerView?.dispose()
    SystemApp.footerView?.dispose()
    SystemApp.helpView?.dispose()
    SystemApp.mapView?.dispose()
    SystemApp.menuView?.dispose()
    SystemApp.settingsView?.dispose()
    SystemApp.startView?.dispose()
    SystemApp.variableManagerView?.dispose()


# IDLE TIMER AND ACTIONS
# -----------------------------------------------------------------------------

# Start the idle timer handlers and bind the `resetIdleTime` to
# the mouse move event on the document.
SystemApp.setIdleTimer = ->
    SystemApp.timerIdleUpdate = setInterval SystemApp.idleTimerTick, SystemApp.idleTimerInterval
    $(document).mousemove SystemApp.resetIdleTime

# Tick the idle timer. This will increase the idleTime value by
# X milliseconds - value defined at the [Settings](settings.html).
SystemApp.idleTimerTick = ->
    SystemApp.idleTime += SystemApp.idleTimerInterval

    # Check if page needs to be refreshed based on the `idleRefreshMinutes`
    # value on the [Settings](settings.html).
    idleMinutes = SystemApp.idleTime / 60000
    if idleMinutes >= SystemApp.Settings.idleRefreshMinutes
        SystemApp.routes.refresh()

# Reset the idle time counter by setting the variable `idleTime` to 0.
SystemApp.resetIdleTime = ->
    SystemApp.idleTime = 0


# LOADING ICON METHODS
# -----------------------------------------------------------------------------

# Toggle the loading icon on or off (parameter enabled).
# A fade in/out effect is applied.
SystemApp.toggleLoading = (enabled) ->
    enabled = false if not enabled?

    if enabled
        SystemApp.$loading.fadeIn SystemApp.Settings.General.fadeDelay
    else
        SystemApp.$loading.fadeOut SystemApp.Settings.General.fadeDelay


# HELPERS
# -----------------------------------------------------------------------------

# Enable or disable the `debug` mode.
SystemApp.toggleDebug = (enabled) ->
    SystemApp.Settings.General.debug = enabled

    if enabled
        SystemApp.$debug.show()
    else
        SystemApp.$debug.hide()

# Prevent accidental use of backspace which could trigger a `history.back()` on the page.
SystemApp.suppressBackspace = (e) ->
    if e.keyCode is 8 and not /input|textarea/i.test(e.target.nodeName)
        e.preventDefault()
        e.stopPropagation()
        return false


# DEBUGGING AND ERROR LOGGING
# -----------------------------------------------------------------------------

# Helper method to log to the console, but only if `debug` is set to true.
SystemApp.consoleLog = (method, message, obj) ->
    if SystemApp.Settings.General.debug
        if obj isnt undefined
            console.log method, message, obj
        else
            console.log method, message

# When an error occurs, log to the browser console and show the error message
# on the footer - [Alert View](alertView.html).
SystemApp.onError = (msg, url, line) ->
    try
        console.error msg, url, line
        SystemApp.alertEvents.trigger "footer", {title: "ERROR!", message: "#{msg} (line #{line})", isError: true}
    catch ex
        console.error "FATAL ERROR!", ex
    return false


# STARTING
# -----------------------------------------------------------------------------
$(document).ready ->
    # Init the app.
    SystemApp.init()