using MPFI
using Test

@testset "MPFI.jl" begin
    # Basic interval operations and properties
    @testset "Basic Operations" begin
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
        @test MPFI.is_inside(BigInterval(2,4), BigInterval(1,4)) == true
        @test MPFI.is_inside(BigInterval(2.,4.1), BigInterval(1,4)) == false
    end

    # Arithmetic operations
    @testset "Arithmetic Operations" begin
        x = BigInterval(1, 2)
        y = BigInterval(3, 4)
        
        # Basic arithmetic
        @test x + y == BigInterval(4, 6)
        @test x - y == BigInterval(-3, -1)
        @test x * y == BigInterval(3, 8)
        @test is_inside(x/y, BigInterval(0.25, 0.6666666666666667))
        
        # Edge cases
        @test x + BigInterval(Inf) == BigInterval(Inf)
        @test x * BigInterval(0) == zero(BigInterval)
        @test x / zero(BigInterval) == BigInterval(-Inf, Inf)
        
        # Multiple operations
        @test x + y + x == BigInterval(5, 8)
        @test x * y * x == BigInterval(3, 16)
    end

    # Precision handling
    @testset "Precision Handling" begin
        # Different precisions
        x = BigInterval(1; precision=64)
        y = BigInterval(2; precision=128)
        
        # Operations should use max precision
        @test precision(x + y) == 128
        @test precision(x * y) == 128
        
        # Explicit precision setting
        z = BigInterval(1; precision=256)
        @test precision(z) == 256
        
        # Precision in conversions
        @test precision(BigInterval(BigFloat(1; precision=512))) == 512
    end

    # Special functions
    @testset "Special Functions" begin
        x = BigInterval(3, 4)
        y = BigInterval(4, 5)
        
        # hypot
        @test isapprox(left(hypot(x, y)), 5.0, atol=1e-10)
        @test isapprox(right(hypot(x, y)), 6.4031242374328485, atol=1e-10)
        
        # ldexp
        @test ldexp(BigInterval(1), 2) == BigInterval(4)
        @test ldexp(BigInterval(1), -1) == BigInterval(0.5)
        
        # square
        @test square(BigInterval(2)) == BigInterval(4)
        @test square(BigInterval(-2, 2)) == BigInterval(0, 4)
    end

    # String parsing and conversion
    @testset "String Parsing and Conversion" begin
        # Valid inputs
        @test BigInterval("1.0") == BigInterval(1.0)
        
        # Invalid inputs
        @test_throws ErrorException BigInterval("not a number")
        @test_throws ErrorException BigInterval("1.2.3")
        
        # String representation
        x = BigInterval(1.234)
        @test string(x, 2) == "[1.23, 1.24]"
    end

    # Type conversions
    @testset "Type Conversions" begin
        x = BigInterval(1,3)
        
        # To other numeric types
        @test convert(Float64, x) == Float64(x) == 2
        @test convert(BigFloat, x) == BigFloat(x) == BigFloat(2)
        @test convert(BigInt, x) == BigInt(x) == BigInt(2)
        
        # From other numeric types
        @test BigInterval(BigFloat(2)) == BigInterval(2)
        @test BigInterval(BigInt(2)) == BigInterval(2)
    end

    # Set operations
    @testset "Set Operations" begin
        x = BigInterval(1, 3)
        y = BigInterval(2, 4)
        
        # Intersection
        @test MPFI.intersect(x, y) == BigInterval(2, 3)
        @test isempty(MPFI.intersect(BigInterval(1, 2), BigInterval(3, 4)))
        
        # Union
        @test MPFI.union(x, y) == BigInterval(1, 4)
        
        # Bisect
        left, right = bisect(x)
        @test left == BigInterval(1, 2)
        @test right == BigInterval(2, 3)
        
        # Blow
        @test blow(x, 0.5) == BigInterval(0.5, 3.5)
    end
end
