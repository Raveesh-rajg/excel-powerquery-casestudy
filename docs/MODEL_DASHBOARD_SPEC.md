# Power Pivot model + dashboard spec

## Model (Manage Data Model)
Load Sales, Budget, Products (connection only + Add to Data Model). Create
Dates in DAX or as a PQ calendar query spanning 2026-01-01..2026-06-30,
marked as date table.

Relationships (single direction):
  Sales[sku] -> Products[SKU]
  Sales[order_date] -> Dates[Date]
  Budget[month] -> Dates[Date]        (budget joins at month grain via first-of-month)
  Budget[Region] + Sales[region]: relate both to a tiny Regions table
  (4 rows) — two facts never relate to each other directly.

## Measures
```dax
Revenue := SUM ( Sales[amount] )
Units := SUM ( Sales[quantity] )
Orders := DISTINCTCOUNT ( Sales[order_id] )
COGS := SUMX ( Sales, Sales[quantity] * RELATED ( Products[Unit Cost] ) )
Margin % := DIVIDE ( [Revenue] - [COGS], [Revenue] )
Budget Amt := SUM ( Budget[budget] )
Variance := [Revenue] - [Budget Amt]
Variance % := DIVIDE ( [Variance], [Budget Amt] )
Revenue YTD := TOTALYTD ( [Revenue], Dates[Date] )
```

## Dashboard sheet
- Top: slicers (Region, Category, Month timeline) wired to all pivots
- KPI row: Revenue / Variance % / Margin % / Orders (CUBEVALUE cells or
  single-cell pivots, conditionally formatted)
- Left: pivot chart, Revenue vs Budget by month (clustered column + line)
- Right: Revenue by Region (bar) + Margin % by Category (bar)
- Bottom: top-10 products pivot with data bars
All charts read the DATA MODEL pivots (not worksheet ranges) — the point of
the exercise.
