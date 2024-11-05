# Basic Usage


The type `BigInterval` represents an arbitrary precision interval floating point number.
It corresponds to the C-type `mpfi_t`.

## Constructors:
You can create intervals using various constructors. The precision is by default equal to `precision(BigFloat)`.
Here are some examples:



```julia
@show a = BigInterval("1.0")
@show b = BigInterval(1.0)
@show c = BigInterval(1, 2)
@show d = BigInterval(BigFloat(1.0), BigFloat(2.0))
@show e = BigInterval(BigInt(1), BigInt(2))
@show f = BigInterval(2.0, 3.0)
@show zero(BigInterval)
@show one(BigInterval)
```

    a = BigInterval("1.0") = [1.0, 1.0]
    b = BigInterval(1.0) = [1.0, 1.0]
    c = BigInterval(1, 2) = [1.0, 2.0]
    d = BigInterval(BigFloat(1.0), BigFloat(2.0)) = [1.0, 2.0]
    e = BigInterval(BigInt(1), BigInt(2)) = [1.0, 2.0]
    f = BigInterval(2.0, 3.0) = [2.0, 3.0]
    zero(BigInterval) = [0.0, -0.0]
    one(BigInterval) = [1.0, 1.0]



    [1.0, 1.0] 


Alternatively, you can use an optional argument to set a specific bit-precision in all the constructor functions:


```julia
@show BigInterval(1//3;precision=23) # "1//3" is Rational
@show BigInterval(1/3;precision=128) # "1/3" is a Float64
```

    BigInterval(1 // 3; precision = 23) = [0.33333331, 0.33333338]
    BigInterval(1 / 3; precision = 128) = [0.3333333333333333148296162562473909929394, 0.3333333333333333148296162562473909929395]



    [0.3333333333333333148296162562473909929394, 0.3333333333333333148296162562473909929395]



```julia
# Default precision
bi = BigInterval();
println("Default precision BigInterval: ", precision(bi))

# Specified precision
bi_128 = BigInterval(precision=128);
println("128-bit precision BigInterval: ", precision(bi_128))
```

    Default precision BigInterval: 256
    128-bit precision BigInterval: 128


Note that the default precision for `BigFloat` can be changed through:
```julia 
setprecision(128)
```
For a specific `BigInterval` the precision cannot be changed after its creation. 


## Basic access functions

- ```left(x::BigInterval)```
Returns the left endpoint of the interval `x` as a `BigFloat`.

- ```right(x::BigInterval)```
Returns the right endpoint of the interval `x` as a `BigFloat`.


```julia
bi = BigInterval(1.0, 2.0)
println("Left endpoint: ", left(bi))
println("Right endpoint: ", right(bi))
```

    Left endpoint: 1.0
    Right endpoint: 2.0


## Arithmetic Operations   

The `mpfi` module supports basic arithmetic operations between intervals and other numeric types. These operations include addition, subtraction, multiplication, and division.



```julia
setprecision(15)
x = BigInterval(1,3)
y = BigInterval("3.5")

sum = x + y
diff = x - y
prod = x * y
quot = x / y

println("Sum: ", sum)
println("Difference: ", diff)
println("Product: ", prod)
println("Quotient: ", quot)
```

    Sum: [4.5, 6.5]
    Difference: [-2.5, -0.5]
    Product: [3.5, 10.5]
    Quotient: [0.285705, 0.857148]


## Set operations

- is_inside, intersect, union, bisect, blow


```julia
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

## Other Functions

The `mpfi` module also supports other mathematical functions such as trigonometric, logarithmic, and exponential functions.


```julia
sin(x)
cos(x)
tan(x)
log(x)
exp(x)
sqrt(x)
cbrt(x)
```


    [1.0, 1.44227]


## Constants

You can create intervals representing common mathematical constants such as π and Euler's number.


```julia
pi_interval = BigInterval(π;precision=8)
e_interval = BigInterval(ℯ)

println("π interval: ", pi_interval)
println("ℯ interval: ", e_interval)
```

    π interval: [3.14, 3.157]
    ℯ interval: [0.577209, 0.57724]


## Comparison Operations

The `mpfi` module provides comparison operations for intervals, including equality, inequality, and ordering.

There are two functions that compare intervals with zero, each serving different purposes:

- `iszero(x::BigInterval)`: Checks if the interval `x` is exactly zero.
- `has_zero(x::BigInterval)`: Checks if the interval `x` contains zero within its bounds.


```julia
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



```julia
bi1 = BigInterval(-1.0, 1.0)
bi2 = BigInterval(1.0, 2.0)
@show bi1 > BigInterval(0.0,0.5)
@show bi2 > BigInterval(-1)

```

    bi1 > BigInterval(0.0, 0.5) = false
    bi2 > BigInterval(-1) = true



    true

