using Documenter
using VLDataScienceMachineLearningPackage

DocMeta.setdocmeta!(
    VLDataScienceMachineLearningPackage,
    :DocTestSetup,
    :(using VLDataScienceMachineLearningPackage);
    recursive = true,
)

makedocs(
    sitename = "CHEME 4800/5800 - Fall 2026",
    authors = "Jeffrey Varner",
    modules = [VLDataScienceMachineLearningPackage],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://varnerlab.github.io/CHEME-5800-CourseRepository-Fall-2026",
        edit_link = "main",
    ),
    pages = [
        "Home" => "index.md",
        "Library" => "library.md",
    ],
    checkdocs = :exports,
    warnonly = true,
)

deploydocs(
    repo = "github.com/varnerlab/CHEME-5800-CourseRepository-Fall-2026.git",
    devbranch = "main",
    push_preview = false,
)
