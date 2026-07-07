# Advanced Excel / Power Query case study

Six messy monthly exports (drifting headers, three date formats, currency
as text, footer junk), a pivot-shaped budget file, and a dirty product
lookup — cleaned entirely in Power Query, modeled in Power Pivot with DAX
(budget variance, YTD, margin), served on a slicer-driven dashboard where
the monthly process is literally Refresh All.

- `generate_data.py` — builds `data/` with every defect planted deliberately
- `docs/POWER_QUERY_M_CODE.md` — paste-ready M for all four queries, each
  defect mapped to its defeat
- `docs/MODEL_DASHBOARD_SPEC.md` — star model, relationships, measures, layout
- `docs/CASE_STUDY.md` — problem -> approach -> insights -> scale boundary

Build the .xlsx per the specs; add a dashboard screenshot and the verified
insight numbers to CASE_STUDY.md after building.
