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
  if [[ $category == "combined" || -f $category ]]; then
    continue
  fi
  pattern="$data_dir/$category/*.csv"
  files=( $pattern )
  
  # save to `/tmp` so MySQL can load the files
  # (LOAD INFILE requires csv files in MySQL data directory or
  #  the whole directory readable to everyone)
  # add a `github__` prefix so we can locate the files more easily
  destfile="/tmp/github__${category}.csv" 
  
  if [[ -f $destfile ]]; then
    echo "Skip $pattern.."
    continue
  fi
  
  echo "Merging $pattern .."
  # use the first line of the first file as column header
  head -n 1 "${files[0]}" > $destfile;
  # skip the first line of all files under in the category directory
  # replace NA with NULL so MySQL can recognize
  tail -q -n +2 $pattern | sed -e s/,NA,/,NULL,/ >> "/tmp/github__${category}.csv"
done
