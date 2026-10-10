module TimeStructVisualizer

using Luxor
using Colors
using TimeStruct

include("plot.jl")
include("nested.jl")

# Public but not exported to avoid name clashes, e.g. with other packages' `draw`.
# The `public` keyword requires Julia 1.11, so it is added through `eval` to keep
# the package loadable on older versions.
@static if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public draw, DrawStyle"))
end

end # module
