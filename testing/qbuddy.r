#!/usr/bin/env Rscript

#E-mail: j.brinco@campus.fct.unl.pt
#This program is Free Software! Under the GNU GPL v3 :)

#############OPTIONS#########################

InternalStandard <- TRUE #TRUE if you want to calculate with internal standard, FALSE otherwise.
CalculateRecovery <- TRUE #TRUE if you want to calculate recoveries instead of the normal operation.
	WriteRecovery <- TRUE #Will write the average and standard deviation of the recovery calculated into the Calibration file, to be used after. If set to FALSE, with display recovery values and write them to optional [Recovery_Output.csv] file.
UseRecovery <- FALSE #TRUE if you want to include recovery values when calculating sample values. WILL ONLY WORK IF YOU ALREADY CALCULATED THE RECOVERIES (see CalculatedRecovery).
Dilution <- FALSE #True if you want to use dilution factor in the calculation. Will look for "Dilution" column in sample signal file.




#############################################



#Get command line arguments
args = commandArgs(trailingOnly=TRUE)

#Load required packages
pacman::p_load(pacman, ggplot2, stringr)

# test if there are enough arguments.
if (! CalculateRecovery) {
 if (length(args)<=3) {
 	stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [Sample_signal.csv] [Calculated_results.csv] [Calibration_output.csv], [Calibration_signal.csv]. \n Note that the last file (calibration signal) should have the name of the compound, and exactly the same name as in its corresponding row in the sample signal file (so that the program knows which row to use in that file) This is CASE SENSITIVE! \n The file names can be whatever you like, just as long as you write them in the right order!", call.=FALSE)
 }
} else {
	if (length(args)<=1){
		stop("Not enough Arguments! \n Usage: Rscript qbuddy.r [Recovery_signal.csv] [Calibration_Signal.csv] [(OPTIONAL) Recovery_Output.csv] \n Note that the script will always look for the first two arguments. If you put the Recovery output in first or second place, you will get an error. \n If you want to calculate Sample values instead of recovery, set CalculateRecovery to FALSE. \n The file names can be whatever you like, just as long as you write them in the right order!", call.=FALSE)}
}


#Read calibration data and get compound name from calibration file
if (! CalculateRecovery) {
	calibration = read.csv(args[4], header=TRUE)
	compound_name <- (gsub("\\.csv", "", args[4]))
} else {
	calibration = read.csv(args[2], header=TRUE)
	compound_name <- (gsub("\\.csv", "", args[2]))
}



#Detects SignalIS and ConcIS strings in the header of the calibration. any() function returns true if any of the values in the vector created by str_detect() are true. Will remove NA values with na.rm. "(?i)SignalIS" would search case insensitive.
SIS <- any(str_detect(names(calibration), "SignalIS", negate = FALSE), na.rm = TRUE)
CIS <- any(str_detect(names(calibration), "ConcIS", negate = FALSE), na.rm = TRUE)

if (InternalStandard) {
if (SIS) {
	if (! CIS) {
		stop("SignalIS column found but not ConcIS. Are you tying to trick me? Please check your CSV! :)")
		}
} else if (CIS) {
	stop("ConcIS column found but not SignalIS. Are you trying to trick me? Please check your CSV! :)")
} else {
	stop("Found no Internal Standard record. Please set InternalStandard to FALSE.")}

}

if (! InternalStandard) {

	if (SIS && CIS) {
			print("Internal Standard data found. They Will be ignored! To use internal standards, set InternalStandard to TRUE.")
		}
}



#################################################
#########MAIN BODY FOR SAMPLE CALCULATION########


#Used when InternalStandard is set to TRUE
if (InternalStandard){

	#Generate adjusted values (Concentration divided by IS Concentration, etc)
	calibration$adj_conc <- (calibration$Conc / calibration$ConcIS)
	calibration$adj_signal <- (calibration$Signal / calibration$SignalIS)

	#Calibration
	calibration.lm <- lm(adj_signal ~ adj_conc, data = calibration)

	#Calculate merit parameters
	intercept = coef(calibration.lm)[1]
	slope = coef(calibration.lm)[2]
	rsquared = summary(calibration.lm)$r.squared
	res_standard_error <- sigma(calibration.lm)

	#Get internal standard concentration and calculate LOD and LOQ
	ISConcentration <- calibration$ConcIS[1]
	LOD <- ((3.3 * res_standard_error) / slope) * ISConcentration
	LOQ <- ((10 * res_standard_error) / slope) * ISConcentration


#Used when InternalStandard is set to FALSE
} else {

	#Calibration
	calibration.lm <- lm(Signal ~ Conc, data = calibration)

	#Calculate merit parameters
	intercept = coef(calibration.lm)[1]
	slope = coef(calibration.lm)[2]
	rsquared = summary(calibration.lm)$r.squared
	res_standard_error <- sigma(calibration.lm)

	#Calculate LOD and LOQ
	LOD <- ((3.3 * res_standard_error) / slope)
	LOQ <- ((10 * res_standard_error) / slope)
}

#####RECOVERY#################
#IF CalculateRecovery is set to TRUE, will run the recovery and exit

if (CalculateRecovery) {

	#Reads recovery data
	recovery = read.csv(args[1], header=TRUE)

	if (InternalStandard) {
		#Calculates adjusted spiked value for internal standard and concentration of spiked samples
		recovery$RealConcSpiked <- ((((recovery$SignalSpiked / recovery$SignalSpikedIS) - intercept) / slope) * recovery$ConcIS)

		#Tests if the signal is not zero (real sample spiked, will take it into account). Calculates adjusted value for non-spiked sample, calibrates, and calculates recovery value.
		if (recovery[1, "Signal"] != 0) {
			recovery$RealConc <- ((((recovery$Signal / recovery$SignalIS) - intercept) / slope) * recovery$ConcIS)
			recovery$Recovery <- ((recovery$RealConcSpiked - recovery$RealConc) / recovery$ConcSpiked)

		} else {
			recovery$Recovery <- (recovery$RealConcSpiked / recovery$ConcSpiked)
		}


	} else {
		recovery$RealConcSpiked <- ((recovery$SignalSpiked - intercept) / slope)

		if (recovery[1, "Signal"] != 0) {
			recovery$RealConc <- ((recovery$Signal - intercept) / slope)
			recovery$Recovery <- ((recovery$RealConcSpiked - recovery$RealConc) / recovery$ConcSpiked)

		} else {
			recovery$Recovery <- (recovery$RealConcSpiked / recovery$ConcSpiked)
			}
		}

		#Calculation of mean, standard deviation and percentage.

	#Calculates average and standard deviation of calculated recoveries and writes them to the calibration CSV
	if (WriteRecovery) {
		CalibrationWithRecovery <- read.csv(args[2], header=TRUE)
		CalibrationWithRecovery$RecoveryMean <- round(mean(recovery$Recovery), digits = 7)
		CalibrationWithRecovery$RecoverySD <- round(sd(recovery$Recovery), digits = 7)
		print(CalibrationWithRecovery)
		write.csv(CalibrationWithRecovery, file = args[2], row.names=FALSE, quote=FALSE)


	} else { #If WriteRecovery is set to FALSE, will output the recovery values to the terminal, and optionally to [Results_Output.csv] file.
		recovery$RecoveryPercent <- round((recovery$Recovery * 100), digits = 2)
		print("The recovery values (in %) are:")
		print(recovery$RecoveryPercent)

		#Write recovery value to optionally passed output file. If a third argument was passed, write the thing.
		if (! is.na(args[3])) {
			RecoveryResults = read.csv(args[3], header=TRUE)
			RecoveryResults$temp_name <- (recovery$RecoveryPercent)
			colnames(RecoveryResults)[colnames(RecoveryResults) == "temp_name"] <- compound_name
			write.csv(RecoveryResults, file = args[3], row.names = FALSE, quote = FALSE)

			}
	}
	quit ()
}




#Writes vector with merit parameters and rounds all values to 5 decimal places
merit <- c(slope, intercept, rsquared, LOD, LOQ)
merit <- round(merit, digits = 5)

#open calibration results file
cal_results = read.csv(args[3], header=TRUE)

#Adds merit parameters to the data frame.
cal_results$temp_name <- merit

#Changes name to compound name
colnames(cal_results)[colnames(cal_results) == "temp_name"] <- compound_name

#writes to the output file specified
write.csv(cal_results, file = args[3], row.names = FALSE, quote = FALSE)




###############################################################
###########Make Nice Looking Plot and print to PDF#############

#Variables are different with and withought Internal standard

if (InternalStandard){
	#Variables that place the formula in the plot according to the axis values
	xplacement <- (min(calibration$adj_conc) + ((max(calibration$adj_conc) - min(calibration$adj_conc))/2)) * (3/4) #The last value is a fraction so that you can adjust to your liking
	#Same as above
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

} else {
	#This code is very similar to the above, only slight changes. It will run if InternalStandard is set to FALSE

	xplacement <- (min(calibration$Conc) + ((max(calibration$Conc) - min(calibration$Conc))/2)) * (3/4)
	yplacement <- max(calibration$Signal) - ((min(calibration$Signal) + ((max(calibration$Signal) - min(calibration$Signal))/2)) * (1/16))

	calibration.plot<-ggplot(data = calibration, aes(x=Conc, y=Signal))+ geom_point()
	calibration.plot <- calibration.plot + labs(title = compound_name, caption = "https://github.com/JBrinco/Quantification-Buddy", x = "Concentration", y = "Signal")
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
}

#Get the name for pdf
pdf_file_name <- gsub("\\.csv", "\\.pdf", args[4])

#Write to PDF!. Can also write to svg by replacing pdf() with svg(), and replacing .pdf with .svg above
pdf(pdf_file_name)
calibration.plot
dev.off()




####Calculation for Samples###############

samples = read.csv(args[1], header=TRUE)

#Change the name of the column with signal values in samples data frame to temporary name. The name of the column MUST BE the same as the one in the calibration file.
colnames(samples)[colnames(samples) == compound_name ] <- "temp_name"

if (InternalStandard) {

	#If SignalIS column is not present in sample file, return an error. Separated into a variable for readability.
	SamplesSignalIS <- any(str_detect(names(samples), "SignalIS", negate = FALSE), na.rm = TRUE)
	if (! SamplesSignalIS) {
		stop("Did not find SignalIS column in your sample signal file. I am not able to calculate adjusted signals for your samples! Either add it, or set InternalStandard to FALSE, so that I can calculate stuff withought internal standards.")
	}

	#Calculate adjusted signal based on SampleIS from samples.
	samples$adj_signal <- (samples$temp_name / samples$SignalIS)

	#Calculates values and puts them in column temp_results
	samples$temp_results <- (((samples$adj_signal - intercept) / slope) * samples$ConcIS)
} else {

	#Calculates values withought IS and puts them in column temp_results
	samples$temp_results <- ((samples$Signal - intercept) / slope)
}

#Read csv file where all the results go
results = read.csv(args[2], header=TRUE)

#Make new column temp_name with sample results
results$temp_name <- round(samples$temp_results, digits = 5)

#Change the name of the new column to compound name (given in the calibration file)
colnames(results)[colnames(results) == "temp_name"] <- compound_name

write.csv(results, file = args[2], row.names = FALSE, quote = FALSE)
