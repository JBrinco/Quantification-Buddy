#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

#On first run uncomment this line!
#install.packages('pacman', repos='http://cran.us.r-project.org')

pacman::p_load(pacman, ggplot2, dplyr, broom, ggpubr)


print(args)
