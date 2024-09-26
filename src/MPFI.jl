
module MPFI

export BigInterval, precision, left, right, has_zero, isbounded


import Base: +, -, *, /, ==, <, >, <=, >=, string, print, show, isnan, MPFR._string, MPFR, exp, exp2, 
    exp10, expm1, cosh, sinh, tanh, sech, csch, coth, inv, sqrt, cbrt, abs, log, log2, 
    log10, log1p, sin, cos, tan, sec, precision, csc, cot, acos, asin, atan, acosh, asinh, atanh, 
    convert, sum, iszero, zero, one, sign, cmp, setprecision, promote_rule, isempty, isinf, deepcopy_internal

import Base.GMP: ClongMax, CulongMax, CdoubleMax

#=
From GMP.jl:
if Clong == Int32
    const ClongMax = Union{Int8, Int16, Int32}
    const CulongMax = Union{UInt8, UInt16, UInt32}
else
    const ClongMax = Union{Int8, Int16, Int32, Int64}
    const CulongMax = Union{UInt8, UInt16, UInt32, UInt64}
end
const CdoubleMax = Union{Float16, Float32, Float64}

=#
# Replace with the path to your shared library (.so, .dylib or .dll file)
#=LIB_PATH = abspath(joinpath(@__DIR__, "../bin/"))

# Load the shared library
if Sys.iswindows()
    libmpfi = joinpath(LIB_PATH, "Windows_x86_64/libmpfi.dll")
else 
    os=readchomp(`uname -s`)
    mach=readchomp(`uname -m`)
    om = os*"_"*mach

    if Sys.isapple()
        # mpfi compiled with --with-gmp-lib=/Applications/Julia-1.9.app/Contents/Resources/julia/lib/julia --with-mpfr-lib=/Applications/Julia-1.9.app/Contents/Resources/julia/lib/julia
        # and with functions exp10m1, exp2m1, log2p1, log10p1 removed from source files of mpfi
        libmpfi = joinpath(LIB_PATH, om*"/libmpfi.0.dylib")
    else # Sys.islinux()
        libmpfi = joinpath(LIB_PATH, om*"/libmpfi.so.0.0.0")
    end
end =#

using MPFI_jll: libmpfi

"""
    BigInterval <: Number

An arbitrary-precision interval floating-point number type, wrapping the C `mpfi` library.
Use this type to perform operations with intervals that represent ranges of numbers rather than single values.

BigInterval corresponds to the C-structure:
    typedef struct {
        __mpfr_struct left;
        __mpfr_struct right;
    }__mpfi_struct;

"""
mutable struct BigInterval <: Number
    left_prec::Clong
    left_sign::Cint
    left_exp::Clong
    left_d::Ptr{Cvoid}
    right_prec::Clong
    right_sign::Cint
    right_exp::Clong
    right_d::Ptr{Cvoid}

    # I ignore the last fields __d of BigFloats
    # Memory here is managed by MPFI

    """
    BigInterval(; precision=DEFAULT_PRECISION())

    Creates a new `BigInterval` with the given precision.
    Precision must be at least 1.
    """
    function BigInterval(;precision::Integer=DEFAULT_PRECISION())
        precision < 1 && throw(DomainError(precision, "`precision` cannot be less than 1."))
        z = new(zero(Clong), zero(Cint), zero(Clong), C_NULL,
                zero(Clong), zero(Cint), zero(Clong), C_NULL)
        ccall((:mpfi_init2,libmpfi), Cvoid, (Ref{BigInterval}, Clong), Ref(z), precision)
        finalizer(mpfi_clear,z)
        return z
    end
end

DEFAULT_PRECISION() = precision(BigFloat)

mpfi_clear(x::BigInterval) = ccall((:mpfi_clear, libmpfi), Cvoid, (Ref{BigInterval},), Ref(x))

zero(::Type{BigInterval}) = BigInterval(0)
one(::Type{BigInterval}) = BigInterval(1)


#  --------------------------------  Basic access functions  -------------------------------------


#function setprecision(x::BigInterval, prec::Clong)
# return ccall((:mpfi_set_prec, libmpfi), Clong, (Ref{BigInterval},Clong), x, prec)
#end
"""
    precision(x::BigInterval) -> Clong

Returns the precision of the `BigInterval` `x`.
"""
function precision(x::BigInterval)
    return ccall((:mpfi_get_prec, libmpfi), Clong, (Ref{BigInterval},), x)
end

"""
    left(x::BigInterval) -> BigFloat

Returns the left bound of the interval as a `BigFloat`.
"""
function left(x::BigInterval)
    z = BigFloat()
    ccall((:mpfi_get_left, libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
    return z
end

"""
    right(x::BigInterval) -> BigFloat

Returns the right bound of the interval as a `BigFloat`.
"""
function right(x::BigInterval)
    z = BigFloat()
    ccall((:mpfi_get_right, libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
    return z
end


#  ---------------------------  Conversions & Promotion --------------------------------------------

function convert(::Type{BigFloat}, x::BigInterval)
    z = BigFloat(;precision=precision(x))
    ccall((:mpfi_get_fr,libmpfi), Cvoid, (Ref{BigFloat}, Ref{BigInterval}), z, x)
    return z
end

convert(::Type{Float64}, x::BigInterval) =
    ccall((:mpfi_get_d,libmpfi), Float64, (Ref{BigInterval},), x)


promote_rule(::Type{BigInterval}, ::Type{<:Real}) = BigInterval
promote_rule(::Type{BigInterval}, ::Type{<:AbstractFloat}) = BigInterval
promote_rule(::Type{BigInterval}, ::Type{<:Number}) = BigInterval



for to in (Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, BigInt, Float32)
    @eval begin
        function convert(::Type{$to}, x::BigInterval)
            convert($to, convert(BigFloat, x))
        end
    end
end
convert(::Type{Integer}, x::BigInterval) = convert(BigInt, x)
convert(::Type{<:AbstractFloat}, x::BigInterval) = convert(BigFloat, x)


#  --------------------------------  Assignment functions  -------------------------------------

# Default 
BigInterval(x::BigInterval) = x

function deepcopy_internal(x::BigInterval, stackdict::IdDict)
    z = BigInterval(;precision=precision(x))
    ccall((:mpfi_set, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
    return z
end


# convert to BigInterval by passing a standard number
for (fJ, fC) in ((:si,:Clong), (:ui,:Culong), (:d,:Cdouble))
    @eval begin
        function BigInterval(x::($fC);precision::Integer=DEFAULT_PRECISION())
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_set_,fJ)), libmpfi), Int32, (Ref{BigInterval}, $fC), Ref(z), x)
            return z
        end
         # Dyadic constructors
        function BigInterval(x::($fC), y::($fC);precision::Integer=DEFAULT_PRECISION())
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_interv_,fJ)), libmpfi), Int32, (Ref{BigInterval}, $fC, $fC), Ref(z), x, y)

            return z
        end
    end
end

# convert to BigInterval by passing a BigInt or a BigFloat
for (fJ, fC) in ((:z,:BigInt), (:fr,:BigFloat))
    @eval begin
        function BigInterval(x::($fC);precision::Integer=DEFAULT_PRECISION())
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_set_,fJ)), libmpfi), Int32, (Ref{BigInterval}, Ref{$fC}), Ref(z), Ref(x))
            return z
        end
        # Dyadic constructors
        function BigInterval(x::($fC), y::($fC);precision::Integer=DEFAULT_PRECISION())
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_interv_,fJ)), libmpfi), Int32, (Ref{BigInterval}, Ref{$fC}, Ref{$fC}), Ref(z), Ref(x), Ref(y))
            return z
        end
    end
end


function BigInterval(x::AbstractString;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    err = ccall((:mpfi_set_str, libmpfi), Int32, (Ref{BigInterval}, Cstring, Int32), Ref(z), x, 10)
    if err != 0; error("Invalid input"); end
    return z
end

BigInterval(x::Integer;precision::Integer=DEFAULT_PRECISION()) = BigInterval(BigInt(x)::BigInt;precision=precision)
BigInterval(x::Integer, y::Integer;precision::Integer=DEFAULT_PRECISION()) = BigInterval(BigInt(x)::BigInt, BigInt(y)::BigInt;precision=precision)

BigInterval(x::Union{Bool,Int8,Int16,Int32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(convert(Clong, x);precision=precision)
BigInterval(x::Union{Bool,Int8,Int16,Int32}, y::Union{Bool,Int8,Int16,Int32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(convert(Clong, x), convert(Clong, y);precision=precision)


BigInterval(x::Union{UInt8,UInt16,UInt32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(convert(Culong, x);precision=precision)
BigInterval(x::Union{UInt8,UInt16,UInt32}, y::Union{UInt8,UInt16,UInt32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(convert(Culong, x), convert(Culong, y);precision=precision)


BigInterval(x::Union{Float16,Float32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(Cdouble(x);precision=precision)
BigInterval(x::Union{Float16,Float32}, y::Union{Float16,Float32};precision::Integer=DEFAULT_PRECISION()) = BigInterval(Cdouble(x), Cdouble(y);precision=precision)


BigInterval(x::Rational;precision::Integer=DEFAULT_PRECISION()) = BigInterval(numerator(x);precision=precision)::BigInterval / BigInterval(denominator(x);precision=precision)::BigInterval
# to do the dyadic constructor for rationals 





#  --------------------------------  Basic arithmetic operations  -------------------------------------


# Basic commutative arithmetic operations between intervals
for (fJ, fC) in ((:+,:add), (:*,:mul))
    @eval begin 
        function ($fJ)(x::BigInterval, y::BigInterval)
            z = BigInterval(;precision=max(MPFI.precision(x), MPFI.precision(y)))
            ccall(($(string(:mpfi_,fC)),libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), Ref(z), Ref(x), Ref(y))
            return z
        end

        # Unsigned Integer
        function ($fJ)(x::BigInterval, c::CulongMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_ui)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Culong), z, x, c)
            return z
        end
        ($fJ)(c::CulongMax, x::BigInterval) = ($fJ)(x,c)

        # Signed Integer
        function ($fJ)(x::BigInterval, c::ClongMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_si)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Clong), z, x, c)
            return z
        end
        ($fJ)(c::ClongMax, x::BigInterval) = ($fJ)(x,c)

        # Float32/Float64
        function ($fJ)(x::BigInterval, c::CdoubleMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_d)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Cdouble), z, x, c)
            return z
        end
        ($fJ)(c::CdoubleMax, x::BigInterval) = ($fJ)(x,c)

        # BigInt
        function ($fJ)(x::BigInterval, c::BigInt)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_z)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInt}), z, x, c)
            return z
        end
        ($fJ)(c::BigInt, x::BigInterval) = ($fJ)(x,c)

         # BigFloat
         function ($fJ)(x::BigInterval, c::BigFloat)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_fr)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigFloat}), z, x, c)
            return z
        end
        ($fJ)(c::BigFloat, x::BigInterval) = ($fJ)(x,c)
    end
end

# More efficient commutative operations
for (fJ, fC) in ((:+, :add), (:*, :mul))
    @eval begin
        function ($fJ)(a::BigInterval, b::BigInterval, c::BigInterval)
            z = BigInterval(;precision=max(MPFI.precision(a),MPFI.precision(b),MPFI.precision(c)))
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, a, b)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, c)
            return z
        end
        function ($fJ)(a::BigInterval, b::BigInterval, c::BigInterval, d::BigInterval)
            z = BigInterval(;precision=max(MPFI.precision(a),MPFI.precision(b),MPFI.precision(c),MPFI.precision(d)))
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, a, b)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, c)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, d)
            return z
        end
        function ($fJ)(a::BigInterval, b::BigInterval, c::BigInterval, d::BigInterval, e::BigInterval)
            z = BigInterval(;precision=max(MPFI.precision(a),MPFI.precision(b),MPFI.precision(c),MPFI.precision(d),MPFI.precision(e)))
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, a, b)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, c)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, d)
            ccall(($(string(:mpfi_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, e)
            return z
        end
    end
end

function sum(arr::AbstractArray{BigInterval})
    z = BigInterval(0)
    for i in arr
        ccall((:mpfi_add, libmpfi), Int32,
            (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, z, i)
    end
    return z
end

for (fJ, fC) in ((:-,:sub), (:/,:div))
    @eval begin 
        function ($fJ)(x::BigInterval, y::BigInterval)
            z = BigInterval(;precision=max(MPFI.precision(x),MPFI.precision(y)))
            ccall(($(string(:mpfi_,fC)),libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), Ref(z), Ref(x), Ref(y))
            return z
        end

        # Unsigned Integer
        function ($fJ)(x::BigInterval, c::CulongMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_ui)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Culong), z, x, c)
            return z
        end

        function ($fJ)(c::CulongMax, x::BigInterval)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_ui_,fC)), libmpfi), Int32, (Ref{BigInterval}, Culong, Ref{BigInterval}), z, c, x)
            return z
        end
        

        # Signed Integer
        function ($fJ)(x::BigInterval, c::ClongMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_si)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Clong), z, x, c)
            return z
        end

        function ($fJ)(c::ClongMax, x::BigInterval)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_si_,fC)), libmpfi), Int32, (Ref{BigInterval}, Clong, Ref{BigInterval}), z, c, x)
            return z
        end
        

        # Float32/Float64
        function ($fJ)(x::BigInterval, c::CdoubleMax)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_d)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Cdouble), z, x, c)
            return z
        end

        function ($fJ)(c::CdoubleMax, x::BigInterval)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_d_,fC)), libmpfi), Int32, (Ref{BigInterval}, Cdouble, Ref{BigInterval}), z, c, x)
            return z
        end
        

        # BigInt
        function ($fJ)(x::BigInterval, c::BigInt)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_z)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInt}), z, x, c)
            return z
        end

        function ($fJ)(c::BigInt, x::BigInterval)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_z_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInt}, Ref{BigInterval}), z, c, x)
            return z
        end

         # BigFloat
         function ($fJ)(x::BigInterval, c::BigFloat)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_,fC,:_fr)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigFloat}), z, x, c)
            return z
        end
        
        function ($fJ)(c::BigFloat, x::BigInterval)
            z = BigInterval(;precision=MPFI.precision(x))
            ccall(($(string(:mpfi_fr_,fC)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigFloat}, Ref{BigInterval}), z, c, x)
            return z
        end
    end
end

#=/* arithmetic operations taking a single interval operand */


/* Special functions                                        */

=#
function -(x::BigInterval)
    z = BigInterval(;precision=MPFI.precision(x))
    ccall((:mpfi_neg, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
    return z
end

function square(x::BigInterval)
    z = BigInterval(;precision=MPFI.precision(x))
    ccall((:mpfi_sqr, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
    return z
end

# exp10m1, :exp2m1 :log10p1, :log2p1 not interfaced
for f in (:exp, :exp2, :exp10, :expm1, :cosh, :sinh, :tanh, :sech, :csch, :coth, :inv,
     :sqrt, :cbrt, :abs, :rec_sqrt, :log, :log2, :log10, :log1p, :sin, :cos, :tan, :sec,
    :csc, :cot, :acos, :asin, :atan, :acosh, :asinh, :atanh)
    @eval function $f(x::BigInterval;precision::Integer=MPFI.precision(x))
        z = BigInterval(;precision=precision)
        ccall(($(string(:mpfi_,f)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
        return z
    end
end

function atan(y::BigInterval, x::BigInterval)
    z = BigInterval(;precision=max(MPFI.precision(x),MPFI.precision(y)))
    ccall((:mpfi_atan2, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, y, x)
    return z
end

# constants

#=
int     mpfi_const_log2         (mpfi_ptr);
int     mpfi_const_pi           (mpfi_ptr);
int     mpfi_const_euler        (mpfi_ptr);
int     mpfi_const_catalan      (mpfi_ptr);
=#
BigInterval(x::Irrational;precision::Integer=DEFAULT_PRECISION()) = convert(BigInterval,x;precision=precision)#BigInterval(BigFloat(x))


# TODO : USE MPFI FUNCTIONS FOR CERTAIN CONSTANTS

#=for (fC, fJ) in ((:pi,:π), (:euler,:ℯ))#, (:catalan,:MathConstants.catalan))
    @eval begin
    #BigInterval(::Irrational{:$fJ}) = convert(BigInterval, $fJ)
    function convert(::Type{BigInterval}, x::Irrational{:($fJ)})
        println("fsdfsd")
        z = BigInterval(;precision=precision)
        ccall(($(string(:mpfi_const_,($fC))),libmpfi), Int32, (Ref{BigInterval},), z)
        return z
    end
    end
end
=#


function convert(::Type{BigInterval}, ::Irrational{:π};precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_const_pi,libmpfi), Cint, (Ref{BigInterval},), z)
    return z
end

function convert(::Type{BigInterval}, ::Irrational{:ℯ};precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_const_euler,libmpfi), Cint, (Ref{BigInterval},), z)
    return z
end



# --------------------------------  Various useful interval functions  -------------------------------------


for f in (:diam_abs, :diam_rel, :diam, :mag, :mig, :mid)
    @eval function $(f)(x::BigInterval;precision::Integer=DEFAULT_PRECISION())
        z = BigFloat(;precision=precision)
        ccall(($(string(:mpfi_,f)), libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
        return z
    end
end

function ldexp(x::BigInterval, n::Clong;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_mul_2si, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Clong), z, x, n)
    return z
end
function ldexp(x::BigInterval, n::Culong;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_mul_2ui, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Culong), z, x, n)
    return z
end
ldexp(x::BigInterval, n::ClongMax) = ldexp(x, convert(Clong, n))
ldexp(x::BigInterval, n::CulongMax) = ldexp(x, convert(Culong, n))
ldexp(x::BigInterval, n::Integer) = x * exp2(BigInterval(n))

function hypot(x::BigInterval, y::BigInterval;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_hypot, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, x, y)
    return z
end



#  --------------------------------  Utility functions  -------------------------------------

# checks if there is intersection 
# when x == 0 it works as has_zero
==(x::BigInterval, y::BigInterval) = left(x)==left(y) && right(x)==right(y) #ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), Ref(x), Ref(y)) == 0
<=(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) != 1
>=(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) !=-1
<(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) == -1
>(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) == 1

function cmp(x::BigInterval, y::BigInt)
    isnan(x) && return 1
    ccall((:mpfi_cmp_z_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInt}), x, y)
end
function cmp(x::BigInterval, y::ClongMax)
    isnan(x) && return 1
    ccall((:mpfi_cmp_si_default, libmpfi), Int32, (Ref{BigInterval}, Clong), x, y)
end
function cmp(x::BigInterval, y::CulongMax)
    isnan(x) && return 1
    ccall((:mpfi_cmp_ui_default, libmpfi), Int32, (Ref{BigInterval}, Culong), x, y)
end
cmp(x::BigInterval, y::Integer) = cmp(x,big(y))
cmp(x::Integer, y::BigInterval) = -cmp(y,x)

function cmp(x::BigInterval, y::CdoubleMax)
    isnan(x) && return isnan(y) ? 0 : 1
    isnan(y) && return -1
    ccall((:mpfi_cmp_d_default, libmpfi), Int32, (Ref{BigInterval}, Cdouble), x, y)
end
cmp(x::CdoubleMax, y::BigInterval) = -cmp(y,x)

function cmp(x::BigInterval, y::BigFloat)
    isnan(x) && return isnan(y) ? 0 : 1
    isnan(y) && return -1
    ccall((:mpfi_cmp_fr_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigFloat}), x, y)
end
cmp(x::BigFloat, y::BigInterval) = -cmp(y,x)




#  ---------------------------------------------  Flags  ------------------------------------------------

function isbounded(x::BigInterval)
    return ccall((:mpfi_bounded_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

function isempty(x::BigInterval)
    return ccall((:mpfi_is_empty, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

function isnan(x::BigInterval)
    return ccall((:mpfi_nan_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

function isinf(x::BigInterval)
    return ccall((:mpfi_inf_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end


iszero(x::BigInterval) = left(x)==0 && right(x)==0

function has_zero(x::BigInterval)
    return ccall((:mpfi_has_zero, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

function sign(x::BigInterval)
    c = cmp(x, 0)
    (c == 0 || isnan(x)) && return x
    return c < 0 ? -one(x) : one(x)
end



# -------------------------------------  Set operations  ---------------------------------------


function is_inside(x::BigInterval, int::BigInterval)
    return ccall((:mpfi_is_inside, :libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, int) > 0
end


for (fJ, fC) in ((:si,:Clong), (:ui,:Culong), (:d,:Cdouble))
    @eval begin
        function is_inside(x::($fC), int::BigInterval)
            return ccall(($(string(:mpfi_is_inside_,fJ)), libmpfi), Int32, (($fC), Ref{BigInterval}), x, int) > 0
        end
    end
end

for (fJ, fC) in ((:z,:BigInt), (:fr,:BigFloat))
    @eval begin
        function is_inside(x::($fC), int::BigInterval)
            return ccall(($(string(:mpfi_is_inside_,fJ)), libmpfi), Int32, (Ref{($fC)}, Ref{BigInterval}), x, int) > 0
        end
    end
end


for f in (:intersect, :union)
    @eval begin 
        function $f(x::BigInterval, y::BigInterval;precision::Integer=DEFAULT_PRECISION())
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_,f)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, x, y) 
            return z
        end
    end
end

function bisect(x::BigInterval;precision::Integer=DEFAULT_PRECISION())
    z1, z2 = BigInterval(;precision=precision), BigInterval(;precision=precision)
    ccall((:mpfi_bisect, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z1, z2, x)
    return z1, z2
end

function blow(x::BigInterval, y::Float64;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_blow, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Cdouble), z, x, y)
    return z
end






#  --------------------------------  Printing  -------------------------------------



function string(x::BigInterval)
    # The contents of x are passed in a BigFloat
    # BigFloat._d is not set but there is no need 
    # The memory @ d is managed by MPFI

    if isnan(x)
        return "[NaN, NaN]"
    else

        left = BigFloat()
        left.prec = x.left_prec
        left.sign = x.left_sign
        left.exp = x.left_exp
        left.d = x.left_d

        right = BigFloat()
        right.prec = x.right_prec
        right.sign = x.right_sign
        right.exp = x.right_exp
        right.d = x.right_d
        #return "[$(string(left)), $(string(right))]"
        return "[$(MPFR._prettify_bigfloat(MPFR.string_mpfr(left, "%RDe"))), $(MPFR._prettify_bigfloat(MPFR.string_mpfr(right, "%RUe")))]"
    end

end

function string(x::BigInterval, k::Integer)
    # The contents of x are passed in a BigFloat
    # BigFloat._d is not set but there is no need 
    # The memory @ d is managed by MPFI

    if isnan(x)
        return "[NaN, NaN]" #"[$(string(Float64(left(x)))), $(string(Float64(right(x))))]"
    else
        left = BigFloat()
        left.prec = x.left_prec
        left.sign = x.left_sign
        left.exp = x.left_exp
        left.d = x.left_d

        right = BigFloat()
        right.prec = x.right_prec
        right.sign = x.right_sign
        right.exp = x.right_exp
        right.d = x.right_d

        #return "[$(_string(left, k)), $(_string(right, k))]"
        return "[$(MPFR._prettify_bigfloat(MPFR.string_mpfr(left, "%.$(k)RDe"))), $(MPFR._prettify_bigfloat(MPFR.string_mpfr(right, "%.$(k)RUe")))]"
    end
end

function _string(x::BigInterval, k::Integer)
   string(x,k)
end

print(io::IO, b::BigInterval) = print(io, string(b))


function show(io::IO, b::BigInterval)
    if get(io, :compact, false)
        print(io, _string(b, 5))
    else
        print(io, string(b))
    end
end



function _import_from_ptr(x::Ptr{Cvoid};precision=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_set, libmpfi), Int32, (Ref{BigInterval}, Ptr{Cvoid}), z, x)
    return z
end

function _print_mem_funcs()
    ccall((:__gmp_get_memory_functions, libmpfi), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), C_NULL, C_NULL,C_NULL)
end



function midpoints(x::Vector{Vector{BigInterval}})::Vector{Vector{BigFloat}}
    return [[(left(x[i][j])+right(x[i][j]))/2 for j in 1:length(x[i])] for i in 1:length(x)]
end

function midpoints(x::Vector{BigInterval})::Vector{BigFloat}
    return [(left(x[i])+right(x[i]))/2 for i in 1:length(x)]
end

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) MPFI

end

# ---------  TO BE WRAPPED 

#=
/* swapping two intervals */
void    mpfi_swap (mpfi_ptr, mpfi_ptr);



/* picks randomly a point m in y */
void    mpfi_alea       (mpfr_ptr, mpfi_srcptr);
void    mpfi_urandom    (mpfr_ptr, mpfi_srcptr, gmp_randstate_t);
void    mpfi_nrandom    (mpfr_ptr, mpfi_srcptr, gmp_randstate_t);
void    mpfi_erandom    (mpfr_ptr, mpfi_srcptr, gmp_randstate_t);



/* Basic arithmetic operations                  */


/* arithmetic operations between an interval operand and a multiple prec. rational */
int     mpfi_add_q      (mpfi_ptr, mpfi_srcptr, mpq_srcptr);
int     mpfi_sub_q      (mpfi_ptr, mpfi_srcptr, mpq_srcptr);
int     mpfi_q_sub      (mpfi_ptr, mpq_srcptr, mpfi_srcptr);
int     mpfi_mul_q      (mpfi_ptr, mpfi_srcptr, mpq_srcptr);
int     mpfi_div_q      (mpfi_ptr, mpfi_srcptr, mpq_srcptr);
int     mpfi_q_div      (mpfi_ptr, mpq_srcptr, mpfi_srcptr);



/* extended division: returns 2 intervals if the denominator contains 0 */
int	mpfi_div_ext	(mpfi_ptr, mpfi_ptr, mpfi_srcptr, mpfi_srcptr);

/* various operations */
int     mpfi_mul_2exp   (mpfi_ptr, mpfi_srcptr, unsigned long);
int     mpfi_mul_2ui    (mpfi_ptr, mpfi_srcptr, unsigned long);
int     mpfi_mul_2si    (mpfi_ptr, mpfi_srcptr, long);
int     mpfi_div_2exp   (mpfi_ptr, mpfi_srcptr, unsigned long);
int     mpfi_div_2ui    (mpfi_ptr, mpfi_srcptr, unsigned long);
int     mpfi_div_2si    (mpfi_ptr, mpfi_srcptr, long);

=#