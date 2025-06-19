# Using MPFI.jl with DynamicPolynomials.jl

MPFI.jl can be seamlessly integrated with [DynamicPolynomials.jl](https://github.com/JuliaAlgebra/DynamicPolynomials.jl) to construct polynomials with interval coefficients and perform various operations on them, such as addition, multiplication, differentiation, and substitution.

## Constructing polynomials

To use MPFI.jl with DynamicPolynomials.jl, follow these steps:

1. Define polynomial variables using `@polyvar`.
2. Create polynomials with interval coefficients using `BigInterval`.

Here’s an example:

```julia-repl
julia> using DynamicPolynomials, MPFI

julia> @polyvar x y # Define polynomial variables
(x, y)

julia> setprecision(14) # Set the precision for MPFI
14

julia> p = BigInterval(3.5) * x^2 + BigInterval(8, 9) * y^4 * x^2 + BigInterval(1, 2) # Construct a polynomial with interval coefficients
([1.0, 2.0]) + ([3.5, 3.5])x² + ([8.0, 9.0])x²y⁴
```
This defines the polynomial 
$$ ([8.0, 9.0])x^2y^4 + ([3.5, 3.5])x^2 + ([1.0, 2.0]) $$
## Performing Operations on polynomials
`MPFI.jl` is compatible with the usual polynomial operations provided by `DynamicPolynomials.jl`, including addition, multiplication, differentiation, and substitution. Notably, it is possible to evaluate polynomials at `BigInterval` values.

### **Addition**  
```julia-repl
julia> p+p
([2.0, 4.0]) + ([7.0, 7.0])x² + ([16.0, 18.0])x²y⁴
```

### **Multiplication**  
```julia-repl
julia> p*p
([1.0, 4.0]) + ([7.0, 14.0])x² + ([12.25, 12.25])x⁴ + ([16.0, 36.0])x²y⁴ + ([56.0, 63.0])x⁴y⁴ + ([64.0, 81.0])x⁴y⁸
```


### **Differentiation**  
```julia-repl
julia> differentiate(p, x)  # Differentiate with respect to x
([7.0, 7.0])x + ([16.0, 18.0])xy⁴
```


### **Substitution**  
- Substitute $x$ with a number. The precision of the coefficients is unchanged.
```julia-repl
julia> subs(p, x => 3) 
([32.5, 33.5]) + ([72.0, 81.0])y⁴
```

- Substitute x with an interval. The precision of the output coefficients is the maximum of default precision, the current precision of the coefficients and the precision of the evaluation point (if specified). 

```julia-repl
julia> subs(p, x => BigInterval(1//3)) 
([1.38879, 2.38916]) + ([0.888733, 1.00012])y⁴
```

!!! warning 
    For consistent results, it is recommended to use the same precision for the evaluation point and the coefficients. Additionally, ensure that the global MPFR precision is set appropriately beforehand to maintain precision consistency across computations.




