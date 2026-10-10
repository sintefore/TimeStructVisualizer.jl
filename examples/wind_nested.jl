# Nested drawing of a time structure typical for investment models of energy systems:
# strategic periods of 5 years, where each year is represented by one week per season
# at hourly resolution, with five wind scenarios for each week.
#
# Run from the package folder with `julia --project examples/wind_nested.jl`. This
# regenerates `docs/example_wind.png`, which is shown in the README.

using Random
using TimeStruct
using TimeStructVisualizer

hours_per_week = 7 * 24
hours_per_year = 8760
seasons = ["winter", "spring", "summer", "autumn"]

# Each season is represented by one week, which represents a quarter of the year
week = SimpleTimes(hours_per_week, 1)
year = RepresentativePeriods(
    length(seasons),
    hours_per_year,
    fill(1 / length(seasons), length(seasons)),
    [OperationalScenarios(5, week) for _ in seasons],
)
ts = TwoLevel(4, 5, year; op_per_strat = hours_per_year)

# Synthetic hourly capacity factors for wind power. Weather systems give a
# persistent variation around the seasonal mean, modelled as an autoregressive
# process, with a weak daily cycle on top.
mean_capacity_factor = Dict("winter" => 0.45, "spring" => 0.35, "summer" => 0.22, "autumn" => 0.38)
persistence = 0.95
variability = 0.2

function wind_week(rng, mean)
    weather = zeros(hours_per_week)
    for h = 2:hours_per_week
        weather[h] =
            persistence * weather[h-1] + variability * sqrt(1 - persistence^2) * randn(rng)
    end
    daily = [0.03 * cos(2π * (h - 15) / 24) for h = 1:hours_per_week]
    return clamp.(mean .+ weather .+ daily, 0, 1)
end

rng = MersenneTwister(2024)
wind = RepresentativeProfile([
    ScenarioProfile([
        OperationalProfile(wind_week(rng, mean_capacity_factor[season])) for _ = 1:5
    ]) for season in seasons
])

# Probabilities are not shown since the scenarios are equally likely, which is
# already visible from their heights. PNG keeps the file small with this many cells.
TimeStructVisualizer.draw(
    ts;
    layout = :nested,
    profile = wind,
    showdur = true,
    width = 1200,
    height = 600,
    filename = joinpath(@__DIR__, "..", "docs", "example_wind.png"),
)
