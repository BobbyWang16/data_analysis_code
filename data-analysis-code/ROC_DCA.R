
rm(list = ls())#清空环境数据
setwd("C:/Users/21332/Desktop/ALTN")

library(ggplot2);
library(Hmisc);
library(MASS)
library(rms);
library(generalhoslem);
library(pROC)
library(grid); 
library(lattice);
library(Formula);
library(ResourceSelection)
library(readxl)

data<-read_excel("C:/Users/21332/Desktop/ALTN/ce_train.xlsx", sheet=1,col_names = TRUE)
data$name=NULL
attach(data)

#查看数据并构建模型

head(data)
mod <- glm(grade~RAD+gender+age+smoke+ECOG+meta+meta_brain+meta_liver+meta_bone+pathologic+treatment_line+best_response
          , data = data, family=binomial())
summary(mod)

#为诺莫图设置特定的环境
dd=datadist(data)
options(datadist="dd") 
ddist <- datadist(data)
options(datadist='ddist')
# generalhoslem



#1.构建模型
logistic.lrm <- lrm(grade~RAD+age+smoke+best_response, data = data)
summary(logistic.lrm )



#2. Nomogram
nom.full <- nomogram(logistic.lrm, fun=plogis,lp=F, funlabel="Likelihood of SF (%)")
plot(nom.full)

#组学模型：训练集及外部验证集
rm(list = ls())#清空环境数据
train<-read_excel("C:/Users/21332/Desktop/ALTN/ce_train.xlsx", sheet=1,col_names = TRUE)
#train$grade<-as.factor(train$grade)#grade代表分组变量名
test<-read_excel("C:/Users/21332/Desktop/ALTN/ce_test.xlsx", sheet=1,col_names = TRUE)
#test$grade<-as.factor(test$grade)
vadiation<-read_excel("C:/Users/21332/Desktop/ALTN/ce_val.xlsx", sheet=1,col_names = TRUE)
#vadiation$grade<-as.factor(test$grade)
#基于训练集构建模型并预测

mod1 <- glm(grade~RAD, data = train, 
            family=binomial())
#summary(mod1)
predict1 <- predict(mod1,train,type = c("response"))
predict2 <- predict(mod1,test,type = c("response"))
predict3 <- predict(mod1,vadiation,type = c("response"))
#获得logistic数据表格
#write.csv(predict1,'predict1.csv')
print(predict3)
#write.csv(predict2,'predict2.csv')


#计算AUC值
roccurve1 <- roc(mod1$y ~ predict1)
auc(roccurve1)
roccurve2 <- roc(test$grade ~ predict2)
auc(roccurve2)
roccurve3 <- roc(vadiation$grade~ predict3)
auc(roccurve3)

#绘制ROC曲线（含95%CI）
thr1.obj <- ci.thresholds(roccurve1)
roc4 <- plot.roc(mod1$y ~ predict1,
     ci=TRUE,print.auc=TRUE,
     print.auc.x=0.4,print.auc.y=0.4,
     auc.polygon=TRUE,
     auc.polygon.col="white",
     print.thres=TRUE,main="NCE-RAD-clinical",col="blue",
     legacy.axes=TRUE)
#grid可以给图像增加边线，若需要的话可以直接加在曲线中
#grid=c(0.5,0.2)   grid.col=c("black","black"),

thr2.obj <- ci.thresholds(roccurve2)
plot.roc(test$grade ~ predict2,add=TRUE,col="red",
         ci=TRUE,print.thres = FALSE,print.auc = TRUE,
         print.auc.x=0.4,print.auc.y = 0.35)

thr3.obj <- ci.thresholds(roccurve3)
plot.roc(vadiation$grade ~ predict3,add=TRUE,col="orange",
         ci=TRUE,print.thres = FALSE,print.auc = TRUE,
         print.auc.x=0.4,print.auc.y = 0.3)
#4.DCA曲线绘制,用的是广泛线性模型

#install.packages("rmda")
library(rmda)

simple<- decision_curve(grade~RAD+age+smoke+best_response,data= train,
                        #family = binomial(link ='logit'),
                        thresholds= seq(0,1, by = 0.01),
                        confidence.intervals = 0.95,
                        study.design = 'case-control', population.prevalence = 0.7)

complex<- decision_curve(grade~RAD+age+smoke+best_response,data= test,
                         #family = binomial(link ='logit'),
                         thresholds= seq(0,1, by = 0.01),
                         confidence.intervals = 0.95,
                         study.design = 'case-control', population.prevalence = 0.7)

complex1<- decision_curve(grade~RAD+age+smoke+best_response,data= vadiation,
                         #family = binomial(link ='logit'),
                         thresholds= seq(0,1, by = 0.01),
                         confidence.intervals = 0.95,
                         study.design = 'case-control', population.prevalence = 0.7)
#如需画两条的DCA，List<- list(simple,complex)，如果只画一条曲线，直接把List替换成simple或complex即可。#curve.names是出图时，图例上每条曲线的名字，书写顺序要跟上面合成list时一致。
#cost.benefit.axis是另外附加的一条横坐标轴，损失收益比，默认值是TRUE，所在不需要时要记得设为FALSE。col设置颜色。confidence.intervals设置是否画出曲线的置信区间，standardize设置是否对净受益率（NB）使用患病率进行校正。。

#训练集DCA
plot_decision_curve(simple,curve.names=c('Training set'),
                    cost.benefit.axis =FALSE,col= '#0066CC',
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#内部验证集DCA
plot_decision_curve(complex,curve.names=c('Internal Validation set'),
                    cost.benefit.axis =FALSE,col= '#FF0000',
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#外部验证集DCA
plot_decision_curve(complex1,curve.names=c('External Validation set'),
                    cost.benefit.axis =FALSE,col= "orange",
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#训练集+验证集在同一张图中
model_all <- list(simple,complex,complex1)
plot_decision_curve(model_all,curve.names=c('Training set','Internal Training set','External Validation set'),
                    cost.benefit.axis =FALSE,col=c("blue","red","orange"),
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")

#ModEvA的使用
library(modEvA)
plotGLM(model = mod1)
AUC(model = mod1)
THRE1<-threshMeasures(model = mod1, thresh = 0.5,col= '#FF0000')
THREP<-threshMeasures(model = mod1, thresh = "preval",col= '#FF0000')
optiT<-optiThresh(model = mod1, measures = c("CCR", "Sensitivity", "kappa", "TSS"), 
                  ylim = c(0, 1))
OPTI<-optiPair(model = mod1, measures = c("Sensitivity", "Specificity"))

