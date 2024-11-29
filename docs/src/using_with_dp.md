# Using MPFI.jl with DynamicPolynomials.jl

MPFI.jl can be seamlessly integrated with [DynamicPolynomials.jl](https://github.com/JuliaAlgebra/DynamicPolynomials.jl) to construct polynomials with interval coefficients and perform various operations on them, such as addition, multiplication, differentiation, and substitution.

## Constructing polynomials

To use MPFI.jl with DynamicPolynomials.jl, follow these steps:

1. Define polynomial variables using `@polyvar`.
2. Create polynomials with interval coefficients using `BigInterval`.

Here’s an example:

```julia
using DynamicPolynomials, MPFI

# Define polynomial variables
@polyvar x y 

# Set the precision for MPFI
setprecision(14)

# Construct a polynomial with interval coefficients
p = BigInterval(3.5) * x^2 + BigInterval(8, 9) * y^4 * x^2 + BigInterval(1, 2)
```
This defines the polynomial 
$$ ([8.0, 9.0])x^2y^4 + ([3.5, 3.5])x^2 + ([1.0, 2.0]) $$
## Performing Operations on polynomials
`MPFI.jl` is compatible with the usual polynomial operations provided by `DynamicPolynomials.jl`, including addition, multiplication, differentiation, and substitution. Notably, it is possible to evaluate polynomials at `BigInterval` values.

### **Addition**  
```julia
@show p + p 
```
**Output:**
``` 
p + p = ([2.0, 4.0]) + ([7.0, 7.0])x² + ([16.0, 18.0])x²y⁴
``` 

### **Multiplication**  
```julia
@show p * p  
```

**Output:**
```
p * p = ([1.0, 4.0]) + ([7.0, 14.0])x² + ([12.25, 12.25])x⁴ + ([16.0, 36.0])x²y⁴ + ([56.0, 63.0])x⁴y⁴ + ([64.0, 81.0])x⁴y⁸
``` 

### **Differentiation**  
```julia
@show differentiate(p, x)  # Differentiate with respect to x
```
**Output:**
``` 
differentiate(p, x) = ([7.0, 7.0])x + ([16.0, 18.0])xy⁴
``` 

### **Substitution**  
- Substitute $x$ with a number. The precision of the coefficients is unchanged.
```julia
@show subs(p, x => 3)  
```
**Output:**
``` 
subs(p, x => 3) = ([32.5, 33.5]) + ([72.0, 81.0])y⁴
```
- Substitute x with an interval. The precision of the output coefficients is the maximum of default precision, the current precision of the coefficients and the precision of the evaluation point (if specified). 

```julia
@show subs(p, x => BigInterval(1//3))  
```
**Output:**
```
subs(p, x => BigInterval(1 // 3)) = ([1.38879, 2.38917]) + ([0.888732, 1.00013])y⁴
```




