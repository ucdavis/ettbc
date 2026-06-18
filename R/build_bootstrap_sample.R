# Assemble one bootstrap dataset from a vector of sampled participant IDs.
# Concatenates the relabeled long-format rows for each sampled participant.
build_bootstrap_sample <- function(boot_ids, long_data_split, id_col) {
  boot_groups <- seq_along(boot_ids) |>
    lapply(
      relabel_bootstrap_group,
      boot_ids = boot_ids, long_data_split = long_data_split, id_col = id_col
    )
  boot_data <- do.call(rbind, boot_groups)
  rownames(boot_data) <- NULL
  boot_data
}
