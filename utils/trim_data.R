# load the big data file, trim it to only include columns we use in the app right now
# note: run in this as working directory

library(dplyr)
library(readr)
set.seed(1)

variables <- c(
  "var_name", "var_descr", "Type", "var_data_holding", "var_ds",
  "var_links", "var_lib", "var_url", "Population", "DCE",
  "official_lang_var_VMS", "official_lang_var_CP"
)


metadata_import <- readr::read_delim("../data/var_all_consolidated.csv",
  delim = "|", escape_double = FALSE, trim_ws = TRUE
)

metadata_lang_manual_check <- readr::read_csv(
  "../data/data_concordance_output_20240116.csv",
  col_types = cols(
    `300339` = col_skip(),
    ds_ref = col_character(), tbl_name = col_character(),
    lang_var_confirmed_VMS = col_logical(),
    official_lang_var_VMS = col_logical(),
    lang_var_confirmed_CP = col_logical(),
    official_lang_var_CP = col_logical(),
    lang_var_concordance = col_logical(),
    lang_off_concordance = col_logical(),
    `0.980929394012633` = col_skip()
  )
)


metadata_raw <- dplyr::left_join(
  x = metadata_import,
  y = metadata_lang_manual_check,
  by = c(
    "key",
    "var_name",
    "var_descr",
    "var_data_holding",
    "var_ds",
    "var_lib",
    "ds_ref",
    "tbl_name"
  )
) |>
  dplyr::select(dplyr::all_of(variables))

object.size(metadata_raw)

metadata_nomalestrom <- metadata_raw |>
  dplyr::filter(.data$var_data_holding != "MAELSTROM") |>
  dplyr::slice_sample(n = 25000)

as.numeric(object.size(metadata_nomalestrom) / object.size(metadata_raw))


readr::write_csv(
  metadata_nomalestrom,
  paste0("var-trimmed-", Sys.Date(), ".csv")
)
