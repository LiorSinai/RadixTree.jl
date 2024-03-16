using Test
using RadixTree

@testset verbose = true "RadixTree" begin
    include("get.jl")
    include("height.jl")
    include("insert.jl")
    include("iterate.jl")
    include("get_n_larger.jl")
end