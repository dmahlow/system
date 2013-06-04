# VARIABLE MANAGER VIEW
# --------------------------------------------------------------------------
# Represents the Variables overlay.

class SystemApp.VariableManagerView extends SystemApp.OverlayView

    $txtCreate: null        # the text input used to create a new variable
    $butCreate: null        # the button used to create a new variable
    $txtDescription: null   # the "Description" textbox when editing an variable item
    $txtCode: null          # the "URL" textbox when editing an variable item
    $butSave: null          # the "Save" button
    $codeErrorMsg: null     # message shown if code is not valid

    timerHideError: null    # cached timer to hide the error message



    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Audit Data overlay view.
    initialize: =>
        @currentSettings = SystemApp.Settings.variable
        @overlayInit "#variables"
        @setDom()
        @setEvents()

    # Dispose the Audit Data view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$menuItem = $ "#menu-variables"
        @$modelsList = $ "#variables-list"
        @$txtCreate = $ "#variables-txt-create"
        @$butCreate = $ "#variables-but-create"

        @$txtDescription = $ "#variables-txt-description"
        @$txtCode = $ "#variables-txt-code"
        @$butSave = $ "#variables-but-save"
        @$codeErrorMsg = $ "#variables-code-error"

    # Bind events to the DOM.
    setEvents: =>
        @$butCreate.click @createVariableClick
        @$txtCreate.keyup @createVariableKeyUp

        @$txtDescription.change @inputOnChange
        @$butSave.click @validateAndSaveCode


    # VARIABLE LIST
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

    # Bind all [Variable](variable.html) information from the [data store](data.html).
    bindVariables: =>
        @clear()
        @addToModelsList item for item in SystemApp.Data.variables.models


    # CREATING VARIABLE
    # ----------------------------------------------------------------------

    # When user clicks the "Add" variable button, add a new record to the
    # [Data.variables](data.html) and move focus to the properties form.
    createVariableClick: (e) =>
        newId = @$txtCreate.val()

        # The ID must have at least 2 chars.
        if newId.length < 2
            @warnField @$txtCreate
            return
        else
            newId = SystemApp.DataUtil.normalize newId, true

        item = SystemApp.Data.variables.create {friendlyId: newId}, {wait: true}
        @clearTextInputs()

    # If the `$txtCreate` field has focus, pressing Enter will call the `click`
    # event on the `$butCreate`.
    createVariableKeyUp: (e) =>
        if e.keyCode is 13
            @$butCreate.click()


    # VARIABLE PROPERTIES
    # ----------------------------------------------------------------------

    # Bind the variable information to the right form.
    # Listen to `refresh` events.
    onBindModel: =>
        if @model?
            @$txtDescription.val @model.description()
            @$txtCode.val @model.code()

    # Force the current data to be refreshed and displayed on the right panel.
    refreshData: =>
        @model.sourceUrl @$txtCode.val()
        @model.refreshData()

    # Triggered when the actual data of an [Variable](variable.html) item has been updated.
    # This will update the right panel with the new data.
    refreshDataOk: (item, data) =>
        @$preview.html JSON.stringify data, null, 4

    # Triggered when the actual data of an [Variable](variable.html) could not be refreshed.
    # This will show a message to the user.
    refreshDataError: (item, error) =>
        @$preview.html error

    # Validate and save the script to the `code` property.
    validateAndSaveCode: (e) =>
        code = @$txtCode.val()
        valMessage = SystemApp.DataUtil.validateEval code

        # If has a validation message, display it and stop here.
        if valMessage?
            @showCodeError valMessage
            return false

        # All good? Save the code to the model.
        @model.code code
        @model.save()

        @fieldSaved @$butSave

    # If script vaildation fails, show a message to the user.
    showCodeError: (message) =>
        @warnField @$txtCode

        @$codeErrorMsg.html message
        @$codeErrorMsg.show()

        # Hide the error message after a few seconds.
        clearTimeout(@timerHideError) if @timerHideError?
        @timerHideError = setTimeout @hideCodeError, SystemApp.Settings.alert.hideDelay

    # Hide the error message and clear the `timerHideError` timeout.
    hideCodeError: =>
        @timerHideError = null
        @$codeErrorMsg.hide()


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Bind the `keyUp` event when overlay is shown.
    onShow: =>
        @bindVariables()

        $(document).keyup @hasModelListKeyUp
        SystemApp.Data.variables.on "add", @addToModelsList
        SystemApp.Data.variables.on "remove", @removeFromModelsList

    # Save the `model` (if there's one) when the overlay is closed,
    # and remove the `keyUp` from the document.
    onHide: =>
        $(document).unbind "keyup", @hasModelListKeyUp
        SystemApp.Data.variables.off "add", @addToModelsList
        SystemApp.Data.variables.off "remove", @removeFromModelsList

        @model?.save()
        @model = null