# CUSTOM VARIABLE MODEL
# --------------------------------------------------------------------------
# Custom variables are javascript blocks that can represent aggregated
# values, calculations and combinations of different [AuditData](auditData.html)
# sources.

class System.Variable extends System.BaseModel
    typeName: "Variable"
    defaults:
        name: null     # the variable name
        code: null     # the variable code


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the custom variable code.
    code: (value) =>
        if value?
            @set "code", value
        @get "code"


# CUSTOM VARIABLE COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of variables.

class System.VariableCollection extends System.BaseCollection
    typeName: "VariableCollection"
    model: System.Variable
    url: System.App.Settings.Variable.url

    # Set the comparator function to order the custom variable collection by friendlyId.
    comparator: (variable) -> return variable.friendlyId()