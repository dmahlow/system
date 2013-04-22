# ALERT RULE MODEL
# --------------------------------------------------------------------------
# Represents a single alert rule. It is used to compare two values
# (source and target), which can be a property of an [AuditData](auditData.html)
# or a static value. Alert rules are meant to be used inside
# [AuditEvent](auditEvent.html) objects only.

class SystemApp.EventRule extends SystemApp.BaseModel
    typeName: "EventRule"
    defaults:
        source: null        # the source value or audit data path to compare
        target: null        # the target value or audit data path to be compared
        comparator: null    # the comparator symbol, can be one of these: < . <= . > . >= . == . !=


    # SYNC
    # ----------------------------------------------------------------------

    # Override the "save" method as we don't need to sync individual alert rules with the server.
    save: (key, value, options) => @noSyncSave key, value, options

    # Override the "destroy" method as we don't need to sync individual alert rules with the server.
    destroy: (options) => @noSyncDestroy options


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the source value.
    source: (value) =>
        if value?
            @set "source", value
        @get "source"

    # Helper to get / set the target value.
    target: (value) =>
        if value?
            @set "target", value
        @get "target"

    # Helper to get / set the comparator symbol.
    comparator: (value) =>
        if value?
            @set "comparator", value
        @get "comparator"


    # METHODS
    # ----------------------------------------------------------------------

    # Test the rule. The `contextValues` array is optional, and will be used only when the source or target
    # have context values (prefix @, going from @1 to @5). Return true or false based on the
    # source value, target value, and the comparator used.
    test: (contextValues) =>
        sourceValue = @source()
        targetValue = @target()

        if not sourceValue?
            return false
        if not targetValue?
            return false

        # Check if source value is a [Variable](variable.html),
        # an [AuditData](auditData.html) property or a context value. Context
        # means the alert is being run against [Shape](shape.html) or [Link](link.html)
        # label values.
        if sourceValue.substring(0, 1) is SystemApp.Settings.General.dataBindingKey
            sourceValue = SystemApp.DataUtil.getDataBindingValue sourceValue
        else if contextValues? and sourceValue.substring(0, 1) is SystemApp.Settings.AuditEvent.contextSpecialKey
            sourceValue = contextValues[parseInt(sourceValue.substring 1)]

        # Same as above, but for the target value.
        if targetValue.substring(0, 1) is SystemApp.Settings.General.dataBindingKey
            targetValue = SystemApp.DataUtil.getDataBindingValue targetValue
        else if contextValues? and targetValue.substring(0, 1) is SystemApp.Settings.AuditEvent.contextSpecialKey
            targetValue = contextValues[parseInt(targetValue.substring 1)]

        # Force setting source and target values to float, in case they're valid numbers.
        if not isNaN sourceValue
            sourceValue = parseFloat sourceValue
        if not isNaN targetValue
            targetValue = parseFloat targetValue

        if not sourceValue? or not targetValue?
            return false

        switch @comparator()
            when ">"  then return sourceValue >  targetValue
            when ">=" then return sourceValue >= targetValue
            when "<"  then return sourceValue <  targetValue
            when "<=" then return sourceValue <= targetValue
            when "==" then return sourceValue == targetValue
            when "!=" then return sourceValue != targetValue

        # If the values and/or symbol are incorrect, then always return false.
        return false


# EVENT RULE COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of event rules.

class SystemApp.EventRuleCollection extends SystemApp.BaseCollection
    typeName: "EventRuleCollection"
    model: SystemApp.EventRule

    # Set the comparator function to order the alert rules collection by source value.
    comparator: (rule) -> return rule.source()