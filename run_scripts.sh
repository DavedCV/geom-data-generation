#!/bin/bash

# Check if at least six arguments are provided
if [ $# -lt 5 ]; then
    echo "Usage: $0 arg1 arg2 arg3 arg4 arg5 [more_args ...]"
    exit 1
fi

# Extract arguments for R script
R_ARG1=$1
R_ARG2=$2
R_ARG3=$3

# Extract arguments for Python script
PY_ARG1=$4
PY_ARG2=$5

# Any additional arguments
shift 5
MORE_ARGS="$@"

# Run the R script with its specific arguments
Rscript csv_generator.R "$R_ARG1" "$R_ARG2" "$R_ARG3"

# Check if the R script ran successfully
if [ $? -ne 0 ]; then
    echo "R script failed to run"
    exit 1
fi

# Run the Python script with its specific arguments
python csv_labels_transformation.py "$R_ARG3" "$PY_ARG1" "$PY_ARG2"

# Check if the Python script ran successfully
if [ $? -ne 0 ]; then
    echo "Python script failed to run"
    exit 1
fi

# Run the Python script with its specific arguments
python json_labels_transformation.py "$R_ARG3" "$PY_ARG1" "$PY_ARG2"

# Check if the Python script ran successfully
if [ $? -ne 0 ]; then
    echo "Python script failed to run"
    exit 1
fi

echo "The scripts ran successfully"
