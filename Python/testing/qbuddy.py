import argparse
import sys
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.api as sm

cal_file_name = sys.argv[1]
cal = pd.read_csv(cal_file_name)

#Script must find the apropriate columns?
namelist = list(cal.columns)
print(namelist)

#Parse the file header and find compound names!
index = 0
compound = []
for column in namelist:
    if column == "ConcIS":
        concIS_index = index
    elif column == "SignalIS":
        signalIS_index = index
    elif column == "Conc":
        conc_index = index
    else:
        compound.append(column)
    index += 1
print(concIS_index)
print(compound)

#if 'ConcIS' and 'SignalIS' in namelist:
#    IS = True
#    cal['AdjustedConc'] = cal['Conc'] / cal['ConcIS']
#    cal['AdjustedSignal'] = cal['Signal'] / cal['SignalIS']
#    plt.scatter(cal.AdjustedConc, cal.AdjustedSignal,  color='black')
#    plt.title('Adjusted Values')
#    plt.xlabel('Adjusted Concentration')
#    plt.ylabel('Adjusted Signal')
#    #cal.boxplot(column=['AdjustedSignal'])
#    #plt.show()
#    y = cal['AdjustedSignal']
#    x = cal[['AdjustedConc']]
#    x = sm.add_constant(x)

#else:
#    IS = False
#    plt.scatter(cal.Conc, cal.Signal,  color='black')
#    plt.title('Adjusted Values')
#    plt.xlabel('Adjusted Concentration')
#    plt.ylabel('Adjusted Signal')
#    plt.show()
#    y = cal['Signal']
#    x = cal[['Conc']]
#    x = sm.add_constant(x)

#model = sm.OLS(y, x).fit()
#print(model.summary())
#print(list(model.params))
#print(model.rsquared)
#cal.to_csv('out.csv')
