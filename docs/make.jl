using Documenter
using MPFI


About = "Introduction" => "index.md"

BasicUsage = "Basic Usage" => "basic_usage.md"

UsingWithDynamicPolynomials = "Using with DynamicPolynomials" => "using_with_dp.md"

Functions = "Functions" => "functions.md"


PAGES = [
    About, 
    BasicUsage,
    UsingWithDynamicPolynomials,
    Functions
]

makedocs(
    sitename = "MPFI.jl",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    modules = [MPFI],
    remotes = nothing,
    checkdocs = :exports,
    pages = PAGES
)

deploydocs(
    repo = "https://gitlab.inria.fr/ckatsama/mpfi.jl",
    versions = ["dev" => "main"]
)


