# Case study — Multi-source sales reporting without manual cleanup

**Problem.** A small retailer's monthly sales exports come from a legacy
system that renames columns between releases, mixes three date formats,
writes currency as text, appends footer junk, and can't keep region names
consistent. Budgets live in a hand-maintained wide spreadsheet; the product
list has duplicate SKUs with conflicting costs. Monthly reporting = a day
of copy-paste-fix, redone from scratch when anything upstream changes.

**Approach.** Power Query owns ALL cleaning (folder-combine with a header
contract, format-explicit date parsing, text-to-currency, key-normalized
dedup, budget unpivot); Power Pivot owns semantics (star model, DAX
measures incl. budget variance and YTD); the dashboard owns nothing but
presentation. July's export lands in the folder -> Refresh All is the
entire monthly process.

**The defects and their defeats** (each planted in the generated data, each
handled by a specific documented technique — see POWER_QUERY_M_CODE.md):
header drift -> rename-map contract; mixed date formats -> ordered strict
parsers, never a permissive single-culture parse; currency text -> Text.Select
+ typed column; footer rows -> shape-based row filter; dirty lookup keys ->
normalize-then-dedup (order matters, and SKU-003's conflicting costs show
which row wins and why that's documented).

**Insights the dashboard surfaces** (verify on your build): North/West
carry most revenue with distinctly higher margin in Hardware; variance vs
budget flips sign mid-quarter — the kind of finding that vanishes when the
data is being hand-fixed instead of read.

**What I'd do differently at scale.** This entire workbook is the
prototype for the dbt+warehouse version: the rename map becomes staging
models, the measures become a semantic layer, Refresh All becomes
orchestration. Excel is the right tool at 6 files and one analyst; the
case study is knowing where that boundary is.
