library(randomForest)
library(pROC)
library(ggplot2)

# 1. Load and prepare data (with manual downsampling)
data <- read.csv("creditcard.csv")
data$Class <- as.factor(data$Class)

# Downsample majority class
set.seed(123)
fraud <- data[data$Class == "1", ]
legit <- data[data$Class == "0", ]
legit_down <- legit[sample(nrow(legit), nrow(fraud)), ]
balanced_data <- rbind(fraud, legit_down)

# 2. Split into train/test (80/20)
train_index <- sample(1:nrow(balanced_data), 0.8 * nrow(balanced_data))
train <- balanced_data[train_index, ]
test <- balanced_data[-train_index, ]

# 3. Train models
# Logistic Regression
logit_model <- glm(Class ~ V1 + V2 + V3 + Amount, 
                  data = train, 
                  family = binomial)

# Random Forest
rf_model <- randomForest(Class ~ V1 + V2 + V3 + Amount,
                        data = train,
                        ntree = 100)

# 4. Get predicted probabilities
test$logit_prob <- predict(logit_model, test, type = "response")
test$rf_prob <- predict(rf_model, test, type = "prob")[, "1"]

# 5. Generate ROC curves
roc_logit <- roc(test$Class, test$logit_prob)
roc_rf <- roc(test$Class, test$rf_prob)

# 6. Plot comparison
ggroc(list(Logistic = roc_logit, RandomForest = roc_rf)) +
  geom_line(size = 1.2) +
  labs(title = "ROC Curve Comparison",
       color = "Model") +
  theme_minimal() +
  scale_color_manual(values = c("#E69F00", "#56B4E9")) +
  geom_abline(slope = 1, intercept = 1, linetype = "dashed")

# 7. Print AUC values
cat("Logistic Regression AUC:", auc(roc_logit), "\n")
cat("Random Forest AUC:", auc(roc_rf), "\n")