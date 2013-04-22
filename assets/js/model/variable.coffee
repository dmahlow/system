# VARIABLE MODEL
# --------------------------------------------------------------------------
# Variables are javascript blocks that can represent aggregated values,
# calculations and combinations of different [AuditData](auditData.html) sources.

class SystemApp.Variable extends SystemApp.BaseModel
    typeName: "Variable"
    defaults:
        code: null     # the variable javascript code


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the custom variable code.
    code: (value) =>
        if value?
            @set "code", value
        @get "code"


# VARIABLE COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of variables.

class SystemApp.VariableCollection extends SystemApp.BaseCollection
    typeName: "VariableCollection"
    model: SystemApp.Variable
    url: SystemApp.Settings.Variable.url

    # Set the comparator function to order the variable collection by friendlyId.
    comparator: (variable) -> return variable.friendlyId()