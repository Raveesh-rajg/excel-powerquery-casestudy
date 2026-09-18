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
