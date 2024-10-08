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

TimeStructVisualizer.draw(simple)TimeStructVisualizer.draw(periods; showdur=true, height=100, width=400, filename="simple.png")
TimeStructVisualizer.draw(varying; showdur=true, height=100, filename="simple_times.png")
TimeStructVisualizer.draw(rep; height=200, layout=:middle)TimeStructVisualizer.draw(scenarios; showprob=true, height=200, width=400, filename="scenario.png")TimeStructVisualizer.draw(opscen; showprob=true, height=200, filename="opscen.png")
TimeStructVisualizer.draw(opscen; showprob=true, height=200, filename="opscen.png")

TimeStructVisualizer.draw(strat; height=200, filename="twolevel.png")TimeStructVisualizer.draw(strat; height=200, filename="twolevel.png", layout=:top)
TimeStructVisualizer.draw(strat_rep; height=500)TimeStructVisualizer.draw(two_rep; height=500)

TimeStructVisualizer.draw(regtree; height=300, filename="regtree.png", layout=:top)
TimeStructVisualizer.draw(scen; filename="scen.png", layout=:top)
op = OperationalProfile([2, 1, 3])
scp = ScenarioProfile([1.0*op, 1.1*op, 1.2*op])
sp = StrategicProfile([scp, scp + 1, scp + 3])TimeStructVisualizer.draw(scen; filename="scen.png", layout=:top, profile=sp)


opscen1 = OperationalScenarios(3,[SimpleTimes(4,2), SimpleTimes(6,1), SimpleTimes(4,[1,1,3,3])], [0.3, 0.4, 0.3])
opscen2 = OperationalScenarios(4,[SimpleTimes(5,1), SimpleTimes(3,2), SimpleTimes(4,[3,2,1,1]), SimpleTimes(2,3)], [0.3, 0.4, 0.2, 0.1])
TimeStructVisualizer.draw(opscen1)

twolev = TwoLevel(2, 53, [opscen1, opscen2])

simple = SimpleTimes(5,1)
p1 = OperationalProfile([1,3,3,4,2])
p2 = ScenarioProfile([[1, 3, 2, 4, 5], [1], [2], [3], [8]])

op = OperationalScenarios(5, SimpleTimes(6,1))
TimeStructVisualizer.draw(twolev; layout = :top, showdur = true, showprob = true, profile = p2)

rep_periods = RepresentativePeriods(2, 365, [0.6, 0.4], [SimpleTimes(7,1), SimpleTimes(7,1)])TimeStructVisualizer.draw(rep_periods; showdur = true)
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
        )TimeStructVisualizer.draw(periods; layout = :top, height=200, profile = cost, filename="profiles.png")
TimeStructVisualizer.draw(periods; layout = :top, height=400, filename="two_complex.png")

scenarios = OperationalScenarios(
    3,
    [SimpleTimes(5,1), SimpleTimes(7,2), SimpleTimes(10,1)],
    [0.3, 0.2, 0.5]
)
TimeStructVisualizer.draw(scenarios; showprob=true, height=200, width=400, filename="scenario.png")

operational = SimpleTimes(7, 1)
two_level_tree = regular_tree(3, [3,2], operational; op_per_strat = 52)
TimeStructVisualizer.draw(two_level_tree; layout=:top, height=400, filename="two_level_tree.png")
