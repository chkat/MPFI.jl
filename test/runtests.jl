using MPFI
using Test

@testset "MPFI.jl" begin
    @test BigInterval("1.0") == BigInterval(BigFloat(1.0))
    @test MPFI.isbounded(BigInterval(1., Inf)) == false
    @test MPFI.isbounded(BigInterval(1., 1.)) == true
    @test MPFI.isbounded(BigInterval()) == false
    @test MPFI.isempty(BigInterval(2, -1)) == false
    @test MPFI.isempty(BigInterval()) == true
    @test MPFI.isnan(BigInterval(Inf)) == false
    @test MPFI.isnan(BigInterval()) == true
    @test MPFI.isinf(BigInterval(1.,Inf)) == true
    @test MPFI.isinf(BigInterval(0)) == false
    @test MPFI.has_zero(BigInterval(1,3)) == false
    @test MPFI.has_zero(BigInterval(1,-1)) == true
    @test MPFI.iszero(BigInterval(0,1)) == false
    @test MPFI.iszero(BigInterval(0,0)) == true
    @test MPFI.is_inside( BigInterval(2,4), BigInterval(1,4)) == true
    @test MPFI.is_inside( BigInterval(2.,4.1), BigInterval(1,4)) == false
    @test MPFI.blow(BigInterval(1,6),2.) == BigInterval(-4, 11)
    @test MPFI.bisect(BigInterval(1,6)) == (BigInterval(1.,3.5), BigInterval(3.5,6.))
    @test MPFI.mid(BigInterval(1,2)) == 1.5
    @test MPFI.isempty(MPFI.intersect(BigInterval(1.0, 2.0), BigInterval(-6,-5))) == true

end
