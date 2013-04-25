# AUDIT ALERT MODEL
# --------------------------------------------------------------------------
# Represents audit alerts to monitor and trigger events based on
# [Alert Rules](eventRule.html) running against audit data or
# static values.

class SystemApp.AuditEvent extends SystemApp.BaseModel
    typeName: "AuditEvent"
    defaults:
        active: true

    relations:
        actions: SystemApp.EventActionCollection
        rules: SystemApp.EventRuleCollection


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the description of the entity.
    description: (value) =>
        if value?
            @set "description", value
        @get "description"

    # Helper to get / set the alert rules collection.
    rules: (value) =>
        if value?
            value = new SystemApp.EventRuleCollection value if not value.typeName?
            value.parentModel = this
            @set "rules", value
        @get "rules"

    # Helper to get / set the alert actions collection.
    actions: (value) =>
        if value?
            value = new SystemApp.EventActionCollection value if not value.typeName?
            value.parentModel = this
            @set "actions", value
        @get "actions"

    # Helper to get / set the alert active (true or false).
    active: (value) =>
        if value?
            @set "active", value
        @get "active"


    # METHODS
    # ----------------------------------------------------------------------

    # Run all rules. This will return the list of matched [Alert Rules](eventRule.html),
    # or an empty array if no rule was matched (so no action to do).
    run: (contextValues) =>
        matchedRules = []

        if @active()
            _.each @rules().models, (rule) =>
                if rule.test(contextValues)
                    matchedRules.push(rule)

        if matchedRules.length > 0
            @trigger "#{@id}:enable", this
        else
            @trigger "#{@id}:disable", this

        return matchedRules


# AUDIT ALERT COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of audit alerts.

class SystemApp.AuditEventCollection extends SystemApp.BaseCollection
    typeName: "AuditEventCollection"
    model: SystemApp.AuditEvent
    url: SystemApp.Settings.AuditEvent.url

    # Set the comparator function to order the audit events collection by title.
    comparator: (auditEvent) -> return auditEvent.friendlyId()