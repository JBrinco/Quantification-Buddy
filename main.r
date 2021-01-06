#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

#On first run uncomment this line!
#install.packages('pacman', repos='http://cran.us.r-project.org')

pacman::p_load(pacman, ggplot2, dplyr, broom)

library(ggplot2)
library(dplyr)
library(broom)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else if (length(args)==1) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else{
# default output file
  args[3] = "out.txt"
}

#Read calibration data
calibration = read.csv(args[1], header=TRUE)

calibration

#####Calculation

calibration.lm <- lm(Signal ~ Conc, data = calibration)


intercept = coef(calibration.lm)[1]

slope = coef(calibration.lm)[2]



###########Make Nice Looking Plot#############

#Variables that place the formula in the plot according to the axis values
xplacement <- (min(calibration$Conc) + ((max(calibration$Conc) - min(calibration$Conc))/2)) * (3/4) #The last value is a fraction so that you can adjust to your liking
xplacement

yplacement <- max(calibration$Signal) - ((min(calibration$Signal) + ((max(calibration$Signal) - min(calibration$Signal))/2)) * (1/16))
yplacement

#Make the plot
calibration.plot<-ggplot(data = calibration, aes(x=Conc, y=Signal))+ geom_point()

calibration.plot <- calibration.plot + geom_smooth(method="lm", col="black")

lm_eqn <- function(calibration){
 #   m <- lm(Signal ~ Conc, data = calibration);
    eq <- substitute(italic(Signal) == a + b %.% italic(Conc)*"  "~~italic(r)^2~"="~r2,
         list(a = format(unname(coef(calibration.lm)[1]), digits = 4),
              b = format(unname(coef(calibration.lm)[2]), digits = 4),
             r2 = format(summary(calibration.lm)$r.squared, digits = 3)))
    as.character(as.expression(eq));
}

calibration.plot <- calibration.plot + geom_text(x = xplacement, y = yplacement, label = lm_eqn(eq), parse = TRUE)

calibration.plot #ADD Print to the name of the calibration file.svg!!!!!


####Calculation for Samples

samples = read.csv(args[2], header=TRUE)

#Calculates values and puts them in column ConcCalc
samples$ConcCalc <- (samples$Signal - intercept) / slope

sample

#Append values to a CSV with:
#Sample,[name equal to calibration csv name]
#That way you can run the script as many times as needed, and it will append only the line with the new values, and have just one CSV for all compounds.
