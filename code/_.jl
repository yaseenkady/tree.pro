using Revise
using BenchmarkTools

using LeanProject
using PathExtension

# ========================
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
                    shorten(ti_di[ti]["path"], 1),
                    " and ",
                    shorten(pa, 1),
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

# ========================
se = joinpath("..", "input", "setting.json")

PAR, PAI, PAC, PAO = get_project_path(se)

SE = read_setting(se)

# ========================
TR = joinpath(PAI, "tree")

EX = joinpath(PAI, "1.example.md")
