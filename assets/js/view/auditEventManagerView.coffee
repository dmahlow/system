# AUDIT EVENT MANAGER VIEW
# --------------------------------------------------------------------------
# Represents the Audit Events overlay.

class SystemApp.AuditEventManagerView extends SystemApp.OverlayView

    $txtCreate: null         # the text input used to create a new audit event
    $butCreate: null         # the button used to create a new audit event
    $txtDescription: null    # the "Description" textbox when editing the audit event
    $chkActive: null         # the "Active" checkbox when editing the audit event
    $gridRules: null         # the right grid containing the current's event rules
    $gridActions: null       # the right grid containing the current's event actions
    $rowAddRule: null        # the last rules row, containing the "Add rule" fields
    $rowAddAction: null      # the last actions row, containing the "Add action" fields
    $icoAddRule: null        # the "Add" icon on the right of the add RULE row
    $icoAddAction: null      # the "Add" icon on the right of the add ACTION row


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Audit Events overlay view.
    initialize: =>
        @currentSettings = SystemApp.Settings.auditEvent
        @overlayInit "#auditevents"
        @setDom()
        @setEvents()

    # Dispose the Audit Events view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$menuItem = $ "#menu-auditevents"
        @$modelsList = $ "#auditevents-list"
        @$txtCreate = $ "#auditevents-txt-create"
        @$butCreate = $ "#auditevents-but-create"

        @$txtDescription = $ "#auditevents-txt-description"
        @$chkActive = $ "#auditevents-chk-active"

        @$gridRules = @$el.find "#auditevents-tab-rules div .grid"
        @$gridActions = @$el.find "#auditevents-tab-actions div .grid"

        @$rowAddRule = @$el.find "#auditevents-tab-rules div .addrow"
        @$rowAddAction = @$el.find "#auditevents-tab-actions div .addrow"
        @$icoAddRule = @$rowAddRule.children(".add")
        @$icoAddAction = @$rowAddAction.children(".add")

    # Bind events to the DOM.
    setEvents: =>
        @$butCreate.click @createEventClick
        @$txtCreate.keyup @createEventKeyUp

        @$txtDescription.change @inputOnChange
        @$chkActive.change @inputOnChange

        @$rowAddRule.children(".source").keyup @createRuleKeyUp
        @$rowAddRule.children(".target").keyup @createRuleKeyUp
        @$icoAddRule.click @createRuleClick

        @$rowAddAction.children(".value").keyup @createActionKeyUp
        @$icoAddAction.click @createActionClick


    # AUDIT EVENTS LIST
    # ----------------------------------------------------------------------

    # Clear the current view by setting the `model` to null
    # and emptying the data grids.
    clear: =>
        @model = null
        @$modelsList.empty()
        @clearTextInputs()

        @bindRules()
        @bindActions()

    # Clear only the text input fields.
    clearTextInputs: =>
        @$txtCreate.val ""

    # Bind all [AuditEvent](auditEvent.html) from the [data store](data.html).
    bindAuditEvents: =>
        @clear()
        @addToModelsList item for item in SystemApp.Data.auditEvents.models


    # CREATING AUDIT EVENTS
    # ----------------------------------------------------------------------

    # When user clicks the "Create" button, add a new record to the audit events
    # collection with the title entered at the `$txtCreate` field.
    createEventClick: (e) =>
        newId = @$txtCreate.val()

        # The ID must have at least 2 chars.
        if newId.length < 2
            @warnField @$txtCreate
            return
        else
            newId = SystemApp.DataUtil.normalize newId, true

        SystemApp.Data.auditEvents.create {friendlyId: newId}, {wait: true}
        @clearTextInputs()

    # If the `$txtCreate` field has focus, pressing Enter will call the `click`
    # event on the `$butCreate`.
    createEventKeyUp: (e) =>
        if e.keyCode is 13
            @$butCreate.click()


    # AUDIT EVENT PROPERTIES
    # ----------------------------------------------------------------------

    # Bind entity properties and refresh the shape template.
    onBindModel: =>
        if @model?
            @$txtDescription.val @model.description()
            @$chkActive.prop "checked", @model.active()

        @bindRules()
        @bindActions()


    # RULES
    # ----------------------------------------------------------------------

    # Bind all rules of the `model` to the `$gridRules`. This is called
    # whenever the user clicks / selects an [AuditEvent](auditEvent.html) on the `$gridAlerts`.
    bindRules: =>
        @$gridRules.empty()

        if @model?
            @stopListening @model.rules()
            @listenTo @model.rules(), "add", @addRuleToGrid
            @listenTo @model.rules(), "remove", @removeRuleFromGrid

            @addRuleToGrid item for item in @model.rules().models
            @$rowAddRule.show()
        else
            @$gridRules.append $(document.createElement "label").html(SystemApp.Messages.pleaseSelectAnAlert)
            @$rowAddRule.hide()

    # Add a single [Alert Rule](eventRule.html) to the `$gridRules`.
    addRuleToGrid: (rule) =>
        row = $(document.createElement "div")
        row.attr "id", SystemApp.Settings.auditEvent.rowRulePrefix + rule.id
        row.data "DataItem", rule
        row.addClass "row"

        source = $(document.createElement "input")
        source.data "propertyname", "source"
        source.attr "type", "text"
        source.attr "title", SystemApp.Messages.tooltipEventRuleSource
        source.addClass "source"
        source.val rule.source()
        source.change rule, @inputOnChange

        comparator = $(document.createElement "select")
        comparator.data "propertyname", "comparator"
        comparator.attr "title", SystemApp.Messages.tooltipEventRuleComparator
        comparator.addClass "comparator"
        comparator.append($(document.createElement "option").html("="))
        comparator.append($(document.createElement "option").html("!="))
        comparator.append($(document.createElement "option").html(">"))
        comparator.append($(document.createElement "option").html(">="))
        comparator.append($(document.createElement "option").html("<"))
        comparator.append($(document.createElement "option").html("<="))
        comparator.val rule.comparator()
        comparator.change rule, @inputOnChange

        target = $(document.createElement "input")
        target.data "propertyname", "target"
        target.attr "type", "text"
        target.attr "title", SystemApp.Messages.tooltipEventRuleTarget
        target.addClass "target"
        target.val rule.target()
        target.change rule, @inputOnChange

        row.append source
        row.append comparator
        row.append target

        @appendDeleteIcon rule, row
        @$gridRules.append row

    # Remove the specified rule from the `$gridRules`.
    removeRuleFromGrid: (rule) =>
        $("#" + SystemApp.Settings.auditEvent.rowRulePrefix + rule.id).remove()
        @model?.save()

    # When user clicks the "Add rule" icon, add a new [Alert Rule](eventRule.html)
    # to the `model` rules collection.
    createRuleClick: (e) =>
        row = $(e.currentTarget).parent()
        source = row.children ".source"
        target = row.children ".target"
        comparator = row.children ".comparator"

        sourceVal = source.val()
        targetVal = target.val()
        comparatorVal = comparator.val()

        # Source value must be set!
        if not sourceVal? or sourceVal is ""
            @warnField source
            source.focus()
            return

        rule = new SystemApp.EventRule()
        rule.generateId()
        rule.source sourceVal
        rule.target targetVal
        rule.comparator comparatorVal

        @model.rules().add rule
        @model.save()

        # Reset the values of the "add" fields and focus on the source field.
        target.val ""
        source.val ""
        source.focus()

    # If user presses "Enter" when editing a field of the "Create rule" row
    # it will force a `click` event on the row's add icon.
    createRuleKeyUp: (e) =>
        if e.keyCode is 13
            @$icoAddRule.click()

    # ACTIONS
    # ----------------------------------------------------------------------

    # Bind all actions of the `model` to the `$gridActions`. This is called
    # whenever the user clicks / selects an [AuditEvent](auditEvent.html) on the `$gridAlerts`.
    bindActions: =>
        @$gridActions.empty()

        if @model?
            @stopListening @model.actions()
            @listenTo @model.actions(), "add", @addActionToGrid
            @listenTo @model.actions(), "remove", @removeActionFromGrid

            @addActionToGrid item for item in @model.actions().models
            @$rowAddAction.show()
        else
            @$gridActions.append $(document.createElement "label").html(SystemApp.Messages.pleaseSelectAnAlert)
            @$rowAddAction.hide()

    # Add a single [Alert Action](eventAction.html) to the `$gridActions`.
    addActionToGrid: (action) =>
        row = $(document.createElement "div")
        row.attr "id", SystemApp.Settings.auditEvent.rowActionPrefix + action.id
        row.data "DataItem", action
        row.addClass "row"

        actionType = $(document.createElement "select")
        actionType.data "propertyname", "actionType"
        actionType.attr "title", SystemApp.Messages.tooltipEventActionType
        actionType.addClass "type"
        actionType.append($(document.createElement "option").val("blink").html("blink"))
        actionType.append($(document.createElement "option").val("colorBg").html("background color"))
        actionType.append($(document.createElement "option").val("colorBorder").html("border color"))
        actionType.append($(document.createElement "option").val("footerMessage").html("footer message"))
        actionType.val action.actionType()
        actionType.change action, @inputOnChange

        actionValue = $(document.createElement "input")
        actionValue.data "propertyname", "actionValue"
        actionValue.attr "title", SystemApp.Messages.tooltipEventActionValue
        actionValue.attr "type", "text"
        actionValue.addClass "value"
        actionValue.val action.actionValue()
        actionValue.change action, @inputOnChange

        row.append actionType
        row.append actionValue

        @appendDeleteIcon action, row
        @$gridActions.append row

    # Remove the specified action from the `$gridActions`.
    removeActionFromGrid: (action) =>
        $("#" + SystemApp.Settings.auditEvent.rowActionPrefix + action.id).remove()
        @model?.save()

    # When user clicks the "Add action" icon, add a new [Alert Action](eventAction.html)
    # to the `model` actions collection.
    createActionClick: (e) =>
        row = $(e.currentTarget).parent()
        type = row.children ".type"
        value = row.children ".value"

        typeVal = type.val()
        valueVal = value.val()

        action = new SystemApp.EventAction()
        action.generateId()
        action.actionType typeVal
        action.actionValue valueVal

        @model.actions().add action
        @model.save()

        # Reset the value of the "add" fields and focus on the value field.
        value.val ""
        value.focus()

    # If user presses "Enter" when editing a field of the "Create action" row
    # it will force a `click` event on the row's add icon.
    createActionKeyUp: (e) =>
        if e.keyCode is 13
            @$icoAddAction.click()


    # SAVE AND DELETE
    # ----------------------------------------------------------------------

    # Create a "delete icon" on the DOM and append it to the specified row.
    appendDeleteIcon: (item, row) =>
        delIcon = $(document.createElement "div")
        delIcon.attr "title", SystemApp.Messages.tooltipDeleteItem
        delIcon.addClass "delete"
        delIcon.click item, @clickDeleteIcon

        row.append delIcon


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Bind the `keyUp` event when overlay is shown.
    onShow: =>
        @bindAuditEvents()

        $(document).keyup @hasModelListKeyUp
        @listenTo SystemApp.Data.auditEvents, "add", @addToModelsList
        @listenTo SystemApp.Data.auditEvents, "remove", @removeFromModelsList

    # Save the `model` (if there's one) when the overlay is closed,
    # and remove the `keyUp` from the document.
    onHide: =>
        $(document).unbind "keyup", @hasModelListKeyUp
        @stopListening()

        @model?.save()
        @model = null