using Microelectronics
using Documenter

DocMeta.setdocmeta!(Microelectronics, :DocTestSetup, :(using Microelectronics); recursive=true)

makedocs(;
    modules=[Microelectronics],
    authors="Chris Winstead <chris.winstead@usu.edu> and contributors",
    sitename="Microelectronics.jl",
    format=Documenter.HTML(;
        canonical="https://cjwinstead.github.io/Microelectronics.jl",
        edit_link="main",
        assets=String[],
        size_threshold_warn=200 * 2^10,     # the reference page is long
        size_threshold=400 * 2^10,
    ),
    pages=[
        "Home" => "index.md",
        "Guide" => [
            "Building netlists" => "netlists.md",
            "Simulations and results" => "simulations.md",
            "Plots and reports" => "plots.md",
            "Transistors" => "transistors.md",
            "SPICE text functions" => "text.md",
        ],
        "Reference" => "reference.md",
        "Internals" => "internals.md",
    ],
    checkdocs=:exports,     # every exported name needs a docstring in the manual
)

# main's latest commit is published under /dev, releases under /stable and
# /vX.Y, and the dev branch (the next major version) under /next. Both
# branches list all of them so the version menu stays the same whichever
# branch deployed last.
deploydocs(;
    repo="github.com/cjwinstead/Microelectronics.jl",
    devbranch="main",
    versions=["stable" => "v^", "v#.#", "dev" => "dev", "next" => "next"],
)
