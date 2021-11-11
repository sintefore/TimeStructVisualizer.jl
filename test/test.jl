using TimeStructures
using TimeStructPlotting

ts = OperationalScenarios(3,SimpleTimes(8,1))

TimeStructPlotting.draw(ts)
