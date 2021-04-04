import seaborn as sns
import matplotlib.pyplot as plt
from scipy import stats

tips = sns.load_dataset("tips")

# get coeffs of linear fit
slope, intercept, r_value, p_value, std_err = stats.linregress(tips['total_bill'],tips['tip'])

# use line_kws to set line label for legend
ax = sns.regplot(x="total_bill", y="tip", data=tips, color='b',
 line_kws={'label':"y={0:.1f}x+{1:.1f}".format(slope,intercept)})

# plot legend
ax.legend()

plt.show()


##OR


 import pandas as pd
 import seaborn as sns
 import matplotlib.pyplot as plt

df = pd.read_excel('data.xlsx')
# assume some random columns called EAV and PAV in your DataFrame
# assume a third variable used for grouping called "Mammal" which will be used for color coding
p = sns.lmplot(x=EAV, y=PAV,
        data=df, hue='Mammal',
        line_kws={'label':"Linear Reg"}, legend=True)

ax = p.axes[0, 0]
ax.legend()
leg = ax.get_legend()
L_labels = leg.get_texts()
# assuming you computed r_squared which is the coefficient of determination somewhere else
slope, intercept, r_value, p_value, std_err = stats.linregress(df['EAV'],df['PAV'])
label_line_1 = r'$y={0:.1f}x+{1:.1f}'.format(slope,intercept)
label_line_2 = r'$R^2:{0:.2f}$'.format(0.21) # as an exampple or whatever you want[!
L_labels[0].set_text(label_line_1)
L_labels[1].set_text(label_line_2)
