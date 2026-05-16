# Interview Explanation: HELP International Aid Prioritization Project

## 1. What is your project?

I built an unsupervised machine learning project to help HELP International, a humanitarian NGO, decide which countries should receive priority from a $10 million aid fund.

The project uses country-level socio-economic and health indicators to group countries into meaningful clusters and identify the countries with the highest need for aid.

## 2. What problem did you solve?

The main problem was that aid prioritization is not based on one factor only. A country may be in need because of high child mortality, low GDP per capita, low income, poor health spending, or low life expectancy.

So instead of manually selecting countries, I created a data-driven clustering approach to support the CEO in making a more objective funding decision.

## 3. How did you solve it?

I followed an end-to-end machine learning workflow:

- I cleaned and inspected the dataset.
- I converted exports, imports, and health spending from GDP percentages into actual values.
- I standardized the numeric variables to make distance-based clustering fair.
- I performed EDA to understand distributions, skewness, outliers, and correlations.
- I used PCA to reduce dimensionality while retaining about 93% of the variance.
- I applied both hierarchical clustering and K-means clustering.
- I evaluated cluster quality using silhouette scores.
- I profiled the clusters using GDP, income, health expenditure, exports, and child mortality.
- I created a need score to rank countries inside the highest-need cluster.

## 4. What technologies did you use?

I used R, tidyverse, ggplot2, PCA, K-means clustering, hierarchical clustering, silhouette analysis, and R Markdown.

## 5. What was your role?

I worked as the data scientist for the full project. I handled data preprocessing, EDA, dimensionality reduction, clustering, model comparison, interpretation, and final recommendation.

## 6. What were the key results?

The analysis found that the highest-priority cluster had very high child mortality, very low GDP per capita, low income, and low health expenditure.

The top countries recommended for aid included Haiti, Sierra Leone, Central African Republic, Chad, Mali, and Niger.

## 7. What was the impact?

This project turns a complex humanitarian decision into a structured, explainable, and data-driven process. Instead of spreading aid randomly, HELP International can focus resources on countries with the strongest evidence of need.
