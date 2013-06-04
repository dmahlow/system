# SCRIPT EDIT VIEW
# --------------------------------------------------------------------------
# Overlay used to edit scripts and code snippets. At the moment it is used
# only to edit [map](map.html) `initScript`.

class SystemApp.ScriptEditorView extends SystemApp.OverlayView

    $txtScriptValue: null   # the textarea with the current script value
    $info: null             # the info text shown above the textarea
    $butSave: null          # the button used to save the script
    $errorMsg: null         # placeholder to show validation error messages

    propertyName: null      # the property which should be updated with the script value, for example a map initScript.
    timerHideError: null    # cached timer to hide the error message

    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the script edit view.
    initialize: =>
        @overlayInit "#script-editor"
        @setDom()
        @setEvents()
        @fullWidth = false

    # Dispose the script edit view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$txtScriptValue = $ "#script-editor-value"
        @$info = $ "#script-editor-info"
        @$butSave = $ "#script-editor-but-save"
        @$errorMsg = @$el.find "span.error"

    # Bind events to the DOM. This will effectively update the `model` automatically
    # whenever any input field value gets changed.
    setEvents: =>
        @$butSave.click @saveScriptValue

    # Set the model and property name to which the script editor should save a script.
    bind: (model, propertyName) =>
        @stopListening @model if @model?

        @model = model
        @propertyName = propertyName
        @$info.html SystemApp.Messages.ScriptEditorInfo[propertyName]

        if model?
            @$txtScriptValue.val(model.get propertyName)


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the current value of `$txtScriptValue`.
    currentValue: (value) =>
        if value?
            @$txtScriptValue.val value
        @$txtScriptValue.val()


    # VALIDATE AND SAVE
    # ----------------------------------------------------------------------

    # Validate and save the script to the property set on `propertyName` of the model.
    # For example when using this view to edit a [map](map.html) `initScript`.
    saveScriptValue: =>
        code = @currentValue()
        valMessage = SystemApp.DataUtil.validateEval code

        # If has a validation message, display it and stop here.
        if valMessage?
            @showError valMessage
            return false

        # All good? Save the script.
        @model.set @propertyName, code
        @model.save()

        @hide()

    # If script vaildation fails, show a message to the user.
    showError: (message) =>
        @warnField @$txtScriptValue

        @$errorMsg.html message
        @$errorMsg.show()

        # Hide the error message after a few seconds.
        clearTimeout(@timerHideError) if @timerHideError?
        @timerHideError = setTimeout @hideError, SystemApp.Settings.alert.hideDelay

    # Hide the error message and clear the `timerHideError` timeout.
    hideError: =>
        @timerHideError = null
        @$errorMsg.hide()


    ## SHOW AND HIDE
    # ----------------------------------------------------------------------

    # When showing the overlay, bind the `model` and `propertyName`. Make sure we
    # stop listening to the current `model` first, if there's one.
    onShow: (model, propertyName) =>
        @bind model, propertyName

    # Stop listening to events when the overlay is closed.
    onHide: =>
        @stopListening()
        @model = null
        @propertyName = null