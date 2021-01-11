#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

pacman::p_load(pacman, ggplot2, stringr)



# test if there are enough arguments.
if (length(args)<=3) {
	stop("Not enough Arguments! \n Usage: Rscript qbuddy_IS.r [Sample_signal.csv] [calculated_results.csv] [calibration_output.csv], [Calibration_signal.csv]. \n Note that the last file (calibration signal) should have the name of the compound, and exactly the same name as in its corresponding row in the sample signal file (so that the program knows which row to use in that file) This is CASE SENSITIVE!", call.=FALSE)
}

#Read calibration data
calibration = read.csv(args[4], header=TRUE)

#Get compound name from the calibration file
compound_name <- (gsub("\\.csv", "", args[4]))

#########################################################
##Evaluate input and turn out errors if it is not correct


#Detects SignalIS and ConcIS strings in the header of the calibration. any() function returns true if any of the values in the vector created by str_detect() are true. Will remove NA values with na.rm. "(?i)SignalIS" would search case insensitive.
SIS <- any(str_detect(names(calibration), "SignalIS", negate = FALSE), na.rm = TRUE)
CIS <- any(str_detect(names(calibration), "ConcIS", negate = FALSE), na.rm = TRUE)

if (SIS) {
	if (CIS) {
		print("Found Everything! Hurray!!!!")

		} else {
			stop("SignalIS column found but not ConcIS. Are you tying to trick me? Please check your CSV! :)")
		}
} else if (CIS) {
	stop("ConcIS column found but not SignalIS. Are you trying to trick me? Please check your CSV! :)")
} else {
	stop("Found no Internal Standard record. Please use the qbuddy.r script instead of this one.")

}


###############################
######MAIN BODY################
#This will run Internal standard calculations if the CIS and SIS columns are present. Will do nothing otherwise.







calibration$adj_conc <- (calibration$Conc / calibration$ConcIS)
calibration$adj_signal <- (calibration$Signal / calibration$SignalIS)

calibration.lm <- lm(adj_signal ~ adj_conc, data = calibration)


intercept = coef(calibration.lm)[1]

slope = coef(calibration.lm)[2]

rsquared = summary(calibration.lm)$r.squared

res_standard_error <- sigma(calibration.lm)

ISConcentration <- calibration$ConcIS[1]

LOD <- ((3.3 * res_standard_error) / slope) * ISConcentration
LOQ <- ((10 * res_standard_error) / slope) * ISConcentration

merit <- c(slope, intercept, rsquared, LOD, LOQ)
merit <- round(merit, digits = 5) #Rounds all values to 5 decimal places


#open calibration results file
cal_results = read.csv(args[3], header=TRUE)

#Adds merit parameters to the data frame.
cal_results$temp_name <- merit

#Changes name to compound name
colnames(cal_results)[colnames(cal_results) == "temp_name"] <- compound_name

#writes to the output file specified
write.csv(cal_results, file = args[3], row.names = FALSE, quote = FALSE)





##############################################################
###########Make Nice Looking Plot and print to PDF#############

#Variables that place the formula in the plot according to the axis values
xplacement <- (min(calibration$adj_conc) + ((max(calibration$adj_conc) - min(calibration$adj_conc))/2)) * (3/4) #The last value is a fraction so that you can adjust to your liking

yplacement <- max(calibration$adj_signal) - ((min(calibration$adj_signal) + ((max(calibration$adj_signal) - min(calibration$adj_signal))/2)) * (1/16))

#Make the plot
calibration.plot<-ggplot(data = calibration, aes(x=adj_conc, y=adj_signal))+ geom_point()

calibration.plot <- calibration.plot + labs(title = compound_name, caption = "https://github.com/JBrinco/Quantification-Buddy", x = "Adjusted Concentration", y = "Adjusted Signal")

calibration.plot <- calibration.plot + geom_smooth(method="lm", col="black")

lm_eqn <- function(calibration){
 #   m <- lm(Signal ~ Conc, data = calibration);
    eq <- substitute(italic(Adj.Signal) == a + b %.% italic(Adj.Conc)*"  "~~italic(r)^2~"="~r2,
         list(a = format(unname(coef(calibration.lm)[1]), digits = 4),
              b = format(unname(coef(calibration.lm)[2]), digits = 4),
             r2 = format(summary(calibration.lm)$r.squared, digits = 3)))
    as.character(as.expression(eq));
}

calibration.plot <- calibration.plot + geom_text(x = xplacement, y = yplacement, label = lm_eqn(eq), parse = TRUE)

pdf_file_name <- gsub("\\.csv", "\\.pdf", args[4])

#Write to PDF!. Can also write to svg by replacing pdf() with svg(), and replacing .pdf with .svg above
pdf(pdf_file_name)

calibration.plot

dev.off()





####Calculation for Samples

samples = read.csv(args[1], header=TRUE)

#Change the name of the column with signal values in samples data frame to temporary name. The name of the column MUST BE the same as the one in the calibration file.
colnames(samples)[colnames(samples) == compound_name ] <- "temp_name"

#If SignalIS column is not present in sample file, return an error.
SamplesSignalIS <- any(str_detect(names(samples), "SignalIS", negate = FALSE), na.rm = TRUE)
if (! SamplesSignalIS) {
	stop("Did not find SignalIS column in your sample signal file. I am not able to calculate adjusted signals for your samples!")
}

#Calculate adjusted signal based on SampleIS from samples.
samples$adj_signal <- (samples$temp_name / samples$SignalIS)

#Calculates values and puts them in column temp_results
samples$temp_results <- (((samples$adj_signal - intercept) / slope) * samples$ConcIS)


#Read csv file which already has the other results
results = read.csv(args[2], header=TRUE)

#Make new column temp_name with sample results
results$temp_name <- round(samples$temp_results, digits = 5)

#Change the name of the new column to compound name (given in the calibration file)
colnames(results)[colnames(results) == "temp_name"] <- compound_name

write.csv(results, file = args[2], row.names = FALSE, quote = FALSE)
