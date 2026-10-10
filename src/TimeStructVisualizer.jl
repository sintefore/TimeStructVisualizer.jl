module TimeStructVisualizer

using Luxor
using Colors
using TimeStruct

include("plot.jl")
include("nested.jl")

# Public but not exported to avoid name clashes, e.g. with other packages' `draw`
public draw, DrawStyle

end # module
