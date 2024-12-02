using Documenter
using MPFI


# Individual files
About = "Introduction" => "index.md"
#HowToIntro = "How-To guides" => "how_to_guides.md" 
BasicUsage = "Basic Usage" => "basic_usage.md"
UsingWithDynamicPolynomials = "Using with DynamicPolynomials" => "using_with_dp.md"
PublicAPI = "Public API" => "functions.md"
PrivateAPI = "Private API" => "private_api.md"

Reference = "Reference" => [PublicAPI, PrivateAPI]
HowTo = "How-To guides" => [
    BasicUsage,
    UsingWithDynamicPolynomials
]


PAGES = [
    About, 
    HowTo,
    Reference
]

makedocs(
    sitename = "MPFI.jl",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    #modules = [MPFI], # this is to ensure that all docstrings are included in the documentation
    remotes = nothing,
    checkdocs = :exports,
    pages = PAGES
)

deploydocs(
    repo = "https://gitlab.inria.fr/ckatsama/mpfi.jl",
    versions = ["dev" => "main"]
)


