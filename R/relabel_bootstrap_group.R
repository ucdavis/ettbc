# Look up one sampled participant's long-format rows and relabel them with a
# fresh synthetic integer id (the draw position `i`) so that duplicated draws
# become distinct participants. Whole-column replacement via `[[<-` drops any
# original factor/character type (rather than coercing `i` into an existing
# factor's levels, which would yield `NA`), so downstream id handling is
# robust to the input id type.
relabel_bootstrap_group <- function(i, boot_ids, long_data_split, id_col) {
  grp <- long_data_split[[as.character(boot_ids[i])]]
  grp[[id_col]] <- as.integer(i)
  grp
}
