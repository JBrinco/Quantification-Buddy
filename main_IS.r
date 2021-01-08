#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

#On first run uncomment this line!
#install.packages('pacman', repos='http://cran.us.r-project.org')

pacman::p_load(pacman, ggplot2, dplyr, broom, stringr)

library(ggplot2) ###Ver quais sao redundantes
library(dplyr)
library(broom)
library(stringr)


# test if there are enough arguments.
if (length(args)==0) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else if (length(args)==1) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [calibration_data.csv] [Sample_signal_data.csv] [(OPTIONAL)output_file.csv]", call.=FALSE)
} else if (length(args)==2){
# default output file
 args[3] = "output.csv"
print("No output file given. Defaulting to 'output.csv'")
}

#Read calibration data
calibration = read.csv(args[1], header=TRUE)


#########################################################
##Evaluate input and turn out errors if it is not correct


#Detects SignalIS and ConcIS strings in the header of the calibration. any() function returns true if any of the values in the vector created by str_detect() are true. Will remove NA values with na.rm.
SIS <- any(str_detect(names(calibration), "(?i)SignalIS", negate = FALSE), na.rm = TRUE)
CIS <- any(str_detect(names(calibration), "(?i)ConcIS", negate = FALSE), na.rm = TRUE)

if (SIS) {
	if (CIS) {
		print("Found Everything! Hurray!!!!")

		} else {
		stop("SignalIS column found but not ConcIS. Are you tying to trick me? Check your CSV!!!")
		}
} else if (CIS) {
	stop("ConcIS column found but not SignalIS. Are you trying to trick me? Check your CSV!!!")
} else {
	stop("Found no Internal Standard record. Please use the qbuddy.r script instead of this one.")

}


###############################
######MAIN BODY################
#This will run Internal standard calculations if the CIS and SIS columns are present. Will do nothing otherwise.







#calibration$adj_conc <- (calibration$Conc / calibration$ConcIS)

calibration.lm <- lm(Signal ~ Conc, data = calibration)


intercept = coef(calibration.lm)[1]

slope = coef(calibration.lm)[2]





##############################################################
###########Make Nice Looking Plot and print to PDF#############

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

pdf_file_name <- gsub("\\.csv", "\\.pdf", args[1])
pdf_file_name

#Write to PDF!. Can also write to svg by replacing pdf() with svg(), and replacing .pdf with .svg above
pdf(pdf_file_name)

calibration.plot

dev.off()






####Calculation for Samples

samples = read.csv(args[2], header=TRUE)

#Get compound name from the calibration file
compound_name <- (gsub("\\.csv", "", args[1]))


#Change the name of the column with signal values in samples data frame to temporary name. The name of the column MUST BE the same as the one in the calibration file.
colnames(samples)[colnames(samples) == compound_name ] <- "temp_name_new"

#Calculates values and puts them in column temp_name
samples$temp_name <- (samples$temp_name_new - intercept) / slope
samples


#Read csv file which already has the other results
results = read.csv(args[3], header=TRUE)
results

#Make new column temp_name with calibration values
results$temp_name <- samples$temp_name
results

#Change the name of the new column to compound name (given in the calibration file)
colnames(results)[colnames(results) == "temp_name"] <- compound_name
results

write.csv(results, file = args[3], row.names = FALSE, quote = FALSE)
