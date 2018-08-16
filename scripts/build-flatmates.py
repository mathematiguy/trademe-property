#!/usr/bin/env python3
"""
Combines the data in trademe/data into one table.

TO DO: Add some tests to make sure the input data is correct.
"""


import os
import logging
import argparse
import numpy as np
import pandas as pd


def read_data(filepath):
    """
    Read and clean a csv at filepath
    """
    data_cols = ['additional_costs', 'available', 'bedrooms', 'couples_ok', 
    	'current_flatmates', 'date', 'description', 'furnishings', 'id_number',
    	'ideal_flatmate', 'in_the_area', 'location', 'parking', 'rent', 'title', 
    	'url', 'view_count']
    df = pd.read_csv(filepath)
    df = df.reindex(columns = data_cols)
    return df


def main():
    logger = logging.getLogger(__name__)
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-path', default='trademe/data',
                        help="data directory")
    parser.add_argument('--output-name', default='flatmates.csv',
                        help="path to put flatmates.csv")
    parser.add_argument('--log-level', default='INFO',
                        help="Log level")
    
    args = parser.parse_args()

    logging.basicConfig(level=args.log_level)

    data_paths = [os.path.join(args.data_path, f) for f in  os.listdir(args.data_path) if f.endswith(".csv")]
    data_dfs = [read_data(fp) for fp in data_paths]
    
    for df in data_dfs:
        logger.debug("%d columns", df.shape[1])
        logger.debug("Column names: %s", df.columns)
        logger.debug("df.head():\n%s", df.head())
    data_df = pd.concat(data_dfs, axis = 0, sort = False)
    
    logger.info("Output:\n%s", data_df.head())

    logger.info("Writing output to: %s", args.output_name)
    data_df.to_csv(args.output_name, index = False)


if __name__ == "__main__":
    main()