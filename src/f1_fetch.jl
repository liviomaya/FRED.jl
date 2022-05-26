
# Safra key! Get new one!
FRED_key() = "c9e84df4d5b609afe2db4711f06c84d2"

function get(id::String; frequency=nothing, aggmethod=nothing)

    # parameters
    params = Dict(
        "api_key" => FRED_key(),
        "file_type" => "json",
        "series_id" => id
    )

    !isnothing(frequency) && merge!(params, Dict("frequency" => frequency))
    !isnothing(aggmethod) && merge!(params,
        Dict("aggregation_method" => aggmethod))

    # download the data
    d = HTTP.request("GET",
        "https://api.stlouisfed.org/fred/series/observations", query=params)
    jfile = String(copy(d.body))
    F = JSON.parse(jfile)

    # DataFrame
    data = F["observations"]
    T = length(data)
    df = DataFrame("date" => Vector{Date}(undef, 0),
        id => Vector{Float64}(undef, 0))
    for t in 1:T
        dict_t = data[t]
        date_t = Date(dict_t["date"], "yyyy-mm-dd")
        v = dict_t["value"]

        if v == "."
            value_t = NaN
        else
            value_t = parse(Float64, v)
        end

        sd = DataFrame("date" => date_t,
            id => value_t)
        df = vcat(df, sd)
    end

    return df
end

function get(id_vec::Vector{String};
    frequency=nothing,
    aggmethod=nothing)

    # DataFrame
    df = DataFrame("date" => Vector{Date}(undef, 0))
    for id in id_vec
        gh = get(id, frequency=frequency, aggmethod=aggmethod)
        df = outerjoin(df, gh, on=:date)
        println("$id done.")
    end

    sort!(df, :date)
    df = coalesce.(df, NaN)

    return df
end

function get(df, id; frequency=nothing, aggmethod=nothing)
    nd = get(id, frequency=frequency, aggmethod=aggmethod)
    df = outerjoin(df, nd, on=:date)
    sort!(df, :date)
    df = coalesce.(df, NaN)
    return df
end