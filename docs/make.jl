using Documenter
using MPFI


About = "Introduction" => "index.md"

Functions = "Functions" => "functions.md"
# GettingStarted = "gettingstarted.md"

# UserGuide = "User's guide" => [
#         "interface.md",
#         operations
#     ]

# DevGuide = "Developer's guide" => [
#         "wrappers.md"
#     ]

# Examples = "Examples" => [
#         "examples/flux.md"
#     ]

# License = "License" => "license.md"

PAGES = [
    About,
    Functions
]

makedocs(
    sitename = "MPFI",
    format = Documenter.HTML(),
    modules = [MPFI],
    remotes = nothing,
    checkdocs = :exports,
    pages = PAGES
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.

deploydocs(
    repo = "https://gitlab.inria.fr/ckatsama/mpfi.jl"
)


