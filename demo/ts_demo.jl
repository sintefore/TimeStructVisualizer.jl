### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 3b8a2c70-43b7-11ec-1e62-7fa4d803a3dc
begin
	import Pkg
	Pkg.activate(string(@__DIR__,"./../"))
end

# ╔═╡ 32ebd6cd-e290-4de5-8df5-4e87c6133e45
using TimeStruct, TimeStructPlotting

# ╔═╡ 051d8959-8c3d-410b-a63d-15899dfc7984
@bind periods html"<input type='range' min = 1 max = 10>"

# ╔═╡ 1b6f7a6c-855e-4228-9c4b-64625920efdd
periods

# ╔═╡ fb5edea4-09ec-4858-b70f-04ccc49e1d56
operation = SimpleTimes(periods,1);

# ╔═╡ 0f760560-c62c-4e2c-b134-e2849bf8d71a
@bind stratpers html"<input type='range' min = 1 max = 8>"

# ╔═╡ c5042e2a-f10c-48b2-8952-9d4b2bf07395
stratpers

# ╔═╡ fd1b1ba1-0b5d-4797-b52c-82fbd4ba02f6
twolevel = TwoLevel(stratpers, 100, operation);

# ╔═╡ 03ffcd48-7ff2-4040-8862-d21d5eb1d6de
const TSP = TimeStructPlotting

# ╔═╡ 6ae36c35-6d04-490a-a3d6-27463ba57727
TSP.draw(twolevel; layout=:top, showdur=true)

# ╔═╡ Cell order:
# ╟─051d8959-8c3d-410b-a63d-15899dfc7984
# ╠═1b6f7a6c-855e-4228-9c4b-64625920efdd
# ╠═fb5edea4-09ec-4858-b70f-04ccc49e1d56
# ╟─0f760560-c62c-4e2c-b134-e2849bf8d71a
# ╠═c5042e2a-f10c-48b2-8952-9d4b2bf07395
# ╠═fd1b1ba1-0b5d-4797-b52c-82fbd4ba02f6
# ╠═6ae36c35-6d04-490a-a3d6-27463ba57727
# ╠═3b8a2c70-43b7-11ec-1e62-7fa4d803a3dc
# ╠═32ebd6cd-e290-4de5-8df5-4e87c6133e45
# ╠═03ffcd48-7ff2-4040-8862-d21d5eb1d6de
