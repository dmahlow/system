# AUDIT DATA MODEL
# --------------------------------------------------------------------------
# Represents audit data from a single or multiple machines / hosts / services.

class SystemApp.AuditData extends SystemApp.BaseModel
    typeName: "AuditData"
    defaults:
        refreshInterval: SystemApp.Settings.auditData.refreshInterval

    # Holds the refresh error count. We'll use this to alert the user in case the audit data
    # couldn't be refreshed for more than X times - defined at the [Settings](settings.html).
    refreshErrorCount: 0

    # Holds the time when the property `data` has been last refreshed and saved to the DB server.
    lastDataRefresh: new Date()
    lastDataSave: new Date(2000, 1, 1)


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the audit data values.
    data: (value) =>
        if value?
            @set "data", value
        @get "data"

    # Helper to get / set the audit data description.
    description: (value) =>
        if value?
            @set "description", value
        @get "description"

    # Helper to get / set the audit data notes.
    notes: (value) =>
        if value?
            @set "notes", value
        @get "notes"

    # Helper to get / set the audit data refresh interval.
    refreshInterval: (value) =>
        if value?
            @set "refreshInterval", value
        @get "refreshInterval"

    # Helper to get / set the original source URL.
    sourceUrl: (value) =>
        if value?
            @set "sourceUrl", value
        @get "sourceUrl"


    # VALIDATE
    # ----------------------------------------------------------------------

    # All validation rules should be put inside this method.
    validate: (attrs) =>

        # Data source URL must be a valid URL.
        if not /((http|https):\/\/(\w+:{0,1}\w*@)?(\S+)|)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/.test attrs.sourceUrl
            return SystemApp.Messages.valInvalidUrl

        # Refresh interval can't be too low.
        if attrs.refreshInterval < SystemApp.Settings.auditData.minRefreshInterval
            return SystemApp.Messages.valRefreshIntervalTooLow


    # METHODS
    # ----------------------------------------------------------------------

    # Refresh the `data` property from the model's specified `sourceUrl` This will use the
    # server's proxy downloader (see the [Server Routes](server/routes.html) for more info)
    # to avoid cross-domain issues.
    refreshData: =>
        if @fetching
            return

        @fetching = true

        $.ajax
            url: SystemApp.Settings.general.remoteDownloaderUrl + "auditdata-" + @id
            timeout: @refreshInterval() * 3
            cache: false
            dataType: "json"
            type: "POST"
            success: @dataRefreshSuccess
            error: @dataRefreshError
            data:
                url: @sourceUrl()

    # When the data has been refreshed successfully, update the `data` property
    # which will trigger a change event across the app. If the `dataSaveInterval`
    # has passed, it will update the data on the local MongoDB server as well.
    dataRefreshSuccess: (resp) =>
        @fetching = false
        @refreshErrorCount = 0

        # If the data received is not valid, then do nothing.
        if not resp? or _.size(resp) < 1
            console.warn "Audit Data JSON is invalid!", this, resp
            return

        @data resp
        @lastDataRefresh = new Date()

        if @lastDataRefresh - @lastDataSave > SystemApp.Settings.auditData.dataSaveInterval
            @save()
            @lastDataSave = new Date()

        @trigger "refresh:ok", this, resp

        # Trigger an app event with the refresh result. That way we can easily listen
        # to refresh updates on all views.
        System?.App?.dataEvents.trigger "auditdata:refresh", this, resp

    # When the data refresh has thrown an error, trigger an error event which
    # will display the error info to the user.
    dataRefreshError: (resp, status, error) =>
        console.log "Audit Data: REFRESH ERROR", this, error, resp

        @fetching = false
        @refreshErrorCount++

        # If the refresh error count is more than 2 times the value set to show an alert, then
        # reset it to 0 so the user will see the alert again soon.
        if @refreshErrorCount > SystemApp.Settings.auditData.alertOnErrorCount * 2
            @refreshErrorCount = 0

        @trigger "refresh:error", this, error

        # Trigger an app event with the refresh error, so we can easily listen
        # to refresh errors and alert the user.
        System?.App?.dataEvents.trigger "auditdata:error", this, resp

    # Parse the given path and return its result (if path is valid).
    getPathValue: (path) =>
        return "" if not path? or path is ""

        # Get the path and first dot or bracket to find the path value.
        firstDot = path.indexOf "."
        firstBracket = path.indexOf "["

        if firstDot >= 0 and firstDot < firstBracket
            itemPath = path.substring firstDot
        else
            itemPath = path.substring firstBracket

        newValue = jsonPath @data(), "$" + itemPath

        # If the value is a number, make sure it's passed as Float and with 2 decimal cases.
        if newValue? and not isNaN(newValue)
            newValue = parseFloat(newValue[0]).toFixed SystemApp.Settings.auditData.decimalCases

        return newValue



# AUDIT DATA COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of audit data models.

class SystemApp.AuditDataCollection extends SystemApp.BaseCollection

    model: SystemApp.AuditData
    url: SystemApp.Settings.auditData.url