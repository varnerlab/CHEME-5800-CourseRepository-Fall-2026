# L11b Markov word generator lab: answer sheet and build notes

Notebook: `weeks/week-11/L11b/CHEME-5800-L11b-Lab-MarkovWordGenerator-Fall-2026.ipynb`
(replaces the scaffold `CHEME-5800-L11b-Lab-MarkovSequenceGenerator-Fall-2026.ipynb`).
Built 2026-10-11. All numbers below are for `seed = 5800`, Julia 1.12.7 with the pinned
Manifest. The week-11 suite pins them (`@meeting "L11b"`, 36 tests).

## Sources

- **The lab**: 2025 CHEME 5800 L11b, *Implementing a Markov Word Generator*
  (`CHEME-5800-Instances/Fall-2025/CHEME-5800-Labs-Fall-2025/labs/week-11/L11b/...Solution...`).
  Kept: the title, the opening sentence, the Data section, the 26-letter character list, the
  `b → r` lookup cell, the "most likely next character" loop, the Task 2 text and `sample_words`
  helper callout, the start character `'b'`, word length 6, 1,000 samples, the real-word check,
  the table of real words, and the two "Future Directions" (false negatives, using more
  characters), which became the Task 3 question.
- **The student task**: 2024 CHEME 5800 D11b (`CHEME-4800-5800-Examples-Labs-Fall-2024/discussion/week-11/D11b/`),
  where students implemented `transitionmatrix(...)` and the README says "Let's compute p_ij
  using the first two characters of each word to make our lives easier." Task 1 uses that
  sentence.
- CHEME-145 M2 `...MarkovWordGenerator-Ungraded-Codio-Activity.ipynb` is the 2025 notebook
  almost word for word. Taken from it: "26×26" in place of "`26 x 26`", the rounded percentage,
  naming `true_generated_words::Set{String}` in the prose, and "Wow! We have".

## What changed from the sources, and why

- **Student work added.** The 2025 lab only called package helpers (its TODOs were "build the
  character array" and "call `sample_words`"). Students now complete three TODOs in
  `L11bMarkov.my_transition_matrix(...)` (`src/Compute.jl`): take the second character of each
  word, count it, and divide each row by its total. The result is checked against the package's
  `vocabulary_transition_matrix(...)`; the reference matches it bit for bit on the vocabulary.
- **The text now says what the matrix is.** The 2025 objective said the lab extracts
  "transition probabilities between consecutive characters", but the package's
  `vocabulary_transition_matrix(...)` uses only the first two characters of each word: row `i`
  is the distribution of the second character among the words that start with `i`. The 2026
  text uses Jeff's 2024 wording and gives the estimate p_ij = n_ij / Σ_k n_ik. Counting every
  neighboring pair would be a different (and arguably better) model; it is the Task 1 question,
  with numbers below, not a code change.
- **The real-word table no longer crashes.** 2025 popped ten words with `pop!` from
  `true_generated_words`. With `seed = 5800` there are only 8 real words, so `pop!` would throw
  on an empty set (and it also emptied the set). The cell now shows up to ten words, sorted,
  without changing the set.
- **Seeded.** `sample_words(...)` draws from Julia's global RNG (the package gives no `rng`
  argument), so the Task 2 cell and the what-if call `Random.seed!(seed)` first.
- **The 2025 two tasks became three**: Task 1 builds the matrix (plus the 2025 discussion loop),
  Task 2 generates words, Task 3 checks them and adds one what-if (word lengths 4 to 8), which
  2025's "the fraction depends on ... the length of the requested words" sentence set up.
- **Shown, not hidden**: 2025 never displayed a generated word. Task 2 now prints the number
  of different words and the first ten in alphabetical order.
- **Data.** The package loader reads `code/src/data/words_dictionary.json`, which was missing
  from the vendored package, so `MyEnglishLanguageVocabularyModel()` failed. It is now copied
  from `~/Desktop/julia_work/VLDataScienceMachineLearningPackage.jl/src/data/` (byte-identical
  to the 2024 D11b copy; 6,825,577 bytes, 370,100 words; SHA-256 `745898d3…5be`, pinned in the
  suite). Source: github.com/dwyl/english-words (`words_dictionary.json` is `words_alpha.txt` as
  JSON). The repository is under The Unlicense, but its README says the list came from an
  archived Infochimps dataset and that "Copyright still belongs to them." Two entries are not
  pure letters (`jean-christophe`, `jean-pierre`); their second characters are letters, so
  nothing changes. `code/src` ships in every weekly bundle (`scripts/build_week.py`,
  `PACKAGE_PATHS`), so each bundle grows by about 1.2 MB compressed.
- **Dropped**: the 2025 cell that defined `P = nothing` and an empty `characters` before filling
  them, and the "Future Directions" block (its two questions are now the Task 3 question).

## Predictions and questions

**Task 1, most likely next character** (largest entry of each row):
a→n 0.201, b→a 0.212, c→o 0.341, d→e 0.345, e→n 0.207, f→o 0.209, g→a 0.206, h→e 0.258,
i→n 0.613, j→a 0.315, k→i 0.217, l→a 0.289, m→a 0.255, n→o 0.647, o→v 0.318, p→r 0.265,
q→u 0.971, r→e 0.614, s→u 0.177, t→r 0.253, u→n 0.885, v→e 0.304, w→a 0.274, x→e 0.358,
y→a 0.346, z→o 0.333. Also quoted: P('b' → 'r') = 0.1395.

**Task 1 question** (why the large probabilities after `u`, `n`, `r`): row `i` of P is the
distribution of the second character among words that *start* with `i`, so it records how
English words begin. Many words begin with the prefixes `un-` (88.5 percent of the `u` words),
`non-`/`no-`, `re-`, `in-` (0.613), and `over-` (o→v 0.318). Counting every pair of
neighboring characters in every word gives much smaller values: u→n 0.211, r→e 0.178,
i→n 0.197, and the most likely character after `n` becomes `e` (0.143). Only q→u stays near
one (0.985).

**Task 2 question** (each character depends only on the one before it): the Markov property.
The generator ignores every earlier character and the position in the word. It also treats
every step as if it were the step from the first to the second character, because that is
where P came from.

**Task 3 prediction** (fraction of six-character words that are real): less than 5 percent.
828 different words, 8 real (0.97%): bacopa, balata, binode, binous, bistre, borele, bovine,
brelan.

**Word-length prediction** (four-character words): the fraction increases.

| word length | different words | real | percent |
|---|---|---|---|
| 4 | 340 | 92 | 27.06 |
| 5 | 631 | 44 | 6.97 |
| 6 | 828 | 8 | 0.97 |
| 7 | 934 | 0 | 0.00 |
| 8 | 985 | 0 | 0.00 |

With seed 1 and start `'t'` the pattern is the same (four characters 29.5%, six 1.1%, seven
and eight 0).

**Task 3 question** (false negatives; using more of each word): a real word missing from the
vocabulary counts as not real, so the fraction is too low (an underestimate). To use more of
each word: count every pair of neighboring characters, not only the first two; or make the
state the previous two characters (a second-order chain, 26² = 676 states); or add an
end-of-word state so the length is learned. For reference, counting every neighboring pair
with the same seed gives 16 real words of 989 at length 6 (1.62%), 171 of 641 at length 4
(26.7%), and 3 at length 7 (bandido, begging, bending).

## Check cell (student-facing) and mutation tests

`@testset "My transition matrix"` (3 tests): P matches the package's
`vocabulary_transition_matrix(...)` (≈); every entry is nonnegative and every row sums to one;
a hand-counted test vocabulary (`'a' => {a, ab, abc, ac}`, `'b' => {ba, bb}`, `'c' => {ca, c-a}`
over the states a, b, c) gives `[0 2/3 1/3; 1/2 1/2 0; 1 0 0]`. Nothing depends on the seed or
on a default run's counts.

- Wrong fills caught (13): stub untouched, TODO 1 untouched or `word[1]` or `word[end]`,
  TODO 2 untouched or `= 1` or `+ 2` or `counts[j, i]`, TODO 3 untouched or `./ K` or
  `./ sum(counts)` or transposed (`P[:, i]`) or a uniform row. Eight of them trip the stub's
  "Oooops!" guard (counts disagree with the number of words counted, or a row with counts does
  not sum to one); the rest fail a test.
- Correct alternatives pass: `collect(word)[2]`, `first(word, 2)[2]`, `+= 1`, `/ N`,
  `.= counts[i, :] ./ sum(counts[i, :])`, an explicit loop over the row.
- The notebook runs with `seed = 1`, `length_of_sample_word = 8`, start `'t'` (no real words,
  empty table, no error).

## Build notes

- `src/Compute.jl` (module `L11bMarkov`, student stub), `src/Compute-solution.jl`. No
  Visualize.jl or Utility.jl: the lab has no plots.
- `Include.jl` loads `Compute.jl` unguarded and has no `using .L11bMarkov`; the notebook calls
  `L11bMarkov.my_transition_matrix(...)`. The `Week11Core` include was removed. Imports:
  Random, Test, DataFrames, PrettyTables.
- The notebook ships without outputs. With the stub, the setup and data cells run; the Task 1
  result cell stops with the "Oooops!" error.
- Style check (`notebook_style_check.py`, bare): 0 findings. Markdown about 1,380 words
  (2025 solution 1,076; the extra is the transition-matrix formula, the check cell, and the
  predictions and questions).
- Suite block: `@meeting "L11b"` with `import JSON`, `import REPL`, `import SHA`, `using Test`
  at the top of the file.
