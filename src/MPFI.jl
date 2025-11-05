module MPFI

export BigInterval, precision, left, right, has_zero, isbounded, intersect, union, is_inside, bisect, blow, diam_abs, diam_rel, diam, mag, mig, mid, square


import Base: +, -, *, /, ==, <, >, <=, >=, string, print, show, isnan, isfinite, isinf, MPFR._string, MPFR, exp, exp2, 
    exp10, expm1, cosh, sinh, tanh, sech, csch, coth, inv, sqrt, cbrt, abs, log, log2, log10, log1p,
    sin, cos, tan, sec, ldexp, precision, csc, cot, acos, asin, atan, acosh, asinh, atanh, hypot,
    convert, sum, iszero, zero, one, sign, cmp, setprecision, promote_rule, isempty, isinf, deepcopy_internal,
    BigFloat, BigInt, Float64, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, BigInt, Float32, 
    real, imag, conj, isless

import Base.GMP: ClongMax, CulongMax, CdoubleMax

using DocStringExtensions


using MPFI_jll: libmpfi

"""
    BigInterval <: Number

An arbitrary-precision interval floating-point number type, wrapping the C `MPFI` library.
Use this type to perform operations with intervals that represent ranges of numbers rather than single values.

# Structure

Internally, `BigInterval` corresponds to the following C structure in `MPFI`:

```c
typedef struct {
    __mpfr_struct left;
    __mpfr_struct right;
} __mpfi_struct;
```
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
    # Memory here is managed by libmpfi
end

 """
    BigInterval(; precision=DEFAULT_PRECISION())

Creates a new `BigInterval` with the specified precision. The precision must be an integer greater than or equal to 1.

# Arguments
- `precision::Integer`: The precision (in bits) for the interval. Defaults to `DEFAULT_PRECISION()`.

# Throws
- `DomainError`: If `precision` is less than 1.

# Example
```julia
julia> x = BigInterval(;precision=128)
[NaN, NaN]

julia> precision(x)
128
```
"""
function BigInterval(; precision::Integer=DEFAULT_PRECISION())
    precision < 1 && throw(DomainError(precision, "`precision` cannot be less than 1."))
    z = BigInterval(zero(Clong), zero(Cint), zero(Clong), C_NULL,
        zero(Clong), zero(Cint), zero(Clong), C_NULL)
    ccall((:mpfi_init2, libmpfi), Cvoid, (Ref{BigInterval}, Clong), Ref(z), precision)
    finalizer(mpfi_clear, z)
    return z
end

DEFAULT_PRECISION() = precision(BigFloat)

mpfi_clear(x::BigInterval) = ccall((:mpfi_clear, libmpfi), Cvoid, (Ref{BigInterval},), Ref(x))

zero(::Type{BigInterval}) = BigInterval(0)
one(::Type{BigInterval}) = BigInterval(1)


#  --------------------------------  Basic access functions  -------------------------------------



"""
    precision(x::BigInterval) -> Clong

Returns the precision of the `BigInterval` `x`.

# Arguments
- `x::BigInterval`: The interval whose precision is to be retrieved.

# Returns
- `Clong`: The precision (in bits) of the interval.

# Example
```julia
julia> x = BigInterval(; precision=128)
[NaN, NaN]

julia> precision(x)
128
```
""" 
function precision(x::BigInterval)
    return ccall((:mpfi_get_prec, libmpfi), Clong, (Ref{BigInterval},), x)
end

"""
    left(x::BigInterval) -> BigFloat

Returns the left bound of the interval as a `BigFloat`.

# Arguments
- `x::BigInterval`: The interval whose left bound is to be retrieved.

# Returns
- `BigFloat`: The left bound of the interval.
"""
function left(x::BigInterval)
    z = BigFloat(;precision=precision(x))
    ccall((:mpfi_get_left, libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
    return z
end


"""
    right(x::BigInterval) -> BigFloat

Returns the right bound of the interval as a `BigFloat`.

# Arguments
- `x::BigInterval`: The interval whose right bound is to be retrieved.

# Returns
- `BigFloat`: The right bound of the interval.
"""
function right(x::BigInterval)
    z = BigFloat(;precision=precision(x))
    ccall((:mpfi_get_right, libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
    return z
end


"""
    sign(x::BigInterval) -> BigInterval

Returns the sign of the `BigInterval` `x`, extending the behavior of [`Base.sign`](@ref) for intervals.

# Behavior
- Conforms to the definition of [`Base.sign`](@ref), where `sign(x)` returns `0` if `x == 0` and `x / |x|` otherwise (i.e., ±1 for real numbers).
- For intervals:
  - If `x` contains `0` or is `NaN`, returns `x`.
  - If `x` is entirely positive, returns `BigInterval(1)=[1.0, 1.0]`.
  - If `x` is entirely negative, returns `BigInterval(-1)=[-1.0, -1.0]`.

  # Arguments
- `x::BigInterval`: The interval whose sign is to be determined.

# Returns
- `BigInterval`: The "sign" of the interval.
"""
function sign(x::BigInterval)
    c = cmp(x, 0)
    (c == 0 || isnan(x)) && return x
    return c < 0 ? -one(x) : one(x)
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

Base.BigFloat(x::BigInterval) = convert(BigFloat, x)
Base.BigInt(x::BigInterval) = convert(BigInt, x)
Base.Float64(x::BigInterval) = convert(Float64, x)
Base.Float32(x::BigInterval) = convert(Float32, x)
Base.Int8(x::BigInterval) = convert(Int8, x)
Base.Int16(x::BigInterval) = convert(Int16, x)
Base.Int32(x::BigInterval) = convert(Int32, x)
Base.Int64(x::BigInterval) = convert(Int64, x)
Base.UInt8(x::BigInterval) = convert(UInt8, x)
Base.UInt16(x::BigInterval) = convert(UInt16, x)
Base.UInt32(x::BigInterval) = convert(UInt32, x)
Base.UInt64(x::BigInterval) = convert(UInt64, x)

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
function BigInterval(x::BigInt;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_set_z, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInt}), Ref(z), Ref(x))
    return z
end
# Dyadic constructors
function BigInterval(x::BigInt, y::BigInt;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_interv_z, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInt}, Ref{BigInt}), Ref(z), Ref(x), Ref(y))
    return z
end

function BigInterval(x::BigFloat;precision::Integer=precision(x))
    z = BigInterval(;precision=precision)
    ccall((:mpfi_set_fr, libmpfi), Int32, (Ref{BigInterval}, Ref{BigFloat}), Ref(z), Ref(x))
    return z
end
# Dyadic constructors
function BigInterval(x::BigFloat, y::BigFloat;precision::Integer=precision(x))
    z = BigInterval(;precision=precision)
    ccall((:mpfi_interv_fr, libmpfi), Int32, (Ref{BigInterval}, Ref{BigFloat}, Ref{BigFloat}), Ref(z), Ref(x), Ref(y))
    return z
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

function -(x::BigInterval)
    z = BigInterval(;precision=MPFI.precision(x))
    ccall((:mpfi_neg, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
    return z
end

function square(x::BigInterval; precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_sqr, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), z, x)
    return z
end

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


BigInterval(x::Irrational;precision::Integer=DEFAULT_PRECISION()) = convert(BigInterval,x;precision=precision)


function convert(::Type{BigInterval}, ::Irrational{:π};precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_const_pi,libmpfi), Cint, (Ref{BigInterval},), z)
    return z
end

function convert(::Type{BigInterval}, ::Irrational{:ℯ};precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_exp,libmpfi), Cint, (Ref{BigInterval},Ref{BigInterval}), z, BigInterval(1))
    return z
end

function convert(::Type{BigInterval}, ::Irrational{:γ};precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_const_euler,libmpfi), Cint, (Ref{BigInterval},), z)
    return z
end



# --------------------------------  Various useful interval functions  -------------------------------------

"""
    mid(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Computes the midpoint of the given `BigInterval`.

# Arguments
- `x::BigInterval`: The interval for which the midpoint is calculated.

# Returns
- `BigFloat`: The midpoint of the interval, calculated as `(left(x) + right(x)) / 2`.
"""
function mid end

"""
    diam_abs(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Returns the absolute diameter of the interval `x` as a `BigFloat`. The diameter represents the distance between the left and right bounds of the interval.

# Arguments
- `x::BigInterval`: The input interval.
- `precision::Integer`: The precision in bits to use for the result. Defaults to `DEFAULT_PRECISION()`.
"""
function diam_abs end

"""
    diam_rel(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Returns the relative diameter of the interval `x` as a `BigFloat`. The relative diameter is calculated as the absolute diameter of the interval divided by the midpoint of the interval.

# Arguments
- `x::BigInterval`: The input interval for which the relative diameter is computed.
- `precision::Integer`: The precision in bits to use for the result. Defaults to `DEFAULT_PRECISION()`.

# Returns
A `BigFloat` representing the relative diameter of the interval.
""" 
function diam_rel end

"""
    diam(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Returns the diameter of the interval `x` as a `BigFloat`. The diameter of the interval is the difference between the right and left bounds of the interval.

# Arguments
- `x::BigInterval`: The input interval for which the diameter is computed.
- `precision::Integer`: The precision in bits to use for the result. Defaults to `DEFAULT_PRECISION()`.

# Returns
A `BigFloat` representing the diameter of the interval.
""" 
function diam end

"""
    mag(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Returns the magnitude of the interval `x` as a `BigFloat`. The magnitude is the maximum of the absolute values of the left and right bounds of the interval.

# Arguments
- `x::BigInterval`: The input interval for which the magnitude is computed.
- `precision::Integer`: The precision in bits to use for the result. Defaults to `DEFAULT_PRECISION()`.

# Returns
A `BigFloat` representing the magnitude of the interval.
"""
function mag end

"""
    mig(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigFloat

Returns the Mignitude of the interval `x`. Mignitude is defined as the smallest absolute value of any element within the interval.

# Arguments
- `x::BigInterval`: The input interval for which the Mignitude is computed.
- `precision::Integer`: The precision in bits to use for the result. Defaults to `DEFAULT_PRECISION()`.

# Returns
A `BigFloat` representing the Mignitude (smallest absolute value) of the interval.

""" 
function mig end

for f in (:diam_abs, :diam_rel, :diam, :mag, :mig, :mid)
    @eval function $(f)(x::BigInterval;precision::Integer=MPFI.precision(x))
        z = BigFloat(;precision=precision)
        ccall(($(string(:mpfi_,f)), libmpfi), Int32, (Ref{BigFloat}, Ref{BigInterval}), z, x)
        return z
    end
end

function ldexp(x::BigInterval, n::Clong;precision::Integer=MPFI.precision(x))
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

function hypot(x::BigInterval, y::BigInterval;precision::Integer=MPFI.precision(x))
    z = BigInterval(;precision=precision)
    ccall((:mpfi_hypot, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, x, y)
    return z
end



#  --------------------------------  Comparison functions and operators  -------------------------------------

# checks if there is intersection 
# when x == 0 it works as has_zero left(x)==left(y) && right(x)==right(y) #
==(x::BigInterval, y::BigInterval) = left(x)==left(y) && right(x)==right(y) 
<=(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) != 1
>=(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) !=-1
<(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) == -1
>(x::BigInterval, y::BigInterval) = ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y) == 1

function cmp(x::BigInterval, y:: BigInterval)
    ccall((:mpfi_cmp_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, y)
end

function cmp(x::BigInterval, y::BigInt)
    isnan(x) && return 1
    ccall((:mpfi_cmp_z_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInt}), x, y)
end
cmp(y::BigInt, x::BigInterval) = -cmp(x,y)
==(x::BigInterval, y::BigInt) = cmp(x,y) == 0 
<=(x::BigInterval, y::BigInt) = cmp(x,y) != 1 
>=(x::BigInterval, y::BigInt) = cmp(x,y) != -1
<(x::BigInterval, y::BigInt) = cmp(x,y) == -1
>(x::BigInterval, y::BigInt) = cmp(x,y) == 1

function cmp(x::BigInterval, y::ClongMax)
    isnan(x) && return 1
    ccall((:mpfi_cmp_si_default, libmpfi), Int32, (Ref{BigInterval}, Clong), x, y)
end
cmp(y::ClongMax, x::BigInterval) = -cmp(x,y)
==(x::BigInterval, y::ClongMax) = cmp(x,y) == 0 
<=(x::BigInterval, y::ClongMax) = cmp(x,y) != 1 
>=(x::BigInterval, y::ClongMax) = cmp(x,y) != -1
<(x::BigInterval, y::ClongMax) = cmp(x,y) == -1
>(x::BigInterval, y::ClongMax) = cmp(x,y) == 1

function cmp(x::BigInterval, y::CulongMax)
    isnan(x) && return 1
    ccall((:mpfi_cmp_ui_default, libmpfi), Int32, (Ref{BigInterval}, Culong), x, y)
end
cmp(y::CulongMax, x::BigInterval) = -cmp(x,y)
==(x::BigInterval, y::CulongMax) = cmp(x,y) == 0 
<=(x::BigInterval, y::CulongMax) = cmp(x,y) != 1 
>=(x::BigInterval, y::CulongMax) = cmp(x,y) != -1
<(x::BigInterval, y::CulongMax) = cmp(x,y) == -1
>(x::BigInterval, y::CulongMax) = cmp(x,y) == 1

cmp(x::BigInterval, y::Integer) = cmp(x,big(y))
cmp(x::Integer, y::BigInterval) = -cmp(y,x)

function cmp(x::BigInterval, y::CdoubleMax)
    isnan(x) && return isnan(y) ? 0 : 1
    isnan(y) && return -1
    ccall((:mpfi_cmp_d_default, libmpfi), Int32, (Ref{BigInterval}, Cdouble), x, y)
end
cmp(y::CdoubleMax, x::BigInterval) = -cmp(x,y)
==(x::BigInterval, y::CdoubleMax) = cmp(x,y) == 0 
<=(x::BigInterval, y::CdoubleMax) = cmp(x,y) != 1 
>=(x::BigInterval, y::CdoubleMax) = cmp(x,y) != -1
<(x::BigInterval, y::CdoubleMax) = cmp(x,y) == -1
>(x::BigInterval, y::CdoubleMax) = cmp(x,y) == 1

function cmp(x::BigInterval, y::BigFloat)
    isnan(x) && return isnan(y) ? 0 : 1
    isnan(y) && return -1
    ccall((:mpfi_cmp_fr_default, libmpfi), Int32, (Ref{BigInterval}, Ref{BigFloat}), x, y)
end
cmp(x::BigFloat, y::BigInterval) = -cmp(y,x)
==(x::BigInterval, y::BigFloat) = cmp(x,y) == 0 
<=(x::BigInterval, y::BigFloat) = cmp(x,y) != 1 
>=(x::BigInterval, y::BigFloat) = cmp(x,y) != -1
<(x::BigInterval, y::BigFloat) = cmp(x,y) == -1
>(x::BigInterval, y::BigFloat) = cmp(x,y) == 1




#  ----------------------------------------  Boolean functions  ------------------------------------------

"""
    isbounded(x::BigInterval) -> Bool

Checks if the interval `x` is bounded, meaning it has finite lower and upper bounds.

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` is bounded, `false` otherwise.
"""
function isbounded(x::BigInterval)
    return ccall((:mpfi_bounded_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

"""
    isempty(x::BigInterval) -> Bool

Checks if the interval `x` is empty, meaning that no values have been assigned to its endpoints.
Identical to isnan(x::BigInterval).

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` is empty, `false` otherwise.

# Extends
[`Base.isempty`](@ref)
"""
function isempty(x::BigInterval)
    return ccall((:mpfi_is_empty, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

"""
    isnan(x::BigInterval) -> Bool

Checks if the interval `x` is NaN (Not a Number).

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` is NaN, `false` otherwise.

# Extends
[`Base.isnan`](@ref)
"""
function isnan(x::BigInterval)
    return ccall((:mpfi_nan_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

function isfinite(x::BigInterval)
    return !isnan(x) && !isinf(x)
end

"""
    isinf(x::BigInterval) -> Bool

Checks if the interval `x` contains infinite values.

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` contains infinite values, `false` otherwise.

# Extends
[`Base.isinf`](@ref)
"""
function isinf(x::BigInterval)
    return ccall((:mpfi_inf_p, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

"""
    iszero(x::BigInterval) -> Bool

Checks if the interval `x` is zero, i.e., both the lower and upper bounds are zero.

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` is zero, `false` otherwise.

# Extends
[`Base.iszero`](@ref)
"""
iszero(x::BigInterval) = left(x)==0 && right(x)==0

"""
    has_zero(x::BigInterval) -> Bool

Checks if the interval `x` contains zero, i.e., the interval includes zero within its bounds.

# Arguments
- `x::BigInterval`: The interval to check.

# Returns
- `Bool`: `true` if `x` contains zero, `false` otherwise.
"""
function has_zero(x::BigInterval)
    return ccall((:mpfi_has_zero, libmpfi), Int32, (Ref{BigInterval},), x) != 0
end

"""
    is_inside(x::BigInterval, int::BigInterval) -> Bool

Checks if the interval `x` is entirely contained within the interval `int`.

# Arguments
- `x::BigInterval`: The interval to test for containment.
- `int::BigInterval`: The interval to check containment in.

# Returns
- `Bool`: `true` if `x` is contained in `int`, otherwise `false`.
"""
function is_inside(x::BigInterval, int::BigInterval)
    return ccall((:mpfi_is_inside, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}), x, int) > 0
end


"""
    is_inside(x::T, int::BigInterval) where T <: Union{Clong, Culong, Cdouble, BigInt, BigFloat}

Checks if the scalar `x` is within the interval `int`.

# Arguments
- `x::T`: A scalar of type `Clong`, `Culong`, `Cdouble`, `BigInt`, or `BigFloat`.
- `int::BigInterval`: The interval to test against.

# Returns
- `Bool`: `true` if `x` is inside `int`, otherwise `false`.
"""
function is_inside end  # Attach the docstring to the generic function

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




# -------------------------------------  Set operations  ---------------------------------------


"""
    intersect(x::BigInterval, y::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> BigInterval

Computes the intersection of two intervals `x` and `y`. When intersection is an empty set, the output interval will have its left bound larger than the right one.

# Arguments
- `x::BigInterval`: The first interval.
- `y::BigInterval`: The second interval.
- `precision::Integer` (optional): The precision of the resulting interval. Defaults to `DEFAULT_PRECISION()`.

# Returns
- `BigInterval`: The intersection of `x` and `y`. If the intervals do not intersect, the result is an empty interval.
"""
function intersect end # Attach the docstring 

"""
    union(x::BigInterval, y::BigInterval) -> BigInterval

Returns the convex hull of the union of two intervals `x` and `y`. This is the smallest interval that contains all the values in both `x` and `y`, ensuring there is no gap between them.

# Arguments
- `x::BigInterval`: The first interval.
- `y::BigInterval`: The second interval.
- `precision::Integer` (optional): The precision of the resulting interval. Defaults to `DEFAULT_PRECISION()`.

# Returns
- `BigInterval`: The union of `x` and `y`.
"""
function union end # Attach the docstring 


for f in (:intersect, :union)
    @eval begin 
        function $f(x::BigInterval, y::BigInterval;precision::Integer=max(MPFI.precision(x), MPFI.precision(y)))
            z = BigInterval(;precision=precision)
            ccall(($(string(:mpfi_,f)), libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z, x, y) 
            return z
        end
    end
end

"""
    bisect(x::BigInterval; precision::Integer=DEFAULT_PRECISION()) -> Tuple{BigInterval, BigInterval}

Bisects the interval `x` into two subintervals of approximately equal width.

# Arguments
- `x::BigInterval`: The interval to bisect.
- `precision::Integer` (optional): The precision of the resulting subintervals. Defaults to `DEFAULT_PRECISION()`.

# Returns
- `Tuple{BigInterval, BigInterval}`: Two subintervals that partition the input interval.
"""
function bisect(x::BigInterval;precision::Integer=DEFAULT_PRECISION())
    z1, z2 = BigInterval(;precision=precision), BigInterval(;precision=precision)
    ccall((:mpfi_bisect, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Ref{BigInterval}), z1, z2, x)
    return z1, z2
end

"""
    blow(x::BigInterval, y::Float64; precision::Integer=DEFAULT_PRECISION()) -> BigInterval

Creates a new interval by expanding the radius of the input interval `x` by a factor of `(1 + y)`, while keeping its center unchanged. 

**Note:** The resulting interval may be overestimated.

# Arguments
- `x::BigInterval`: The input interval to expand. 
- `y::Float64`: The factor to expand the radius by, added as `(1 + y)`.
- `precision::Integer`: (Optional) The precision for the resulting interval. Defaults to `DEFAULT_PRECISION()`.

# Returns
- `BigInterval`: A new interval with the expanded radius.
"""
function blow(x::BigInterval, y::Float64;precision::Integer=DEFAULT_PRECISION())
    z = BigInterval(;precision=precision)
    ccall((:mpfi_blow, libmpfi), Int32, (Ref{BigInterval}, Ref{BigInterval}, Cdouble), z, x, y)
    return z
end


#  --------------------------------  Printing  -------------------------------------



function string(x::BigInterval)
    # The contents of x are passed in a BigFloat
    # BigFloat._d is not set but there is no need 
    # The memory @ d is managed by GMP

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
        return "[$(string(left)), $(string(right))]"
        #return "[$(MPFR._prettify_bigfloat(MPFR.string_mpfr(left, "%RDe"))), $(MPFR._prettify_bigfloat(MPFR.string_mpfr(right, "%RUe")))]"
    end

end

function string(x::BigInterval, k::Integer)
    # The contents of x are passed in a BigFloat
    # BigFloat._d is not set but there is no need 
    # The memory @ d is managed by GMP

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


#  ---------------------------  Additional functions  --------------------------------

"""
    _import_from_ptr(x::Ptr{Cvoid}; precision=DEFAULT_PRECISION()) -> BigInterval

Imports a `BigInterval` from a raw pointer to the MPFI structure. The precision of the 
resulting `BigInterval` can be specified.

# Arguments
- `x::Ptr{Cvoid}`: A C-pointer to the MPFI structure.
- `precision::Integer`: The precision (in bits) for the resulting `BigInterval`. Defaults to `DEFAULT_PRECISION()`.

# Returns
- `BigInterval`: The interval corresponding to the imported MPFI structure.

# Notes
This is a low-level function designed for internal use. Direct usage in applications is 
not recommended unless you are handling MPFI pointers explicitly.
"""
function _import_from_ptr(x::Ptr{Cvoid};precision=precision(x))
    z = BigInterval(;precision=precision)
    ccall((:mpfi_set, libmpfi), Int32, (Ref{BigInterval}, Ptr{Cvoid}), z, x)
    return z
end

function precision(x::Ptr{Cvoid})
    return ccall((:mpfi_get_prec, libmpfi), Clong, (Ptr{Cvoid},), x)
end


@doc read(joinpath(dirname(@__DIR__), "README.md"), String) MPFI

#  --------------------------------  Complex number functions  -------------------------------------

"""
    real(x::BigInterval) -> BigInterval

Returns the real part of the interval `x`. Since `BigInterval` represents real intervals,
this function simply returns the interval itself.

# Arguments
- `x::BigInterval`: The input interval.

# Returns
- `BigInterval`: The interval itself, as it represents a real number.

# Examples
```julia
julia> x = BigInterval(1, 2)
[1.0, 2.0]

julia> real(x)
[1.0, 2.0]
```
"""
real(x::BigInterval) = x

"""
    imag(x::BigInterval) -> BigInterval

Returns the imaginary part of the interval `x`. Since `BigInterval` represents real intervals,
this function always returns zero.

# Arguments
- `x::BigInterval`: The input interval.

# Returns
- `BigInterval`: A zero interval, as real intervals have no imaginary component.

# Examples
```julia
julia> x = BigInterval(1, 2)
[1.0, 2.0]

julia> imag(x)
[0.0, -0.0]
```
"""
imag(x::BigInterval) = zero(x)

"""
    conj(x::BigInterval) -> BigInterval

Returns the complex conjugate of the interval `x`. Since `BigInterval` represents real intervals,
the complex conjugate is the interval itself.

# Arguments
- `x::BigInterval`: The input interval.

# Returns
- `BigInterval`: The interval itself, as the complex conjugate of a real number is the number itself.

# Examples
```julia
julia> x = BigInterval(1, 2)
[1.0, 2.0]

julia> conj(x)
[1.0, 2.0]
```
"""
conj(x::BigInterval) = x

isless(x::BigInterval, y::BigInterval) = left(x) < left(y) || (left(x) == left(y) && right(x) < right(y))

end

