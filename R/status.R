#' Show pusher status for all tracked repositories
#'
#' @return A data frame with unpublished and due commit counts.
status <- function() {
  repos <- .read_repos()
  if (!nrow(repos)) {
    return(data.frame())
  }

  rows <- lapply(seq_len(nrow(repos)), function(i) {
    repo <- repos[i, , drop = FALSE]
    analysis <- tryCatch(.analyze_repo(repo), error = function(e) e)
    if (inherits(analysis, "error")) {
      return(.analysis_row(repo, error = analysis))
    }
    .analysis_row(repo, analysis)
  })

  do.call(rbind, rows)
}
