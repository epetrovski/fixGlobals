#' add_global_vars
#'
#' Adds missing variables to globalVariables().
#'
#' @export
#'
#' @importFrom utils capture.output
#'
#' @examples
#' \dontrun{
#' initiate_file()
#' }
add_global_vars <- function(){

  # Find package name
  package_name <- find_package_name()

  # Check if package is loaded - if not, codetools will fail
  if (!paste0("package:", package_name) %in% search())
    stop(paste0("Package must be loaded with library(", package_name, ")"))

  # Path to zzz_global_variables.R
  file_path <- paste0(rprojroot::find_rstudio_root_file(), "/R/zzz_global_variables.R")

  # Check if "zzz_global_variables.R" exists
  if (!file.exists(file_path)) {
    message("zzz_global_variables.R doesn't exist - initiates it.")
    initiate_file()
  }

  # Catch lines with undefined global variables or functions
  output <- capture.output(codetools::checkUsagePackage(package_name))

  # Catch names of undefined global variables
  new_vars <- lapply(output, get_varName)

  # Create vector with variable names sans lines concerning functions
  new_vars <- paste0(new_vars[new_vars != "NO MATCH"])

  # Write to zzz_global_variables.R
  append_file(new_vars, file_path)

}

#' get_varName
#'
#' Find svariable names in the output of R CMD check.
#'
#' @return A list of matches
#'
#' @param string The string we're looking for
#'
get_varName <- function(string){

  # REGEX to catch names of global variables
  pattern <- ".*no visible binding for global variable '(.*)'.*"

  # Return name if there's a global variabel, otherwise return "NO MATCH"
  ifelse(grepl(pattern, string), gsub(pattern, "\\1", string), "NO MATCH")
}

#' append_file
#'
#' Reads from and wrties to zzz_global_variables.R.
#'
#' @param new_vars A vector with names of new variables to add
#' @param file_path Path to zzz_global_variables.R
append_file <- function(new_vars, file_path){

  # Connects to script
  file_connection <- file(file_path)

  # Reads script
  file_content <- readLines(file_connection)

  # Trims leading and trailing white spaces
  file_content_strp <- lapply(file_content, function(x)  gsub("^\\s+|\\s+$", "", x))

  # Find first line where variables can be added
  line_num <- which(file_content_strp == "globalVariables(")

  # All the text from the beginning of the globalVariables function to end of script
  relevant_content <- paste(file_content_strp[line_num:length(file_content_strp)], collapse = "")

  # Get variable names of already defined variables
  vars_defined <- stringi::stri_match_all(str = relevant_content, regex = '"(.*?)\\"')[[1]][,2]

  # Collect variables that should be written to script in alphabetical order
  all_vars <- sort(unique(c(setdiff(vars_defined, c("foo_a", "foo_b")), new_vars)))

  # Split vector to keep lines of max 4 variable names
  if (length(all_vars) > 4)
    all_vars <- split(all_vars, ceiling(seq_along(all_vars) / 4))

  # Text to write to file
  new_content <- paste0(
    "    globalVariables(\n       c(# Insert variable names below\n         \"",
    paste0(
      lapply(all_vars, function(x) paste(x, collapse = "\", \"")), collapse = "\", \n         \""),
    "\"\n      )\n    )\n}\n\nfix_undefined_global_vars()")

  # Adds
  file_content <- append(file_content[1:line_num - 1], new_content)

  # Write back to file and close connection
  writeLines(file_content, file_connection)
  close(file_connection)

  # Indicate that variables have been written to file
  vars_written <- setdiff(new_vars, vars_defined)

  if (length(vars_written) > 0) {
    message(paste0("The following variables have been added to globalVariables(): ",
                   paste0(vars_written, collapse = ", "), ".")) } else {
      message(paste0("No new variables found."))
    }
}

#' initiate_file
#'
#' Creates a new zzz_global_variables.R file.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' initiate_file()
#' }'
#'
initiate_file <- function() {

  # Path to zzz_global_variables.R
  file_path <- paste0(rprojroot::find_rstudio_root_file(), "/R/zzz_global_variables.R")

  # Check if file already exists
  if (file.exists(file_path))
    stop("zzz_global_variables already exists - will not overwrite.
          Delete file manually to start over.")

  # Create file
  file.create(file_path)

  # Connect to file
  file_connection <- file(file_path)

  # Write to file
  writeLines("#' A fix to avoid R CMD check notes for \"no visible binding for global variable\"
#'
#' This script makes it possible to refer to columns in data frame like objects
#' with Non Standard Evaluation (NSE) used by packages like data.table and dplyr
#' without encountering R CMD check notes concernng \"no visible binding for
#' global variable\". Names of the variables refered to with NSE are added to
#' a character vector in the function globalVariables() below.
#'
#' @importFrom utils globalVariables
#'
fix_undefined_global_vars <- function() {
  if (getRversion() >= \"2.15.1\")
    globalVariables(
      c(# Insert variable names below
         \"foo_a\", \"foo_b\"
        )
      )
}
fix_undefined_global_vars()",
file_connection)

  # Close connection
  close(file_connection)
}

#' find_package_name
#'
#' Finds the name of the package that the user is working on.
#'
#' @return Name of the package that user is in
#'
find_package_name <- function(){

  # path to DESCRIPTION-fil
  desc_path <- paste0(rprojroot::find_rstudio_root_file(), "/DESCRIPTION")

  # Check if file exists
  if (!file.exists(desc_path))
    stop("DESCRIPTION file not found. Are you working in an R-package?")

  # Connect
  file_connection <- file(desc_path)

  # Read script
  file_content <- readLines(file_connection, warn = FALSE)

  # Find first line where a variabel can be added
  line_num <- which(grepl("Package:", file_content))

  # Close connection
  close(file_connection)

  # Package name
  return(sub('^.* ([[:alnum:]]+)$', '\\1', file_content[line_num]))
}
