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
  args[2] = "out.txt"
}

#Read calibration data
calibration = read.csv(args[1], header=TRUE)


#####Calculation

calibration.lm <- lm(Signal ~ Conc, data = calibration)

summary(calibration.lm)

###Make Nice Looking Plot

xplacement <- (min(calibration$Conc) + ((max(calibration$Conc) - min(calibration$Conc))/2)) * (1/2) #The last value is a fraction so that you can adjust to your liking
xplacement

yplacement <- max(calibration$Signal) - ((min(calibration$Signal) + ((max(calibration$Signal) - min(calibration$Signal))/2)) * (1/4))
yplacement

#yplacement <- (max(calibration$Signal)) + (median(calibration$Signal)/4)

#yplacement

calibration.plot<-ggplot(data = calibration, aes(x=Conc, y=Signal))+
                     geom_point()

calibration.plot <- calibration.plot + geom_smooth(method="lm", col="black")

#calibration.plot <- calibration.plot + stat_regline_equation(label.x = 3, label.y = 7)

lm_eqn <- function(calibration){
 #   m <- lm(Signal ~ Conc, data = calibration);
    eq <- substitute(italic(y) == a + b %.% italic(x)*"   "~~italic(r)^2~"="~r2,
         list(a = format(unname(coef(calibration.lm)[1]), digits = 4),
              b = format(unname(coef(calibration.lm)[2]), digits = 4),
             r2 = format(summary(calibration.lm)$r.squared, digits = 3)))
    as.character(as.expression(eq));
}

calibration.plot <- calibration.plot + geom_text(x = xplacement, y = yplacement, label = lm_eqn(eq), parse = TRUE)

calibration.plot
