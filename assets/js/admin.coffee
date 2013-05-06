# System APP
# -----------------------------------------------------------------------------
# This is the base app controller.

#= require app.instance.coffee

# LIBS
# -----------------------------------------------------------------------------
#= require lib/jquery.js
#= require lib/jquery.localdata.js
#= require lib/jquery.cookie.js
#= require lib/jsonpath.js
#= require lib/lodash.js
#= require lib/backbone.js
#= require lib/async.js

# APP UTILS AND MANAGERS
# -----------------------------------------------------------------------------
#= require settings.coffee
#= require messages.coffee
#= require dataUtil.coffee
#= require routes/adminRoutes.coffee

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

# MAIN LAYOUT VIEWS
# -----------------------------------------------------------------------------
#= require view/baseView.coffee
#= require view/adminView.coffee
#= require view/admin/usersTabView.coffee
#= require view/admin/toolsTabView.coffee


# ROUTES
# -----------------------------------------------------------------------------
# All routes should be defined inside the [Routes](routes.html) file.
SystemApp.routes = null


# INIT AND DISPOSE
# -----------------------------------------------------------------------------

# Inits the app. First prepare the views, them set the DOM cache,
# load data to the Data object, init the menu and finally init the footer.
SystemApp.init = ->
    window.onerror = SystemApp.onError
    SystemApp.currentView = new SystemApp.AdminView()

# HELPERS
# -----------------------------------------------------------------------------

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
    SystemApp.init()