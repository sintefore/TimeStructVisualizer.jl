using TimeStruct
using TimeStructVisualizer

simple = SimpleTimes(10,1)
periods = SimpleTimes(5, [1, 1, 1, 5, 5])
varying = SimpleTimes([1, 1, 1, 3, 3, 5, 5])
opscen = OperationalScenarios([SimpleTimes(5,1), SimpleTimes(3,2), SimpleTimes(4,[3,2,1,1]), SimpleTimes(2,3)], [0.3, 0.4, 0.2, 0.1])
scenarios = OperationalScenarios(5, SimpleTimes(7,1))
rep = RepresentativePeriods(2, 100, [0.2, 0.8], [opscen, opscen])
strat = TwoLevel(3, 15, SimpleTimes(5,1))
scen = TwoLevel(3, 15, OperationalScenarios(3,SimpleTimes(5,1)))

two_rep = TwoLevel(3, 100, RepresentativePeriods(2, 100, [0.5, 0.5], [SimpleTimes(3,1), SimpleTimes(4,1)]))

strat_rep = TwoLevel(3, 20.0, rep)

regtree = regular_tree(5, [3,2], SimpleTimes(5,1))
regtree = regular_tree(5, [3,2], opscen)


TimeStructPlotting.draw(simple)
TimeStructPlotting.draw(periods; showdur=true, height=100, width=400, filename="simple.png")

TimeStructPlotting.draw(varying; showdur=true, height=100, filename="simple_times.png")

TimeStructPlotting.draw(rep; height=200, layout=:middle)
TimeStructPlotting.draw(scenarios; showprob=true, height=200, width=400, filename="scenario.png")
TimeStructPlotting.draw(opscen; showprob=true, height=200, filename="opscen.png")

TimeStructPlotting.draw(opscen; showprob=true, height=200, filename="opscen.png")


TimeStructPlotting.draw(strat; height=200, filename="twolevel.png")
TimeStructPlotting.draw(strat; height=200, filename="twolevel.png", layout=:top)

TimeStructPlotting.draw(strat_rep; height=500)
TimeStructPlotting.draw(two_rep; height=500)


TimeStructPlotting.draw(regtree; height=300, filename="regtree.png", layout=:top)

TimeStructPlotting.draw(scen; filename="scen.png", layout=:top)
op = OperationalProfile([2, 1, 3])
scp = ScenarioProfile([1.0*op, 1.1*op, 1.2*op])
sp = StrategicProfile([scp, scp + 1, scp + 3])
TimeStructPlotting.draw(scen; filename="scen.png", layout=:top, profile=sp)


opscen1 = OperationalScenarios(3,[SimpleTimes(4,2), SimpleTimes(6,1), SimpleTimes(4,[1,1,3,3])], [0.3, 0.4, 0.3])
opscen2 = OperationalScenarios(4,[SimpleTimes(5,1), SimpleTimes(3,2), SimpleTimes(4,[3,2,1,1]), SimpleTimes(2,3)], [0.3, 0.4, 0.2, 0.1])

TimeStructPlotting.draw(opscen1)

twolev = TwoLevel(2, 53, [opscen1, opscen2])

simple = SimpleTimes(5,1)
p1 = OperationalProfile([1,3,3,4,2])
p2 = ScenarioProfile([[1, 3, 2, 4, 5], [1], [2], [3], [8]])

op = OperationalScenarios(5, SimpleTimes(6,1))

TimeStructPlotting.draw(twolev; layout = :top, showdur = true, showprob = true, profile = p2)

rep_periods = RepresentativePeriods(2, 365, [0.6, 0.4], [SimpleTimes(7,1), SimpleTimes(7,1)])
TimeStructPlotting.draw(rep_periods; showdur = true)
periods = TwoLevel(2, 365, rep_periods)

cost = StrategicProfile(
            [
                RepresentativeProfile(
                    [
                        OperationalProfile([3, 3, 4, 3, 4, 6, 5]),
                        FixedProfile(5)
                    ]
                ),
                FixedProfile(7)
            ]
        )
TimeStructPlotting.draw(periods; layout = :top, height=200, profile = cost, filename="profiles.png")

TimeStructPlotting.draw(periods; layout = :top, height=400, filename="two_complex.png")

scenarios = OperationalScenarios(
    3,
    [SimpleTimes(5,1), SimpleTimes(7,2), SimpleTimes(10,1)],
    [0.3, 0.2, 0.5]
)
TimeStructPlotting.draw(scenarios; showprob=true, height=200, width=400, filename="scenario.png")
