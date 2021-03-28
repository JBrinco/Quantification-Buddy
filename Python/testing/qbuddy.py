import argparse
import sys
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.api as sm
import argparse
from matplotlib.backends.backend_pdf import PdfPages



#Argument Parsing
parser = argparse.ArgumentParser()
parser.add_argument("CalibrationCSV", help="The csv file with calibration curve data")
parser.add_argument("SampleCSV", help="The csv with sample values")
parser.add_argument("-o" "--output", help="The name of the output file")
parser.add_argument("-i", "--int_standard", help="Use this option if your calibration has an internal standard", action="store_true")
args = parser.parse_args()

if args.int_standard:
    print("Calibrating with Internal Standard")


cal = pd.read_csv(args.CalibrationCSV)

print(list(cal.columns))

#Parse the file header and find compound names!
index = 0
compounds = []
concIS_index = None
signalIS_index = None
conc_index = None
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

print(concIS_index)
print(signalIS_index)
print(conc_index)
print(compounds)

if args.int_standard:
    cal['AdjustedConc'] = cal['Conc'] / cal['ConcIS']
    for analyte in compounds:
        string = analyte + "Adj"
        cal[string] = cal[analyte] / cal['SignalIS']
        plt.scatter(cal.AdjustedConc, cal[string],  color='black')
        plt.title(analyte + '(Adjusted)')
        plt.xlabel('Adjusted Concentration')
        plt.ylabel('Adjusted Signal')
        PdfPages(r'chart.pdf').savefig()
        #cal.boxplot(column=['AdjustedSignal'])
        plt.show()
        # plt.close()
        y = cal[string]
        # x = cal[['AdjustedConc']]
        # x = sm.add_constant(x)
        print(cal)

else:
    IS = False
    plt.scatter(cal.Conc, cal.Signal,  color='black')
    plt.title('Adjusted Values')
    plt.xlabel('Adjusted Concentration')
    plt.ylabel('Adjusted Signal')
    plt.show()
    y = cal['Signal']
    x = cal[['Conc']]
    x = sm.add_constant(x)

# model = sm.OLS(y, x).fit()
# print(model.summary())
# print(list(model.params))
# print(model.rsquared)
# cal.to_csv('out.csv')
