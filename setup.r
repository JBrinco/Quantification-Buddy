#!/usr/bin/env Rscript

install.packages('pacman', repos='http://cran.us.r-project.org')

pacman::p_load(pacman, ggplot2, dplyr, optparse, broom)

library(ggplot2)
library(dplyr)
library(broom)
library(optparse)
