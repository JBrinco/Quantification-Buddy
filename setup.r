#!/usr/bin/env Rscript

install.packages('pacman', repos='http://cran.us.r-project.org')

pacman::p_load(pacman, ggplot2, dplyr, argparse, broom)
