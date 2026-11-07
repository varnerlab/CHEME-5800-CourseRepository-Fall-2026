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
        # The library page holds every docstring of the course package on one page, about
        # 490 KiB. Documenter's default limit is 200 KiB, so we raise it to 1 MiB.
        size_threshold = 1024 * 1024,
        size_threshold_warn = 512 * 1024,
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
