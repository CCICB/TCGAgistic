df_manifest <- function(){
  path_to_dataset_manifest <- "https://github.com/CCICB/TCGAgisticDB/raw/main/inst/cohorts.csv"
  df <- utils::read.csv(path_to_dataset_manifest, header=TRUE, check.names = FALSE)
}

#' List Available Datasets
#'
#' @return a dataframe listing available datasets
#' @examples
#' tcga_gistic_available()
#'
#' @importFrom maftools readGistic
#' @export
tcga_gistic_available <- function(){
  df <- df_manifest()
  return(df)
  #unique(df[,!names(df) %in% c("Filepath", "CopyNumberLevel")])
}


#' Load TCGA GISTIC data
#'
#' Load TCGA GISTIC objects into R. Streams data from [TCGAgisticDB](https://github.com/CCICB/TCGAgisticDB) repo.
#'
#' @param cohort abbreviation of TCGA cohort See [tcga_gistic_available()] for valid values (string)
#' @param source source of the data (currently we only support 'Firehose' data (string)
#' @inheritParams maftools::readGistic
#' @param verbose verbosity (flag)
#'
#' @return A maftools & CRUX-compatible list of summarized data.
#' @export
#'
#' @examples
#' # Load libraries
#' library(TCGAgistic)
#' library(maftools)
#'
#' # Load dataset
#' gistic <- tcga_gistic_load("ACC", source = "Firehose", cnLevel = "all")
#'
#' # Visualise results
#' gisticChromPlot(gistic)
tcga_gistic_load <- function(cohort, source = "Firehose", cnLevel = c("all", "deep", "shallow"), verbose = TRUE){
  cnLevel <- rlang::arg_match(cnLevel)
  df_available_cohorts <- tcga_gistic_available()

  if (!all(cohort %in% df_available_cohorts[[1]]))
    stop("Could not find requested cohort!\nUse tcga_gistic_available() to list available cohorts")

  if (!all(source %in% df_available_cohorts[["Source"]]))
    stop("Could not find requested Source!\nUse `tcga_gistic_available()` to list available Sources")

  if(length(cohort) > 1)
    stop("Can only request one cohort at a time!")

  if(!pingr::is_online())
    stop("Loading this dataset requires an internet connection. Please connect to the internet and try again")

  doi <- df_available_cohorts[df_available_cohorts$Cohort == cohort & df_available_cohorts$Source == source, "DOI"]

  path_github_folder = "https://github.com/CCICB/TCGAgisticDB/raw/main/inst/gistic_rds/"

  path_rds <- paste0(path_github_folder, cohort, '_',  source, '.cnlevel_', cnLevel, ".rds")

  gistic <- tryCatch(
    expr = {
      z <- gzcon(con = url(path_rds, "rb"))
      g <- readRDS(z)
      close(z)
      return(g)
    },
    error = function(err){
      stop("Failed to read cohort: ", cohort, "from source: ", source, ' with cnLevel of: ', cnLevel, ".\nThis dataset probably doesn't exist")
    },
    warning = function(warn){
      stop("Failed to read cohort [", cohort, "] from source [", source, '] with cnLevel of [', cnLevel, "].\nThis dataset probably doesn't exist", call. = TRUE)
    }
  )



  if(verbose) message("Loading TCGA gistic data for cohort ", cohort, "\nIf you find this dataset useful, please cite: \n", doi)

  return(gistic)

}
