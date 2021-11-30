using OrderedCollections

using PathExtension

function walk_up(tr::String)::Vector{Vector{Union{String,Vector{String}}}}

    return [
        [ro, di_, [fi for fi in fi_ if endswith(fi, ".md")]] for
        (ro, di_, fi_) in walkdir(tr; topdown = false)
    ]

end

function is_good_name(na::String)::Bool

    return occursin(r"^([0-9]+\.){1,2}[_0-9a-z]+(\.md$|$)", na)

end

function split_name(na::String)::Vector{Union{Int64,Float64,String}}

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

function make_continuous(ro::String, na_::Vector{String})::Nothing

    for (id, na) in enumerate(sort!(na_; by = split_name))

        co = join((id, split_name(na)[2:end]...), ".")

        if na != co

            PathExtension.move(joinpath(ro, na), joinpath(ro, co))

        end

    end

    return nothing

end

function id(md::String)::Vector{Int64}

    sp_ = splitpath(md)

    return [
        parse(Int64, split(sp, ".")[1]) for sp in sp_[(findfirst(sp_ .== "tree")+1):end]
    ]

end

function read_content(md::String)::Dict{String,Vector{String}}

    bl_ = ["# =", "# .", "# <", "# >"]

    li_ = [li for li in readlines(md) if li != ""]

    lbl_ = [li for li in li_ if startswith(li, '#')]

    sh = PathExtension.shorten(md, 1)

    if length(li_) == 0

        println("writing ", sh)

        write(md, join(bl_, "\n"^2))

    elseif length(lbl_) != length(bl_) || !all(lbl_ .== bl_)

        error("fix block ", sh)

    end

    bl_li_ = Dict(bl => Vector{String}() for bl in bl_)

    bl = ""

    for li in li_

        if li in bl_

            bl = li

            continue

        end

        push!(bl_li_[bl], li)

    end

    he = bl_li_["# ="]

    if 0 < length(he)

        de = he[1]

        if any(occursin(st, de) for st in ['.', ';', '(', ')'])

            error("fix description ", sh)

        end

    end

    for bl in ["# <", "# >"]

        for no in bl_li_[bl]

            if any(occursin(st, no) for st in [';'])

                # TODO: error
                println("fix node ", sh)

            end

        end

    end

    return bl_li_

end

function catalog(
    tr,
)::OrderedDict{String,Dict{String,Union{String,Vector{Int64},Dict{String,Vector{String}}}}}

    ti_di =
        Dict{String,Dict{String,Union{String,Vector{Int64},Dict{String,Vector{String}}}}}()

    for (ro, di_, fi_) in walk_up(tr)

        for fi in fi_

            ti = split_name(fi)[2]

            if ti == "_"

                ti = split_name(splitdir(ro)[2])[2]

            end

            md = joinpath(ro, fi)

            if haskey(ti_di, ti)

                error("fix duplicate ", ti)

            else

                ti_di[ti] = Dict("md" => md, "id" => id(md), "co" => read_content(md))

            end

        end

    end

    return sort(ti_di; by = ti -> ti_di[ti]["id"])

end

# ==============================================================================
# Lean Project
# ==============================================================================
using Revise
using BenchmarkTools

using LeanProject

se = joinpath("..", "input", "setting.json")

PAR, PAI, PAC, PAO = LeanProject.get_project_path(se)

SE = LeanProject.read_setting(se)
