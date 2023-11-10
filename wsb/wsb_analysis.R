### Load the RedditExtractor package, which allows you to extract data from Reddit posts and comments
library(RedditExtractoR)
### Load the SentimentAnalysis package, which provides tools for sentiment analysis of text data
library(SentimentAnalysis)
### Load the SnowballC package, which provides word stemming algorithms for various languages
library(SnowballC)
### Load the dplyr package, which provides functions for data manipulation and transformation
library(dplyr)
### Load the ggplot2 package, which provides a system for creating graphics based on the grammar of graphics
library(ggplot2)
### Load the ggpmisc package, which provides miscellaneous extensions to ggplot2
library(ggpmisc)

## Use the find_thread_urls function to get the URLs of the top threads from the wallstreetbets subreddit in the past year
wsb_threads <- find_thread_urls(subreddit = "wallstreetbets", sort_by = "top", period = "year")
### View the results
head(wsb_threads)

## Use the get_thread_content function to get the content of the first 15 threads from the URLs you obtained
wsb_comments <- get_thread_content(wsb_threads$url[1:15])

## Change the text format of the comments to UTF-8 encoding, which is a standard way of representing characters in different languages
wsb_comments$comments$comment <- enc2utf8(wsb_comments$comments$comment)

## Use the analyzeSentiment function to perform sentiment analysis on the comments, using the General Inquirer dictionary
## This function returns a score for each comment, ranging from -5 to 5, where negative values indicate negative sentiment and positive values indicate positive sentiment
wsb_sentiment <- analyzeSentiment(wsb_comments$comments$comment)

## Combine the data from the comments and the sentiment analysis into a single data frame called wsb_dataset
wsb_dataset <- bind_cols(wsb_comments$comments, wsb_sentiment)

## Plot a histogram of the sentiment scores, using the ggplot function and the geom_histogram layer
## This shows the distribution of the sentiment scores across all comments
ggplot(wsb_dataset, aes(x = SentimentGI)) + geom_histogram() + labs(title = "Sentiment for wallstreetbets")

## Plot a scatterplot of the sentiment scores versus the date of posting, using the ggplot function and the geom_point layer
## This shows how the sentiment changes over time
ggplot(wsb_dataset, aes(x = date, y = SentimentGI)) + geom_point() + labs(title = "Observation over time")

## Plot a scatterplot of the sentiment scores versus the comment score, using the ggplot function, the geom_point layer, and the geom_smooth layer
## The geom_smooth layer adds a linear regression line to the plot, showing the relationship between the sentiment and the comment score
ggplot(wsb_dataset, aes(x = score, y = SentimentGI)) + geom_point() + geom_smooth(method = lm )

## Plot a hexplot of the density of the sentiment scores versus the comment score, using the ggplot function, the geom_hex layer, the scale_fill_gradient layer, the geom_smooth layer, and the stat_poly_eq layer
##The geom_hex layer creates a hexagonal binning plot, where the color of each hexagon represents the number of observations in that bin
## The scale_fill_gradient layer changes the color scheme of the plot, using blue for low values and orange for high values
## The geom_smooth layer adds a quadratic regression line to the plot, showing the nonlinear relationship between the sentiment and the comment score
## The stat_poly_eq layer adds the equation and the adjusted R-squared value of the quadratic model to the plot
ggplot(wsb_dataset, aes(x = score, y = SentimentGI)) + geom_hex(bins = 20, color = "white") +
  scale_fill_gradient(low = 'blue', high = 'orange') +
  labs(title = "Sentiment by comment score") +
  geom_smooth(method = lm, formula = y ~ poly(x,2)) +
  theme_minimal() +
  stat_poly_eq(
    aes(label = paste(..eq.label.., ..adj.rr.label.., sep = "~~~~" )),
    formula = y ~ poly(x,2), parse = TRUE
  )

## Plot a scatterplot of the sentiment scores versus the word count of the comments, using the ggplot function, the geom_point layer, and the geom_smooth layer
## The word count is calculated by the analyzeSentiment function as the number of words in each comment
## The geom_smooth layer adds a linear regression line to the plot, showing the relationship between the sentiment and the word count
ggplot(wsb_dataset, aes(x = WordCount, y = SentimentGI)) + geom_point() + geom_smooth(method = lm )

## Plot a hexplot of the density of the sentiment scores versus the word count of the comments, using the same layers as before
ggplot(wsb_dataset, aes(x = WordCount, y = SentimentGI)) + geom_hex(bins = 20, color = "white") +
  scale_fill_gradient(low = 'blue', high = 'orange') +
  labs(title = "Sentiment by word count") +
  geom_smooth(method = lm, formula = y ~ poly(x,2)) +
  theme_minimal() +
  stat_poly_eq(
    aes(label = paste(..eq.label.., ..adj.rr.label.., sep = "~~~~" )),
    formula = y ~ poly(x,2), parse = TRUE
  )
