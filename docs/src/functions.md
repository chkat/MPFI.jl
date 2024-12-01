
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

- [`Base.isempty`](https://docs.julialang.org/en/v1/base/collections/#Base.isempty): The `isempty` function is extended to check if a given `BigInterval` is empty.
- [`Base.isnan`](https://docs.julialang.org/en/v1/base/numbers/#Base.isnan)
- [`Base.isinf`](https://docs.julialang.org/en/v1/base/numbers/#Base.isinf) Checks if a given `BigInterval` contains infinite values.
- [`Base.iszero`](https://docs.julialang.org/en/v1/base/numbers/#Base.iszero) Checks if a given `BigInterval` is zero, i.e., both the lower and upper bounds are zero.

