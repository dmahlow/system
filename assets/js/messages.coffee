# MESSAGES
# --------------------------------------------------------------------------
# All, repeating, ALL dynamic messages should be set here!

SystemApp.Messages =

    # TERMS
    # ----------------------------------------------------------------------
    accessDenied: "Access denied!"
    attention: "Attention!"
    auditDataRefresh: "Audit data refresh"
    availableSources: "Available sources..."
    cancel: "Cancel"
    createItem: "Create item"
    createMaps: "create maps"
    createMapText: "Please enter the new map name..."
    createVariable: "Create new variable..."
    current: "Current value"
    custom: "Custom"
    dataOutdated: "Data is not up-to-date!"
    dataSaved: "Data saved!"
    editThisMap: "edit this map"
    elementsSelected: "elements selected"
    error: "Error"
    invalidRoute: "Invalid route!"
    lastUpdate: "Last update"
    localMapName: "My Local Map"
    mapInfoStats: "#S shapes, #L links"
    multipleShapesSelected: "Multiple shapes selected!"
    newLink: "NEW LINK"
    noIcon: "No icon"
    noLabel: "No label"
    noLabelsSet: "No labels set..."
    noShapeSelected: "No shape(s) or link(s) selected"
    pleaseSelectAnAlert: "Please select an alert..."
    removeLink: "Remove link"
    removeShape: "Remove shape"
    rowActionCount: "# action(s)"
    rowRuleCount: "# rule(s)"
    saved: "Saved!"
    saveDetails: "Save details"
    saveVariable: "Save variable"
    scheduledRefreshAlert: "The app is scheduled to refresh the whole page in a few seconds (#)!<br />
                            If you do not wish the page to refresh, please click on this panel."
    scripted: "Scripted"
    searchWatermark: "Search entities..."
    server: "SERVER"
    startLocalMapText: "Use the Local Test Map to try the System App features."


    # TOOLTIPS
    # ----------------------------------------------------------------------
    tooltipItemId: "Enter the unique ID for this model. No spaces or special characters allowed."
    tooltipEventRuleComparator: "Select one of the alert comparator values: equals, not equals,
                                 greater than w/wo, less than w/wo."
    tooltipEventRuleSource: "Enter the alert SOURCE value. Can be a static or an audit data value (beginning with #)."
    tooltipEventRuleTarget: "Enter the alert TARGET value. Can be a static or an audit data value (beginning with #)."
    tooltipEventActionShapeId: "If you want the alert to happen on a specific shape, please enter the Shape ID here.
                                Otherwise it will happen on shapes that have the specified Audit Data property bound."
    tooltipEventActionType: "Select one of the action types."
    tooltipEventActionValue: "Enter the action value, which relates to its type. For example set the background colour
                              must have a valid colour as value."
    tooltipAuditEventTitle: "Please enter the audit event TITLE here."
    tooltipCreateVariable: "Click to validate and save the code above as a custom variable."
    tooltipVariableCode: "Enter the custom variable name. That value must be UNIQUE!"
    tooltipVariableName: "Enter the custom variable code here. You MUST add at least one return
                          clause for it to work properly."
    tooltipDeleteItem: "Click to DELETE this item."
    tooltipEditItem: "Click to EDIT this item."
    tooltipLinker: "Click and drag to create a new link..."
    tooltipResize: "Click and drag to resize..."
    tooltipShapeAuditEventCheckbox: "Check / uncheck that audit event to the selected shape(s)."


    # WATERMARKS
    # ----------------------------------------------------------------------
    customVarNameWatermark: "Give the variable a name..."
    customVarCodeWatermark: "Enter the custom variable code..."


    # SUCCESS MESSAGES
    # ----------------------------------------------------------------------
    okDataSavedLocally: "All entities were persisted to the local storage."


    # ERROR MESSAGES
    # ----------------------------------------------------------------------
    errAuditDataRefreshCount: "Could not refresh # for #{SystemApp.Settings.auditData.alertOnErrorCount} times in a row.
                               Maybe the URL is wrong? Click on this box to open the Audit Events view for editing."
    errCouldNotLoadFromServer: "Could not load data from server!"
    errCreatingMap: "Could not create new map."
    errEntityOutdated: "Entity #E objects haven't been updated since #D."
    errEvalFailed: "Eval failed!"
    errEvalReturn: "Eval must have a return statement!"
    errInvalidRoute: "The path you have entered does not exist."
    errMapDoesNotExist: "The specified map does not exist!"
    errMapIsReadOnly: "This map is read-only and cannot be updated."
    errMapNameExists: "There's already a map called #."
    errNoPermissionTo: "You don't have the necessary permissions to #."
    errParseModel: "Error while parsing data from server."


    # VALIDATION MESSAGES
    # ----------------------------------------------------------------------
    valAllFieldsEmpty: "All fields are empty!"
    valDescriptionIsRequired: "A description is required."
    valGridSizeTooSmall: "The grid size is too small. Minimum allowed is  #{SystemApp.Settings.map.minGridSize}."
    valHexColour: "Value must be a hex colour."
    valInvalidUrl: "The entered URL is not valid."
    valLessThanMin: "Minimum accepted value is #."
    valMoreThanMax: "Maximum accepted value is #."
    valNameIsDuplicate: "The entered name already exists."
    valNameIsRequired: "A name is required."
    valNoSpecialChars: "No special characters allowed."
    valNumeric: "Value must be a number."
    valPaperSizeTooSmall: "The paper size too small. Minimum is  #{SystemApp.Settings.map.minPaperSize}."
    valRefreshIntervalTooLow: "Refresh interval too low. Minimum is #{SystemApp.Settings.auditData.minRefreshInterval}."
    valRequired: "This field cannot be empty."
    valTitleIsRequired: "A title is required."
    valUrl: "The value must be a valid URL."


    # SCRIPT EDITOR DESCRIPTIONS
    # ----------------------------------------------------------------------
    ScriptEditorInfo:
        initScript: "The code below will be executed after the map has loaded on the browser."