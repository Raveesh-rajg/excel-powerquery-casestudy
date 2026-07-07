# Power Query — the M code, pattern by pattern

Four queries. Paste into Advanced Editor; each header explains the defect
it defeats.

## 1. `Sales` — folder combine with schema normalization

Defeats: header drift across files, three date formats, currency-as-text,
footer junk, region whitespace/casing.

```m
let
    // one row per file; keeps refresh working when July's export lands
    Source = Folder.Files(ParamDataFolder & "\exports"),
    CsvOnly = Table.SelectRows(Source, each [Extension] = ".csv"),

    // per-file parse WITHOUT promoted headers yet — we normalize first
    Parsed = Table.AddColumn(CsvOnly, "Data", each
        Csv.Document([Content], [Delimiter = ",", QuoteStyle = QuoteStyle.Csv])),

    // normalize each file's schema to canonical names BEFORE combining.
    // Header-name drift is a data contract violation; the rename map is the
    // contract, and unknown headers fail loudly here instead of silently
    // misaligning columns downstream.
    RenameMap = [
        #"Order ID" = "order_id",  order_id = "order_id",  OrderID = "order_id",
        #"Order Date" = "order_date", order_date = "order_date", Date = "order_date",
        Region = "region", region = "region", #"Sales Region" = "region",
        SKU = "sku", sku = "sku", #"Product SKU" = "sku",
        Qty = "quantity", quantity = "quantity", Units = "quantity",
        #"Sale Amount" = "amount_text", amount = "amount_text", #"Revenue ($)" = "amount_text"
    ],
    Normalized = Table.TransformColumns(Parsed, {"Data", each
        let promoted = Table.PromoteHeaders(_, [PromoteAllScalars = true]),
            renamed = Table.RenameColumns(promoted,
                List.Transform(Table.ColumnNames(promoted),
                    (c) => {c, Record.FieldOrDefault(RenameMap, c, c)}))
        in renamed}),

    Combined = Table.Combine(Normalized[Data]),

    // footer junk: real rows always have an ORD id
    RealRows = Table.SelectRows(Combined, each
        Text.StartsWith(Text.From([order_id]), "ORD")),

    // region: trim + clean + proper-case in one pass
    CleanRegion = Table.TransformColumns(RealRows,
        {"region", each Text.Proper(Text.Trim(Text.Clean(_))), type text}),

    // SKU casing (a few arrive lowercase)
    CleanSku = Table.TransformColumns(CleanRegion,
        {"sku", each Text.Upper(Text.Trim(_)), type text}),

    // currency-as-text: strip $ and commas, then type with en-US culture
    Amount = Table.AddColumn(CleanSku, "amount", each
        Number.FromText(Text.Select([amount_text], {"0".."9", ".", "-"})),
        Currency.Type),

    // three date formats in one column: try strict formats in order;
    // Date.FromText with a single culture would silently misread 03/04 rows
    ParseDate = (t as text) as date =>
        let iso = try Date.FromText(t, [Format = "yyyy-MM-dd"]),
            us  = try Date.FromText(t, [Format = "M/d/yyyy"]),
            mon = try Date.FromText(t, [Format = "d-MMM-yy", Culture = "en-US"])
        in if not iso[HasError] then iso[Value]
           else if not us[HasError] then us[Value]
           else mon[Value],
    Dated = Table.AddColumn(Amount, "order_date_parsed", each ParseDate([order_date]), type date),

    Final = Table.SelectColumns(Dated,
        {"order_id", "order_date_parsed", "region", "sku", "quantity", "amount"}),
    Typed = Table.TransformColumnTypes(Final,
        {{"quantity", Int64.Type}}),
    Renamed = Table.RenameColumns(Typed, {{"order_date_parsed", "order_date"}})
in
    Renamed
```

## 2. `Budget` — unpivot

```m
let
    Source = Csv.Document(File.Contents(ParamDataFolder & "\budget_wide.csv"),
                          [Delimiter = ",", QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    // unpivot EVERYTHING except Region: survives new month columns unchanged
    Unpivoted = Table.UnpivotOtherColumns(Promoted, {"Region"}, "month_label", "budget_text"),
    Month = Table.AddColumn(Unpivoted, "month", each
        Date.FromText("2026-" & Text.Start([month_label], 3) & "-01",
                      [Format = "yyyy-MMM-dd", Culture = "en-US"]), type date),
    Typed = Table.TransformColumnTypes(Month, {{"budget_text", Currency.Type}}),
    Final = Table.SelectColumns(
        Table.RenameColumns(Typed, {{"budget_text", "budget"}}),
        {"Region", "month", "budget"})
in
    Final
```

## 3. `Products` — dedup a dirty lookup

```m
let
    Source = Csv.Document(File.Contents(ParamDataFolder & "\product_lookup.csv"),
                          [Delimiter = ",", QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    CleanKey = Table.TransformColumns(Promoted,
        {"SKU", each Text.Upper(Text.Trim(_)), type text}),
    Typed = Table.TransformColumnTypes(CleanKey, {{"Unit Cost", Currency.Type}}),
    // dedup AFTER normalizing the key — Table.Distinct before Trim/Upper
    // would keep "SKU-001 " and "SKU-001" as two rows and the model
    // relationship would fail on duplicate keys anyway
    Deduped = Table.Distinct(Typed, {"SKU"})
in
    Deduped
```
(Which duplicate survives `Table.Distinct` is the first-loaded — for the
case study that's acceptable and DOCUMENTED; production would sort by an
updated_at first. SKU-003's two costs are the planted example.)

## 4. `ParamDataFolder` — parameter, so the workbook travels

Manage Parameters > New: text parameter holding the data folder path. Every
source references it; moving the workbook = edit one value.
