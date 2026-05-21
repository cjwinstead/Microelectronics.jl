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
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cjwinstead/Microelectronics.jl",
    devbranch="main",
)
