options(warn=-1)
library <- function (...) {
  packages <- as.character(match.call(expand.dots = FALSE)[[2]])
  suppressWarnings(suppressMessages(lapply(packages, base::library, character.only = TRUE)))
  return(invisible())
}

library(tidyverse, partykit, jsonlite)

library(partykit)
library(jsonlite)

# Function to get all nodes with information in a tree in JSON format
get_tree_structure_json <- function(node, data) {
  
  # Create a list object to store node details
  node_details <- list()
  
    # Store node information
    node_details$id <- node$id
    if (is.terminal(node)) {
      node_details$info <- list(
        Relative_Type_Mean = node$info$prediction,
        Pop_Share = node$info$nobs,
        Box_Number = node$id
      )
    }
  
  # Check for child nodes and recursively process each one
  if (!is.null(node$kids)) {
    nodeName <- ""
    children <- list()
    for (i in seq_along(node$kids)) {
      kid <- node$kids[[i]]
      split <- node$split
      varname <- names(data)[split$varid]
      nodeName <- varname
      index_value <- NULL
      
      if (!is.null(split$index)) {
        levels <- levels(data[[varname]])
        kid_indices <- which(split$index == i)
        index_value <- paste(levels[kid_indices], collapse = ",")
      }
      
      # Collect child node details along with the split condition leading to it
      child_details <- get_tree_structure_json(kid, data)
      child_details$split_condition <- paste(varname, "->", index_value)
      children[[i]] <- child_details
    }
    node_details$children <- children
    node_details$nodeName <- nodeName
  }
  
  return(node_details)
}

# Function to modify the tree by adding node metrics (e.g., relative type means and population shares)
modify_tree <- function(data, tree, dep, wts, norm = FALSE) {
  
  # Convert tree nodes to a list for easier manipulation
  ct_node <- as.list(tree$node)
  
  # Predict node assignments (terminal node ID) for each observation in the data
  data$types <- predict(tree, type = "node")
  
  # Add dependent variable and weights to the data
  data$dep <- data[[dep]]
  data$wts <- data[[wts]]
  
  # Calculate weighted means within each node
  pred <- data %>%
    group_by(types) %>%
    mutate(x = stats::weighted.mean(x = dep, w = wts)) %>%
    dplyr::select(types, x) %>%
    summarise_all(funs(mean), na.rm = TRUE) %>%
    ungroup()
  
  # Calculate overall weighted mean for normalization
  a <- data %>%
    mutate(m = stats::weighted.mean(x = dep, wts))
  
  # Find the mean of the overall weighted means
  mean_pop <- round(mean(a$m), 3)
  
  # Convert prediction results to a dataframe
  pred <- as.data.frame(pred)
  qi <- pred
  
  # Calculate the proportion of observations in each terminal node (population share)
  for (t in 1:length(qi[, 1])) {
    typ <- as.numeric(names(table(data$types)[t]))  # Determine the type of the node
    qi[t, 2] <- length(data$types[data$types == typ]) / length(data$types)  # Calculate population share
  }
  
  # Normalize predictions if requested
  if (norm == TRUE) {
    # Normalize the weighted mean by the overall population mean
    # print(paste0("1 corresponds to the weighted mean: ", mean_pop))
    pred$x <- pred$x / mean_pop
    dig <- 3  # Number of decimal places for formatting
  } else {
    pred$x <- pred$x
    dig <- 0  # No normalization required
  }
  
  # Update tree nodes with the calculated predictions and population share
  for (t in 1:nrow(pred)) {
    ct_node[[pred[t, 1]]]$info$prediction <- as.numeric(paste(format(round(pred[t, -1], digits = dig), nsmall = 2)))
    ct_node[[pred[t, 1]]]$info$nobs <- as.numeric(paste(format(round(100 * qi[t, -1], digits = 2), nsmall = 2)))
  }
  
  # Reconstruct the tree with the updated nodes
  tree$node <- as.partynode(ct_node)
  
  # Return the modified tree
  return(tree)
}

# Function to get all paths from the root to terminal nodes, including node information
get_all_node_paths <- function(node, data, path = list(), all_paths = list()) {
  
  # Check if the current node is a terminal node
  if (partykit::is.terminal(node)) {
    # Construct the path string with additional node information
    new_path <- c(path, 
                  paste("Relative_Type_Mean", "->", node$info$prediction),
                  paste("Pop_Share", "->", node$info$nobs),
                  paste("Box_Number", "->", node$id))
    
    # Store the path in the result list with the node ID as the key
    all_paths[[paste0("Node ", node$id)]] <- new_path
    return(all_paths)
  }
  
  # If the node has child nodes, recursively traverse them
  if (!is.null(node$kids)) {
    for (i in seq_along(node$kids)) {
      kid <- node$kids[[i]]
      split <- node$split
      varname <- names(data)[split$varid]
      index_value <- NULL
      
      # Handle categorical splits
      if (!is.null(split$index)) {
        levels <- levels(data[[varname]])
        kid_indices <- which(split$index == i)
        index_value <- paste(levels[kid_indices], collapse = ",")
      }
      
      # Construct the path for the current split
      new_path <- c(path, paste(varname, "->", index_value))
      
      # Recursively call the function for the child node
      all_paths <- get_all_node_paths(kid, data, new_path, all_paths)
    }
  }
  
  return(all_paths)
}

# Function to create a dataframe aligned with general_df from a list of paths
create_dataframe_from_paths <- function(paths_list, general_columns) {
  # Initialize an empty list to store dataframes for each path
  all_data <- list()
  
  # Iterate over each path in the list of paths
  for (path in paths_list) {
    string_list <- path
    
    # Reverse loop to ensure last occurrences are kept for duplicates
    reversed_list <- rev(string_list)
    
    # Initialize an empty named list for extracted data
    extracted_data <- list()
    
    # Extract the column names and data from the reversed string_list
    for (string in reversed_list) {
      parts <- unlist(strsplit(string, " -> "))
      column_name <- parts[1]
      value <- parts[2]
      
      # Add to extracted_data only if it hasn't been added yet
      if (!column_name %in% names(extracted_data)) {
        extracted_data[[column_name]] <- value
      }
    }
    
    # Initialize a list with general_columns names filled with NA
    complete_data <- as.list(rep(NA, length(general_columns)))
    names(complete_data) <- general_columns
    
    # Fill the list with the extracted data
    for (name in names(extracted_data)) {
      complete_data[[name]] <- extracted_data[[name]]
    }
    
    # Manually add classificarion data 
    complete_data[["Country_Code"]] <- country_code
    complete_data[["Year"]] <- year
    complete_data[["Type"]] <- type
    
    # Convert the list to a dataframe and add it to all_data list
    df <- as.data.frame(complete_data, stringsAsFactors = FALSE)
    all_data[[length(all_data) + 1]] <- df
  }
  
  # Combine all dataframes into a single dataframe
  result_df <- do.call(rbind, all_data)
  
  return(result_df)
}

args = commandArgs(trailingOnly=TRUE)

tree_dir <- args[1]
csv_dir <- args[2]
gen_dir <- args[3] 

# read all csv data results files
data_results <- list.files(csv_dir, full.names = TRUE)
tree_paths <- list.files(tree_dir, full.names = TRUE)

for (tree_path in tree_paths) {
  # Use regular expressions to extract the type (exante/expost)
  type_match <- regmatches(tree_path, regexpr("expost|exante", tree_path))
  type <- type_match
  # Use regular expressions to extract the country_year (any pattern between 'tree_' and '_all')
  country_year_match <- regmatches(tree_path, regexpr("(?<=tree_)[^_]+_[0-9]{4}(?=_all)", tree_path, perl = TRUE))
  
  # Split the country_year to get country_code and year
  country_year_split <- unlist(strsplit(country_year_match, "_"))
  country_code <- country_year_split[1]
  year <- country_year_split[2]
  
  # Load data and "tree" object
  x <- load(tree_path)
  tree <- if (x == "exante_tree") {
    get(x)
  } else {
    get(x)[["tree"]]
  }
  rm(x)
  
  # Find the corresponding CSV file in data_results that matches country_year
  country_year_match <- paste0("_", country_year_match)
  csv_path <- data_results[grep(country_year_match, data_results)][1]
  #print(csv_path)
  data <- ""
    
  # Check if a matching CSV file was found
  if (length(csv_path) == 1) {
    # Read the matched CSV file
    data <- read.csv(csv_path, row.names = 1)
    # Print the paths and extracted variables
    print(c(tree_path, csv_path, country_code, year, type))
  } else {
    # Handle the case where no match or multiple matches were found
    warning(paste("No match or multiple matches found for", country_year_match))
  }
  
  # Transform tree
  modified_tree <- modify_tree(data = data, tree = tree, dep = "income", wts = "weights", norm = TRUE)

  # Create an empty general data frame with specified column names
  column_names <- c("Country_Code", "Year", "Type", "Box_Number", "Relative_Type_Mean", "Pop_Share", "Birth_Area", "Father_Edu", "Mother_Edu", "Father_Occ", "Mother_Occ", "Ethnicity", "Sex")
  general_df <- data.frame(matrix(ncol = length(column_names), nrow = 0))
  colnames(general_df) <- column_names
  
  # get all node paths data
  all_node_paths <- get_all_node_paths(modified_tree$node, modified_tree$data)
  
  # Create the dataframe from path_to_node data
  df_data_paths <- create_dataframe_from_paths(all_node_paths, colnames(general_df))
  
  # Merge the created dataframe with general_df
  final_df <- rbind(general_df, df_data_paths)
  
  write.csv(final_df, file = paste(gen_dir, "/", country_code, "_", year, "_", type, ".csv", sep = ""), row.names = FALSE)
  
  tree_json <- get_tree_structure_json(modified_tree$node, modified_tree$data)
  tree_json_string <- toJSON(tree_json, pretty = TRUE, auto_unbox = TRUE)
  # cat(tree_json_string)
  # Write the JSON string to a file using jsonlite
  write(tree_json_string, paste(gen_dir, "/", country_code, "_", year, "_", type, ".json", sep = ""))
}
