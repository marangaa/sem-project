# Load the packages
library(RedditExtractoR)
library(SentimentAnalysis)
library(tidyverse)
library(caret)
library(xgboost)
library(ggplot2)


# Extract the posts and comments from the subreddits using redditExtractoR package
reddit_threads <- find_thread_urls(keywords = "crude oil, oil price, oil market, oil demand, oil supply", subreddit = "energy, economy, investing, wallstreetbets", sort_by = "top", period = "year")
data <- get_thread_content(reddit_threads$url[1:20])

# Bind the rows of the comments and threads tables
data <- bind_rows(data$comments, data$threads)

# Filter the data to keep only the relevant columns
thread_data <- data %>% select(date, score, comment)

# # Combine the title and the selftext columns into one text column
# data$text <- paste(data$title, data$selftext, sep = " ")
#
# # Remove the title and the selftext columns
# data <- data %>% select(-title, -selftext)
#
# # Convert the created_utc column to date format
# data$created_utc <- as.Date(as.POSIXct(data$created_utc, origin = "1970-01-01"))

# Perform sentiment analysis on the text column using SentimentAnalysis package
corpus <- Corpus(VectorSource(thread_data$comment))
sentiment <- analyzeSentiment(corpus)

# Convert the sentiment data frame into a list
sentiment <- as.list(sentiment)

# Rename the elements of the list to match the column names of the data
names(sentiment) <- colnames(data)

# Add the sentiment scores to the data
combined_data <- cbind(thread_data, sentiment)

# Get the daily average sentiment scores
daily_sentiment <- data %>%
  group_by(date) %>%
  summarise(across(c(score, starts_with("sentiment")), mean))

# Load the crude oil price data from the U.S. Energy Information Administration
oil_price <- read.csv("https://www.eia.gov/dnav/pet/hist_xls/RBRTEd.xls", skip = 2)

# Rename the columns
colnames(RBRTEd) <- c("date", "price")

# # Convert the date column to date format
# oil_price$date <- as.Date(oil_price$date, format = "%m/%d/%Y")

# Filter the oil price data to match the date range of the reddit data
oil_price <- RBRTEd %>%
  filter(date >= min(daily_sentiment$date) & date <= max(daily_sentiment$date))

# Merge the oil price data with the daily sentiment data
merged_data <- merge(oil_price, daily_sentiment, by.x = "date", by.y = "date")

# Create a binary target variable that indicates whether the oil price increased or decreased from the previous day
merged_data$target <- ifelse(merged_data$price > lag(merged_data$price), 1, 0)

# Remove the rows with missing values
merged_data <- merged_data %>% drop_na()

# Split the data into training and testing sets
set.seed(123)
split <- createDataPartition(merged_data$target, p = 0.8, list = FALSE)
train <- merged_data[split, ]
test <- merged_data[-split, ]

# Define the predictor and the target variables
x_train <- train %>% select(-date, -price, -target)
y_train <- train$target
x_test <- test %>% select(-date, -price, -target)
y_test <- test$target

# Convert the target variables to factors
y_train <- as.factor(y_train)
y_test <- as.factor(y_test)

# Train an XGBoost model using caret package
model <- train(
  x = x_train,
  y = y_train,
  method = "xgbTree",
  trControl = trainControl(method = "cv", number = 5),
  tuneGrid = expand.grid(
    nrounds = 100,
    max_depth = 3,
    eta = 0.1,
    gamma = 0,
    colsample_bytree = 1,
    min_child_weight = 1,
    subsample = 1
  )
)

# Make predictions on the test set
pred <- predict(model, x_test)

# Convert the predicted values to factors
pred <- as.factor(pred)

# Make sure the levels of the predicted and the actual values are the same
levels(pred) <- levels(y_test)

# Evaluate the model performance using confusion matrix.md
confusionMatrix(pred, y_test)



# Create a line plot of the crude oil price over time
ggplot(merged_data, aes(x = date, y = price)) +
  geom_line() +
  labs(title = "Crude Oil Price Over Time",
       x = "Date",
       y = "Price (Dollars per Barrel)")

# Save the plot as a PNG file
ggsave("./wsb/oil_price_plot.png")

# Create a bar plot of the daily average sentiment scores over time
ggplot(daily_sentiment, aes(x = date, y = value, fill = name)) +
  geom_col(position = position_dodge()) +
  labs(title = "Daily Average Sentiment Scores Over Time",
       x = "Date",
       y = "Sentiment Score",
       fill = "Sentiment Type")

# Save the plot as a PNG file
ggsave("./wsb/sentiment_plot.png")

# Add a smoother line to the plot
ggplot(merged_data, aes(x = price, y = score)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Crude Oil Price Versus Score",
       x = "Price (Dollars per Barrel)",
       y = "Score")

# Add a color gradient to the points based on the date
ggplot(merged_data, aes(x = price, y = score, color = date)) +
  geom_point() +
  scale_color_gradient(low = "blue", high = "red") +
  labs(title = "Crude Oil Price Versus Score",
       x = "Price (Dollars per Barrel)",
       y = "Score",
       color = "Date")

# Add a facet grid to the plot based on the target variable
ggplot(merged_data, aes(x = price, y = score)) +
  geom_point() +
  facet_grid(target ~ .) +
  labs(title = "Crude Oil Price Versus Score",
       x = "Price (Dollars per Barrel)",
       y = "Score")
