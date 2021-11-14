using TimeStruct
using TimeStructPlotting

opscen1 = OperationalScenarios(3,[SimpleTimes(4,2), SimpleTimes(6,1), SimpleTimes(4,[1,1,3,3])], [0.3, 0.4, 0.3])
opscen2 = OperationalScenarios(4,[SimpleTimes(5,1.5), SimpleTimes(3,2), SimpleTimes(4,[3,2,1,1]), SimpleTimes(2,3)], [0.3, 0.4, 0.2, 0.1])

twolev = TwoLevel(2, 53, [opscen1, opscen2])

simple = SimpleTimes(5,1)
p1 = OperationalProfile([1,3,3,4,2])
p2 = ScenarioProfile([[1, 3, 2, 4, 5], [1], [2], [3], [8]])

op = OperationalScenarios(5, SimpleTimes(6,1))

TimeStructPlotting.draw(twolev; layout = :top, showdur = true, showprob = true, profile = p1)
