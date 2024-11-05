# Using with DynamicPolynomials.jl


The `mpfi` module can be used in combination with `DynamicPolynomials.jl` to construct polynomials with interval coefficients and perform basic operations with them (addition, multiplication, substitution, differentiation):


```julia
using DynamicPolynomials
@polyvar x y 
setprecision(14)
p = BigInterval(3.5) * x^2 + BigInterval(8, 9) * y^4 * x^2 + BigInterval(1, 2)
```


$$ ([8.0, 9.0])x^{2}y^{4} + ([3.5, 3.5])x^{2} + ([1.0, 2.0]) $$



```julia
@show p * p
@show p + p  
@show differentiate(p,x)
@show subs(p, x => 3)
@show subs(p, x => BigInterval(1//3))

```

    p * p = ([64.0, 81.0])x⁴y⁸ + ([56.0, 63.0])x⁴y⁴ + ([16.0, 36.0])x²y⁴ + ([12.25, 12.25])x⁴ + ([7.0, 14.0])x² + ([1.0, 4.0])
    p + p = ([16.0, 18.0])x²y⁴ + ([7.0, 7.0])x² + ([2.0, 4.0])
    differentiate(p, x) = ([16.0, 18.0])xy⁴ + ([7.0, 7.0])x
    subs(p, x => 3) = ([72.0, 81.0])y⁴ + ([32.5, 33.5])
    subs(p, x => BigInterval(1 // 3)) = ([0.888732, 1.00013])y⁴ + ([1.38879, 2.38917])



$$ ([0.888732, 1.00013])y^{4} + ([1.38879, 2.38917]) $$