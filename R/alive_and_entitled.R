# Box 1 (part 1) of c01_eligibility.sas: alive at the age threshold, entitled
# by age (not disability/ESRD).
#' @noRd
alive_and_entitled <- function(
    demographics, id_col, agein_month_col, death_month_col, orec_col) {
  death <- demographics[[death_month_col]]
  agein <- demographics[[agein_month_col]]
  alive_at_agein <- !is.na(agein) & (is.na(death) | death >= agein)
  entitled_by_age <- !is.na(demographics[[orec_col]]) &
    demographics[[orec_col]] == 0

  demographics[
    alive_at_agein & entitled_by_age,
    c(id_col, agein_month_col),
    drop = FALSE
  ]
}
