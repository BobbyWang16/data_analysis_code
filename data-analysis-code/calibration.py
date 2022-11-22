#导入数据集
import pandas as pd

col_names1 = ['grade','RAD', 'age','smoke','best_response']
col_names2 = ['grade','RAD','pathologic']

train1 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\ce_train.xlsx', sheet_name='Sheet2', header=None, names=col_names1)
test1 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\ce_test.xlsx', sheet_name='Sheet2', header=None, names=col_names1)
val1 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\ce_val.xlsx', sheet_name='Sheet2', header=None, names=col_names1)

train2 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\nce_train.xlsx', sheet_name='Sheet2', header=None, names=col_names2)
test2 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\nce_test.xlsx', sheet_name='Sheet2', header=None, names=col_names2)
val2 = pd.read_excel(r'C:\Users\21332\Desktop\ALTN\nce_val.xlsx', sheet_name='Sheet2', header=None, names=col_names2)

#数据处理-赋值
#feature_cols1 = ['RAD', 'age','smoke','best_response']
#feature_cols2 = ['RAD','pathologic']
feature_cols1 = ['RAD']
feature_cols2 = ['RAD']

X_train1=train1[feature_cols1]
X_test1=test1[feature_cols1]
X_val1=val1[feature_cols1]

X_train2=train2[feature_cols2]
X_test2=test2[feature_cols2]
X_val2=val2[feature_cols2]

y_train1=train1.grade
y_test1=test1.grade
y_val1=val1.grade

y_train2=train2.grade
y_test2=test2.grade
y_val2=val2.grade

#验证集的回归模型
from sklearn.linear_model import LogisticRegression
logreg_model1 = LogisticRegression(solver= 'newton-cg').fit(X=X_train1,y=y_train1)
logreg_model2 = LogisticRegression(solver= 'newton-cg').fit(X=X_train2,y=y_train2)

y_pred1 = logreg_model1.predict_proba(X_test1)
y_pred2 = logreg_model1.predict_proba(X_val1)
y_pred3 = logreg_model2.predict_proba(X_test2)
y_pred4 = logreg_model2.predict_proba(X_val2)

#内部验证集的calibration
from sklearn.calibration import calibration_curve
logreg_y11, logreg_x11 = calibration_curve(y_test1, y_pred1[:,1], n_bins=10)
logreg_y12, logreg_x12 = calibration_curve(y_test2, y_pred3[:,1], n_bins=10)

#外部验证集的calibration
from sklearn.calibration import calibration_curve
logreg_y21, logreg_x21 = calibration_curve(y_val1, y_pred2[:,1], n_bins=10)
logreg_y22, logreg_x22 = calibration_curve(y_val2, y_pred4[:,1], n_bins=10)

#画训练集的图
# matplotlib inline
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.transforms as transforms

fig, ax = plt.subplots()
# only these two lines are calibration curves

plt.plot(logreg_x11,logreg_y11, marker='o', linewidth=1, label='CE-CT')
plt.plot(logreg_x12,logreg_y12, marker='o', linewidth=1, label='NCE-CT')

#plt.plot(rf_x, rf_y, marker='o', linewidth=1, label='rf')

# reference line, legends, and axis labels
line = mlines.Line2D([0, 1], [0, 1], color='black')
transform = ax.transAxes
line.set_transforms(transform)
ax.add_line(line)
fig.suptitle('Internal validation cohort-Calibration plot')
ax.set_xlabel('Predicted probability')
ax.set_ylabel('Acute probability')
plt.legend()
plt.savefig('calibration plot2.jpg')
plt.show()


fig1, ax1 = plt.subplots()
# only these two lines are calibration curves

plt.plot(logreg_x21,logreg_y21, marker='o', linewidth=1, label='CE-CT')
plt.plot(logreg_x22,logreg_y22, marker='o', linewidth=1, label='NCE-CT')

#plt.plot(rf_x, rf_y, marker='o', linewidth=1, label='rf')

# reference line, legends, and axis labels
line1 = mlines.Line2D([0, 1], [0, 1], color='black')
transform1 = ax1.transAxes
line1.set_transforms(transform1)
ax1.add_line(line1)
fig1.suptitle('External validation cohort-Calibration plot')
ax1.set_xlabel('Predicted probability')
ax1.set_ylabel('Acute probability')
plt.legend()
plt.savefig('calibration plot3.jpg')
plt.show()