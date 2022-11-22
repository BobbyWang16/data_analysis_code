library(readxl)
library(openxlsx)
library(stringr)
library(Matrix)
library(glmnet)
rm(list = ls())
setwd("C:/Users/liuli/Desktop/ALTN/")

data<-read_excel("RadiomicsENHANCER.xlsx", sheet=2,col_names = TRUE)
#<!-- 数据框仅保留特征和因变量,删除姓名和ID列 -->

names(data)=paste("V", 1:852, sep = "")


#因子变量赋值
data$V1<-as.factor(data$V1)

#创建新表，存储值
dat2<-data.frame(t1=as.character(1:3))
#起始列
Star<-2
#终止列
Over<-852

#进行批量T检验

#Mean,SD&P值计算
for ( i in c(Star:Over)){                       
  means<-tapply(data[[i]],data$V1,mean)
  means<-sprintf('5%.4f',round(means,4))  #小数点位数，注意'%.4f'和round()中的数字都要做对应修改
  SD<-tapply(data[[i]],data$V1,sd)
  SD<-sprintf('5%.4f',round(SD,4))       #小数点位数，注意'%.4f'和round()中的数字都要做对应修改
  M.t<-t.test(data[[i]]~V1,data=data,var.equal=T) 
  pvalue<-M.t[[3]]
  if(pvalue>0.1){
    a<-paste(means,'±',SD)
    a[3]<-'NS'
  }
  else if(pvalue>0.05){
    a<-paste(means,'±',SD)
    a[3]<-pvalue
  }
  else if(pvalue>0.01){
    a<-paste(means,'±',SD)
    a[3]<-'*'
  }
  else {
    a<-paste(means,'±',SD)
    a[3]<-'**'
  }
  dat2[i-(Star-1)]<-a
  names(dat2)[i-(Star-1)]<-names(data[,i])
}

#行列转置
dat3<-t(dat2)  

#导出检验结果
dat3<-as.data.frame(dat3)
write.xlsx(dat3,'CH_T_result.xlsx')


data<-read_excel("C:/Users/liuli/Desktop/ALTN/RadiomicsENHANCER.xlsx", sheet=2,col_names = TRUE)
#data$name=NULL
names(data)=paste("V", 1:459, sep = "")
data$V1<-factor(data$V1,levels = c(0,1),labels=c("low","high"))

set.seed(130)
ind<-sample(2,nrow(data),replace=TRUE,prob=c(0.8,0.2))
train<-data[ind==1,]
test<-data[ind==2,]
str(test)

write.xlsx(train,'trainCH28.xlsx')
write.xlsx(test,'testCH28.xlsx')
table(train$V1)
table(test$V1)

x<-data.matrix(train[,2:453])#特征起始列
y<-train[[1]]
newx<-data.matrix(test[,2:453])

library(glmnet)
lasso<-glmnet(x,y,family="binomial",alpha=1)
print(lasso)

plot(lasso,label=TRUE)
plot(lasso,xvar="lambda",label=TRUE)

set.seed(123)
lasso.cv=cv.glmnet(x,y,family="binomial",nfolds=10)
plot(lasso.cv)

lasso.cv$lambda.min
lasso.cv$lambda.1se


coef(lasso.cv,s="lambda.1se")

coef(lasso.cv,s="lambda.min")

