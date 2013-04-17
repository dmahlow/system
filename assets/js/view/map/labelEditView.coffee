# LABEL EDIT VIEW
# --------------------------------------------------------------------------
# Overlay that is shown whenever the user clicks an editable label on the map.
# Right now this can happen on [Shape Views](shapeView.html) and [Link Views](linkView.html).

class System.MapLabelEditView extends System.BaseView

    tagName: "div"
    className: System.App.Settings.LabelEdit.className

    ox: 0                       # temporary value to hold the original X (left) position of the view
    oy: 0                       # temporary value to hold the original Y (top) position of the view
    lastPressedKey: null        # holds the last pressed key by the user
    lastEvalCode: null          # holds the value of the last entered / validated eval code
    currentVariable: null       # holds the current [Variable](variable.html) being edited

    $currentValueSpan: null     # the span with the current value of the attached label
    $txtSimple: null            # the textbox used to edit the label
    $txtCustomVarName: null     # the textbox that sets the name of the new [Variable](variable.html)
    $txtCustomVarCode: null     # the textarea used to edit complex eval values
    $linkCreateCustomVar: null  # the link/button to create a new custom variable
    $butSaveCustomVar: null     # the "Save custom variable" button
    $autoCompleteDiv: null      # the autocomplete div (displayed below the edit textbox)
    $simpleWrapper: null        # the simple div container (wrapper for the txtSimple and autoCompleteDiv)
    $customVarWrapper: null     # the custom variable div container (wrapper for txtCustomVarName and txtCustomVarCode)

    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the label edit view and set its parent view.
    initialize: =>
        @baseInit()

    # Base dispose for all shapes.
    dispose: =>
        @hide()

        @currentVariable = null

        @baseDispose()


    # HELPER PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the current value of `$txtCustomVarName`.
    customVarNameValue: (value) =>
        if value?
            @$txtCustomVarName.val value
        @$txtCustomVarName.val()

    # Helper to get / set the current value of `$txtCustomVarCode`.
    customVarCodeValue: (value) =>
        if value?
            @$txtCustomVarCode.val value
        @$txtCustomVarCode.val()

    # Helper to get / set the current value of `$txtSimple`.
    simpleValue: (value) =>
        if value?
            @$txtSimple.val value
        @$txtSimple.val()

    # Helper to get / set the value of the `$currentValueSpan` element.
    currentValue: (value) =>
        if value?
            @$currentValueSpan.html value
        @$currentValueSpan.html()

    # Helper to get / set the value of the `$autoCompleteDiv` element.
    autoCompleteValue: (value) =>
        if value?
            @$autoCompleteDiv.empty()

            # If value is array, bind each of its elements.
            if value instanceof Array
                @$autoCompleteDiv.append item for item in value
            else
                @$autoCompleteDiv.append value

            # If value is empty, hide the div so it doesn't show a white space.
            if @$autoCompleteDiv.html().length > 1
                @$autoCompleteDiv.css "display", ""
            else
                @$autoCompleteDiv.css "display", "none"

        @$autoCompleteDiv.html()


    # RENDER AND POSITIONING
    # ----------------------------------------------------------------------$

    # Render the label edit view on the map. The `mapView` cached variable is
    # set following the hierarchy: *LabelsView > *View > MapView.
    render: (parent) =>
        if parent?
            @parentView = parent
            @mapView = parent.parentView.parentView

        # Create the simple label text field.
        @$txtCustomVarName = $ document.createElement "input"
        @$txtCustomVarName.attr "type", "text"
        @$txtCustomVarName.attr "placeholder", System.App.Messages.customVarNameWatermark
        @$txtCustomVarName.attr "title", System.App.Messages.tooltipVariableName
        @$txtCustomVarName.addClass "variable"
        @$txtCustomVarName.keyup @customVarNameKeyUp

        # Create the custom variable "code" textarea.
        @$txtCustomVarCode = $ document.createElement "textarea"
        @$txtCustomVarCode.attr "placeholder",  System.App.Messages.customVarCodeWatermark
        @$txtCustomVarCode.attr "title", System.App.Messages.tooltipVariableCode
        @$txtCustomVarCode.addClass "variable"
        @$txtCustomVarCode.keyup @customVarCodeKeyUp
        @$txtCustomVarCode.bind "mousewheel", @editingMouseWheel

        # Create the "Save" custom variable button.
        @$butSaveCustomVar = $ document.createElement "button"
        @$butSaveCustomVar.addClass "variable save"
        @$butSaveCustomVar.html System.App.Messages.saveVariable
        @$butSaveCustomVar.attr "title", System.App.Messages.tooltipCreateVariable
        @$butSaveCustomVar.click @customVarSaveClick

        # Create the custom variable name + code wrapper.
        @$customVarWrapper = $ document.createElement "div"
        @$customVarWrapper.addClass "variable"
        @$customVarWrapper.append @$txtCustomVarName
        @$customVarWrapper.append @$txtCustomVarCode
        @$customVarWrapper.append @$butSaveCustomVar

        # Create the simple label text field.
        @$txtSimple = $ document.createElement "input"
        @$txtSimple.attr "type", "text"
        @$txtSimple.keyup @simpleKeyUp

        # Create the "new custom variable" link
        @$linkCreateCustomVar = $ document.createElement "span"
        @$linkCreateCustomVar.addClass "create-variable"
        @$linkCreateCustomVar.html System.App.Messages.createVariable
        @$linkCreateCustomVar.click @showCustomVar

        # Create the autocomplete div and the current value span.
        @$autoCompleteDiv = $ document.createElement "div"
        @$autoCompleteDiv.bind "mousewheel", @editingMouseWheel
        @$autoCompleteDiv.addClass "autocomplete"

        # Create the current value span.
        @$currentValueSpan = $ document.createElement "span"
        @$currentValueSpan.addClass "current-value"

        # Create the simple field + autocomplete wrapper.
        @$simpleWrapper = $ document.createElement "div"
        @$simpleWrapper.addClass "simple"
        @$simpleWrapper.append @$txtSimple
        @$simpleWrapper.append @$linkCreateCustomVar
        @$simpleWrapper.append @$autoCompleteDiv

        # Append all elements to the current view, and the itself to the [Map View](mapView.html).
        @$el.css "display", "none"
        @$el.addClass "styled"
        @$el.append @$currentValueSpan
        @$el.append @$customVarWrapper
        @$el.append @$simpleWrapper

        @mapView.$el.append @$el

        return this

    # Save the current value by triggering the `save` event, and hide the view.
    # When adding a new custom variable, this will be called just after the
    # `saveCustomVar`.
    save: =>
        value = @simpleValue()
        value = value + @customVarCodeValue() if value is System.App.Settings.General.evalPrefix

        @currentValue @simpleValue()
        @trigger "save", this, value
        @hide()

    # Creates a new [Variable](variable.html) with the specified name and code,
    # and set the label value to the variable prefix "#" plus the added variable name.
    saveCustomVar: =>
        varName = @$txtCustomVarName.val().replace RegExp(" ", "g"), ""
        varCode = $.trim @$txtCustomVarCode.val()

        if @currentVariable?
            @currentVariable.friendlyId varName
            @currentVariable.code varCode
            @currentVariable.save()
        else
            customVar = new System.Variable()
            customVar.friendlyId varName
            customVar.code varCode

            System.App.Data.variables.add customVar
            customVar.save()

        @customVarNameValue ""
        @simpleValue System.App.Settings.General.dataBindingKey + System.App.Settings.Variable.bindingNamespace + "." + varName
        @showSimple()

    # Show the view with the specified value and position.
    show: (value, x, y) =>
        $(document).unbind "keyup", @documentKeyUp
        $(document).keyup @documentKeyUp

        @stopListening()
        @listenTo System.App.mapEvents, "zoom", @hide

        value = "" if not value?

        @simpleValue value

        @ox = x
        @oy = y

        @showSimple()
        @currentValue System.App.Messages.current + ": " + value

        @$el.fadeIn System.App.Settings.LabelEdit.opacityInterval

        @$txtSimple.focus()

    # Hide the `$txtCustomVarCode` text area and bring back the simple text field
    # and its autocomplete div to the view.
    showSimple: =>
        $(document).unbind "mousedown", @editingMouseDown
        $(document).mousedown @editingMouseDown

        size = @simpleValue().length + 1
        size = System.App.Settings.LabelEdit.minTxtSize if size < System.App.Settings.LabelEdit.minTxtSize

        @$txtSimple.attr "size", size
        @autoCompleteValue @simpleValue()
        @parseValue()
        @bindAutoComplete()

        @currentVariable = null

        @$customVarWrapper.css "display", "none"
        @$simpleWrapper.css "display", ""
        @setPosition()

        @$txtSimple.focus()

    # Show the `$txtCustomVarCode` text area which allows the user to enter
    # ANY javascript evlatuation to bind data to the label. This will
    # hide the simple text editor and its autocomplete box.
    # The `initial` value is optional.
    showCustomVar: (variable) =>
        $(document).unbind "mousedown", @editingMouseDown

        @$simpleWrapper.css "display", "none"
        @$customVarWrapper.css "display", ""
        @$txtCustomVarName.prop "disabled", false

        @setPosition()

        if variable?.friendlyId?
            @currentVariable = variable
            @customVarNameValue @currentVariable.friendlyId()
            @customVarCodeValue @currentVariable.code()
            @$txtCustomVarCode.focus()
        else
            @currentVariable = null
            @customVarNameValue ""
            @customVarCodeValue ""
            @$txtCustomVarName.focus()

    # After editing the label, remove the temporary textbox (or if user cancels editing).
    hide: =>
        $(document).unbind "mousedown", @editingMouseDown
        $(document).unbind "keyup", @documentKeyUp
        @stopListening()

        @$el.fadeOut System.App.Settings.LabelEdit.opacityInterval

        @lastPressedKey = null
        @currentVariable = null

    # Called to check the current position and size of the view, so it never
    # overlaps the borders of the page.
    setPosition: () =>
        x = @ox
        y = @oy

        x = x * (1 / @mapView.currentZoom) - @$el.outerWidth() / 2
        x = x - @mapView.getViewBox().x * (1 / @mapView.currentZoom)
        y = y * (1 / @mapView.currentZoom) + 10
        y = y - @mapView.getViewBox().y * (1 / @mapView.currentZoom)

        maxX = $(window).outerWidth() - @$el.outerWidth() - $("#map-controls").outerWidth() - 10
        maxY = $(window).outerHeight() - @$el.outerHeight() - $("#footer").outerHeight() - 10

        x = 1 if x < 1
        x = maxX if x > maxX
        y = 1 if y < 1
        y = maxY if y > maxY

        @$el.css "left", x
        @$el.css "top", y

    # Check if user is writing a static value, or binding to an [AuditData](auditData.html} using a special key.
    parseValue: =>
        value = @simpleValue()

        if System.App.DataUtil.hasAuditData value
            @$txtSimple.addClass "highlight"
        else
            @$txtSimple.removeClass "highlight"

        @bindAutoComplete()


    # AUTOCOMPLETE
    # ----------------------------------------------------------------------

    # Check the current `$txtSimple` value and if it's a valid [Audit Data item](auditData.html)
    # then bind its contents to the `$autoCompleteDiv`.
    bindAutoComplete: =>
        auditDataNamespace = System.App.Settings.General.dataBindingKey + System.App.Settings.AuditData.bindingNamespace
        value = @simpleValue()

        if value.indexOf(".") < 1
            @bindAutoCompleteEntities()
        else if value.indexOf(auditDataNamespace) >= 0
            value = value.replace auditDataNamespace, ""
            auditDataName = value.split(".")[1].split("[")[0]
            @bindAutoCompleteProperties auditDataName if auditDataName.length > 0

    # Populate the `$autoCompleteDiv` with a list of possible [AuditData](auditData.html) entities.
    bindAutoCompleteEntities: =>
        auditDataNamespace = System.App.Settings.General.dataBindingKey + System.App.Settings.AuditData.bindingNamespace
        variableNamespace = System.App.Settings.General.dataBindingKey + System.App.Settings.Variable.bindingNamespace
        value = @simpleValue()
        arr = []

        # If the entered value is empty or the custom variable special key `#`,
        # add the list of registered [Variables](variable.html) to the resulting array.
        if value.length < 1 or value.indexOf(variableNamespace) >= 0

            ulCustomVar = $(document.createElement "ul")
            ulCustomVar.addClass "variable"

            _.each System.App.Data.variables.models, (item) =>
                li = $(document.createElement "li")

                name = $(document.createElement "span")
                name.attr "title", variableNamespace + "." + item.friendlyId()
                name.html item.friendlyId()
                name.click @autoCompleteClick

                edit = $(document.createElement "img")
                edit.attr "src", "images/ico-edit.png"
                edit.data "variable", item
                edit.click @customVarEditClick

                li.append name
                li.append edit
                ulCustomVar.append li

            arr.push ulCustomVar

        # If the entered value is empty or the audit data special key `$`,
        # add the list of registered [AuditData](auditData.html) to the resulting array.
        if value.length < 1 or value.indexOf(auditDataNamespace) >= 0

            ulAuditData = $(document.createElement "ul")
            ulAuditData.addClass "auditdata"

            _.each System.App.Data.auditData.models, (item) =>
                li = $(document.createElement "li")
                li.attr "title", auditDataNamespace + "." + item.friendlyId() + "."
                li.html item.friendlyId()
                li.click @autoCompleteClick

                ulAuditData.append li

            arr.push ulAuditData

        @autoCompleteValue arr

    # Populate the `$autoCompleteDiv` with a list of properties for the specified [AuditData](auditData.html).
    # If no ``auditDataName`` is passed, then bind all found properties from all [AuditData](auditData.html) items.
    bindAutoCompleteProperties: (friendlyId) =>
        json = []
        auditData = _.filter System.App.Data.auditData.models, (item) -> item.attributes.friendlyId.indexOf(friendlyId) >= 0

        if auditData.length > 0
            _.each auditData, (item) => json.push @auditDataDumper item

            # Bind the search results and reset the position to make
            # sure it's not going outside the current view.
            @autoCompleteValue json
            @setPosition()

        else

            @autoCompleteValue ""

    # Dump the [AuditData](auditData.html) to an easy to read and clickable HTML.
    # This is used by the property auto complete.
    auditDataDumper: (auditData) =>
        data = auditData.data()
        path = System.App.Settings.General.dataBindingKey + System.App.Settings.AuditData.bindingNamespace + "." + auditData.friendlyId()
        div = $(document.createElement "div")

        # Recursively parse and bind all properties to the autocomplete area.
        @auditPropertyDump data, path, 1, div, data instanceof Array

        return div

    # Dump a single object property to the autocomplete box. This function is
    # recursive and started by the `auditDataDumper` method above.
    auditPropertyDump: (obj, path, level, parentDiv, fromArray) =>
        return if not obj?
        searchTerms = @simpleValue()

        # Add current object's keys to an array.
        keys = []
        keys.push k for k of obj

        # Only sort if the object is NOT an array.
        keys.sort() if not fromArray

        for k of keys
            propName = keys[k]
            propValue = obj[propName]

            if fromArray

                propHtml = propValue
                title = "#{path}[#{k}]"

            else

                propHtml = propName

                if propName.indexOf(".") > 0
                    title = "#{path}['#{propName}']"
                else
                    title = "#{path}.#{propName}"

            # Create a cleaner version of search terms and title to be used
            # while comparing values (code below).
            altSearchTerms = searchTerms.replace(/\./g, "").replace(/\[/g, "").replace(/\]/g, "").replace(/\'/g, "")
            altTitle = title.replace(/\./g, "").replace(/\[/g, "").replace(/\]/g, "").replace(/\'/g, "")

            # Only bind property if it matches the current text entered
            # on the `txtSimple` input field.
            if altSearchTerms is "" or altSearchTerms.indexOf(altTitle) >= 0 or altTitle.indexOf(altSearchTerms) >= 0
                spanProp = $(document.createElement "span")
                spanProp.html propHtml
                spanProp.addClass "level" + level
                spanProp.attr "title", title
                spanProp.click @autoCompleteClick
                parentDiv.append spanProp

                # If property value is an object, proceed with recursion.
                if typeof propValue is "object"
                    @auditPropertyDump propValue, title, level + 1, parentDiv, (propValue instanceof Array)

    # When user clicks an object (entity or property name) on the `$autoCompleteDiv`, copy its value
    # and paste to the `$txtSimple`.
    autoCompleteClick: (e) =>
        obj = $ e.target
        value = obj.attr "title"
        currentValue = @simpleValue()

        # If user clicks twice on a property, it will save the new value and hide this view.
        if value is currentValue
            @save()
        else
            @simpleValue value
            @parseValue()
            @$txtSimple.focus()

        e.preventDefault()
        e.stopPropagation()

    # When user clicks the "edit" icon next to a [Variable](variable.html), open
    # the custom variable textfields for editing.
    customVarEditClick: (e) =>
        src = $ e.currentTarget
        variable = src.data "variable"
        @showCustomVar variable


    # MOUSE AND KEYBOARD EVENTS
    # ----------------------------------------------------------------------

    # When user is editing a label and clicks somewhere on the map, check for the
    # source element. If it's not part of this view then hide it.
    editingMouseDown: (e) =>
        css = System.App.Settings.LabelEdit.className
        src = $ e.target
        parent = src.parents ".#{css}"
        labelPosition = src.data "labelPosition"
        parentLabelPosition = src.parent().data "labelPosition"
        isLabel = (labelPosition? and labelPosition isnt "") or (parentLabelPosition? and parentLabelPosition isnt "")

        # If user hasn't clicked inside the editing box, then hide the view.
        if not isLabel and not src.hasClass(css) and parent.length < 1
            @hide()
        else
            e.stopPropagation()

    # When editing the label, the mouse wheel should stop propagation to
    # avoid the map zoom being changed - but only when mouse is over the
    # `$autoCompleteDiv` or the `$txtCustomVarCode` elements.
    editingMouseWheel: (e) =>
        e.stopPropagation()

    # When user presses a key while editing the label value. Pressing "Enter" will trigger `save`,
    # pressing "Esc" will hide the view.
    documentKeyUp: (e) =>
        @hide() if e.which is 27

    # When pressing keys on `$txtSimple`, check if the value is blank and the key being pressed
    # is the special key defined on the [Settings](settings.html). If so, starts the
    # autocomplete feature. Pressing "Enter" will save. And if user enters the eval prefix
    # defined at `System.App.Settings.General.evalPrefix`, then call `showCustomVar`.
    simpleKeyUp: (e) =>
        @parseValue()
        @save() if e.which is 13


    # EVAL
    # ----------------------------------------------------------------------

    # Validate the `$txtCustomVarCode` field, and if it fails, then add the `.error`
    # class to alert the user.
    validateCustomVar: =>
        name = @customVarNameValue()
        code = $.trim @customVarCodeValue()

        if code is ""
            @simpleValue ""
            @showSimple()
            return

        # Check if user has entered a variable name, and if the code has a return statement.
        if name.length < 2
            @warnField @$txtCustomVarName
            @$txtCustomVarName.focus()
            valMessage = {message: System.App.Messages.valNameIsRequired}
        else if code.indexOf("return") < 0
            valMessage = {message: System.App.Messages.errEvalReturn}
        else
            valMessage = System.App.DataUtil.validateEval code

        # Check if variable name is duplicate or not.
        if @currentVariable?
            duplicateItem = System.App.Data.variables.getByFriendlyId name
            if duplicateItem? and duplicateItem.length > 0 and duplicateItem[0].id isnt @currentVariable.id
                @warnField @$txtCustomVarName
                @$txtCustomVarName.focus()
                valMessage = {message: System.App.Messages.valNameIsDuplicate}

        # If has a validation message, display it and stop here.
        if valMessage?
            @lastEvalCode = code
            @evalShowError valMessage
            return false

        @$txtCustomVarCode.removeClass "error"
        return true

    # If the eval parsing fails, quickly display the error message on the `$txtCustomVarCode`,
    # and then put the original text back after a few seconds by calling `evalClearError`.
    evalShowError: (valMessage) =>
        console.warn "Error while parsing the eval field!", valMessage, this

        text = valMessage.message
        text += "\n\n" + valMessage.stacktrace if valMessage.stacktrace?

        @$txtCustomVarCode.val text
        @$txtCustomVarCode.prop "disabled", true
        @$txtCustomVarCode.addClass "error"

        @lastPressedKey = null

        setTimeout @evalClearError, System.App.Settings.LabelEdit.evalErrorTimeout

    # Clear the validation error message and set the `$txtCustomVarCode` back to its original text.
    evalClearError: =>
        @$txtCustomVarCode.unbind "keydown"
        @$txtCustomVarCode.val @lastEvalCode if @lastEvalCode?
        @$txtCustomVarCode.prop "disabled", false
        @$txtCustomVarCode.removeClass "error"

        @lastEvalCode = null

    # When pressing keys on `$txtCustomVarName`, check the key pressed to hide (Esc)
    # or move focus to `$txtCustomVarCode` on (Enter).
    customVarNameKeyUp: (e) =>
        keyCode = e.which
        isEnter = keyCode is 13

        # If user pressed "Esc" and the `$txtCustomVarName` has less than 2 characters
        # then hide the eval field and show the simple one.
        if keyCode is 27 and @customVarCodeValue.length < 2
            @simpleValue ""
            @showSimple()
            e.stopPropagation()
            e.preventDefault()

        # If user pressed "Enter" and a value was entered, change focus to `$txtCustomVarCode`.
        else if isEnter and @customVarNameValue().length > 0
            @$txtCustomVarCode.focus()

        @lastPressedKey = keyCode

    # When pressing keys on `$txtCustomVarCode`, check the key pressed to hide (Esc)
    # or save (Enter) the label value.
    customVarCodeKeyUp: (e) =>
        keyCode = e.which

        # If user pressed "Esc" and the `$txtCustomVarCode` has less than 2 characters
        # then hide the eval field and show the simple one.
        if keyCode is 27 and @customVarCodeValue.length < 2
            @simpleValue ""
            @showSimple()
            e.stopPropagation()
            e.preventDefault()

        @lastPressedKey = keyCode

    # When user clicks the "Save variable" button, validate the entered values and proceed
    # only if the [Variable](variable.html) name is not a duplicate, and
    # the entered code is working and valid.
    customVarSaveClick: =>
        if @validateCustomVar()
            @saveCustomVar()