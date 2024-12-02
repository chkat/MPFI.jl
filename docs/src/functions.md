
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
MPFI.bisect
MPFI.blow
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

# Other functions:

```@docs
MPFI.midpoint
``` 