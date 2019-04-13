
# fixGlobals <img src="man/figures/logo.png" align ="right" height="180" />

A helper tool for package developers to avoid R CMD check notes
concerning “no visible binding for global variable” that occur when a
function refers to a variable that isn’t defined in the global
environment.

These notes exist for obvious good reason but can become a nuisance when
using data transformation packages like `data.table` and `dplyr` which
make use of Non Standard Evaluation (NSE) to refer to columns in a data
frame like R object. Every use of NSE creates an R CMD check note due to
the fact that the R CMD check interprets unquoted variable names as
global variables.

`fixGlobals` works by maintaining a character vector of variable names,
passed to `utils::globalVariables()`, and which are ignored during the R
CMD check.

## How to use

### Initiate zzz\_global\_variables.R

First the file “R/zzz\_global\_variables.R” must be initiated with
`fixGlobals::initiate_file()`. This is the default content of
“zzz\_global\_variables.R”:

``` r
#' A fix to avoid R CMD check notes for \"no visible binding for global variable\"
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
  if (getRversion() >= "2.15.1")
    globalVariables(
      c(# Insert variable names below
        "foo_a", "foo_b"
        )
      )
}

fix_undefined_global_vars()
```

### Add variables

It’s possible to maintain the character vector in `globalVariables()`
manually. Below the column `cyl` from mtcars is added and the
placeholders `foo_a, foo_b` are removed:

``` r
fix_undefined_global_vars <- function() {
  if (getRversion() >= "2.15.1")
    globalVariables(
      c(# Insert variable names below
        "cyl"
        )
      )
}

fix_undefined_global_vars()
```

However, this becomes cumbersome if NSE is used extensively. In
stead,`fixGlobals::add_global_vars()` can be used to automatically add
variable names to the vector.

For instance, a function `subset_cars()` can be defined to use
`data.table` to subset several columns from `mtcars`:

``` r
subset_cars <- function(mtcars) {
  dtcars <- as.data.table(mtcars)
  dtcars[, .(cyl, mpg, disp, hp, drat, carb)]
}
```

In this example R CMD check notes will be provided for `mpg, disp, hp,
drat, carb` if `devtools::check()` is executed. No note is provided for
`cyl` since this variable was provided manually to `globalVariables()`
earlier — see example above. However, if `fixGlobals::add_global_vars()`
is executed zzz\_global\_variables.R will be updated and check notes
concerning these variable are avoided:

``` r
fix_undefined_global_vars <- function() {
  if (getRversion() >= "2.15.1")
    globalVariables(
      c(# Insert variable names below
        "cyl", "carb", "disp", "drat", 
        "hp", "mpg"
        )
      )
}

fix_undefined_global_vars()
```

Notice that `fixGlobals` also keeps order by sorting alphabetically and
puts no more that four variables in a line.

## Install

You can install `fixGlobals` from GitHub.

``` r
# install.packages("devtools")
devtools::install_github("epetrovski/fixGlobals")
```
