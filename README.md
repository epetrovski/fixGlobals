
# fixGlobals <img src="man/figures/logo.png" align ="right" height="180" />

A helper tool to avoid R CMD check notes for “no visible binding for
global variable” due to the use of Non Standard Evaluation (NSE) to
refer to columns in a data frame like R object. Data transformation
packages like `data.table` and `dplyr` use NSE.

`fixGlobals` maintains the input to the function
`utils::globalVariables()` located in “R/zzz\_global\_variables.R”.
`utils::globalVariables()` ensures that R CMD check notes do not occur
for objects it has been provided the name of.

## Initiate zzz\_global\_variables.R

If the file “R/zzz\_global\_variables.R” does not already exist, it can
be created with `fixGlobals::initiate_file()`. By default, the content
of zzz\_global\_variables.R looks like
this:

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

## Add variables

It’s possible to maintain the character vector in globalVariables()
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

However, it’s cumbersome to maintain the character vector manually if
one makes extensive use of NSE. In stead,`fixGlobals::add_globalVars()`
is used to automatically add variable names to the vector.

In the example below, `data.table` is used to refer to several columns
in mtcars.

``` r
subset_cars <- function(mtcars) {
  dtcars <- as.data.table(mtcars)
  dtcars[, .(cyl, mpg, disp, hp, drat, carb)]
}
```

In this example R CMD check notes will be provided for `mpg, disp, hp,
drat, carb` if `devtools::check()` is executed. No note is provided for
`cyl` since this variable was provided manually to `globalVariables()`
earlier — see example above. However, if `fixGlobals::add_globalVars()`
is executed zzz\_global\_variables.R will be updated:

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
