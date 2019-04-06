# Test that a file can be created
context("create_file")

# A file is created
initiate_file()

# Test
expect_true(file.exists("R/zzz_global_variables.R"))

# Cleanup
file.remove(paste0(rprojroot::find_rstudio_root_file(), "/R/zzz_global_variables.R"))
