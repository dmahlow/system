# ALERT VIEW
# --------------------------------------------------------------------------
# Controls and display alerts. This is NOT related to audit events, for these
# please go to the [Audit Events View](auditEventManagerView.html).
#
# Right now we have two alerts styles:
# Footer, which will show the alert on the footer bar, and Tooltip,
# which will display a floating overlay alert on the app.
# The main method to look here is the `showFooter`, which
# receives an alert object with the following possible properties:
#
# * (object) savedModel: if you're saving a model, you only need to set this property
# * (object) removedModel: if you're removing a model, you only need to set this property
# * (string) title: the title, which appears in strong text
# * (string) message: the alert message or description
# * (bool) isError: if true, alert will show in red, if false will show in green

class SystemApp.AlertView extends SystemApp.BaseView

    serverErrors: []          # keep a list of errors that happened on the server side
    queueFooter: []           # queue of footer alerts to be displayed
    queueTooltip: []          # queue of tooltip alerts to be displayed
    isFooterVisible: false    # is the footer alert being displayed at the moment?
    isTooltipVisible: false   # is the tooltip alert being displayed at the moment?
    lastFooterAlert: null     # holds the last footer alert


    # DOM CACHE
    # ----------------------------------------------------------------------

    $wrapperFooter: null   # the wrapper for the footer alert
    $titleFooter: null     # footer title element
    $msgFooter: null       # footer message span
    $timeFooter: null      # footer timespan element

    $wrapperTooltip: null  # the wrapper for the tooltip (overlay) alert
    $titleTooltip: null    # tooltip title element
    $msgTooltip: null      # tooltip message span
    $timeTooltip: null     # tooltip timespan element


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the alert view control.
    initialize: =>
        @setDom()
        @setEvents()

    # Dispose the alert cview control.
    dispose: =>
        $(document).off "keydown", @keyDown

        SystemApp.alertEvents.off "footer", @showFooter
        SystemApp.alertEvents.off "tooltip", @showTooltip
        SystemApp.serverEvents.off "error", @showServerError

        for collection in SystemApp.Data.allCollections
            collection.off "add", @modelAdded
            collection.off "remove", @modelRemoved

        @$wrapperFooter.css "display", "none"

        @queueFooter = null
        @queueTooltip = null

        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$wrapperFooter = $ "#alert-footer"
        @$titleFooter = @$wrapperFooter.children "label"
        @$msgFooter = @$wrapperFooter.children "span"
        @$timeFooter = @$wrapperFooter.children "time"

        @$wrapperTooltip = $ "#alert-tooltip"
        @$titleTooltip = @$wrapperTooltip.find "div > label"
        @$msgTooltip = @$wrapperTooltip.find "div > span"
        @$timeTooltip = @$wrapperTooltip.find "div > time"

    # Set and bind alert events to the view. It will automatically listen to models
    # added and removed from all collections available on the [data store](data.html).
    setEvents: =>
        $(document).keydown @keyDown

        SystemApp.alertEvents.on "footer", @showFooter
        SystemApp.alertEvents.on "tooltip", @showTooltip
        SystemApp.serverEvents.on "error", @showServerError


    # LISTEN TO MODEL UPDATES
    # ----------------------------------------------------------------------

    # If `listen` is true, view will show a footer alert whenever any model is added
    # or removed from the [data](data.html) collections. Set `listen` to false to stop
    # listening to these events.
    listenToModels: (listen) =>
        for collection in SystemApp.Data.allCollections
            collection.off "add", @modelAdded
            collection.off "remove", @modelRemoved
            collection.off "error", @modelError

        if listen
            for collection in SystemApp.Data.allCollections
                collection.on "add", @modelAdded
                collection.on "remove", @modelRemoved
                collection.on "error", @modelError

    # Listen to model updates.
    modelAdded: (model) =>
        @showFooter {savedModel: model}

    # Listen to model removals.
    modelRemoved: (model) =>
        @showFooter {removedModel: model}

    # Listen to model errors (while saving or fetching from server).
    modelError: (model, xhr) =>
        console.warn "Model error!!!", model, xhr


    # FOOTER ALERTS
    # ----------------------------------------------------------------------

    # Shows the specified title and message on the footer area.
    showFooter: (alertObj) =>
        alertObj.timestamp = new Date()

        if @lastFooterAlert?
            timeoutLess = (alertObj.timestamp - @lastFooterAlert.timestamp) < SystemApp.Settings.Alert.similarTimeout
            sameAlert = alertObj.title is @lastFooterAlert.title and alertObj.message is @lastFooterAlert.message

            # Avoid showing repeated alerts multiple times in a row.
            if timeoutLess and sameAlert
                return

        @lastFooterAlert = _.clone alertObj
        @queueFooter.push alertObj
        @nextFooter()

    # Get the next footer alert from the queue and display it.
    nextFooter: =>
        if @isFooterVisible or @queueFooter.length < 1
            return

        alertObj = @queueFooter.shift()
        title = null
        message = null

        # If there's a `savedModel` or `removedModel` property, try to use its
        # `text` or `name` property as title, and the type of the entity as the message.
        # Otherwise use the `title` and `message` properties of the alert object.
        if alertObj.savedModel?
            if alertObj.savedModel.text?
                title = alertObj.savedModel.text()
            else if alertObj.savedModel.friendlyId?
                title = alertObj.savedModel.friendlyId()
            else
                title = alertObj.savedModel.id
            message = alertObj.savedModel.typeName + " saved to the database!"
        else if alertObj.removedModel?
            if alertObj.removedModel.text?
                title = alertObj.removedModel.text()
            else if alertObj.removedModel.friendlyId?
                title = alertObj.removedModel.friendlyId()
            else
                title = alertObj.removedModel.id
            message = alertObj.removedModel.typeName + " REMOVED from the database!"
        else
            title = alertObj.title
            message = alertObj.message

        # Strip the timezone out of the time string, to keep it "compact".
        time = alertObj.timestamp.toTimeString()
        sep = time.indexOf "("
        time = time.substring(0, sep - 1) if sep > 0

        @$titleFooter.html title
        @$msgFooter.html message
        @$timeFooter.html time

        @$wrapperFooter.removeClass()

        if alertObj.isError
            @$wrapperFooter.addClass "error"
        else
            @$wrapperFooter.addClass "ok"

        delay = SystemApp.Settings.Alert.hideDelay
        delay = delay * 2 if alertObj.isError

        @$wrapperFooter.fadeIn SystemApp.Settings.Alert.opacityInterval
        @isFooterVisible = true
        _.delay @hideFooter, delay + SystemApp.Settings.Alert.opacityInterval

        # Log alerts to the console only if app is in debug mode.
        if SystemApp.Settings.General.debug
            if alertObj.isError
                console.warn "Alert Error", title, message
            else
                console.log "Alert Info", title, message

    # Hide the footer alert and call `nextFooter` again to check for new alerts.
    hideFooter: =>
        @isFooterVisible = false
        @$wrapperFooter.fadeOut SystemApp.Settings.Alert.opacityInterval, @nextFooter


    # TOOLTIP ALERTS
    # ----------------------------------------------------------------------

    # Show a tooltip alert.
    showTooltip: (alertObj) =>
        alertObj.timestamp = new Date()

        # Log alerts to the console only if app is in debug mode.
        if SystemApp.Settings.General.debug
            if alertObj.isError
                console.error "Alert", alertObj
            else
                console.log "Alert", alertObj

        @queueTooltip.push alertObj
        @nextTooltip()

    # Get the next tooltip alert from the queue and display it.
    nextTooltip: =>
        if @isTooltipVisible or @queueTooltip.length < 1
            return

        alertObj = @queueTooltip.shift()

        # Strip the timezone out of the time string, to keep it "compact".
        time = alertObj.timestamp.toTimeString()
        sep = time.indexOf "("
        time = time.substring(0, sep - 1) if sep > 0

        @$titleTooltip.html alertObj.title
        @$msgTooltip.html alertObj.message
        @$timeTooltip.html time

        @$wrapperTooltip.unbind "click"
        @$wrapperTooltip.removeClass()

        # Append the `error` or `ok` class, depending if isError is true or false.
        if alertObj.isError
            @$wrapperTooltip.addClass "error"
        else
            @$wrapperTooltip.addClass "ok"

        # Bind the click action to the tooltip container, if there's one specified.
        if alertObj.clickAction?
            @$wrapperTooltip.click alertObj.clickAction

        delay = SystemApp.Settings.Alert.hideDelay
        delay = delay if alertObj.isError

        @$wrapperTooltip.fadeIn SystemApp.Settings.Alert.opacityInterval
        @isTooltipVisible = true
        _.delay @hideTooltip, delay + SystemApp.Settings.Alert.opacityInterval

    # Hide a tooltip alert. NOT IMPLEMENTED YET!
    hideTooltip: =>
        @isTooltipVisible = false
        @$wrapperTooltip.fadeOut SystemApp.Settings.Alert.opacityInterval, @nextTooltip


    # SERVER ALERTS
    # ----------------------------------------------------------------------

    # Show an alert whenever an error happens on the node.js server.
    # This is triggered using Socket.IO.
    showServerError: (err) =>
        if SystemApp.Settings.General.debug
            @showFooter {isError: true, title: SystemApp.Messages.server + " " + err.title, message: err.message}


    # KEYBOARD EVENTS
    # ----------------------------------------------------------------------

    # When user presses the ESC key, hide the tooltip alert (if there's one visible).
    keyDown: (e) =>
        keyCode = e.keyCode
        if keyCode is 27
            @hideTooltip()