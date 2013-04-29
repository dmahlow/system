# VARIABLE MODEL
# --------------------------------------------------------------------------
# Variables are javascript blocks that can represent aggregated values,
# calculations and combinations of different [AuditData](auditData.html) sources
# and static values.

class SystemApp.Variable extends SystemApp.BaseModel
    typeName: "Variable"
    defaults:
        code: null          # the variable javascript code
        description: null   # the variable description / notes


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the variable code.
    code: (value) =>
        if value?
            @set "code", value
        @get "code"

    # Helper to get / set the variable description.
    description: (value) =>
        if value?
            @set "description", value
        @get "description"


# VARIABLE COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of variables.

class SystemApp.VariableCollection extends SystemApp.BaseCollection
    typeName: "VariableCollection"
    model: SystemApp.Variable
    url: SystemApp.Settings.Variable.url

    # Set the comparator function to order the variable collection by friendlyId.
    comparator: (variable) -> return variable.friendlyId()