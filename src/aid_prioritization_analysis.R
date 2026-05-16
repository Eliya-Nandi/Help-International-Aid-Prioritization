#Eliya Chritopher Nandi  (0829396 )
#MSc in Statistics and Data Science
#Course: Statistical Machine Learning
#Email: eliyachristopher.nandi@community.unipa.it


# ============================
# 1. Load Necessary Libraries
# ============================

# Load required libraries for data manipulation, analysis, and visualization
library(keras3)
library(tidyverse)    # Data manipulation and visualization
library(skimr)        # Summary statistics
library(ggcorrplot)   # Correlation plots
library(ggplot2)      # Visualizations
library(e1071)        # For skewness and kurtosis (not used here but can be useful)
library(ggcorrplot)   # For correlation plots
library(factoextra)   # For PCA visualization

# ============================
# 2. Load the Dataset
# ============================

# Read the dataset from the specified location
df <- read.csv("Country-data.csv")

head(df)
str(df)
# ============================
# 3. Feature Engineering
# ============================

# Convert % of GDP to actual values for exports, health, and imports
df <- df %>%
  mutate(
    exports = (exports * gdpp) / 100,
    health = (health * gdpp) / 100,
    imports = (imports * gdpp) / 100
  )

# Ensure 'gdpp' and 'income' are numeric
df$gdpp <- as.numeric(df$gdpp)
df$income <- as.numeric(df$income)

# ============================
# 4. Prepare Data for Analysis
# ============================

# Convert 'country' to a factor and create working dataset
mydf <- df %>% mutate(country = factor(country))
str(mydf)
# Check for missing values in the dataset
cat("Total NAs:", sum(sapply(mydf, function(x) sum(is.na(x)))), "\n")

# ============================
# 5. Exploratory Data Analysis (EDA)
# ============================

# Select features excluding 'country'
X <- mydf %>% select(-country)

# Reshape data to long format for plotting
X_long <- mydf %>% select(country, all_of(names(X))) %>% pivot_longer(cols = names(X), names_to = "feature", values_to = "value")

# Plot distributions of features in raw scale
ggplot(X_long, aes(x = value)) +
  geom_histogram(bins = 25, fill = "#4C72B0", color = "white", alpha = 0.85) +
  facet_wrap(~feature, scales = "free") +
  theme_minimal(base_size = 12) +
  labs(title = "Distributions of Features (Raw Scale)", x = "Value", y = "Count")

# ============================
# 6. Log Transformations for Skewed Variables
# ============================

# Apply log transformation to skewed variables
skew_vars <- c("gdpp", "income", "child_mort")
X_long %>% filter(feature %in% skew_vars) %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 25) +
  facet_wrap(~feature, scales = "free") +
  scale_x_continuous(trans = "log10") +  # Apply log10 scale
  theme_minimal() +
  labs(title = "Log10 View of Skewed Variables (EDA Only)")

# ============================
# 7. Outlier Detection Using Boxplots
# ============================

# Detect outliers using boxplots (outliers marked in red)
ggplot(X_long, aes(x = feature, y = value, fill = feature)) +
  geom_boxplot(outlier.colour = "red", outlier.size = 3, outlier.alpha = 0.6) +
  coord_flip() +  # Flip axes for readability
  theme_minimal() +
  labs(title = "Boxplots for Outlier Detection (Raw Scale)") +
  theme(legend.position = "none")

# ============================
# 8. Multivariate Outlier Detection (Z-scores)
# ============================

# Normalize data (Z-score normalization)
X_scaled <- scale(X)

# Calculate Z-scores for outliers
outlier_rank <- tibble(
  country = mydf$country,
  outlier_score = sqrt(rowSums(X_scaled^2))  # Euclidean distance based on Z-scores
) %>%
  arrange(desc(outlier_score))  # Sort by outlier score

# Display top 10 outliers based on Z-scores
cat("Top 10 Multivariate Outliers based on Z-scores:\n")
print(head(outlier_rank, 10))

# ============================
# 9. Visualizing Top 10 Outliers
# ============================

# Show top 10 outliers based on Z-scores
top_outliers <- outlier_rank %>% slice_head(n = 10)  # Extract top 10 outliers

# Plot top 10 outliers in a bar plot
ggplot(top_outliers, aes(x = reorder(country, outlier_score), y = outlier_score, fill = outlier_score)) +
  geom_bar(stat = "identity", color = "black") +
  theme_minimal() +
  coord_flip() +  # Flip axes for readability
  labs(title = "Top 10 Multivariate Outliers based on Z-scores", 
       x = "Country", 
       y = "Outlier Score") +
  scale_fill_gradient(low = "blue", high = "red")  # Color gradient for outlier score

# ============================
# 10. Confirming Normalization (Z-scores)
# ============================

# Check mean and standard deviation after normalization (should be ~0 and ~1)
round(colMeans(X_scaled), 4)
round(apply(X_scaled, 2, stats::sd), 4)

# ============================
# 11. Correlation Heatmap of Features
# ============================

# Calculate correlation matrix for all features in X
corr <- cor(X, use = "pairwise.complete.obs")

# Create a correlation heatmap to visualize relationships between variables
ggcorrplot(corr, type = "lower", lab = TRUE) + 
  labs(title = "Correlation Heatmap of Socio-economic Indicators")  # Add title



# ============================
# PCA vs. Autoencoders Comparison
# ============================

# --- 2. PCA Analysis ---
# Perform PCA on scaled data
pca_result <- prcomp(X_scaled)

# Show summary to check the explained variance of each principal component
summary(pca_result)

# PCA: Scree Plot (Visualizing explained variance per component)
p_scree <- fviz_eig(pca_result, addlabels = TRUE, ylim = c(0, 60), 
                    barfill = "#4C72B0", barcolor = "#4C72B0",
                    main = "PCA - Scree Plot (Explained Variance)")
print(p_scree)

# PCA: Cumulative Explained Variance (Visualizing cumulative variance)
plot(cumsum(pca_result$sdev^2) / sum(pca_result$sdev^2), type = "b", 
     main = "Cumulative Explained Variance", col = "red", xlab = "Number of Components", 
     ylab = "Cumulative Variance", cex.main = 1.5, cex.lab = 1.2)
grid()

# PCA: Explained Variance (per component)
explained_variance <- pca_result$sdev^2 / sum(pca_result$sdev^2)
cat("Explained variance by each PC:\n")
print(explained_variance)

# PCA: Cumulative Explained Variance
cumulative_variance <- cumsum(explained_variance)
cat("Cumulative explained variance:\n")
print(cumulative_variance)

# PCA: Number of components to keep based on 90% variance
num_components <- which(cumulative_variance >= 0.90)[1]
cat("Number of components to keep based on 90% variance:", num_components, "\n")

# =======================================
# ---  Autoencoder for Dimensionality Reduction ---
# =======================================

# Define the input dimension (number of features)
input_dim <- ncol(X_scaled)  # Number of features in the dataset

# Set the latent dimension to 4 (to reduce to 4 dimensions for Autoencoder)
latent_dim <- 4  

# Define the encoder layers (the part that reduces the dimensions)
input_layer <- layer_input(shape = c(input_dim))  # Input layer
encoder_hidden1 <- layer_dense(input_layer, units = 128, activation = "relu")  # First hidden layer
encoder_output <- layer_dense(encoder_hidden1, units = latent_dim, activation = "relu")  # Latent space

# Define the decoder layers (the part that reconstructs the original data)
decoder_hidden1 <- layer_dense(encoder_output, units = 128, activation = "relu")  # Decoder layer
decoder_output <- layer_dense(decoder_hidden1, units = input_dim, activation = "sigmoid")  # Output layer

# Create the full Autoencoder model (including both encoder and decoder)
autoencoder <- keras_model(inputs = input_layer, outputs = decoder_output)

# Compile the model with Adam optimizer and MSE loss
autoencoder %>% compile(
  optimizer = "adam",
  loss = "mean_squared_error"
)

# Train the Autoencoder model (input data is the same as output data)
history <- autoencoder %>% fit(
  X_scaled, X_scaled,
  epochs = 50,
  batch_size = 32,
  validation_split = 0.2
)

# Extract the encoder part of the model (for dimensionality reduction)
encoder <- keras_model(
  inputs = input_layer,
  outputs = encoder_output
)

# Use the encoder to transform the data into a lower-dimensional space (latent space)
encoded_data <- encoder %>% predict(X_scaled)

# View the compressed representation (latent space) of the data
head(encoded_data)
encoded_df <- as.data.frame(encoded_data)
# Manually assign column names to the encoded data for easier visualization
colnames(encoded_df) <- paste("V", 1:ncol(encoded_df), sep = "")

# Visualize the first two dimensions of the latent space (2D)
ggplot(encoded_df, aes(x = V1, y = V2)) +
  geom_point(alpha = 0.5, color = "blue") +  # Scatter plot with transparency
  labs(title = "2D Latent Space from Autoencoder", 
       x = "Latent Dimension 1", y = "Latent Dimension 2") +
  theme_minimal()

# 3D visualization of the latent space (using the first three dimensions)
library(rgl)  # Load rgl for 3D visualization

# 3D plot for the first three latent dimensions
plot3d(encoded_df$V1, encoded_df$V2, encoded_df$V3, 
       col = "blue", size = 3, 
       xlab = "Latent Dimension 1", ylab = "Latent Dimension 2", zlab = "Latent Dimension 3",
       main = "3D Latent Space from Autoencoder")



# ============================
# Step 4: Dimensionality Reduction Choice Based on Analysis
# ============================

# 1. Perform PCA for Linear Dimensionality Reduction
pca_result <- prcomp(X_scaled)
pca_latent <- pca_result$x[, 1:2]  # Take first two PCs for visualization

# 2. Autoencoder Model for Non-Linear Dimensionality Reduction
# Use the trained Autoencoder to extract the latent space (encoded data)
encoder <- keras_model(inputs = input_layer, outputs = encoder_output)
encoded_data <- encoder %>% predict(X_scaled)

# --- 3. Visualize PCA vs Autoencoder Results ---
# PCA Visualization
pca_df <- data.frame(PC1 = pca_latent[,1], PC2 = pca_latent[,2])

ggplot(pca_df, aes(x = PC1, y = PC2)) +
  geom_point(alpha = 0.5, color = "blue") +
  labs(title = "2D PCA Latent Space", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal()

# Autoencoder Visualization (2D)
autoencoder_df <- data.frame(Latent_Dim1 = encoded_data[,1], Latent_Dim2 = encoded_data[,2])

ggplot(autoencoder_df, aes(x = Latent_Dim1, y = Latent_Dim2)) +
  geom_point(alpha = 0.5, color = "red") +
  labs(title = "2D Latent Space from Autoencoder", 
       x = "Latent Dimension 1", y = "Latent Dimension 2") +
  theme_minimal()

# --- 4. Make a decision based on analysis ---
# Check if data has strong linear correlation, PCA is more suitable
if (sum(abs(cor(X_scaled))) > 0.7) {
  message("PCA is suitable for dimensionality reduction due to linear correlations in data.")
} else {
  message("Autoencoder is better suited for dimensionality reduction due to non-linear relationships in data.")
}

# ============================
# Step 3: PCA for Dimensionality Reduction (Using PCA)
# ============================

# Keep first 4 PCs (~90% variance)
k <- 4
country_names <- mydf$country
pca_data <- as.data.frame(pca_result$x[, 1:k])
pca_data$country <- country_names  # Add country names for reference

# Check dimensions of the resulting data
dim(pca_data)
head(pca_data)

# ============================
# Step 4: Distance Matrix
# ============================

# Use PCA data for clustering 
pca_mat <- pca_data %>% select(-country)

# Compute Euclidean distance matrix
dist_pca <- dist(pca_mat, method = "euclidean")

# Quick check of the distance matrix
print(dist_pca)

# ============================
# Step 4.1: Hierarchical Clustering (Ward's method)
# ============================

# Perform hierarchical clustering using Ward's method
hc_ward <- hclust(dist_pca, method = "ward.D2")

# Plot the dendrogram for hierarchical clustering
plot(
  hc_ward,
  labels = FALSE,
  hang = -1,
  main = "Hierarchical Clustering Dendrogram (Ward's Method)",
  xlab = "",
  ylab = "Height"
)


# ============================
# STEP 4.3: Cut Dendrogram (Choose Optimal k)
# ============================

# Set optimal k (k = 4 based on dendrogram analysis)
k_final <- 4

# Cut the dendrogram at k = 4
clusters <- cutree(hc_ward, k = k_final)

# Add cluster labels to PCA data
pca_data$cluster <- factor(clusters)

# Check cluster sizes
table(pca_data$cluster)

# Plot dendrogram with highlighted clusters
plot(
  hc_ward,
  labels = FALSE,
  hang = -1,
  main = "Hierarchical Clustering Dendrogram (Ward's, k = 4)"
)
rect.hclust(hc_ward, k = k_final, border = 2:5)  # Highlight the clusters

# Calculate silhouette for clustering
library(cluster)
sil <- silhouette(clusters, dist_pca)  # 'dist_pca' is the Euclidean distance matrix

# Visualize silhouette plot
fviz_silhouette(sil) + 
  ggtitle("Silhouette Plot for Hierarchical Clustering (k = 4)") +
  theme_minimal()

# Calculate the average silhouette width
avg_sil_width <- mean(sil[, 3])
cat("Average Silhouette Width for k = 4:", avg_sil_width, "\n")

# Plot dendrogram with country names as labels
plot(
  hc_ward,
  labels = pca_data$country,  # Use country names as labels
  hang = -1,
  main = "Hierarchical Clustering Dendrogram (Ward's Method)",
  xlab = "",
  ylab = "Height",
  cex = 0.6  # Adjust text size
)
rect.hclust(hc_ward, k = k_final, border = 2:5)  # Highlight clusters

# ============================
# STEP 5: Visualizing Clusters in PCA Space
# ============================
pca_cluster_df <- data.frame(
  PC1 = pca_latent[, 1],
  PC2 = pca_latent[, 2],
  Cluster = factor(clusters),
  country = pca_data$country
)


# Plot the clusters in PCA space (2D plot)
ggplot(pca_cluster_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(title = "PCA Clusters Visualization (2D)", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))

# ============================
# STEP 5: Visualizing Clusters with fviz_cluster
# ============================

# Ensure clusters are factors
pca_cluster_df$Cluster <- factor(clusters)

# Add country names back for labeling
pca_cluster_df$country <- country_names

# Use factoextra's fviz_cluster() to visualize clusters with countries as labels
library(factoextra)
fviz_cluster(
  list(data = pca_cluster_df[, c("PC1", "PC2")], cluster = pca_cluster_df$Cluster),
  geom = "point",  # Points for clusters
  ellipse.type = "convex",  # Add ellipses for each cluster
  main = "PCA Clusters Visualization with Countries",
  palette = c("red", "blue", "green", "purple"),  # Cluster colors
  ggtheme = theme_minimal()
) + 
  geom_text(data = pca_cluster_df, aes(x = PC1, y = PC2, label = country), 
            size = 3, check_overlap = TRUE)  # Add country names as labels



# Step 1: Summarizing the Clusters

# Verify pca_data structure and ensure country names are correctly assigned
country_names <- mydf$country

# Add cluster assignments to pca_data
pca_data$cluster <- clusters

# Create the cluster summary data frame
cluster_summary <- data.frame(
  Country = country_names,
  Cluster = factor(pca_data$cluster)
)

# Check the cluster summary and cluster sizes
cat("Cluster Sizes:\n")
print(table(cluster_summary$Cluster))

# View countries in each cluster
cat("\nCountries in each cluster:\n")
split(cluster_summary$Country, cluster_summary$Cluster)

# ==========================================
# Step 1: Visualizing Clusters in PCA Space (2D)

# Plot the clusters in PCA space (2D plot)
ggplot(pca_cluster_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(title = "PCA Clusters Visualization (2D)", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))

# Add country names as labels to the PCA clusters plot
pca_cluster_df$country <- country_names
ggplot(pca_cluster_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_text(aes(label = country), size = 3, check_overlap = TRUE, vjust = 1.5, hjust = 0.5) +
  labs(title = "PCA Clusters Visualization with Countries", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))

# Step 3: Cluster Summary Check

# Check cluster sizes and view the countries in each cluster
cat("Cluster Sizes:\n")
print(table(pca_data$cluster))

cat("\nCountries in each cluster:\n")
split(cluster_summary$Country, cluster_summary$Cluster)

# Step 4: Visualize the Dendrogram Again (with Cluster Labels)

# Plot dendrogram with cluster labels and country names
plot(
  hc_ward,
  labels = pca_data$country,
  hang = -1,
  main = "Hierarchical Clustering Dendrogram with Country Labels",
  xlab = "",
  ylab = "Height",
  cex = 0.6
)

# Highlight clusters in the dendrogram
rect.hclust(hc_ward, k = k_final, border = 2:5)




# =========================================================
# Step 1: Elbow Method to Find Optimal k
# =========================================================

# Use only numeric PCA components (PCA scores) for clustering
pca_numeric_data <- pca_result$x  # PCA scores

# Elbow Method to determine optimal k
wss <- sapply(1:10, function(k) {
  kmeans(pca_numeric_data, centers = k, nstart = 25)$tot.withinss
})

# Plot Elbow Method to visualize optimal k
plot(1:10, wss, type = "b", pch = 19, xlab = "Number of Clusters (k)", 
     ylab = "Total Within-Cluster Sum of Squares", main = "Elbow Method for K-means")

# =========================================================
# Step 2: Perform K-means clustering with k = 4
# =========================================================

# Set seed for reproducibility and perform K-means clustering
set.seed(123)
kmeans_result <- kmeans(pca_numeric_data, centers = 4, nstart = 25)

# Check the cluster assignments
kmeans_result$cluster

# =========================================================
# Step 3: Visualize the Clusters in PCA Space
# =========================================================

# Create a data frame with PCA components and cluster assignments
pca_cluster_df_kmeans <- data.frame(
  PC1 = pca_numeric_data[, 1],  # First principal component
  PC2 = pca_numeric_data[, 2],  # Second principal component
  Cluster = factor(kmeans_result$cluster)  # Cluster labels
)

# Plot the K-means clusters in PCA space (2D plot)
ggplot(pca_cluster_df_kmeans, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(title = "K-means Clusters Visualization (2D)", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))

# =========================================================
# Step 4: Silhouette Score for K-means
# =========================================================

# Compute the silhouette for K-means clustering (k = 4)
sil_kmeans <- silhouette(kmeans_result$cluster, dist(pca_numeric_data))

# Visualize silhouette plot for K-means
fviz_silhouette(sil_kmeans) + 
  ggtitle("Silhouette Plot for K-means Clustering (k = 4)") +
  theme_minimal()

# Calculate the average silhouette width for k = 4
avg_sil_width_kmeans <- mean(sil_kmeans[, 3])
cat("Average Silhouette Width for K-means (k = 4):", avg_sil_width_kmeans, "\n")

# =========================================================
# Step 5: Cluster Summary
# =========================================================

# Create the cluster summary data frame
# Create the cluster summary data frame
country_names <- mydf$country  # Country names

pca_numeric_data <- as.data.frame(pca_numeric_data)  # FIX
pca_numeric_data$cluster <- kmeans_result$cluster    # Add cluster labels (no warning)


cluster_summary <- data.frame(
  Country = country_names,
  Cluster = factor(pca_numeric_data$cluster)
)

# Check cluster sizes and countries in each cluster
cluster_sizes <- table(cluster_summary$Cluster)
cat("Cluster Sizes:\n")
print(cluster_sizes)

cat("\nCountries in each cluster:\n")
print(split(cluster_summary$Country, cluster_summary$Cluster))


# ==============================================================
# Comparison Between K-means and Hierarchical Clustering
# ==============================================================

# Convert pca_data to a data frame and add cluster labels
pca_data_df <- as.data.frame(pca_result$x)  # PCA result as data frame
pca_data_df$cluster_hc <- clusters  # Add hierarchical clusters
pca_data_df$country <- country_names  # Add country names

# Visualize the clusters in PCA space (Hierarchical Clustering)
pca_cluster_df_hc <- data.frame(
  PC1 = pca_data_df$PC1, 
  PC2 = pca_data_df$PC2, 
  Cluster = factor(pca_data_df$cluster_hc)  # Hierarchical clusters
)

# Plot the clusters from Hierarchical Clustering in PCA space
ggplot(pca_cluster_df_hc, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(title = "Hierarchical Clustering Results (k = 4)", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))

# Visualizing K-means Clustering in PCA space
pca_cluster_df_kmeans <- data.frame(
  PC1 = pca_result$x[, 1],  # First principal component from PCA result
  PC2 = pca_result$x[, 2],  # Second principal component from PCA result
  Cluster = factor(kmeans_result$cluster)  # K-means cluster labels
)

# Plot the clusters from K-means in PCA space (2D plot of PC1 vs PC2)
ggplot(pca_cluster_df_kmeans, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +  # Adjust point size and transparency
  labs(title = "K-means Clustering Results", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal() +
  scale_color_manual(values = c("red", "blue", "green", "purple"))  # Customize cluster colors

# Silhouette Score Comparison

# Print average silhouette width for Hierarchical Clustering
cat("Average Silhouette Width for Hierarchical Clustering (k = 4):", avg_sil_width, "\n")

# Print average silhouette width for K-means Clustering
cat("Average Silhouette Width for K-means (k = 4):", avg_sil_width_kmeans, "\n")

# ================================================================
# Cluster Profiling for K-means
# ==============================================================

# Combine K-means cluster labels with socio-economic and health data
kmeans_cluster_df <- data.frame(
  country = country_names, 
  cluster = factor(kmeans_result$cluster), 
  gdpp = mydf$gdpp, 
  income = mydf$income, 
  exports = mydf$exports, 
  health = mydf$health, 
  child_mort = mydf$child_mort
)

# Calculate the mean values of each variable by cluster
cluster_summary_kmeans <- kmeans_cluster_df %>%
  group_by(cluster) %>%
  summarise(
    avg_gdpp = mean(gdpp, na.rm = TRUE),
    avg_income = mean(income, na.rm = TRUE),
    avg_exports = mean(exports, na.rm = TRUE),
    avg_health = mean(health, na.rm = TRUE),
    avg_child_mort = mean(child_mort, na.rm = TRUE)
  )

# View the cluster summaries
print(cluster_summary_kmeans)



# ================================================================
# Step 2: Aid Prioritization for K-means Clusters
# ================================================================

# Prioritize aid to clusters with low GDP, high child mortality, and low health expenditure
aid_priority_clusters_kmeans <- cluster_summary_kmeans %>%
  arrange(avg_child_mort, avg_gdpp) %>%  # Prioritize clusters with higher child mortality and lower GDP
  top_n(1, wt = avg_child_mort)  # Get the cluster with the highest child mortality

cat("Cluster in Most Need of Aid (K-means Clustering):\n")
print(aid_priority_clusters_kmeans)

# ================================================================
# Step 1: Cluster Profiling for Hierarchical Clustering
# ================================================================

# Combine Hierarchical cluster labels with socio-economic and health data
hc_cluster_df <- data.frame(
  country = country_names, 
  cluster = factor(clusters), 
  gdpp = mydf$gdpp, 
  income = mydf$income, 
  exports = mydf$exports, 
  health = mydf$health, 
  child_mort = mydf$child_mort
)

# Calculate the mean of each variable by cluster
cluster_summary_hc <- hc_cluster_df %>%
  group_by(cluster) %>%
  summarise(
    avg_gdpp = mean(gdpp, na.rm = TRUE),
    avg_income = mean(income, na.rm = TRUE),
    avg_exports = mean(exports, na.rm = TRUE),
    avg_health = mean(health, na.rm = TRUE),
    avg_child_mort = mean(child_mort, na.rm = TRUE)
  )

cat("Cluster Summary for Hierarchical Clustering:\n")
print(cluster_summary_hc)

# Prioritize aid to clusters with low GDP, high child mortality, and low health expenditure
aid_priority_clusters_hc <- cluster_summary_hc %>%
  arrange(avg_child_mort, avg_gdpp) %>%  # Prioritize clusters with higher child mortality and lower GDP
  top_n(1, wt = avg_child_mort)  # Get the cluster with the highest child mortality

cat("Cluster in Most Need of Aid (Hierarchical Clustering):\n")
print(aid_priority_clusters_hc)

# ================================================================
# Step 1: List Countries in Cluster 3 (K-means)
# ================================================================

# Extract countries in Cluster 3 for K-means
countries_cluster_3_kmeans <- mydf %>%
  filter(kmeans_result$cluster == 3) %>%
  select(country)

cat("Countries in Cluster 3 (K-means):\n")
print(countries_cluster_3_kmeans)

# ================================================================
# Step 2: Visualize Cluster 3 in PCA Space
# ================================================================

# Filter PCA data for countries in Cluster 3
pca_cluster_3_df <- pca_cluster_df_kmeans %>%
  filter(Cluster == 3)

# Plot Cluster 3 in PCA space
ggplot(pca_cluster_3_df, aes(x = PC1, y = PC2)) +
  geom_point(color = "red", size = 3) +
  labs(title = "Countries in Cluster 3 (K-means) in PCA Space", 
       x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal()

# ================================================================
# Step 3: Explore Socio-Economic and Health Indicators for Cluster 3
# ================================================================

# Filter original data for countries in Cluster 3 (K-means)
cluster_3_data_full <- mydf %>% 
  filter(country %in% countries_cluster_3_kmeans$country)

head(cluster_3_data_full)

# View summary statistics for socio-economic and health indicators in Cluster 3
cat("Summary Statistics for Socio-economic and Health Indicators (Cluster 3):\n")
summary(cluster_3_data_full)

# ================================================================
# Step 1: Visualize the Distribution of Key Indicators for Cluster 3
# ================================================================

# Visualize the distribution of key indicators in Cluster 3
ggplot(cluster_3_data_full, aes(x = child_mort)) +
  geom_histogram(binwidth = 10, fill = "red", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Child Mortality in Cluster 3", 
       x = "Child Mortality", y = "Frequency") +
  theme_minimal()

ggplot(cluster_3_data_full, aes(x = gdpp)) +
  geom_histogram(binwidth = 500, fill = "blue", color = "black", alpha = 0.7) +
  labs(title = "Distribution of GDP per Capita in Cluster 3", 
       x = "GDP per Capita", y = "Frequency") +
  theme_minimal()

ggplot(cluster_3_data_full, aes(x = health)) +
  geom_histogram(binwidth = 50, fill = "green", color = "black", alpha = 0.7) +
  labs(title = "Distribution of Health Expenditure in Cluster 3", 
       x = "Health Expenditure", y = "Frequency") +
  theme_minimal()

# ================================================================
# Step 2: Visualize Cluster 3 in Comparison to Other Clusters
# ================================================================

# Visualize all clusters, highlighting Cluster 3 in PCA space
ggplot(pca_cluster_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(title = "Clusters in PCA Space (Cluster 3 Highlighted)", 
       x = "Principal Component 1", y = "Principal Component 2") +
  scale_color_manual(values = c("red", "blue", "green", "purple")) +
  geom_point(data = pca_cluster_3_df, aes(x = PC1, y = PC2), color = "black", size = 4, shape = 16) +  # Highlight Cluster 3
  theme_minimal()



# ================================================================
# Step 3: Aid Prioritization Visualization for All Clusters
# ================================================================

# Combine socio-economic and health data with cluster labels
pca_cluster_df_full <- pca_cluster_df %>%
  left_join(mydf %>% select(country, child_mort, gdpp, income, health), by = c("country" = "country"))

# Visualize child mortality, GDP, and health expenditure across clusters
ggplot(pca_cluster_df_full, aes(x = Cluster, y = child_mort, fill = Cluster)) +
  geom_boxplot() +
  labs(title = "Child Mortality by Cluster", x = "Cluster", y = "Child Mortality") +
  theme_minimal()

ggplot(pca_cluster_df_full, aes(x = Cluster, y = gdpp, fill = Cluster)) +
  geom_boxplot() +
  labs(title = "GDP per Capita by Cluster", x = "Cluster", y = "GDP per Capita") +
  theme_minimal()

ggplot(pca_cluster_df_full, aes(x = Cluster, y = health, fill = Cluster)) +
  geom_boxplot() +
  labs(title = "Health Expenditure by Cluster", x = "Cluster", y = "Health Expenditure") +
  theme_minimal()

# ================================================================
# Step 4: Aid Prioritization (Generate Recommendations)
# ================================================================

# Identify countries in need of aid based on K-means and Hierarchical clusters
countries_cluster_3_kmeans <- mydf %>%
  filter(kmeans_result$cluster == 3) %>%
  select(country)

countries_cluster_1_hc <- mydf %>%
  filter(clusters == 1) %>%
  select(country)

countries_in_need_of_aid <- unique(c(countries_cluster_3_kmeans$country, countries_cluster_1_hc$country))

cat("Countries in Most Need of Aid (K-means and Hierarchical Clustering):\n")
print(countries_in_need_of_aid)

# Generate recommendation for aid distribution
cat("\nRecommendation for Aid Distribution:\n")
cat("====================================\n")
cat("The following countries are in the most need of aid due to low GDP, high child mortality, and low health expenditure:\n")
print(countries_in_need_of_aid)

cat("\nRationale:\n")
cat("1. **Cluster 3 (K-means)** and **Cluster 1 (Hierarchical Clustering)** represent countries with severe health and economic challenges.\n")
cat("2. These countries need urgent aid in healthcare and infrastructure development.\n")
cat("3. Aid should prioritize **health**, **economic development**, and **education/infrastructure**.\n")

# ================================================================
# Step 5: Assign Need Score and Sort Countries
# ================================================================

# Calculate 'Need Score' based on child mortality, GDP, and health expenditure
cluster_3_data_full$normalized_child_mort <- scale(cluster_3_data_full$child_mort)
cluster_3_data_full$normalized_gdpp <- scale(cluster_3_data_full$gdpp)
cluster_3_data_full$normalized_health <- scale(cluster_3_data_full$health)

# Create need score (higher score = higher need)
cluster_3_data_full$need_score <- cluster_3_data_full$normalized_child_mort + 
  -cluster_3_data_full$normalized_gdpp + 
  -cluster_3_data_full$normalized_health

# Sort countries based on need score (highest need first)
sorted_countries <- cluster_3_data_full %>%
  arrange(desc(need_score)) %>%
  select(country, need_score)

# Display sorted countries
head(sorted_countries)

# ================================================================
# Step 6: Visualize Countries by Need Score
# ================================================================

# Visualize countries ranked by need score
ggplot(sorted_countries, aes(x = reorder(country, need_score), y = need_score, fill = need_score)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  coord_flip() + 
  labs(title = "Countries Ranked by Need for Aid", x = "Country", y = "Need Score") +
  theme_minimal() +
  scale_fill_gradient(low = "red", high = "green")

# ================================================================
# Step 7: Hierarchical Clustering - Cluster 4 Analysis
# ================================================================

# Adding the hierarchical clustering labels to `mydf`
mydf$cluster <- clusters  

cluster_data_two_countries_hc <- mydf %>% 
  filter(cluster == 4)  # Filter for countries in Cluster 4

cat("\nSummary Statistics for Cluster 4 (Hierarchical Clustering):\n")
summary(cluster_data_two_countries_hc)
print(cluster_data_two_countries_hc)

# ================================================================
# Step 8: K-means - Cluster 1 Analysis
# ================================================================

# Analyze countries in Cluster 1 (K-means)
cluster_with_two_kmeans <- cluster_summary_kmeans %>%
  filter(cluster == 1)

cat("Countries in Cluster 1 (K-means):\n")

# Directly filter the dataset for countries in Cluster 1 (K-means)
cluster_data_two_countries_kmeans <- mydf %>%
  filter(kmeans_result$cluster == 1)

# Display the countries in Cluster 1
print(cluster_data_two_countries_kmeans$country)

# Check the summary statistics for the countries in Cluster 1 (K-means)
cat("\nSummary Statistics for Cluster 1 (K-means):\n")
summary(cluster_data_two_countries_kmeans)

cluster_1_stats_table <- cluster_data_two_countries_kmeans


cat("Statistics for Countries in Cluster 1 (K-means):\n")
print(cluster_1_stats_table)

cat("\nInterpretation of Cluster 1 (K-means):\n")
cat("Cluster 1 contains two countries with high GDP, low child mortality, and high health expenditure.\n")
cat("These countries are outliers due to their economic prosperity.\n")
cat("They may be excluded from aid prioritization analysis.\n")



