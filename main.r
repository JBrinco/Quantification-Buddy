#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

#On first run uncomment this line!
#install.packages('pacman', repos='http://cran.us.r-project.org')

#pacman::p_load(pacman, ggplot2, dplyr, broom, ggpubr)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else if (length(args)==1) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else{
# default output file
  args[2] = "out.txt"
}

print(args)

calibration = read.csv(args[1], header=TRUE)

print(calibration)

#Calculation

summary(calibration)
