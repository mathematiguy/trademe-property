#!/usr/bin/env python3
"""
Combines the data in trademe/data into one table.

TO DO: Add some tests to make sure the input data is correct.
"""


import os
import logging
import argparse
from datetime import datetime
import numpy as np
import pandas as pd


def ascii_filter(s):
    if not isinstance(s, str):
        return s
    else:
        return "".join(filter(lambda x: ord(x)<128, s))


def infer_listed_date(listed_date):
    now = datetime.now()
    listed_date = listed_date.str.extract("Listed: (.+)$", expand = False)
    listed_date = listed_date.str.replace(",", " {}".format(now.year))
    listed_date = pd.to_datetime(listed_date, format = "%a %d %b %Y %H:%M %p")
    listed_date[listed_date > now] = listed_date[listed_date > now].apply(lambda t: t.replace(year = now.year  - 1))
    return listed_date


def infer_available_time(available):
    now = datetime.now()
    available_years = {}
    for year in range(now.year-1, now.year+2):
        available_years[year] = available + " {}".format(year)
    available_years = pd.DataFrame(available_years)
    available_years = available_years.apply(lambda x: pd.to_datetime(x, format="%a %d %b %Y", errors='coerce'))
    closest_year = pd.DataFrame(
        available_years.apply(lambda x: available_years.columns[np.abs(x - now).values.argmin()], axis = 1),
        columns = ['year'])
    year_comparison = pd.concat([pd.to_datetime(available + " {}".format(now.year),
        format="%a %d %b %Y", errors='coerce'), closest_year], axis = 1)
    year_comparison = year_comparison.apply(lambda x: x.available.replace(year = x.year), axis = 1)
    return year_comparison


def process_data(filepath):
    """
    Read and clean a csv at filepath
    """
    data_cols = ['additional_costs', 'available', 'bedrooms', 'couples_ok', 
    	'current_flatmates', 'listed_date', 'description', 'furnishings', 'id_number',
    	'ideal_flatmate', 'in_the_area', 'location', 'parking', 'rent', 'title', 
    	'url', 'view_count']
    df = pd.read_csv(filepath)
    df = df.reindex(columns = data_cols)
    df = df.applymap(ascii_filter)

    df['region'] = df.location.str.extract(",([^,]+)$", expand=False)
    df['area']   = df.location.str.extract(", ([A-z\s/]+), ", expand=False)
    df['suburb'] = df.location.str.extract("^([A-z\s/]+),", expand=False)
    df.loc[df.area.isna(), 'area'] = df.loc[df.area.isna(), 'suburb']
    
    df['listed_date']    = infer_listed_date(df.listed_date)
    df['available_date'] = infer_available_time(df.available)

    df['bedrooms']  = df.title.str.extract("([0-9\+]+) bedrooms?", expand=False)
    df['id_number'] = df.id_number.str.extract("([0-9]+)", expand=False)
    df['rent']      = df.rent.str.extract("\$([0-9\.]+)", expand=False)

    finished_cols = ['id_number', 'region', 'area', 'suburb', 'rent',
        'listed_date', 'available_date', 'furnishings', 
        'current_flatmates', 'ideal_flatmate', 'couples_ok', 'parking',
        'in_the_area', 'description', 'url', 'view_count']

    df = df.loc[:, finished_cols]

    return df


def main():
    global logger
    logger = logging.getLogger(__name__)
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-path', default='trademe/data',
                        help="data directory")
    parser.add_argument('--output-path', default='flatmates.csv',
                        help="path to put flatmates.csv")
    parser.add_argument('--log-level', default='INFO',
                        help="Log level")
    
    args = parser.parse_args()

    logging.basicConfig(
        level=args.log_level,
        format='[%(asctime)s] | line %(lineno)d | %(levelname)s | %(message)s',
        datefmt='%H:%M:%S')

    data_paths = [os.path.join(args.data_path, f) for f in  os.listdir(args.data_path) if f.endswith(".csv")]
    data_dfs = [process_data(fp) for fp in data_paths]
    
    for df in data_dfs:
        # log details for each table
        logger.debug("%d columns", df.shape[1])
        logger.debug("Column names: %s", df.columns)
        logger.debug("df.head():\n%s", df.head())

    data_df = pd.concat(data_dfs, axis = 0, sort = False)
    
    logger.info("Output:\n%s", data_df.head())

    logger.info("Writing output to: %s", args.output_path)
    data_df.to_csv(args.output_path, index = False)


if __name__ == "__main__":
    main()