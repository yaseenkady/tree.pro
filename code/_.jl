using Revise
using BenchmarkTools
using PyCall

using Kwat

kwat = pyimport("kwat")

pas = joinpath("..", "input", "setting.json")

SE = Kwat.workflow.read_setting(pas)

PAR, PAI, PAC, PAO = Kwat.workflow.get_path(pas)

# ==============================================================================
function shorten_path(pa::String, di::String)::String

    sp_ = splitpath(pa)

    id = findfirst(sp_ .== di)

    return joinpath(sp_[(id + 1):end]...)

end

function move(
    pa1::String,
    pa2::String;
    n_di::Int64 = 0,
    te::Bool = false,
)::String

    sp1_ = splitpath(pa1)

    sp2_ = splitpath(pa2)

    n_sk = length(Kwat.vector.get_longest_common_prefix([sp1_, sp2_])) - n_di

    println(joinpath(sp1_[n_sk:end]...), " ==> ", joinpath(sp2_[n_sk:end]...))

    if te

        return "Testing (not moved)."

    else

        return mv(pa1, pa2)

    end

end

# ==============================================================================
function walk_up(hi::String)::Vector{Vector{Union{String, Vector{String}}}}

    return [
        [ro, di_, [fi for fi in fi_ if endswith(fi, ".md")]] for
        (ro, di_, fi_) in walkdir(hi; topdown = false)
    ]

end

function is_good_structure(na::String)::Bool

    return occursin(r"^([0-9]+\.){1,2}[a-z0-9_]+(\.md$|$)", na)

end

function split_good_structure(na::String)::Tuple{Float64, String, String}

    sp_ = string.(split(na, "."))

    if !endswith(na, ".md")

        sp_ = push!(sp_, "/")

    end

    fl1 = parse(Float64, sp_[1])

    fl2 = tryparse(Float64, sp_[2])

    if isnothing(fl2)

        pa_ = (fl1, sp_[2:3]...)

    else

        pa_ = (fl1 + fl2 / 10.0, sp_[3:4]...)

    end

    return pa_

end

function make_id(pa::String, hi::String)::Vector{Int64}

    sp_ = splitpath(pa)

    return [
        parse(Int64, split(sp, ".")[1]) for
        sp in sp_[(findfirst(sp_ .== hi) + 1):end]
    ]

end
