# MPFI.jl

`MPFI.jl` is a Julia wrapper for the [MPFI](https://perso.ens-lyon.fr/nathalie.revol/software.html) (Multiple Precision Floating-Point Interval) C library, which provides interval arithmetic with arbitrary precision, based on [MPFR](https://www.mpfr.org/). This package enables Julia users to perform high-precision interval computations seamlessly.

## Features

- *Arbitrary Precision*: Perform interval arithmetic with precision limited only by available memory, thanks to MPFI’s reliance on MPFR.  
- *Compatibility*: Ideal for users porting code from other languages that already use MPFI or MPFR.  

- *Validated Numerical Computations*: Ensure reliable bounds for computations to maintain rigor in scientific and engineering applications.  
- *DynamicPolynomials Integration*: You can use `MPFI.jl` in combination with the `DynamicPolynomials` package to create polynomials with interval coefficients, differentiate them, and evaluate them at other intervals.

## Installation
   
To use the `MPFI.jl` package, install it using the repository's url:

```julia-repl
julia> import Pkg; Pkg.add(url="https://gitlab.inria.fr/ckatsama/mpfi.jl.git");

julia> using MPFI
```

## Quick Start

Here’s a simple example to get started with `MPFI.jl`:

```julia-REPL
julia> using MPFI

julia> a = BigInterval(1.0, 2.0)  
[1.0, 2.0]
julia> b = BigInterval(0.5, 1.5) 
[0.5, 1.5]

julia> sum = a + b  
[1.5, 3.5]
julia> product = a * b 
[0.5, 3.0]
julia> difference = a - b
[-0.5, 1.5]


julia> println("Lower bound of sum: ", left(sum))
Lower bound of sum: 1.5

julia> println("Upper bound of sum: ", right(sum))
Upper bound of sum: 3.5

julia> println("Intersection of intervals: ", MPFI.intersect(a, b))
Intersection of intervals: [1.0, 1.5]

julia> println("Union of intervals: ", MPFI.union(a, b))
Union of intervals: [0.5, 2.0]

julia> c = BigInterval(1//3;precision=14) # Define an interval by specifying its precision
[0.333312, 0.333344]
julia> precision(c)
14

julia> c = BigInterval(1//3) # Define an interval with the default precision of BigFloat
[0.3333333333333333333333333333333333333333333333333333333333333333333333333333304, 0.3333333333333333333333333333333333333333333333333333333333333333333333333333348]
julia> precision(c)
256
```



## The Julia Interval Arithmetic Ecosystem

For users migrating code that relies on MPFI or MPFR, `MPFI.jl` provides compatibility while leveraging MPFI's high-precision interval arithmetic. For other use cases, there are several other packages available in the Julia ecosystem:

- [Intervals.jl](https://invenia.github.io/Intervals.jl/stable/)
- [IntervalArithmetic.jl](https://juliaintervals.github.io/IntervalArithmetic.jl/stable/)
- [MPFI.jl](https://github.com/JuliaIntervals/MPFI.jl) (GitHub) Package: An older package wrapping MPFI, but it is not maintained and lacks full functionality.



