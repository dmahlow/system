# AUDIT DATA MANAGER VIEW
# --------------------------------------------------------------------------
# Represents the audit data overlay.

class SystemApp.AuditDataManagerView extends SystemApp.OverlayView

    $txtCreate: null         # the text input used to create a new audit data
    $butCreate: null         # the button used to create a new audit data
    $txtDescription: null    # the "Description" textbox when editing an audit data item
    $txtSourceUrl: null      # the "URL" textbox when editing an audit data item
    $txtRefresh: null        # the "Refresh interval" textbox when editing an audit data item
    $preview: null           # the "Preview" div showing the actual audit data


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Audit Data overlay view.
    initialize: =>
        @currentSettings = SystemApp.Settings.AuditData
        @overlayInit "#auditdata"
        @setDom()
        @setEvents()

    # Dispose the Audit Data view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$menuItem = $ "#menu-auditdata"
        @$modelsList = $ "#auditdata-list"
        @$txtCreate = $ "#auditdata-txt-create"
        @$butCreate = $ "#auditdata-but-create"

        @$txtDescription = $ "#auditdata-txt-description"
        @$txtSourceUrl = $ "#auditdata-txt-url"
        @$txtRefresh = $ "#auditdata-txt-refresh"

        @$preview = $ "#auditdata-preview"

    # Bind events to the DOM.
    setEvents: =>
        @$butCreate.click @createAuditDataClick
        @$txtCreate.keyup @createAuditDataKeyUp

        @$txtDescription.change @inputOnChange
        @$txtSourceUrl.change @inputOnChange
        @$txtRefresh.change @inputOnChange


    # AUDIT DATA LIST
    # ----------------------------------------------------------------------

    # Clear the current view by setting the `model` to null
    # and emptying the `$modelsList`.
    clear: =>
        @model = null
        @$modelsList.empty()
        @clearTextInputs()

    # Clear the text input fields.
    clearTextInputs: =>
        @$txtCreate.val ""

    # Bind all [AuditData](auditData.html) information from the [data store](data.html).
    bindAuditData: =>
        @clear()
        @addToModelsList item for item in SystemApp.Data.auditData.models


    # CREATING AUDIT DATA
    # ----------------------------------------------------------------------

    # When user clicks the "Add" audit data button, add a new record to the
    # [Data.auditData](data.html) and move focus to the properties form.
    createAuditDataClick: (e) =>
        newId = @$txtCreate.val()

        # The ID must have at least 2 chars.
        if newId.length < 2
            @warnField @$txtCreate
            return
        else
            newId = SystemApp.DataUtil.normalize newId, true

        item = SystemApp.Data.auditData.create {friendlyId: newId}, {wait: true}
        @clearTextInputs()

    # If the `$txtCreate` field has focus, pressing Enter will call the `click`
    # event on the `$butCreate`.
    createAuditDataKeyUp: (e) =>
        if e.keyCode is 13
            @$butCreate.click()


    # AUDIT DATA PROPERTIES
    # ----------------------------------------------------------------------

    # Bind the audit data information to the right form.
    # Listen to `refresh` events.
    onBindModel: =>
        if @model?
            @$txtDescription.val @model.description()
            @$txtSourceUrl.val @model.sourceUrl()
            @$txtRefresh.val @model.refreshInterval()
            @$preview.html JSON.stringify @model.data(), null, 4

    # Force the current data to be refreshed and displayed on the right panel.
    refreshData: =>
        @model.sourceUrl @$txtSourceUrl.val()
        @model.refreshData()

    # Triggered when the actual data of an [AuditData](auditData.html) item has been updated.
    # This will update the right panel with the new data.
    refreshDataOk: (item, data) =>
        @$preview.html JSON.stringify data, null, 4

    # Triggered when the actual data of an [AuditData](auditData.html) could not be refreshed.
    # This will show a message to the user.
    refreshDataError: (item, error) =>
        @$preview.html error


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Bind the `keyUp` event when overlay is shown.
    onShow: =>
        @bindAuditData()

        $(document).keyup @hasModelListKeyUp
        SystemApp.Data.auditData.on "add", @addToModelsList
        SystemApp.Data.auditData.on "remove", @removeFromModelsList

    # Save the `model` (if there's one) when the overlay is closed,
    # and remove the `keyUp` from the document.
    onHide: =>
        $(document).unbind "keyup", @hasModelListKeyUp
        SystemApp.Data.auditData.off "add", @addToModelsList
        SystemApp.Data.auditData.off "remove", @removeFromModelsList

        @model?.save()
        @model = null