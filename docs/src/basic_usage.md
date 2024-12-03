# Basic Usage


The type `BigInterval` represents an arbitrary precision interval floating point number.
It corresponds to the C-type `mpfi_t`.

## Constructors
You can create intervals using various constructors. The precision is by default equal to `precision(BigFloat)`.
Here are some examples:



```julia-repl
julia> a = BigInterval("1.0")
[1.0, 1.0]

julia> b = BigInterval(1.0)
[1.0, 1.0]

julia> c = BigInterval(1, 2)
[1.0, 2.0]

julia> d = BigInterval(BigFloat(1.0), BigFloat(2.0))
[1.0, 2.0]

julia> zero(BigInterval)
[0.0, -0.0]

julia> one(BigInterval)
[1.0, 1.0]
```
   
Alternatively, you can use an optional argument to set a specific bit-precision in all the constructor functions. Then, precision can be accessed with the `precision` function:


```julia-repl
julia> x = BigInterval(1//3;precision=23) # "1//3" is Rational
[0.33333331, 0.33333338]

julia> precision(x)
23

julia> y = BigInterval(1/3;precision=128) # "1/3" is a Float64
[0.3333333333333333148296162562473909929394, 0.3333333333333333148296162562473909929395]

julia> precision(y)
128

julia> z = BigInterval(1//3) # Default precision of BigFloat
[0.3333333333333333333333333333333333333333333333333333333333333333333333333333304, 0.3333333333333333333333333333333333333333333333333333333333333333333333333333348]

julia> precision(z)
256

julia> precision(BigFloat)
256
```

Note that the default precision for `BigFloat` can be changed through:
```julia-repl 
julia> setprecision(128)
```

!!! warning
    For a specific `BigInterval` the precision cannot be changed after its creation. 


## Accessing left and right endpoints


```julia-repl
julia> a = BigInterval(1.0, 2.0)
[1.0, 2.0]

julia> left(a)
1.0

julia> right(a)
2.0

julia> typeof(right(a))
BigFloat
```

## Arithmetic Operations   

`MPFI.jl` supports basic arithmetic operations between intervals and other numeric types. These operations include addition, subtraction, multiplication, and division.



```julia-repl
julia> a = BigInterval(1.0, 2.0)
[1.0, 2.0]

julia> b = BigInterval(0.5, 1.5)
[0.5, 1.5]

julia> a+b
[1.5, 3.5]

julia> a-b
[-0.5, 1.5]

julia> a*b
[0.5, 3.0]

julia> a/b
[0.6666666666666666666666666666666666666666666666666666666666666666666666666666609, 4.0]
```


## Math Functions

`MPFI.jl` also supports other mathematical functions such as trigonometric, logarithmic, and exponential functions.
For an exhaustive list see here. 


```julia-repl
julia> x = BigInterval(1//3;precision=23) 
[0.33333331, 0.33333338]

julia> sin(x)
[0.32719463, 0.32719476]

julia> cos(x)
[0.94495689, 0.94495702]

julia> tan(x)
[0.34625351, 0.34625364]

julia> log(x)
[-1.0986126, -1.098612]

julia> exp(x)
[1.3956122, 1.3956128]

julia> sqrt(x)
[0.57735013, 0.57735038]
```


## Math Constants

You can create intervals representing common mathematical constants such as π and Euler's number.


```julia-repl
julia> pi_interval = BigInterval(π;precision=8)
[3.14, 3.157]

julia> e_interval = BigInterval(ℯ)
[0.5772156649015328606065120900824024310421593359399235988057672348848677267776598, 0.5772156649015328606065120900824024310421593359399235988057672348848677267776686]
```


## Set operations

- is_inside, intersect, union, bisect, blow


```julia-repl
@show isempty(x)
@show isinf(x)
@show isbounded(x)
@show isnan(x)

```

    isempty(x) = false
    isinf(x) = false
    isbounded(x) = true
    isnan(x) = false



    false


## Various interval functions: 
- diam_abs, diam_rel, diam, mag, mig, mid, hypot




    [1.0, 1.44227]



## Comparison Operations

The `mpfi` module provides comparison operations for intervals, including equality, inequality, and ordering.

There are two functions that compare intervals with zero, each serving different purposes:

- `iszero(x::BigInterval)`: Checks if the interval `x` is exactly zero.
- `has_zero(x::BigInterval)`: Checks if the interval `x` contains zero within its bounds.


```julia-repl
bi1 = BigInterval(-1.0, 1.0)
bi2 = BigInterval(0.0, 0.0)
bi3 = BigInterval(1.0, 2.0)

println("iszero(bi1): ", iszero(bi1)) # false
println("has_zero(bi1): ", has_zero(bi1)) # true
println("bi1 == 0: ", bi1 == 0) # false

println("iszero(bi2): ", iszero(bi2)) # true
println("has_zero(bi2): ", has_zero(bi2)) # true
println("bi2 == 0: ", bi2 == 0) # true

println("iszero(bi3): ", iszero(bi3)) # false
println("has_zero(bi3): ", has_zero(bi3)) # false
println("bi3 == 0: ", bi3 == 0) # false
```

    iszero(bi1): false
    has_zero(bi1): true
    bi1 == 0: false
    iszero(bi2): true
    has_zero(bi2): true
    bi2 == 0: true
    iszero(bi3): false
    has_zero(bi3): false
    bi3 == 0: false



```julia-repl
bi1 = BigInterval(-1.0, 1.0)
bi2 = BigInterval(1.0, 2.0)
@show bi1 > BigInterval(0.0,0.5)
@show bi2 > BigInterval(-1)

```

    bi1 > BigInterval(0.0, 0.5) = false
    bi2 > BigInterval(-1) = true



    true

