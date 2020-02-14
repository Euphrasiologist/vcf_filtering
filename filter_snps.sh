#!/usr/bin/env bash

# Max Brown 14.2.20. Please use, share, modify as you see fit.
# This script is loosely based on https://github.com/jpuritz/dDocent/blob/master/scripts/filter_missing_ind.sh

# A friendly wrapper for filtering SNPs by amount of missing data.

######## Housekeeping ########
# Check vcftools version on the machine

VCFTOOLSVERSION=$(vcftools | awk '/VCF/' | grep -oh '[0-9]*' | tail -1)

printf "You are running vcftools version 0.1.%s\n" $VCFTOOLSVERSION

if [ "$VCFTOOLSVERSION" -lt "10" ]; then
    printf "Please install a later version of vcftools at https://vcftools.github.io/index.html"
    exit 1
fi

printf "Checking VCF file...\n"

if [[ -z $1 ]]; then
    printf "Usage: filter_snps.sh [vcf OR vcf.gz] [missing data tolerated] [output prefix]\n"
    exit 1
fi

# Check the version of the VCF file itself
# check for .gz file ending
match_gz="\\.gz$"

if [[ $1 =~ $match_gz ]]; then
    VCFVERSION=$(zcat $1 | head | grep -oh "[[:digit:]]\\..*")
    printf "Gzipped VCF file detected...\n"

elif ! [[ $1 =~ $match_gz ]]; then
    VCFVERSION=$(cat $1 | head | grep -oh "[[:digit:]]\\..*")
    printf "VCF file found...\n"
fi

CORRECTVERS="4.0|4.1|4.2"

if ! [[ $VCFVERSION =~ $CORRECTVERS ]]; then
    printf "You have an old VCF version. Please make an updated VCF file.\n"
    exit 1
fi

######## Run vcftools ########

# stop if second argument not supplied.
if [[ -z "$2" ]]; then
    printf "Please supply a number from 0-1 representing the maximum percent of missing data tolerated. e.g. 0.25\n"
    exit 1
fi

# stop if third argument not supplied
if [[ -z "$3" ]]; then
    printf "Please give output prefix.\n"
    exit 1
fi

# if .gz file
if [[ $1 =~ $match_gz ]]; then
    vcftools --gzvcf $1 --max-missing $2 --out $3 --recode --recode-INFO-all
# if not .gz file
elif ! [[ $1 =~ $match_gz ]]; then
    vcftools --vcf $1 --max-missing $2 --out $3 --recode --recode-INFO-all
fi