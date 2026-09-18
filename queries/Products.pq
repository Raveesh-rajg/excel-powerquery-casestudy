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
    Indexed = Table.AddIndexColumn(Typed, "SourceRow", 0, 1, Int64.Type),
    Stable = Table.Buffer(Table.Sort(Indexed, {{"SourceRow", Order.Ascending}})),
    Deduped = Table.RemoveColumns(Table.Distinct(Stable, {"SKU"}), {"SourceRow"})
in
    Deduped
