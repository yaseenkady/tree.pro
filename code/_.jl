using Revise
using BenchmarkTools

using OrderedCollections

using LeanProject
using PathExtension

# ========
function walk_up(tr::String)::Vector{Vector{Union{String, Vector{String}}}}

    return [
        [ro, di_, [fi for fi in fi_ if endswith(fi, ".md")]] for
        (ro, di_, fi_) in walkdir(tr; topdown = false)
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

function id_name(pa::String, tr::String)::Vector{Int64}

    sp_ = splitpath(pa)

    return [
        parse(Int64, split(sp, ".")[1]) for
        sp in sp_[(findfirst(sp_ .== split(tr, "/")[end]) + 1):end]
    ]

end

function get_parent_title(ro::String)::String

    return split_name(splitdir(ro)[2])[2]

end

# TODO: add to .jl
function get_order(an_::Vector, ta_::Vector)::Vector{Int64}

    return [findfirst(an_ .== ta) for ta in ta_]

end

function read_content(md::String)::Dict{String, Vector{String}}

    bl_ = ["# .", "# <", "# >"]

    li_ = [li for li in readlines(md) if li != ""]

    lbl_ = [li for li in li_ if startswith(li, '#')]

    sh = shorten(md, 1)

    if length(li_) == 0

        println("writing ", sh)

        li_ = copy(bl_)

        insert!(li_, 2, split_name(splitdir(md)[2])[2])

        write(md, join(li_, "\n"^2))

    elseif length(lbl_) != length(bl_) || !all(lbl_ .== bl_)

        error("block ", sh)

    end

    bl_li_ = Dict(bl => Vector{String}() for bl in bl_)

    bl = ""

    for li in li_

        if li in bl_

            bl = li

        else

            push!(bl_li_[bl], li)

        end

    end

    he = bl_li_["# ."]

    if length(he) == 0

        println("# . ", sh)

    else

        de = he[1]

        if any(occursin(st, de) for st in ['.', ';', '(', ')'])

            println("description ", sh)

        end

    end

    for bl in ["# <", "# >"]

        for no in bl_li_[bl]

            if any(occursin(st, no) for st in [';'])

                println("node ", sh)

            end

            if any(occursin(st, no) for st in ['('])

                #println(no)

            end

        end

    end

    return bl_li_

end

function catalog(
    tr,
)::OrderedDict{
    String,
    Dict{String, Union{String, Vector{Int64}, Dict{String, Vector{String}}}},
}

    ti_di = Dict{
        String,
        Dict{
            String,
            Union{String, Vector{Int64}, Dict{String, Vector{String}}},
        },
    }()

    for (ro, di_, fi_) in walk_up(tr)

        for fi in fi_

            ti = split_name(fi)[2]

            if ti == "_"

                ti = get_parent_title(ro)

            end

            pa = joinpath(ro, fi)

            if haskey(ti_di, ti)

                error(
                    "duplicated ",
                    shorten(ti_di[ti]["pa"], 1),
                    " and ",
                    shorten(pa, 1),
                )

            else

                ti_di[ti] = Dict(
                    "pa" => pa,
                    "id" => id_name(pa, string(rstrip(tr, '/'))),
                    "co" => read_content(pa),
                )

            end

        end

    end

    return sort(ti_di; by = ti -> ti_di[ti]["id"])

end

# ========
se = joinpath("..", "input", "setting.json")

PAR, PAI, PAC, PAO = get_project_path(se)

SE = read_setting(se)

# ========
TR = joinpath(PAI, "tree")
