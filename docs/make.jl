using Documenter
using MPFI


# Individual files
About = "Introduction" => "index.md"
#HowToIntro = "How-To guides" => "how_to_guides.md" 
BasicUsage = "Basic Usage" => "basic_usage.md"
UsingWithDynamicPolynomials = "Using with DynamicPolynomials" => "using_with_dp.md"
PublicAPI = "Public API" => "public_api.md"
PrivateAPI = "Private API" => "private_api.md"

Reference = "Reference" => [PublicAPI, PrivateAPI]
Manual = "Manual" => [
    BasicUsage,
    UsingWithDynamicPolynomials
]


PAGES = [
    About, 
    Manual,
    Reference
]

makedocs(
    sitename = "MPFI.jl",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    #modules = [MPFI], # this is to ensure that all docstrings are included in the documentation
    # remotes = nothing,
    checkdocs = :exports,
    pages = PAGES
)

deploydocs(
    repo = "https://gitlab.inria.fr/ckatsama/mpfi.jl.git",
    versions = ["dev" => "main"]
)


