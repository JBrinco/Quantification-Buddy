import argparse
import sys
import os

import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
from matplotlib.backends.backend_pdf import PdfPages



#Argument Parsing default='out.csv',
parser = argparse.ArgumentParser()
parser.add_argument("CalibrationCSV", help="The csv file with calibration curve data")
parser.add_argument("SampleCSV", help="The csv with sample values")
parser.add_argument("-o", "--output", type=str, help="The name of the output file for the sample results")
parser.add_argument("-p", "--print", type=str, help="An optional output file for the merit parameters")
parser.add_argument("-i", "--int_standard", help="Use this option if your calibration has an internal standard", action="store_true")
parser.add_argument("-f", "--force", help="Force the script to overwrite any previous files with the same name (like the output file)", action="store_true")
parser.add_argument("-v", "--verbose", help="Verbose output, showing all calculated values and internal variables", action="store_true")
args = parser.parse_args()


cal = pd.read_csv(args.CalibrationCSV)
samples = pd.read_csv(args.SampleCSV)
results = pd.DataFrame()

# print(list(cal.columns))

################PARSER###################

#WRITE FOR THE SAMPLE SIGNAL FILE!

#Parse the file header and find compound names!
index = 0
compounds = []
concIS_index = None
signalIS_index = None
conc_index = None
#Stores the position of each necessary column, and the names of the analytes. Also stores any other columns present!!!
for column in list(cal.columns):
    if column == "ConcIS":
        concIS_index = index
    elif column == "SignalIS":
        signalIS_index = index
    elif column == "Conc":
        conc_index = index
    else:
        compounds.append(column)
    index += 1


#If the int_standard option is set, but it can't find one of the needed columns
if args.int_standard and concIS_index == None:
    print ("I can't find the ConcIS column in your calibration data!")
    sys.exit()
if args.int_standard and signalIS_index == None:
    print ("I can't find the SignalIS column in your calibration data!")
    sys.exit()
if conc_index == None:
    print ("I can't find the Conc column in your calibration data!")
    sys.exit()
if len(compounds) == 0:
    print("There are no compound signal columns in your calibration file! What's going on?")
    sys.exit()


if args.verbose:
    print("I have found the following compounds:\n")
    for comp in compounds:
        print(comp)
    print("\nWARNING: If any of these is not a compound, it might be causing an error. Please remove that column from your calibration file!")





##################CALIBRATION AND CALCULATION#########################

#Calibration loop if internal standard option is set
if args.int_standard:
    cal['AdjustedConc'] = cal['Conc'] / cal['ConcIS']
    results["Sample"] = samples["Sample"]

    for analyte in compounds: #Per analyte found in the parser above, run the calibration steps
        string = analyte + "Adj" #Set a name for the adjusted signal column
        cal[string] = cal[analyte] / cal['SignalIS']
        slope, intercept, rvalue, pvalue, stderr = stats.linregress(cal['AdjustedConc'],cal[string]) #stats.linregress returns an object with these atributes: slope, intercept, rvalue, pvalue, stderr and intercept_stderr. I could also pull them one by one.
        r2 = rvalue * rvalue
        ConcIS = float(cal.at[1, 'ConcIS'])
        LOD = ((3.3 * stderr) / slope) * ConcIS
        LOQ = ((10 * stderr) / slope) * ConcIS

        if args.verbose:
            print('\n---------------------\n' + analyte + '\n---------------------\n')
            print("Model parameters:\n")
            print("Slope: " + str(format(slope, '.5f')))
            print("Intercept: " + str(format(intercept, '.5f')))
            print("Coeficient of determination: " + str(format(r2, '.5f')))
            print("Limit of Detection: " + str(format(LOD, '.5f')))
            print("Limit of Quantification: " + str(format(LOQ, '0.5f')))

        #Calculate the sample signal!
        results[analyte] = (((samples[analyte] / samples['SignalIS']) - intercept) / slope) * samples['ConcIS']


        #Optional calculate residuals





else:
    y = cal['Signal']
    x = cal[['Conc']]
    x = sm.add_constant(x)
    x = sm.add_constant(x)
    model = sm.OLS(y, x).fit()
    print(analyte + '\n')
    # print(model.summary())
    print(list(model.params))
    print(model.rsquared)
    print(model)
    plt.scatter(cal.Conc, cal.Signal,  color='black')
    plt.title('Adjusted Values')
    plt.xlabel('Adjusted Concentration')
    plt.ylabel('Adjusted Signal')
    plt.show()

print('\n\n---------------------\n  Results  \n---------------------\n')
print(results)


##################OUTPUT WRITING TO FILE###########################

if args.output:
    if os.path.isfile(args.output) and not args.force:
        print("\nThe output file name you gave already exists! Please delete it or run with the -f option to overwrite the existent file")
        sys.exit()
    results.to_csv(args.output)
    print("\nOutput written to: " + args.output)
else:
    if not os.path.isfile('qbuddy-output.csv'):
        results.to_csv('qbuddy-output.csv')
        print("\nOutput written to: qbuddy-output.csv")
    else:
        print("\nThe file \"qbuddy-output.csv\" already exists and you did not specify an output file name. No output written.")
