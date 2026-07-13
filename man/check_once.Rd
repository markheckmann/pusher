\name{check_once}
\alias{check_once}
\title{Check tracked repositories once}
\usage{check_once(dry_run = TRUE)}
\arguments{
\item{dry_run}{If \code{TRUE}, report what would be pushed without pushing.}
}
\value{A data frame summarising the run, invisibly.}
\description{Check tracked repositories once and push due commits when \code{dry_run = FALSE}.}
