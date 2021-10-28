using Revise
using BenchmarkTools
using PyCall

using Kwat

kwat = pyimport("kwat")

pas = joinpath("..", "input", "setting.json")

SE = Kwat.workflow.read_setting(pas)

PAR, PAI, PAC, PAO = Kwat.workflow.get_path(pas)

# ==============================================================================
function shorten_path(pa::String, n_ba::Int64)::String

    return joinpath(splitpath(pa)[(end - n_ba):end]...)

end

function shorten_path(pa::String, di::String)::String

    sp_ = splitpath(pa)

    id = findfirst(sp_ .== split(di, "/")[end]) + 1

    return shorten_path(pa, length(sp_) - id)

end

function move(
    pa1::String,
    pa2::String;
    n_ba::Int64 = 1,
    te::Bool = false,
)::String

    sp1_ = splitpath(pa1)

    sp2_ = splitpath(pa2)

    n_sk = length(Kwat.vector.get_longest_common_prefix([sp1_, sp2_])) - n_ba

    println(joinpath(sp1_[n_sk:end]...), " ==> ", joinpath(sp2_[n_sk:end]...))

    if te

        return ""

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

function is_good_name(na::String)::Bool

    return occursin(r"^([0-9]+\.){1,2}[a-z0-9_]+(\.md$|$)", na)

end

function split_name(na::String)::Vector{Union{Int64, Float64, String}}

    sp_ = string.(split(na, "."))

    it1 = parse(Int64, sp_[1])

    it2 = tryparse(Int64, sp_[2])

    if isnothing(it2)

        pa_ = [it1; sp_[2:end]]

    else

        pa_ = [it1 + it2 / 10; sp_[3:end]]

    end

    return pa_

end

function make_continuous(
    ro::String,
    na_::Vector{String};
    te::Bool = false,
)::Nothing

    for (id, na) in enumerate(sort!(na_; by = split_name))

        co = join((id, split_name(na)[2:end]...), ".")

        if na != co

            move(joinpath(ro, na), joinpath(ro, co); te = te)

        end

    end

    return nothing

end

function id_name(pa::String, hi::String)::Vector{Int64}

    sp_ = splitpath(pa)

    return [
        parse(Int64, split(sp, ".")[1]) for
        sp in sp_[(findfirst(sp_ .== split(hi, "/")[end]) + 1):end]
    ]

end

function get_parent_title(ro::String)::String

    return split_name(splitdir(ro)[2])[2]

end

function catalog(hi)::Dict{String, Dict{String, Union{String, Vector{Int64}}}}

    ti_di = Dict{String, Dict{String, Union{String, Vector{Int64}}}}()

    for (ro, di_, fi_) in walk_up(hi)

        for fi in fi_

            ti = split_name(fi)[2]

            if ti == "_"

                ti = get_parent_title(ro)

            end

            pa = joinpath(ro, fi)

            if haskey(ti_di, ti)

                error(
                    "2: ",
                    shorten_path(ti_di[ti]["path"], 1),
                    " and ",
                    shorten_path(pa, 1),
                )

            else

                ti_di[ti] = Dict(
                    "path" => pa,
                    "id" => id_name(pa, string(rstrip(hi, '/'))),
                )

            end

        end

    end

    return ti_di

end
