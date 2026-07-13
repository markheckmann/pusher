.quote_log_value <- function(x) {
  x <- as.character(x)
  if (!grepl("[[:space:]\"=]", x)) {
    return(x)
  }
  paste0('"', gsub('"', '\\"', x, fixed = TRUE), '"')
}

.log_message <- function(level, repo = NA_character_, branch = NA_character_, result, ...) {
  .ensure_pusher_dir()

  fields <- list(
    repo = repo,
    branch = branch,
    result = result,
    ...
  )
  fields <- fields[!vapply(fields, function(x) length(x) == 0 || is.na(x), logical(1))]
  field_text <- paste(
    sprintf("%s=%s", names(fields), vapply(fields, .quote_log_value, character(1))),
    collapse = " "
  )
  line <- paste(.iso_now(), level, field_text)
  cat(line, "\n", file = .log_file(), append = TRUE)
  invisible(line)
}

.last_log_result <- function(repo_root) {
  path <- .log_file()
  if (!file.exists(path)) {
    return(NA_character_)
  }

  lines <- readLines(path, warn = FALSE)
  hits <- lines[grepl(paste0("repo=", repo_root), lines, fixed = TRUE) |
    grepl(paste0('repo="', repo_root, '"'), lines, fixed = TRUE)]
  if (!length(hits)) {
    return(NA_character_)
  }
  hits[[length(hits)]]
}

.empty_log_entries <- function() {
  data.frame(
    timestamp = character(),
    level = character(),
    repo = character(),
    branch = character(),
    result = character(),
    sha = character(),
    count = integer(),
    reason = character(),
    line = character(),
    stringsAsFactors = FALSE
  )
}

.parse_log_line <- function(line) {
  match <- regexec("^([^ ]+) ([A-Z]+) (.*)$", line)
  parts <- regmatches(line, match)[[1]]
  if (length(parts) != 4L) {
    return(NULL)
  }

  tokens <- regmatches(
    parts[[4]],
    gregexpr('([A-Za-z_][A-Za-z0-9_]*)=("(\\\\.|[^"\\\\])*"|[^[:space:]]+)', parts[[4]], perl = TRUE)
  )[[1]]
  fields <- list()
  for (token in tokens) {
    pos <- regexpr("=", token, fixed = TRUE)[[1]]
    if (pos <= 1L) {
      next
    }
    key <- substr(token, 1L, pos - 1L)
    value <- substr(token, pos + 1L, nchar(token))
    if (grepl('^".*"$', value)) {
      value <- substr(value, 2L, nchar(value) - 1L)
      value <- gsub('\\"', '"', value, fixed = TRUE)
    }
    fields[[key]] <- value
  }

  data.frame(
    timestamp = parts[[2]],
    level = parts[[3]],
    repo = fields$repo %||% NA_character_,
    branch = fields$branch %||% NA_character_,
    result = fields$result %||% NA_character_,
    sha = fields$sha %||% NA_character_,
    count = suppressWarnings(as.integer(fields$count %||% NA_character_)),
    reason = fields$reason %||% NA_character_,
    line = line,
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) {
    y
  } else {
    x
  }
}

.read_log_entries <- function() {
  path <- .log_file()
  if (!file.exists(path)) {
    return(.empty_log_entries())
  }

  lines <- readLines(path, warn = FALSE)
  entries <- lapply(lines, .parse_log_line)
  entries <- entries[!vapply(entries, is.null, logical(1))]
  if (!length(entries)) {
    return(.empty_log_entries())
  }

  do.call(rbind, entries)
}

#' List recent successful pushes
#'
#' @param n Maximum number of pushes to return.
#' @return A data frame of recent successful push log entries, newest first.
last_pushes <- function(n = 20) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 0) {
    stop("n must be a single non-negative number.", call. = FALSE)
  }

  entries <- .read_log_entries()
  pushes <- entries[entries$result == "pushed", , drop = FALSE]
  if (!nrow(pushes) || n == 0) {
    return(pushes[FALSE, , drop = FALSE])
  }

  keep <- utils::tail(seq_len(nrow(pushes)), n)
  pushes[rev(keep), , drop = FALSE]
}
