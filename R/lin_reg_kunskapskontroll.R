#install.packages("corrplot")




library(readxl)
library(stringr)
library(car)


library(ggplot2)
library(tidyr)
library(dplyr)
library(corrplot) 
library(patchwork)


library(leaps)
library(MASS)
library(Metrics)
library(caret)
library(glmnet)

file_path <- "C:/Users/Hanss/Downloads/grupp_insamling_bildata.xlsx"

data <- read_excel(file_path)

dim(data)

str(data)

summary(data)

colnames(data)

bildata <- data[c("Försäljningspris", "Säljare", "Bränsle", "Växellåda", "Miltal",
                  "Modellår", "Biltyp", "Drivning",  "Hästkrafter (Hk)", "Färg", 
                  "Motorstorlek (cc)", "Modell")]

dim(bildata)
#View(bildata)

# check for missing values
missing_values <- is.na(bildata)
missing_counts <- colSums(missing_values)
print(missing_counts)

# el bilar har inte motor change, changing na to 0
el_cars <- subset(bildata, Bränsle == "El")
el_cars$`Motorstorlek (cc)` <- ifelse(is.na(el_cars$`Motorstorlek (cc)`), "0", 
                                      el_cars$`Motorstorlek (cc)`)
bildata[bildata$Bränsle == "El", ] <- el_cars

# Change "Hästkrafter (Hk)" and "Motorstorlek" to numeric variables

bildata$`Motorstorlek (cc)` <- as.numeric(str_extract(bildata$`Motorstorlek (cc)`, "\\d+"))
bildata$`Hästkrafter (Hk)` <- as.numeric(str_extract(bildata$`Hästkrafter (Hk)`, "\\d+"))

# Cleaning "Växellåda" and "Färg"
bildata <- bildata %>% mutate(Växellåda = gsub("\r\n", "", Växellåda))
bildata$Färg <- gsub("\\s*\\(.*", "", bildata$Färg)
bildata$Bränsle <- gsub("/", "_", bildata$Bränsle)
bildata$Modell <- gsub(" ", "_", bildata$Modell)



# change to english column names
colnames(bildata) <- c("Sales_Price", "Seller", "Fuel", "Gearbox", "Mileage", 
                       "Model_Year", "Car_Type", "Drivetrain", "Horsepower", 
                       "Color", "Motor_Size", "Model" )

# look for duplicates
duplicate_rows <- duplicated(bildata)
duplicate_data <- data[duplicate_rows, ]
#view(duplicate_data)

# get rid of duplicates
bildata_clean <- bildata %>% distinct()
dim(bildata_clean)
bildata<-bildata_clean

# Fill missing categorical data with constant values after investigation
bildata$Drivetrain <- ifelse(is.na(bildata$Drivetrain), "missing", 
                             bildata$Drivetrain)
bildata$Gearbox <- ifelse(is.na(bildata$Gearbox), "missing", bildata$Gearbox)
bildata$Car_Type <- ifelse(is.na(bildata$Car_Type), "unknown", bildata$Car_Type)
bildata$Color <- ifelse(is.na(bildata$Color), "missing", bildata$Color)
bildata$Model <- ifelse(is.na(bildata$Model), "missing", bildata$Model)



# still missing values, these rows are dropped because there are more than
# one column missing data and it is not possible to verify the data
missing_motor_data <-  bildata %>% filter(is.na(Motor_Size))
#view(missing_motor_data)

bildata <- bildata %>% filter(!is.na(Motor_Size))   

# changing categorical variables to nominal data
bildata$Fuel <- factor(bildata$Fuel)
bildata$Seller <- factor(bildata$Seller)
bildata$Drivetrain <- factor(bildata$Drivetrain)
bildata$Gearbox <- factor(bildata$Gearbox)
bildata$Color <- factor(bildata$Color)
bildata$Car_Type <- factor(bildata$Car_Type)

#------------------------------------------------------------------------------
# POC

poc_model <- lm(Sales_Price ~ Mileage + Model_Year, 
                data = bildata)

summary(poc_model)


# Plot diagnostics

par(mfrow = c(2, 2))
plot(poc_model, which = 1)
plot(poc_model, which = 2)
plot(poc_model, which = 3)
plot(poc_model, which = 5)


# Check for multicollinearity

vif(poc_model)

# Checking test error - used for reference later
aic_value <- AIC(poc_model)
bic_value <- BIC(poc_model)

print(paste("AIC:", aic_value))
print(paste("BIC:", bic_value))


#--------------------------------------------------------------------

# Exploring the data further



fuel_counts <- table(bildata$Fuel)
print(fuel_counts)
barplot(fuel_counts, main = "Fuel Counts", 
        xlab = "Fuel Type", ylab = "Frequency", col = palette())
tapply(bildata$Sales_Price, bildata$Fuel, summary)

gearbox_counts <- table(bildata$Gearbox)
print(gearbox_counts)
ggplot(bildata, aes(x = Gearbox, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Gearbox by Fuel Type",  
       x = "Gearbox",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Gearbox, summary)

gearbox_obs <- subset(bildata, Gearbox == "missing")
#view(gearbox_obs)
bildata <- bildata %>% filter(Gearbox != "missing")  
bildata$Gearbox <- factor(bildata$Gearbox)


drivetrain_counts <- table(bildata$Drivetrain)
print(drivetrain_counts)
ggplot(bildata, aes(x = Drivetrain, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Drivetrain by Fuel Type",  
       x = "Drivetrain",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Drivetrain, summary)

seller_counts <- table(bildata$Seller)
print(seller_counts)
ggplot(bildata, aes(x = Seller, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Seller by Fuel Type",  
       x = "Seller",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Seller, summary)

model_year_counts <- table(bildata$Model_Year)
print(model_year_counts)
ggplot(bildata, aes(x = Model_Year, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Model Year by Fuel Type",  
       x = "Model Year",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Model_Year, summary)

# Excluding older models with low representation that aren't environmental
# friendly cars
bildata <- bildata %>% filter(Model_Year >= 2000)
bildata <- bildata %>% filter(Model_Year <= 2024)



car_type_counts <- table(bildata$Car_Type)
print(car_type_counts)
ggplot(bildata, aes(x = Car_Type, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Car Type by Fuel Type",  
       x = "Car Type",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Car_Type, summary)

# These car types have too few observations and no real conclusion can be drawn.
car_type_obs <- subset(bildata, Car_Type == "Cab" | Car_Type == "Cab" | 
                       Car_Type == "Coupé" | Car_Type == "Familjebuss" |
                       Car_Type == "unknown")
#view(car_type_obs)
bildata <- subset(bildata, !(Car_Type %in% c("Cab", "Coupé", "Familjebuss", "unknown")))  #kom tillbaka gör till other?
bildata$Car_Type <- factor(bildata$Car_Type)


# A closer look att the different colors has the decision to combine colors has been made.
# There aren't many examples of light and dark colors and makes sense to combine to get
# a more general look at the effect of color on sales price.

bildata$Color[bildata$Color %in% c("Ljusblå", "Mörkblå")] <- "Blå"
bildata$Color[bildata$Color %in% c("Ljusbrun", "Mörkbrun")] <- "Brun"
bildata$Color[bildata$Color %in% c("Ljusgrå", "Mörkgrå")] <- "Grå"
bildata$Color[bildata$Color %in% c("Ljusgrön", "Mörkgrön")] <- "Grön"
bildata$Color <- factor(bildata$Color)

color_counts <- table(bildata$Color)
print(color_counts)

custom_colors <- c("Blå" = "blue", "Brun" = "brown", "Grå" = "darkgrey", "Grön" = "green", 
                  "Gul" = "yellow", "Röd" = "red", "Silver" = "lightgrey", 
                  "Svart"= "black", "Vit"="white")

color_counts_df <- data.frame(Color = names(color_counts), Frequency = as.numeric(color_counts))
ggplot(bildata, aes(x = Color, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Color by Fuel Type",  
       x = "Color",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  
tapply(bildata$Sales_Price, bildata$Color, summary)


model_counts <- table(bildata$Model)
print(model_counts)
ggplot(bildata, aes(x = Model, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Model by Fuel Type",  
       x = "Model",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
tapply(bildata$Sales_Price, bildata$Model, summary)


# Investigating the numeric variables       
# signs of on linear relationships
plot_horsepower <- ggplot(data=bildata, aes(x=(Horsepower), y=Sales_Price)) + 
  geom_point(stat="identity", color="blue") + 
  geom_smooth(se = FALSE)
tapply(bildata$Sales_Price, bildata$Horsepower, summary)


plot_mileage <- ggplot(data=bildata, aes(x=Mileage, y=Sales_Price)) +
  geom_point(stat="identity", color="blue") +
  geom_smooth(se = FALSE)



plot_model_year <- ggplot(data=bildata, aes(x=Model_Year, y=Sales_Price)) +
  geom_point(stat="identity", color="blue") +
  geom_smooth(se = FALSE)
tapply(bildata$Sales_Price, bildata$Model_Year, summary)


plot_horsepower + plot_mileage + plot_model_year + plot_layout(ncol = 1)


# Histograms for all numeric variables
numeric_cols <- bildata %>% select_if(is.numeric)
numeric_cols %>% 
  gather(key, value) %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 30, fill = "purple") +
  facet_wrap(~ key, scales = "free") +
  labs(title = "Histogram of Numeric Variables") +
  theme_minimal()

# Extra för rapporten
hist(bildata$Sales_Price, 
     main = "Volvo Sales Prices Across All Models",
     xlab = "Sales Price", ylab = "Frequency",
     col = "Blue", border = "black")


# Boxplots for numeric variables (Horsepower, Mileage, Motor_size, Sales_Price)

ggplot(bildata, aes(x = Fuel, y = Sales_Price, fill = Fuel)) +
  geom_boxplot() +
  labs(title = "Boxplot of Sales Price")
  

ggplot(bildata, aes(x = Fuel, y = Horsepower, fill = Fuel)) +
  geom_boxplot() +
  labs(title = "Boxplot of Horsepower") 


ggplot(bildata, aes(x = Fuel, y = Motor_Size, fill = Fuel)) +
  geom_boxplot() +
  labs(title = "Boxplot of Motor Size")

ggplot(bildata, aes(x = "", y = Mileage, fill = Fuel)) +
  geom_boxplot() +
  labs(title = "Boxplot of Mileage") +
  facet_wrap(~ Fuel)


# ----------------------------------------------------------------------------

# Closer look at outliers

#sp_outliers <- boxplot.stats(bildata$Sales_Price)$out
#sp_outliers_indices <- which(bildata$Sales_Price %in% sp_outliers)
#sp_outliers_data <- bildata[sp_outliers_indices, ]
#view(sp_outliers_data)

#summary(sp_outliers_data)
# This data point is taken out, new car for 2025 and only one of its kind
# bildata <- bildata[-sp_outliers_indices, ]
# Changing to filtering by year automatically took away this outlier


mileage_outliers <- boxplot.stats(bildata$Mileage)$out
mileage_outliers_indices <- which(bildata$Mileage %in% mileage_outliers)
mileage_outliers_data <- bildata[mileage_outliers_indices, ]
view(mileage_outliers_data)

summary(mileage_outliers_data)

# This data point is taken out because newer car with unusally high mileage
# Pris: 290 000 Mileage: 190 724 Year: 2020

bildata <- bildata[-mileage_outliers_indices[4], ]

# This data point is taken out because it is an older car with unusally low mileage
# Pris: 27 000 Mileage: 46 200 Year: 2007

bildata <- bildata[-mileage_outliers_indices[5], ]


#hp_outliers <- boxplot.stats(bildata$Horsepower)$out
#hp_outliers_indices <- which(bildata$Horsepower %in% hp_outliers)
#hp_outliers_data <- bildata[hp_outliers_indices, ]
#view(hp_outliers_data)
# aren't any
#------------------------------------------------------------------------------
# Looking into correlations

numeric_data <- bildata %>% select_if(is.numeric)
correlations <- cor(numeric_data)
corrplot(correlations, method= "number")
pairs(numeric_data)

#------------------------------------------------------------------------------
# Looking how individual variables effect Sales Price
#------------------------------------------------------------------------------


# 1. Seller
seller <- lm(Sales_Price ~ Seller, data = train_set)
ss <- summary(seller)
confint(seller)

var_results_df <- data.frame(
  Model = "seller",
  RMSE = sqrt(mean(ss$residuals^2)),
  R_squared = ss$r.squared,
  Adj_R_squared = ss$adj.r.squared,
  stringsAsFactors = FALSE
)


# 2. Fuel
fuel <- lm(Sales_Price ~ Fuel, data = train_set)
fs <- summary(fuel)
confint(fuel)
par(mfrow = c(2, 2))
plot(fuel)
BIC(fuel)
AIC(fuel)

new_var_df <- data.frame(
  Model = "fuel",
  RMSE = sqrt(mean(fs$residuals^2)),
  R_squared = fs$r.squared,
  Adj_R_squared = fs$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)




# 3. Gearbox
gearbox <- lm(Sales_Price ~ Gearbox, data = train_set)
gs <- summary(gearbox)

new_var_df <- data.frame(
  Model = "gearbox",
  RMSE = sqrt(mean(gs$residuals^2)),
  R_squared = gs$r.squared,
  Adj_R_squared = gs$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)

# 4. Mileage
mileage <- lm(Sales_Price ~ Mileage, data = train_set)
ms <- summary(mileage)
confint(mileage)
par(mfrow = c(2, 2))
plot(mileage)
BIC(mileage)
AIC(mileage)

new_var_df <- data.frame(
  Model = "mileage",
  RMSE = sqrt(mean(ms$residuals^2)),
  R_squared = ms$r.squared,
  Adj_R_squared = ms$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)


# 5. Model Year
model_year <- lm((Sales_Price) ~ Model_Year, data=train_set)
mys <- summary(model_year)
confint(model_year)
par(mfrow = c(2, 2))
plot(model_year)
BIC(model_year)
AIC(model_year)

new_var_df <- data.frame(
  Model = "model year",
  RMSE = sqrt(mean(mys$residuals^2)),
  R_squared = mys$r.squared,
  Adj_R_squared = mys$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)

# 6. Car Type
car_type <- lm(Sales_Price ~ Car_Type, data=train_set)
cts <- summary(car_type)
confint(car_type)
par(mfrow = c(2, 2))
plot(car_type)
BIC(car_type)
AIC(car_type)

new_var_df <- data.frame(
  Model = "car type",
  RMSE = sqrt(mean(cts$residuals^2)),
  R_squared = cts$r.squared,
  Adj_R_squared = cts$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)

# 7. Drivetrain
drivetrain <- lm(Sales_Price ~ Drivetrain, data=train_set)
ds <- summary(drivetrain)


new_var_df <- data.frame(
  Model = "drivetrain",
  RMSE = sqrt(mean(ds$residuals^2)),
  R_squared = ds$r.squared,
  Adj_R_squared = ds$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)

# 8.Horsepower
horsepower <- lm(Sales_Price ~ Horsepower, data=train_set)
hs <- summary(horsepower)
confint(horsepower)
par(mfrow = c(2, 2))
plot(horsepower)
BIC(horsepower)
AIC(horsepower)


new_var_df <- data.frame(
  Model = "horsepower",
  RMSE = sqrt(mean(hs$residuals^2)),
  R_squared = hs$r.squared,
  Adj_R_squared = hs$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)
# 9. Color
color <- lm(Sales_Price ~ Color, data=train_set)
cs <- summary(color)



new_var_df <- data.frame(
  Model = "color",
  RMSE = sqrt(mean(cs$residuals^2)),
  R_squared = cs$r.squared,
  Adj_R_squared = cs$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)
# 10. Motor size
motor_size <- lm(Sales_Price ~ Motor_Size, data=train_set)
mtrs <- summary(motor_size)


new_var_df <- data.frame(
  Model = "motorsize",
  RMSE = sqrt(mean(mtrs$residuals^2)),
  R_squared = mtrs$r.squared,
  Adj_R_squared = mtrs$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df)


# 11. Model
model <- lm(Sales_Price ~ Model, data=train_set)
sm <- summary(model)

new_var_df <- data.frame(
  Model = "model",
  RMSE = sqrt(mean(sm$residuals^2)),
  R_squared = sm$r.squared,
  Adj_R_squared = sm$adj.r.squared,
  stringsAsFactors = FALSE
)

var_results_df <- rbind(var_results_df, new_var_df) 

view(var_results_df)
#------------------------------------------------------------------------------
# Looking at variable interaction/effects
# ----------------------------------------------------------------------------

# 1. Model Year and Fuel
#---------------------------------
# Insight on deprecation rates by analyzing the model year and its impact on 
# price based on fuel type.  

ggplot(bildata, aes(x = Fuel, fill = factor(Model_Year))) +
  geom_bar(position = "dodge") +
  labs(title = "Grouped Bar Plot of Model Year by Fuel")

ggplot(bildata, aes(x = Model_Year, y = Sales_Price, color = Fuel)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ Fuel)


interaction1 <- lm(sqrt(Sales_Price) ~ Model_Year * Fuel, data = train_set)
par(mfrow=c(2,2))
plot(interaction1)

summary_interaction <-summary(interaction1)
vif(interaction1)

rsq_sqrt <- summary(interaction1)$r.squared
rmse_sqrt <- sqrt(mean(interaction1$residuals^2))


results_df <- data.frame(
  Model = "Model_Year * Fuel",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary_interaction$adj.r.squared,
  Transformer = "sqrt"
)



# Significant model (p < 2.2e-16).
# High R-squared (0.92) but check for multicollinearity.
# VIF: Extremely high for Fuel and interaction terms - multicollinearity!

#----------------------------------------------------------------------------------
# 2. Mileage and Fuel
#------------------------------
# Analyze relationship between mileage, fuel type, and sales price.

ggplot(bildata, aes(x = Mileage, y = (Sales_Price), color = Fuel)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Sales Price vs Mileage by Fuel Type")

# looked at both * and +
# * determines the depreciation rate for the different fuel types
# 
interaction2 <- lm((Sales_Price) ~ Mileage + Fuel, data = train_set)
summary_interaction<-summary(interaction2)

plot(interaction2)

vif(interaction2)
rsq_sqrt <- summary(interaction2)$r.squared
rmse_sqrt <- sqrt(mean(interaction2$residuals^2))

print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))


ggplot(bildata, aes(x = Mileage, y = Sales_Price)) +
  geom_point(aes(color = Fuel)) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ Fuel)

new_results <- data.frame(
  Model = "Mileage + Fuel",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary_interaction$adj.r.squared,
  Transformer = "none"
)
results_df <- rbind(results_df, new_results)

# Mileage has a significant negative impact on sales price (higher mileage = lower price).
# not too many high mileage el cars

#--------------------------------------------------------------------
# Feature engineering Mileage Depreciation Rate per Fuel type

# Calculate depreciation rate by fuel type
# seperate dataframes for fuel type then calculating depreciation rate
fuel_groups <- split(bildata, bildata$Fuel)

# notera that spliting the data are farther down in the code
depreciation_rates <- lapply(fuel_groups, function(group) {
  FT <- lm(Sales_Price ~ Mileage, data = group)
  return(coef(FT)[2])
})
# Create a data frame with fuel types and depreciation rates
depreciation_df <- data.frame(Fuel = names(fuel_groups), 
                              Depreciation_Rate = depreciation_rates, 
                              row.names = NULL)



max_year <- max(train_set$Model_Year, na.rm = TRUE)
train_set$Car_Age <- max_year - train_set$Model_Year
test_set$Car_Age <- max_year - test_set$Model_Year


train_set$Depreciation_Rate <- depreciation_factors[train_set$Fuel]
test_set$Depreciation_Rate <- depreciation_factors[test_set$Fuel]


train_set$Depreciation_Rate <- train_set$Depreciation_Rate * train_set$Car_Age
test_set$Depreciation_Rate <- test_set$Depreciation_Rate * test_set$Car_Age


train_set$Mileage_Depreciation_Rate <- train_set$Mileage * train_set$Depreciation_Rate
test_set$Mileage_Depreciation_Rate <- test_set$Mileage * test_set$Depreciation_Rate


FE_model1 <- lm(Sales_Price ~ Mileage_Depreciation_Rate + Mileage, data = train_set)
summary(FE_model1)



summary(FE_model1)
plot(FE_model1)
vif(FE_model1, type="predictor")
confint(FE_model1)



# High multicollinearity Mileage and Fuel. Feature engineering?
# Both Mileage and Mileage_Depreciation_Rate have significant negative 
# impacts on sales price (p-value < 0.001). This confirms that higher mileage 
# and a faster depreciation rate are associated with lower sales prices.
# The model explains a substantial portion of the variance in sales price 
# (adjusted R-squared = 0.74). The VIF values for both features are identical 
# (around 5.4), indicating high multicollinearity. This can make it difficult
# to interpret the individual coefficients reliably


#-----------------------------------------------------------------------------
# 3. Mileage and Model Year
#------------------------
# To see how the depreciation of eco-friendly cars compares with that of other 
# cars as they age and accumulate mileage.

ggplot(data=bildata, aes(x=Model_Year, y=Mileage, color = Fuel)) +
  geom_point() +
  geom_smooth(se = FALSE)

ggplot(data=bildata, aes(x=Model_Year, y=Mileage, color=Fuel)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE, aes(group=Fuel)) +
  facet_wrap(~Fuel)

interaction3 <- lm(sqrt(Sales_Price) ~ Mileage * Model_Year, data = train_set)
summary(interaction3)

plot(interaction3)
vif(interaction3)

rsq_sqrt <- summary(interaction3)$r.squared
rmse_sqrt <- sqrt(mean(interaction3$residuals^2))

print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

new_results <- data.frame(
  Model = "Mileage * Model Year",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction3)$adj.r.squared,
  Transformer = "sqrt"
  )
results_df <- rbind(results_df, new_results)

# All coefficients (Intercept, Mileage, Model_Year, and the interaction) are 
# statistically significant (p-value < 2.2e-16) based on the t-values.
# The model has a very high R-squared value (0.9247) and adjusted R-squared 
# (0.9243), indicating it explains a large portion of the variance in the 
# square root of sales price.
# OBS Multicolinearity!

#------------------------------------------------------------------------------
# 4. Horsepower and Fuel
#--------------------------------------
# Analyzing the relationship between fuel type and horsepower can provide 
# insights into how engine power impacts vehicle prices, considering fuel
# usage differences. 

interaction4 <- lm(sqrt(Sales_Price) ~ Horsepower * Fuel, data = train_set)
summary(interaction4)

plot(interaction4)
vif(interaction4)

rsq_sqrt <- summary(interaction4)$r.squared
rmse_sqrt <- sqrt(mean(interaction4$residuals^2))

print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))


ggplot(bildata, aes(x = Fuel, y = Horsepower, fill = Fuel)) +
  geom_violin() +
  theme_minimal() +
  labs(title = "Violin Plot of Horsepower by Fuel Type")

ggplot(bildata, aes(x = Horsepower, y = Sales_Price, color = Fuel)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ Fuel) +
  theme_minimal() +
  labs(title = "Sales Price by Horsepower for Each Fuel Type")


new_results <- data.frame(
  Model = "Horsepower * Fuel",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction4)$adj.r.squared,
  Transformer = "sqrt",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# Horsepower increases, sales price increases
# The electric cars (El) have a particularly high positive coefficient, 
# suggesting that they tend to have higher sales prices compared to the base 
# category (which could be petrol if Bensin is petrol and is the omitted 
# category due to the dummy variable encoding). The interaction between 
# Horsepower and Fuel_El is highly significant and negative. This could 
# indicate that the positive relationship between horsepower and sales price 
# is less pronounced for electric cars. This makes sense given electric cars 
# do not follow the traditional horsepower metric used for combustion engines.
# High multicollinerity Horsepower and Fuel.



# -----------------------------------------------------------------------------

# 5. Fuel Type and Motor Size: 
#-----------------------------------
# To understand how the engine size impacts the pricing of eco-friendly cars 
# compared to traditional fuel cars.


interaction5 <- lm(Sales_Price ~ Fuel * Motor_Size, data = train_set)
summary(interaction5)
plot(interaction5)
vif(interaction5)
vif(interaction5, type="predict")

rsq_sqrt <- summary(interaction5)$r.squared
rmse_sqrt <- sqrt(mean(interaction5$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

ggplot(bildata, aes(x = Motor_Size, y = Sales_Price, color = Fuel)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ Fuel) +
  theme_minimal() +
  labs(title = "Sales Price by Motor Size for Each Fuel Type")

new_results <- data.frame(
  Model = "Fuel * Motor Size",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction5)$adj.r.squared,
  Transformer = "none",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# RMSE is very large which means poor fit, There are bands in the plot which 
# implies that motor size should be a qualitative variable. Electric cars do not
# have motor size and one can say that it isn't relevant for the model. Decision
# made to no include motor size.

#------------------------------------------------------------------------------
# 6. Fuel type and Seller
#----------------------------------
# Provide insights into how different types of sellers influence the pricing 
# of cars based on their fuel type. 

ggplot(bildata, aes(x = Sales_Price, fill = Fuel)) +
  geom_histogram(position = "dodge") +
  facet_wrap(~ Fuel) +
  theme_minimal() +
  labs(title = "Histogram of Sales Price by Fuel Type", 
       x = "Sales Price", y = "Frequency")

ggplot(bildata, aes(x = Seller, y = Sales_Price, fill = Fuel)) +
  geom_bar(stat = "identity") +  
  facet_wrap(~ Fuel) +
  theme_minimal() +
  labs(title = "Bar Plot of Sales Price by Seller for Each Fuel Type", 
       y = "Sales Price")

interaction6 <- lm((Sales_Price) ~ Fuel * Seller, data = train_set)
summary(interaction6)

par(mfrow=c(2,2))
plot(interaction6)
vif(interaction6)

rsq_sqrt <- summary(interaction6)$r.squared
rmse_sqrt <- sqrt(mean(interaction6$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

new_results <- data.frame(
  Model = "Seller * Fuel",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction6)$adj.r.squared,
  Transformer = "none",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# Multicollineraity 8.2 between Fuel and Seller.
# The significance of the coefficients suggests that both Fuel and Seller, 
# impact Sales_Price to varying degrees. 


#------------------------------------------------------------------------------

# 7. Drivetrain and Gearbox
#-----------------------------------
# This interaction might reveal if certain combinations are more preferable 
# or valuable for environmentally friendly cars. 

interaction7 <- lm(sqrt(Sales_Price) ~ Gearbox * Drivetrain, data = train_set)
summary(interaction7)
plot(interaction7)
vif(interaction7)


rsq_sqrt <- summary(interaction7)$r.squared
rmse_sqrt <- sqrt(mean(interaction7$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

ggplot(bildata, aes(x = Drivetrain, y = Sales_Price, fill = Gearbox)) +
  geom_bar(stat = "summary", fun = "mean", position = "dodge") +
  theme_minimal() +
  labs(title = "Sales Price by Drivetrain and Gearbox", 
       x = "Drivetrain", y = "Sales Price", fill = "Gearbox")


new_results <- data.frame(
  Model = "Drivetrain * Gearbox",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction7)$adj.r.squared,
  Transformer = "sqrt",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# Gearbox-Manuell och Drivetrain-Tvåhjulsdriven have significant negative 
# coefficents which indicates the manuell och two-wheel drive tends to have 
# a lower price. If the car has a manuell does not effect if it will be a  
# two-wheel drive or four-wheel drive.

#-----------------------------------------------------------------------------

# 8. Car Type and Color: 
#-----------------------------------
# Some studies suggest color preferences might vary by vehicle type. This
# interaction could show if such preferences impact enviormently friendly
# cars differently.

interaction8 <- lm((Sales_Price) ~ Car_Type * Color, data = train_set)
summary(interaction8)
plot(interaction8)
vif(interaction8)


rsq_sqrt <- summary(interaction8)$r.squared
rmse_sqrt <- sqrt(mean(interaction8$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

ggplot(bildata, aes(x = Car_Type, y = Sales_Price, fill = Color)) +
  geom_bar(stat = "summary", fun = "mean", position = "dodge") +
  theme_minimal() +
  labs(title = "Sales Price by Drivetrain and Gearbox", 
       x = "Car_Type", y = "Sales Price", fill = "Color")

new_results <- data.frame(
  Model = "Car Type * Color",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction8)$adj.r.squared,
  Transformer = "none",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# Multicollinearity , inte så significant

#-----------------------------------------------------------------------------

# 9. Gearbox and Mileage: 
#-----------------------------------
# This interaction could show if the type of gearbox in eco-friendly cars
# affects how mileage impacts the car’s value.


interaction9 <- lm(sqrt(Sales_Price) ~ Gearbox * Mileage, data = train_set)
summary(interaction9)
par(mfrow=c(2,2))
plot(interaction9)
vif(interaction9)

rsq_sqrt <- summary(interaction9)$r.squared
rmse_sqrt <- sqrt(mean(interaction9$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))


ggplot(bildata, aes(x = Mileage, y = Sales_Price, color = Gearbox)) +
  geom_point(position = position_dodge(width = 0.5)) +
  theme_minimal() +
  labs(title = "Sales Price by Gearbox and Mileage", 
       x = "Mileage", y = "Sales Price", color = "Gearbox")


new_results <- data.frame(
  Model = "Gearbox * Mileage",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction9)$adj.r.squared,
  Transformer = "sqrt",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)



# Cars with automatic gearboxes generally have higher sales prices compared to 
# manual cars. Sales price tends to decrease with increasing mileage, with 
# this effect being more pronounced for manual cars. The negative coefficient 
# for the "GearboxManuell" variable suggests that manual cars have lower 
# sales prices than automatic cars. The negative coefficient for "Mileage" 
# confirms that as mileage increases, sales prices decrease. The positive and 
# significant interaction term "GearboxManuell:Mileage" indicates that the 
# negative impact of mileage on sales prices is less for manual cars compared 
# to automatic ones. Electric cars all automatic, so already have higher price



#------------------------------------------------------------------------------

# 10. Fuel Type and Car type: 
#---------------------------------------

# Important for understanding how the combination of fuel type and car type 
# design influences pricing for eco-friendly cars.

interaction10 <- lm((Sales_Price) ~ Fuel * Car_Type, data = train_set)
summary(interaction10)
par(mfrow=c(2,2))
plot(interaction10)
vif(interaction10)

rsq_sqrt <- summary(interaction10)$r.squared
rmse_sqrt <- sqrt(mean(interaction10$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))


ggplot(bildata, aes(x = Car_Type, y = Sales_Price, fill = Fuel)) +
  geom_bar(stat = "summary", fun = "mean", position = "dodge") +
  theme_minimal() +
  labs(title = "Sales Price by Drivetrain and Fuel",
       x = "Drivetrain", y = "Sales Price", fill = "Fuel")

ggplot(bildata, aes(x = Drivetrain, fill = Fuel)) +
  geom_bar(stat = "count") +  
  labs(title = "Distribution of Drivetrain by Fuel Type",  
       x = "Drivetrain",  
       y = "Number of Cars") +  
  facet_wrap(~ Fuel)  


new_results <- data.frame(
  Model = "Drivetrain * Fuel",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction6)$adj.r.squared,
  Transformer = "none",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# Two-wheel drive vehicles are associated with a lower sales price compared 
# to four-wheel drive vehicles. For El:Two-wheel and 
# Miljöbränsle_Hybrid: Two-wheel are significant. This suggests that the 
# difference in price between two-wheel and four-wheel drive vehicles is 
# notably different for electric and hybrid vehicles compared to the bensin.



#------------------------------------------------------------------------------

# 11. Fuel Type and Gearbox:
#----------------------------------------
# To analyze if certain drivetrains are more prevelant in different  
# acrossenviornmently -friendly market.


interaction11 <- lm((Sales_Price) ~ Fuel * Gearbox, data = bildata)
summary(interaction11)
par(mfrow=c(2,2))
plot(interaction11)
vif(interaction11, type="predictor")

rsq_sqrt <- summary(interaction11)$r.squared
rmse_sqrt <- sqrt(mean(interaction11$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))


ggplot(bildata, aes(x = Gearbox, y = Sales_Price, fill = Fuel)) +
  geom_bar(stat = "summary", fun = "mean", position = "dodge") +
  theme_minimal() +
  labs(title = "Sales Price by Drivetrain and Fuel",
       x = "Gearbox", y = "Sales Price", fill = "Fuel")

new_results <- data.frame(
  Model = "Fuel * Gearbox",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction6)$adj.r.squared,
  Transformer = "none",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

tapply(bildata$Sales_Price, bildata$Drivetrain, summary)





#------------------------------------------------------------------------------

# 12. Model Year and Horsepower: 
#----------------------------------------
# Examining if newer eco-friendly models with more horsepower are priced 
# differently. 

interaction12 <- lm(sqrt(Sales_Price) ~ Model_Year * Horsepower, data = bildata)
summary(interaction12)
par(mfrow=c(2,2))
plot(interaction12)
vif(interaction12)

rsq_sqrt <- summary(interaction12)$r.squared
rmse_sqrt <- sqrt(mean(interaction12$residuals^2))
print(paste("R squared: ", rsq_sqrt, "RMSE: ", rmse_sqrt))

ggplot(bildata, aes(x = Horsepower, y = Sales_Price, color = as.factor(Model_Year))) +
  geom_point(alpha = 0.6) + 
  theme_minimal() +
  labs(title = "Sales Price by Horsepower and Model Year",
       x = "Horsepower", y = "Sales Price", color = "Model Year")



ggplot(bildata, aes(x = Horsepower, y = Sales_Price, color = as.factor(Model_Year))) +
  geom_point(alpha = 0.6) + 
  facet_wrap(~ Fuel, scales = "free_y") +
  theme_minimal() +
  labs(title = "Sales Price by Horsepower and Model Year",
       x = "Horsepower", y = "Sales Price", color = "Model Year") 
 
new_results <- data.frame(
  Model = "Model Year * Horsepower",
  RMSE = rmse_sqrt,
  R_squared = rsq_sqrt,
  Adj_R_squared = summary(interaction6)$adj.r.squared,
  Transformer = "sqrt",
  stringsAsFactors = FALSE
)
results_df <- rbind(results_df, new_results)

# The interaction term between Model_Year and Horsepower is positive and 
# significant, suggesting that the impact of horsepower on the square root of 
# sales price increases with newer model years. The model explains a 
# substantial amount of variance, with an R-squared of 0.9359, which is very 
# high. The RMSE of approximately 54.61 suggests that the model's predictions
# are close to the actual data points when considering the square root 
# transformation.


#----------------------------------------------------------------------------
#  A side by side view of how some metrics look for the above interactions. 
# Notera några model har sqrt and some don't, it is not clea

view(results_df)




#-----------------------------------------------------------------------------

#Test Train Split

set.seed(42)
index <- createDataPartition(bildata$Sales_Price, p = 0.8, list = FALSE)
train_set <- bildata[index, ]
test_set <- bildata[-index, ]


#-----------------------------------------------------------------------------
# Testing a few models


model1 <- lm(sqrt(Sales_Price) ~ Mileage_Depreciation_Rate + Mileage + Horsepower 
             + Car_Type + Model_Year, data = train_set)

# Check the summary to understand the impact of each variable
summary(model1)


model1_summary <- summary(model1)

model1_adjr2 <- model1_summary$adj.r.squared
model1_bic <- BIC(model1)

predictions_model1 <- predict(model1, newdata = test_set)
predictions_model1_summary <- summary(predictions_model1)
actual_values <- test_set$Sales_Price
#Put RMSE back on original scale
model1_rmse <- sqrt(mean((actual_values - (predictions_model1^2))^2))


model1_vif <- vif(model1)

par(mfrow=c(2,2))
plot(model1)
confint(model1)

# Square the predictions to reverse the transformation
predictions_model1_original_scale <- predictions_model1^2  

# Plot Predicted vs Actual on the original scale for Model 1
plot(actual_values, predictions_model1_original_scale, 
     main = "Predicted vs Actual (Model 1)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")


# This model har a strong adjusted R^2 and a low RMSE. For perspective, 
# it's helpful to look at it as a percentage of the mean or median values:
# RMSE as a percentage of mean 41^2 / 286571 (from summary(data)) which is 0.59
# RMSE as a percentage of median 41^2 / 279900 (from summary(data)) which is 0.60
# = a percentage of mean=( 
# Despite this other models should be considered.



#-----------------------------------------------------------------------------
# Model 2 and 3


# Preparing data for foward and best selection
train_matrix <- model.matrix(Sales_Price ~ Model_Year + Car_Type + Mileage +
                               Seller + Color + Drivetrain + Fuel +
                               Gearbox + Horsepower + Model_Year*Mileage + Fuel*Mileage
                             + Model_Year * Fuel + Horsepower*Fuel, data = train_set)

test_matrix <- model.matrix(Sales_Price ~ Model_Year + Car_Type + Mileage +
                               Seller + Color + Drivetrain + Fuel +
                               Gearbox + Horsepower + Model_Year*Mileage + Fuel*Mileage
                             + Model_Year * Fuel + Horsepower*Fuel, data = test_set)



train_df <- data.frame(Sales_Price = train_set$Sales_Price, train_matrix)
test_df <- data.frame(Sales_Price = test_set$Sales_Price, test_matrix)


#-----------------------------------------------------------------------------

# Foward Selection Model 2

fwd_model <- regsubsets(train_matrix, train_set$Sales_Price,  
            wt=rep(1,length(train_set$Sales_Price)),  
            force.in=NULL,force.out=NULL,intercept=TRUE,
            nvmax=43, nbest=1, method="forward", warn.dep=TRUE)

summary(fwd_model)
plot(fwd_model)

plot(fwd_model_summary$bic, type = "l", col = "red", 
     xlab = "Number of Variables", 
     ylab = "BIC", 
     main = "BIC over Number of Variables")
points(which.min(fwd_model_summary$bic), min(fwd_model_summary$bic), 
       col = "blue", pch = 19)

plot(fwd_model_summary$cp, type = "l", col = "green", 
     xlab = "Number of Variables", 
     ylab = "Mallows' Cp", 
     main = "Cp over Number of Variables")
points(which.min(fwd_model_summary$cp), min(fwd_model_summary$cp), 
       col = "blue", pch = 19)

plot(fwd_model_summary$adjr2, type = "l", col = "blue", 
     xlab = "Number of Variables", 
     ylab = "Adjusted R-squared", 
     main = "Adjusted R-squared over Number of Variables")
points(which.max(fwd_model_summary$adjr2), max(fwd_model_summary$adjr2), 
       col = "red", pch = 19)


# Getting information for the model chosen by foward selection
fwd_model_summary <- summary(fwd_model)
best_model_index <- which.min(fwd_model_summary$bic)
best_model_coefs <- coef(fwd_model, id = best_model_index)
coefficient_names <- names(best_model_coefs)
coefficient_names <- coefficient_names[coefficient_names != "(Intercept)"]

model2_string <- paste("Sales_Price ~", paste(coefficient_names, collapse = " + "))

# Creating the best model chosen by foward selection
model2 <- lm(model2_string, data = train_df)  

model2_summary <- summary(model2)


model2_adjr2 <- model2_summary$adj.r.squared
model2_bic <- BIC(model2)

predictions_model2 <- predict(model2, newdata = test_df)
predictions_model2_summary <- summary(predictions_model2)
model2_rmse <- sqrt(mean((actual_values - predictions_model2)^2))

vif(model2, type="predictor")

par(mfrow=c(2,2))
plot(model2)

plot(predictions_model2, actual_values - predictions_model2, 
     xlab = "Predicted", 
     ylab = "Residuals", 
     main = "Residuals vs. Predicted")
abline(h = 0, col = "red")



#------------------------------------------------------------------------------

# Best subset selection


best_selection_model <- regsubsets(train_matrix, train_set$Sales_Price,  
                        wt=rep(1,length(train_set$Sales_Price)),  
                        force.in=NULL,force.out=NULL,intercept=TRUE,
                        nvmax=43, nbest=1, method="exhaustive", warn.dep=TRUE)

summary(best_selection_model)
plot(best_selection_model)



plot(best_selection_model_summary$bic, type = "l", col = "red", 
     xlab = "Number of Variables", 
     ylab = "BIC", 
     main = "BIC over Number of Variables")
points(which.min(best_selection_model_summary$bic), 
       min(best_selection_model_summary$bic), 
       col = "blue", pch = 19)

plot(best_selection_model_summary$cp, type = "l", col = "green", 
     xlab = "Number of Variables", 
     ylab = "Mallows' Cp", 
     main = "Cp over Number of Variables")
points(which.min(best_selection_model_summary$cp), 
       min(best_selection_model_summary$cp), 
       col = "blue", pch = 19)

plot(best_selection_model_summary$adjr2, type = "l", col = "blue", 
     xlab = "Number of Variables", 
     ylab = "Adjusted R-squared", 
     main = "Adjusted R-squared over Number of Variables")
points(which.max(best_selection_model_summary$adjr2), 
       max(best_selection_model_summary$adjr2), 
       col = "red", pch = 19)



# Getting information for the model chosen by foward selection
best_selection_model_summary <- summary(best_selection_model)
best_selection_index <- which.min(best_selection_model_summary$bic)
best_selection_coefs <- coef(best_selection_model, 
                             id = best_selection_index)
best_coefficient_names <- names(best_selection_coefs)
best_coefficient_names <- best_coefficient_names[best_coefficient_names 
                                                 != "(Intercept)"]


model3_string <- paste("Sales_Price ~", paste(best_coefficient_names, 
                                              collapse = " + "))

# Creating the best model chosen by best selection


model3 <- lm(model3_string, data = train_df)  

model3_summary <- summary(model3)

model3_adjr2 <- model3_summary$adj.r.squared
model3_bic <- BIC(model3)

predict_model3 <- predict(model3, newdata = test_df)
predict_model3_summary <- summary(predict_model3)
model3_rmse <- sqrt(mean((test_df$Sales_Price - predict(model3, 
                                                        newdata = test_df))^2))
vif(model3)

par(mfrow=c(2,2))
plot(model3)

plot(predict_model3, actual_values - predict_model3, 
     xlab = "Predicted", 
     ylab = "Residuals", 
     main = "Residuals vs. Predicted")
abline(h = 0, col = "red")




#------------------------------------------------------------------------------

# Ridge 



# Ridge on Fwd Selection (model 2) best model to make sure it isn't overfitting.
#----------------------------------------------------------------------------

# Preparing model 2 for ridge

model2_formula <- as.formula(model2_string)
print(model2_formula)


x_model2_train <- model.matrix(model2_formula, data = train_df)
x_model2_test <- model.matrix(model2_formula, data = test_df)

y_train <- train_set$Sales_Price
y_test <- test_set$Sales_Price


# Cross validation to find the best lambda

cv_ridge_model2 <- cv.glmnet(x_model2_train, y_train, alpha = 0, 
                             standardize = TRUE, type.measure = "mse", 
                             nfolds = 20)

bl_ridge2 <- cv_ridge_model2$lambda.min

plot(cv_ridge_model2, main = "Cross-validation Curve (Ridge Model 2)",
     xlab = "Lambda", ylab = "Mean Squared Error")

# Create Ridge for model 2 with the best lambda
ridge2 <- glmnet(x_model2_train, y_train, alpha = 0, 
                       lambda = bl_ridge2, standardize = TRUE)



predict_ridge2 <- predict(ridge2, s = bl_ridge2, newx = x_model2_test)


ridge2_rmse <- sqrt(mean((y_test - predict_ridge2)^2))



ridge2_nz_coefs <- sum(coef(ridge2, s = bl_ridge2) != 0) - 1


ridge2_rsquared <- 1 - sum((y_test - predict_ridge2)^2) / sum((y_test - mean(y_test))^2)



n <- length(y_test)  
ridge2_adjr2 <- 1 - ((1 - ridge2_rsquared) * (n - 1) / (n - ridge2_nz_coefs - 1))



k <- ridge2_nz_coefs + 1
rss <- sum((y_test - predict_ridge2)^2)
log_likelihood <- -n/2 * (log(2 * pi * rss / n) + 1)

ridge2_bic <- log(n) * k - 2 * log_likelihood


# Plots for evaluating the model

ridge2_residuals <- y_test - predict_ridge2

# Plot Residuals vs Fitted
plot(x = predict_ridge2, y = ridge2_residuals, 
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")


# Q-Q plot for residuals
qqnorm(ridge2_residuals)
qqline(ridge2_residuals, col = "red")


# Plot Scale-Location

ridge2_std_residuals <- rstandard(lm(y_test ~ predict_ridge2))

plot(predict_ridge2, sqrt(abs(ridge2_std_residuals)),
     xlab = "Fitted values", 
     ylab = "Sqrt of abs standardized residuals",
     main = "Scale-Location")
abline(h = mean(sqrt(abs(ridge2_std_residuals))), col = "red", lwd = 1)


# Plot Predicted vs Actual
plot(y_test, predict_ridge2, 
     main = "Predicted vs Actual (Ridge Model 2)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")  






#------------------------------------------------------------------------------

# Ridge on Best subselection (model 3) best model to handle multicollinearity. 

# Preparing model 3 for ridge

model3_formula <- as.formula(model3_string)
print(model3_formula)


x_model3_train <- model.matrix(model3_formula, data = train_df)
x_model3_test <- model.matrix(model3_formula, data = test_df)


# Cross validation to find the best lambda

cv_ridge_model3 <- cv.glmnet(x_model3_train, y_train, alpha = 0, 
                             standardize = TRUE, type.measure = "mse", 
                             nfolds = 20)

bl_ridge3 <- cv_ridge_model3$lambda.min

plot(cv_ridge_model3, main = "Cross-validation Curve (Ridge Model 3)",
     xlab = "Lambda", ylab = "Mean Squared Error")

# Create Ridge for model 2 with the best lambda
ridge3 <- glmnet(x_model3_train, y_train, alpha = 0, 
                 lambda = bl_ridge3, standardize = TRUE)



predict_ridge3 <- predict(ridge3, s = bl_ridge3, newx = x_model3_test)


ridge3_rmse <- sqrt(mean((y_test - predict_ridge3)^2))



ridge3_nz_coefs <- sum(coef(ridge3, s = bl_ridge3) != 0) - 1


ridge3_rsquared <- 1 - sum((y_test - predict_ridge3)^2) / sum((y_test - mean(y_test))^2)



n <- length(y_test)  
ridge3_adjr2 <- 1 - ((1 - ridge3_rsquared) * (n - 1) / (n - ridge3_nz_coefs - 1))



k <- ridge2_nz_coefs + 1
rss <- sum((y_test - predict_ridge3)^2)
log_likelihood <- -n/2 * (log(2 * pi * rss / n) + 1)

ridge3_bic <- log(n) * k - 2 * log_likelihood


# Plots for evaluating the model

ridge3_residuals <- y_test - predict_ridge3

# Plot Residuals vs Fitted
plot(x = predict_ridge3, y = ridge3_residuals, 
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")


# Q-Q plot for residuals
qqnorm(ridge3_residuals)
qqline(ridge3_residuals, col = "red")


# Plot Scale-Location
ridge3_std_residuals <- rstandard(lm(y_test ~ predict_ridge3))

plot(predict_ridge3, sqrt(abs(ridge3_std_residuals)),
     xlab = "Fitted values", 
     ylab = "Sqrt of abs standardized residuals",
     main = "Scale-Location")
abline(h = mean(sqrt(abs(ridge3_std_residuals))), col = "red", lwd = 1)


# Plot Predicted vs Actual
plot(y_test, predict_ridge3, 
     main = "Predicted vs Actual (Ridge Model 3)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")  





#-----------------------------------------------------------------------------
# Ridge on Intuitive (model 1) to handle multicollinearity

# Preparing model 1 for ridge
model1_formula <- as.formula(Sales_Price ~ Model_Year * Mileage + Horsepower + 
                               Car_Type + Gearbox + Fuel * Model_Year)


x_model1_train <- model.matrix(model1_formula, data = train_set)
x_model1_test <- model.matrix(model1_formula, data = test_set)


# Cross validation to find the best lambda

cv_ridge_model1 <- cv.glmnet(x_model1_train, y_train, alpha = 0, 
                             standardize = TRUE, type.measure = "mse", 
                             nfolds = 20)

bl_ridge1 <- cv_ridge_model1$lambda.min

plot(cv_ridge_model1, main = "Cross-validation Curve (Ridge Model 1)",
     xlab = "Lambda", ylab = "Mean Squared Error")

# Create Ridge for model 2 with the best lambda
ridge1 <- glmnet(x_model1_train, y_train, alpha = 0, 
                 lambda = bl_ridge1, standardize = TRUE)



predict_ridge1 <- predict(ridge1, s = bl_ridge1, newx = x_model1_test)


ridge1_rmse <- sqrt(mean((y_test - predict_ridge1)^2))



ridge1_nz_coefs <- sum(coef(ridge1, s = bl_ridge1) != 0) - 1


ridge1_rsquared <- 1 - sum((y_test - predict_ridge1)^2) / sum((y_test - mean(y_test))^2)



n <- length(y_test)  
ridge1_adjr2 <- 1 - ((1 - ridge1_rsquared) * (n - 1) / (n - ridge1_nz_coefs - 1))





rss <- sum((y_test - predict_ridge1)^2)
log_likelihood <- -n/2 * (log(2 * pi * rss / n) + 1)

ridge1_bic <- log(n) * k - 2 * log_likelihood


# Plots for evaluating the model

ridge1_residuals <- y_test - predict_ridge1

# Plot Residuals vs Fitted
plot(x = predict_ridge1, y = ridge1_residuals, 
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")


# Q-Q plot for residuals
qqnorm(ridge1_residuals)
qqline(ridge1_residuals, col = "red")


# Plot Scale-Location
ridge1_std_residuals <- rstandard(lm(y_test ~ predict_ridge1))

plot(predict_ridge1, sqrt(abs(ridge1_std_residuals)),
     xlab = "Fitted values", 
     ylab = "Sqrt of abs standardized residuals",
     main = "Scale-Location")
abline(h = mean(sqrt(abs(ridge1_std_residuals))), col = "red", lwd = 1)


# Plot Predicted vs Actual
plot(y_test, predict_ridge1, 
     main = "Predicted vs Actual (Ridge Model 1)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")  




#------------------------------------------------------------------------------
# Lasso

# Lasso on Intuitive (model 1) to handle multicollinearity

cv_lasso_model1 <- cv.glmnet(x_model1_train, y_train, alpha = 1, 
                             standardize = TRUE, type.measure = "mse", nfolds = 20)


lasso1_bl <- cv_lasso_model1$lambda.min


lasso1 <- glmnet(x_model1_train, y_train, alpha = 1, 
                       lambda = lasso1_bl, standardize = TRUE)


lasso1_predict <- predict(lasso1, s = lasso1_bl, 
                                   newx = x_model1_test)


lasso1_rmse <- sqrt(mean((y_test - lasso1_predict)^2))


predict_lasso1 <- predict(lasso1, s = lasso1_bl, newx = x_model1_test)


lasso1_rmse <- sqrt(mean((y_test - predict_lasso1)^2))


# Manually calculating the number of non-zero coefficients
lasso1_nz_coefs <- sum(coef(lasso1, s = lasso1_bl) != 0) - 1


lasso1_rsquared <- 1 - sum((y_test - predict_lasso1)^2) / sum((y_test - mean(y_test))^2)



n <- length(y_test)  
lasso1_adjr2 <- 1 - ((1 - lasso1_rsquared) * (n - 1) / (n - lasso1_nz_coefs - 1))




k <- ridge2_nz_coefs + 1
rss <- sum((y_test - predict_lasso1)^2)
log_likelihood <- -n/2 * (log(2 * pi * rss / n) + 1)

lasso1_bic <- log(n) * k - 2 * log_likelihood


# Plots for evaluating the model

lasso1_residuals <- y_test - predict_lasso1

# Plot Residuals vs Fitted
plot(x = predict_lasso1, y = lasso1_residuals, 
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")


# Q-Q plot for residuals
qqnorm(lasso1_residuals)
qqline(lasso1_residuals, col = "red")


# Plot Scale-Location
lasso1_std_residuals <- rstandard(lm(y_test ~ predict_lasso1))

plot(predict_lasso1, sqrt(abs(lasso1_std_residuals)),
     xlab = "Fitted values", 
     ylab = "Sqrt of abs standardized residuals",
     main = "Scale-Location")
abline(h = mean(sqrt(abs(lasso1_std_residuals))), col = "red", lwd = 1)


# Plot Predicted vs Actual
plot(y_test, predict_lasso1, 
     main = "Predicted vs Actual (Lasso Model 1)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")  




#-----------------------------------------------------------------------------

# Lasso on Best Selection model 3 to handle multicollinearity

cv_lasso_model3 <- cv.glmnet(x_model3_train, y_train, alpha = 1, 
                             standardize = TRUE, type.measure = "mse", nfolds = 20)


lasso3_bl <- cv_lasso_model3$lambda.min


lasso3 <- glmnet(x_model3_train, y_train, alpha = 1, 
                 lambda = lasso3_bl, standardize = TRUE)


lasso3_predict <- predict(lasso3, s = lasso3_bl, 
                          newx = x_model3_test)


lasso3_rmse <- sqrt(mean((y_test - lasso3_predict)^2))


predict_lasso3 <- predict(lasso3, s = lasso3_bl, newx = x_model3_test)


lasso3_rmse <- sqrt(mean((y_test - predict_lasso3)^2))



lasso3_nz_coefs <- sum(coef(lasso3, s = lasso3_bl) != 0) - 1


lasso3_rsquared <- 1 - sum((y_test - predict_lasso3)^2) / sum((y_test - mean(y_test))^2)



n <- length(y_test)  
lasso3_adjr2 <- 1 - ((1 - lasso3_rsquared) * (n - 1) / (n - lasso3_nz_coefs - 1))


k <- ridge2_nz_coefs + 1
rss <- sum((y_test - predict_lasso3)^2)
log_likelihood <- -n/2 * (log(2 * pi * rss / n) + 1)

lasso3_bic <- log(n) * k - 2 * log_likelihood


# Plots for evaluating the model

lasso3_residuals <- y_test - predict_lasso3

# Plot Residuals vs Fitted
plot(x = predict_lasso3, y = lasso3_residuals, 
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")


# Q-Q plot for residuals
qqnorm(lasso3_residuals)
qqline(lasso3_residuals, col = "red")


# Plot Scale-Location
lasso3_std_residuals <- rstandard(lm(y_test ~ predict_lasso3))

plot(predict_lasso3, sqrt(abs(lasso3_std_residuals)),
     xlab = "Fitted values", 
     ylab = "Sqrt of abs standardized residuals",
     main = "Scale-Location")
abline(h = mean(sqrt(abs(lasso3_std_residuals))), col = "red", lwd = 1)


# Plot Predicted vs Actual
plot(y_test, predict_lasso3, 
     main = "Predicted vs Actual (Lasso Model 3)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")  

#------------------------------------------------------------------------------


Model <- c("Model 1", "Model 2", "Model 3", "Ridge Model 1", "Ridge Model 2", 
            "Ridge Model 3", "Lasso Model 1", "Lasso Model 3")
RMSE <- c(model1_rmse, model2_rmse, model3_rmse, ridge1_rmse, ridge2_rmse, 
           ridge3_rmse, lasso1_rmse, lasso3_rmse)
Adj_R_Squared <- c(model1_adjr2, model2_adjr2, model3_adjr2, ridge1_adjr2, 
                    ridge2_adjr2, ridge3_adjr2, lasso1_adjr2, lasso3_adjr2)
BIC <- c(model1_bic, model2_bic, model3_bic, ridge1_bic, ridge2_bic, ridge3_bic, 
          lasso1_bic, lasso3_bic)

model_comparison <- data.frame(Model, RMSE, Adj_R_Squared, BIC)

# Printing the comparison table
view(model_comparison)

#------------------------------------------------------------------------------

# Adjusting final model
# Testing a few models

final_model <- lm(sqrt(Sales_Price) ~ Mileage + Horsepower + Fuel 
             + Car_Type + Model_Year, data = train_set)

# Check the summary to understand the impact of each variable
summary(final_model)


final_model_summary <- summary(final_model)

final_model_adjr2 <- final_model_summary$adj.r.squared
final_model_bic <- BIC(final_model)

final_predict <- predict(final_model, newdata = test_set)
summary(final_predict)
actual_values <- test_set$Sales_Price
#Put RMSE back on original scale
final_model_rmse <- sqrt(mean((actual_values - (final_predict^2))^2))


vif(final_model)

par(mfrow=c(2,2))
plot(final_model)
confint(final_model)

# Square the predictions to reverse the transformation
final_pred_original_scale <- nypredictions_model1^2  

# Plot Predicted vs Actual on the original scale for Model 1
plot(actual_values, final_pred_original_scale, 
     main = "Predicted vs Actual (Model 1)",
     xlab = "Actual Sales Price", 
     ylab = "Predicted Sales Price", 
     pch = 19, col = 'blue')
abline(0, 1, col = "red")







#-----------------------------------------------------------------------------
#API
# Hämta stats från scb

library(pxweb)
library(jsonlite)





# URL toggplot2# URL to the data table
url <- "https://api.scb.se/OV0104/v1/doris/sv/ssd/START/TK/TK1001/TK1001A/PersBilarDrivMedel"


# Get PXWEB metadata about a table
px_meta <- pxweb_get(url)
px_meta



pxweb_query_list <-
  list(
    "Region" = c("*"), 
    "Drivmedel" = c("*"),
    "ContentsCode" = c("*"),
    "Tid" = c("*")
  )
pxq <- pxweb_query(pxweb_query_list)
pxweb_validate_query_with_metadata(pxq, px_meta)

pxd <- pxweb_get(
  url,
  pxq
)
pxd

pxdf <- as.data.frame(pxd, column.name.type = "text", variable.value.type = "text")
head(pxdf)
dim(pxdf)
uni <- unique(pxdf$drivmedel)
uni

# dropping drivmedel that is unknown 
pxdf <- pxdf[!(pxdf$drivmedel %in% c("gas/gas flexifuel", "övriga bränslen", "etanol/etanol flexifuel")), ]


# combining hybrids
pxdf$drivmedel[pxdf$drivmedel == "elhybrid" | pxdf$drivmedel == "laddhybrid"] <- "hybrid"

names(pxdf)
names(pxdf)[names(pxdf) == "Nyregistrerade personbilar"] <- "nyreg_personbilar"

library(dplyr)

# Assuming "månad" is your date column in format YYYYMM
pxdf <- pxdf %>%
  mutate(year = as.numeric(substr(månad, 1, 4)),  # Extracting the year part
         month = as.numeric(substr(månad, 6, 7)))  # Extracting the month part

pxdf_last_five_years <- pxdf %>%
  filter(year >= lubridate::year(Sys.Date()) - 5)

# Group by year and drivmedel, then summarize to get the total number of newly registered cars
pxdf_summary <- pxdf_last_five_years %>%
  group_by(year, drivmedel) %>%
  summarize(total_registered_cars = sum(nyreg_personbilar))

# Plot the summarized data
ggplot(pxdf_summary, aes(x = factor(year), y = total_registered_cars, fill = drivmedel)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "Year", y = "Total Registered Cars", fill = "Drivmedel") +
  ggtitle("Total Registered Cars by Drivmedel for the Last Five Years") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  

#------------------------------------------------------------------------------

#plotting the last 5 years

pxdf_summary <- pxdf_last_five_years %>%
  group_by(year, month, drivmedel) %>%
  summarize(total_registered_cars = sum(nyreg_personbilar))


ggplot(pxdf_summary, aes(x = as.Date(paste(year, month, "01", sep = "-")), 
                         y = total_registered_cars, color = drivmedel)) +
  geom_line() +
  labs(x = "Date", y = "Total Registered Cars", color = "Drivmedel") +
  ggtitle("Total Registered Cars by Drivmedel for the Last Five Years (SCB)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#------------------------------------------------------------------------------
# plotting rolling 12

pxdf_rolling_12_months <- pxdf %>%
  filter(year * 100 + month >= (lubridate::year(Sys.Date()) - 1) * 100 +
           lubridate::month(Sys.Date()))

# Group by month and drivmedel, then summarize to get the total number of newly
# registered cars

pxdf_summary_rolling_12_months <- pxdf_rolling_12_months %>%
  group_by(month, drivmedel) %>%
  summarize(total_registered_cars = sum(nyreg_personbilar))


ggplot(pxdf_summary_rolling_12_months, aes(x = factor(month), 
                                           y = total_registered_cars, 
                                           color = drivmedel, group = drivmedel)) +
  geom_line() +
  labs(x = "Month", y = "Total Registered Cars", color = "Drivmedel") +
  ggtitle("Total Registered Cars by Drivmedel for the Last Rolling 12 Months (SCB)") +
  theme_minimal() +
  scale_x_discrete(labels = month.abb) 
