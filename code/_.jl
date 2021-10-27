using Revise
using BenchmarkTools
using PyCall

using Kwat

kwat = pyimport("kwat")

pas = joinpath("..", "input", "setting.json")

SE = Kwat.workflow.read_setting(pas)

PAR, PAI, PAC, PAO = Kwat.workflow.get_path(pas)

# ==============================================================================
function walk_up(tr::String)::Vector{Vector{Union{String, Vector{String}}}}

    return [
        [ro, di_, [fi for fi in fi_ if endswith(fi, ".md")]] for
        (ro, di_, fi_) in walkdir(tr; topdown = false)
    ]

end

function is_good_structure(na::String)::Bool

    if occursin(r"^[0-9]+\.[0-9]+[_0-9a-z]+(\.md$|$)", na)

        @warn(string("May be bad name: ", na))

    end

    return occursin(r"^([0-9]+\.){1,2}[_0-9a-z]+(\.md$|$)", na)

end

function split_good_structure(na::String)::Vector{Union{Float64, String}}

    pa_ = Vector{Union{Float64, String}}()

    sp_ = string.(split(na, "."))

    it1 = tryparse(Int64, sp_[1])

    it2 = tryparse(Int64, sp_[2])

    if isnothing(it2)

        pa_ = [convert(Float64, it1); sp_[2:end]]

    else

        pa_ = [parse(Float64, join([it1, it2], ".")); sp_[3:end]]

    end

    return pa_

end

function make_id(pa::String)::Vector{Int64}

    sp_ = splitpath(pa)

    return [
        parse(Int64, split(sp, ".")[1]) for
        sp in sp_[(findfirst(sp_ .== "tree") + 1):end]
    ]

end
