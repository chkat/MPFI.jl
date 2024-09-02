using MPFI
using Test

@testset "MPFI.jl" begin
    @test BigInterval("1.0") == BigInterval(BigFloat(1.0))
end
