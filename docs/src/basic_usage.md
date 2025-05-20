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

You can create intervals representing common mathematical constants such as π, ℯ and Euler's constant.


```julia-repl
julia> pi_interval = BigInterval(π;precision=8)
[3.14, 3.157]

julia> e_interval = BigInterval(ℯ;precision=8)
[2.703, 2.719]

julia> γ_interval = BigInterval(Base.MathConstants.eulergamma;precision=8)
[0.5742, 0.5781]
```


## Comparing Intervals

`MPFI.jl` provides a suite of functions and operators for comparing intervals. Below is an explanation of the comparison methods and their usage.

### Zero Tests

Two dedicated functions are available for testing intervals against zero:

- `iszero(x::BigInterval)`: Returns `true` if the interval `x` is exactly zero (i.e., `[0, 0]`).
- `has_zero(x::BigInterval)`: Returns `true` if the interval `x` contains zero within its bounds.

#### Examples:
```julia-repl
julia> x = BigInterval(-1, 1)
[-1.0, 1.0]

julia> iszero(x)
false

julia> has_zero(x)
true

julia> x = BigInterval(0)
[0.0, -0.0]

julia> iszero(x)
true

julia> has_zero(x)
true
```


### Comparison Functions

The `cmp` function performs a comparison between intervals or between an interval and a real number. It uses the corresponding MPFI C functions, such as `mpfi_cmp_default`, `mpfi_cmp_ui_default`, and others, depending on the types of arguments. The function returns:
- `1` if one or both operands are invalid (contain NaN).
- `-1` if the first operand is strictly less than the second.
- `0` if the intervals overlap or the value lies within the interval.
- `1` if the first operand is strictly greater than the second.

The following variations of `cmp` handle comparisons with different types:

- `cmp(x::BigInterval, y::BigInterval)`: Compares two intervals.
- `cmp(x::BigInterval, y::Integer)`: Compares an interval with an integer, converting the integer to a `BigInterval`.
- `cmp(x::BigInterval, y::BigFloat)`: Compares an interval with a `BigFloat`.
- `cmp(x::BigInterval, y::CdoubleMax)`: Compares an interval with a double.
- Additional `cmp` overloads handle other types like `BigInt`, `ClongMax`, `CulongMax`, etc.

### Comparison Operators
 
Comparison operators (`==`, `<=`, `>=`, `<`, `>`) rely on the output of `cmp`. These operators return `true` or `false` based on the comparison:

- `==`: Returns `true` if the intervals or values are considered equal (intersection or exact match).
- `<=`: Returns `true` if the first interval is less than or equal to the second.
- `>=`: Returns `true` if the first interval is greater than or equal to the second.
- `<`: Returns `true` if the first interval is strictly less than the second.
- `>`: Returns `true` if the first interval is strictly greater than the second.

**Example:**
```julia-repl
julia> x = BigInterval(0,2)
[0.0, 2.0]

julia> y = BigInterval(1.0, 2.0) 
[1.0, 2.0]

julia> z = BigInterval(4,5)
[4.0, 5.0]

julia> x > y
false

julia> x>=y
true

julia> z>x
true

julia> z>y
true
```

#### Important Notes
1. The `==` operator for intervals behaves differently compared to `cmp`. It checks if the intervals are exactly the same:
   ```julia
   ==(x::BigInterval, y::BigInterval) = left(x) == left(y) && right(x) == right(y)
   ```
   This means that `==` only returns `true` if both endpoints match exactly, even if the intervals intersect.

   **Example:**
   ```julia-repl
   julia> x = BigInterval(0,2)
   [0.0, 2.0]

   julia> y = BigInterval(1,3) 
   [1.0, 3.0]

   julia> x == y 
   false

   julia> cmp(x,y)
   0
   ```

2. For intervals compared to `0`, the `==` operator behaves like `has_zero`, checking if the interval contains `0` within its bounds.

    **Example:**
   ```julia-repl
   julia> x = BigInterval(-1.0, 1.0)
   [-1.0, 1.0]

   julia> y = BigInterval(1.0, 2.0)
   [1.0, 2.0]

   julia> x == 0
   true

   julia> y == 0
   false
   ```


