#!/usr/bin/env bash

# -------------------------------------
# Merge scraped data into one .csv file
# so we can import them into MySQL using
# LOAD INFILE
# -------------------------------------

data_dir="/srv/github_data"
cd $data_dir
mkdir -p ./combined

for category in `ls ./`; do
  if [[ $category == "combined" || $category =~ ".csv" ]]; then
    continue
  fi
  pattern="$data_dir/$category/*.csv"
  files=( $pattern )
  # use the first line of the first file as column header
  echo "Merging $pattern .."
  # save to `/tmp` so MySQL can load the files
  # (LOAD INFILE requires csv files in MySQL data directory or
  #  the whole directory readable to everyone)
  # add a `github__` prefix so we can locate the files more easily
  head -n 1 "${files[0]}" > "/tmp/github__${category}.csv" ;
  # skip the first line of all files under in the category directory
  tail -q -n +2 "${files[0]}" >> "/tmp/github__${category}.csv"
done
