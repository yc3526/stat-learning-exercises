library(tree)
library(ISLR)
attach(Carseats)

# Turns Sales into binary 
High = ifelse(Sales <= 8, "No", "Yes")
Carseats = data.frame(Carseats, High)

# Classification tree
tree.carseats = tree(High~.-Sales, data=Carseats)
summary(tree.carseats)
plot(tree.carseats)
text(tree.carseats, pretty=0) 
tree.carseats

# Validation
set.seed(2)
train = sample(1:nrow(Carseats), 200)
Carseats.test = Carseats[-train, ]
High.test = High[-train]
tree.carseats = tree(High~.-Sales, data=Carseats, subset=train)
tree.pred = predict(tree.carseats, Carseats.test, type="class")
table(tree.pred, High.test)
(86+57)/200

# Pruning the tree
set.seed(3)
cv.carseats = cv.tree(tree.carseats, FUN=prune.misclass)
names(cv.carseats)
cv.carseats
par(mfrow=c(1, 2))
plot(cv.carseats$size, cv.carseats$dev, type="b")
plot(cv.carseats$k, cv.carseats$dev, type="b")
prune.carseats = prune.misclass(tree.carseats, best=9)
plot(prune.carseats)
text(prune.carseats, pretty=0)
tree.pred = predict(prune.carseats, Carseats.test, type="class")
table(tree.pred, High.test)
(94+60)/200

# Fitting regression tree
library(MASS)
set.seed(1)
train = sample(1:nrow(Boston), nrow(Boston)/2)
tree.boston = tree(medv~., Boston, subset=train)
summary(tree.boston)
plot(tree.boston)
text(tree.boston, pretty=0)
cv.boston = cv.tree(tree.boston)
plot(cv.boston$size, cv.boston$dev, type="b")
# Best tree is unpruned
tree.pred = predict(tree.boston, Boston[-train, ])
boston.test = Boston[-train, "medv"]
plot(tree.pred, boston.test)
abline(0, 1)
mean((boston.test - tree.pred)^2)

# Bagging and Random Forest
# mtry=p gives Bagging, mtry < p gives Random Forest
library(randomForest)
set.seed(1)
bag.boston = randomForest(medv~., data=Boston, subset=train, mtry=6, importance=T)
bag.boston
bag.pred = predict(bag.boston, Boston[-train, ])
plot(bag.pred, boston.test)
abline(0, 1)
mean((boston.test - bag.pred)^2)
varImpPlot(bag.boston)
importance(bag.boston)

# Boosting
library(gbm)
?gbm
boost.boston = gbm(medv~., data=Boston[train, ], distribution="gaussian", n.trees=5000, 
                   interaction.depth=4, shrinkage=0.2, verbose=T)
summary(boost.boston)
par(mfrow=c(1, 2))
plot(boost.boston, i="rm")
plot(boost.boston, i="lstat")
boost.pred = predict(boost.boston, Boston[-train, ], n.trees=5000)
mean((boston.test - boost.pred)^2)