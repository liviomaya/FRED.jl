
module FRED

include("f0_header.jl")
include("f1_fetch.jl")

end # module

###############################################################
###############################################################
###############################################################
###############################################################
###############################################################
###############################################################

using CSV
using DataFrames, Dates
using HTTP
using JSON
using PrettyTables


###############################################################
###############################################################
###############################################################
###############################################################
###############################################################
###############################################################


FRED_key() = "c9e84df4d5b609afe2db4711f06c84d2"

function get_series(id::String)

    # parameters
    params = Dict(
        "api_key" => FRED_key(),
        "file_type" => "json",
        "series_id" => id
    )

    # download the data
    d = HTTP.request("GET", "https://api.stlouisfed.org/fred/series/observations", query = params)
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

function get_series(id_vec::Vector{String})

    # DataFrame
    df = DataFrame("date" => Vector{Date}(undef, 0))
    for id in id_vec
        gh = get_series(id)
        df = outerjoin(df, gh, on = :date)
    end

    sort!(df, :date)
    df = coalesce.(df, NaN)

    return df
end

function get_series(df, id)
    nd = get_series(id)
    df = outerjoin(df, nd, on = :date)
    sort!(df, :date)
    df = coalesce.(df, NaN)
    return df
end


###############################################################
###############################################################
###############################################################
###############################################################
###############################################################
###############################################################

using FRED

user() = "LIVIMAY"
pass() = "Safra666"
proxy_add() = "http://$(user()):$(pass())@proxysrv.safra.com.br:8080"
ENV["HTTP_PROXY"] = proxy_add()
ENV["HTTPS_PROXY"] = proxy_add()

# id = "PAYEMS" , "EFFR"
df = FRED.get_series(id) # get one series
df = FRED.get_series(id_vec) # get multiple series
df = FRED.get_series(df, id) # increment existent frame
df = FRED.get_series(df, id_vec) # increment existent frame

CSV.write(file, df) # save table (after loading CSV)

