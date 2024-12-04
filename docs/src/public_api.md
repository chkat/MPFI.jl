
# BigInterval

```@docs
MPFI.BigInterval
```  
```@docs
MPFI.left
MPFI.right
```
# Constructors
```@docs
MPFI.BigInterval(;precision::Integer=DEFAULT_PRECISION())
``` 


# Boolean functions

```@docs
MPFI.isbounded
MPFI.has_zero
MPFI.is_inside(::BigInterval, ::BigInterval)
MPFI.is_inside
``` 


# Set Operations

```@docs
MPFI.intersect
MPFI.union
``` 

!!! warning
    The functions `union` and `intersection` provided in this package do **not** extend the `Base.union` and `Base.intersect` functions. Instead, they are specifically implemented for use with `MPFI`. Ensure you use the `MPFI` module's versions when working with intervals.

```@docs
MPFI.bisect
MPFI.blow
MPFI.diam_abs
MPFI.diam_rel
MPFI.diam
MPFI.mag
MPFI.mig
MPFI.mid
``` 

# Extensions of `Base` Functions

In this section, we list the extensions made to `Base` functions to handle the custom type `BigInterval`.

- [`Base.sign`](https://docs.julialang.org/en/v1/base/math/#Base.sign): Conforms to the definition of `Base.sign`, where `sign(x)` returns `0` if `x == 0` and `x / |x|` otherwise (i.e., ±1 for real numbers).
    - For intervals:
        - If `x` contains `0` or is `NaN`, returns `x`.
        - If `x` is entirely positive, returns `BigInterval(1)=[1.0, 1.0]`.
        - If `x` is entirely negative, returns `BigInterval(-1)=[-1.0, -1.0]`.

!!! warning
    While this function provides a generic interval-based sign definition, it is **strongly recommended** to define a custom `sign` function tailored to the specific needs of your application. The general approach may not be suitable for certain contexts.
- [`Base.precision`](https://docs.julialang.org/en/v1/base/numbers/#Base.precision)
- [`Base.isempty`](https://docs.julialang.org/en/v1/base/collections/#Base.isempty): The `isempty` function is extended to check if a given `BigInterval` is empty.
- [`Base.isnan`](https://docs.julialang.org/en/v1/base/numbers/#Base.isnan)
- [`Base.isinf`](https://docs.julialang.org/en/v1/base/numbers/#Base.isinf) Checks if a given `BigInterval` contains infinite values.
- [`Base.iszero`](https://docs.julialang.org/en/v1/base/numbers/#Base.iszero) Checks if a given `BigInterval` is zero, i.e., both the lower and upper bounds are zero.
- [`Base.exp`](https://docs.julialang.org/en/v1/base/math/#Base.exp-Tuple{Float64})
- [`Base.exp2`](https://docs.julialang.org/en/v1/base/math/#Base.exp2)
- [`Base.exp10`](https://docs.julialang.org/en/v1/base/math/#Base.exp10)
- [`Base.expm1`](https://docs.julialang.org/en/v1/base/math/#Base.expm1)
- [`Base.cosh`](https://docs.julialang.org/en/v1/base/math/#Base.cosh-Tuple{Number})
- [`Base.sinh`](https://docs.julialang.org/en/v1/base/math/#Base.sinh-Tuple{Number})
- [`Base.tanh`](https://docs.julialang.org/en/v1/base/math/#Base.tanh-Tuple{Number})
- [`Base.Math.sech`](https://docs.julialang.org/en/v1/base/math/#Base.Math.sech-Tuple%7BNumber%7D)
- [`Base.Math.csch`](https://docs.julialang.org/en/v1/base/math/#Base.Math.csch-Tuple{Number})
- [`Base.coth`](https://docs.julialang.org/en/v1/base/math/#Base.coth)
- [`Base.inv`](https://docs.julialang.org/en/v1/base/math/#Base.inv)
- [`Base.sqrt`](https://docs.julialang.org/en/v1/base/math/#Base.sqrt)
- [`Base.cbrt`](https://docs.julialang.org/en/v1/base/math/#Base.cbrt)
- [`Base.abs`](https://docs.julialang.org/en/v1/base/math/#Base.abs)
- [`Base.log`](https://docs.julialang.org/en/v1/base/math/#Base.log)
- [`Base.log2`](https://docs.julialang.org/en/v1/base/math/#Base.log2)
- [`Base.log10`](https://docs.julialang.org/en/v1/base/math/#Base.log10)
- [`Base.log1p`](https://docs.julialang.org/en/v1/base/math/#Base.log1p)
- [`Base.sin`](https://docs.julialang.org/en/v1/base/math/#Base.sin)
- [`Base.cos`](https://docs.julialang.org/en/v1/base/math/#Base.cos)
- [`Base.tan`](https://docs.julialang.org/en/v1/base/math/#Base.tan)
- [`Base.sec`](https://docs.julialang.org/en/v1/base/math/#Base.sec)
- [`Base.csc`](https://docs.julialang.org/en/v1/base/math/#Base.csc)
- [`Base.cot`](https://docs.julialang.org/en/v1/base/math/#Base.cot)
- [`Base.acos`](https://docs.julialang.org/en/v1/base/math/#Base.acos)
- [`Base.asin`](https://docs.julialang.org/en/v1/base/math/#Base.asin)
- [`Base.atan`](https://docs.julialang.org/en/v1/base/math/#Base.atan-Tuple{Number})
- [`Base.acosh`](https://docs.julialang.org/en/v1/base/math/#Base.acosh-Tuple{Number})
- [`Base.asinh`](https://docs.julialang.org/en/v1/base/math/#Base.asinh-Tuple{Number})
- [`Base.atanh`](https://docs.julialang.org/en/v1/base/math/#Base.atanh-Tuple{Number})
- [`Base.Math.hypot`](https://docs.julialang.org/en/v1/base/math/#Base.Math.hypot)
- [`Base.Math.ldexp`](https://docs.julialang.org/en/v1/base/math/#Base.Math.ldexp)

