#!/usr/bin/env bash

# Max Brown 15.2.20. Please use, share, modify as you see fit.
# This script is loosely based on https://github.com/jpuritz/dDocent/blob/master/scripts/filter_missing_ind.sh

# A friendly wrapper for filtering individuals by amount of missing data.

######## Housekeeping ########
# Check vcftools version on the machine

# if no arguments
if [[ -z $1 ]]; then
    printf "Error. No arguments supplied.\nUsage: filter_inds.sh [vcf OR vcf.gz] [missing data tolerated] [output prefix]\n"
    exit 1
fi

VCFTOOLSVERSION=$(vcftools | awk '/VCF/' | grep -oh '[0-9]*' | tail -1)

printf "You are running vcftools version 0.1.%s\n" $VCFTOOLSVERSION

if [ "$VCFTOOLSVERSION" -lt "10" ]; then
    printf "Please install a later version of vcftools at https://vcftools.github.io/index.html\n"
    exit 1
elif [ "$VCFTOOLSVERSION" -lt "13" ]; then
        VCFMISSINGFLAG="--missing"
elif [ "$VCFTOOLSVERSION" -ge "13" ]; then
        VCFMISSINGFLAG="--missing-indv"
fi

printf "Checking VCF file...\n"

# Check the version of the VCF file itself
# check for .gz file ending
match_gz="\\.gz$"

if [[ $1 =~ $match_gz ]]; then
    # check that the VCF is the correct format. If there is a match, 1 should return.
    CHECKVCFGZ=$(zcat $1 | head -1 | grep -ohc "##fileformat=VCF")
    if [[ $CHECKVCFGZ =~ "0" ]]; then
        printf "Incorrect VCF format, please check the VCF is not corrupt.\n"
        exit 1
    fi    
    # the argument for later
    VCFARG="--gzvcf"
    # save the vcf version
    VCFVERSION=$(zcat $1 | head | grep -oh "[[:digit:]]\\..*")
    printf "Gzipped VCF file detected...\n"

elif ! [[ $1 =~ $match_gz ]]; then
    # check that the VCF is the correct format. If there is a match, 1 should return.
    CHECKVCFGZ=$(cat $1 | head -1 | grep -ohc "##fileformat=VCF")
    if [[ $CHECKVCFGZ =~ "0" ]]; then
        printf "Incorrect VCF format, please check the VCF is not corrupt.\n"
        exit 1
    fi    
    # the argument for later
    VCFARG="--vcf"
    # save the vcf version
    VCFVERSION=$(cat $1 | head | grep -oh "[[:digit:]]\\..*")
    printf "Unzipped VCF file detected...\n"

fi
# currently these are the correct versions.
CORRECTVERS="4.0|4.1|4.2"

if ! [[ $VCFVERSION =~ $CORRECTVERS ]]; then
    printf "You have an old VCF version. Please make an updated VCF file.\n"
    exit 1
fi

# stop if second argument not supplied.
if [[ -z "$2" ]]; then
    printf "Please supply a number from 0-1, individuals with more than this proportion of missing data will be removed. e.g. 0.25\n"
    exit 1
fi

# stop if third argument not supplied
if [[ -z "$3" ]]; then
    printf "Please give prefix for output file.\n"
    exit 1
fi

######## Run vcftools ########

# call vcftools to calculate the percent missing data per individual.
vcftools $VCFARG $1 $VCFMISSINGFLAG --out $3 

# explicitly say what the threshold is
THRESHOLD=$(awk "BEGIN {print $2*100; exit}")

printf "Individuals with more than %.0f percent missing data will be removed\n" $THRESHOLD

# 5th column is the percent missingness
sort -n -k5 $3.imiss | awk -v x=$2 '$5<x {print $1}' | awk 'NR>1' > MISSINGINDS

NMISSINGINDS=$(sort -n -k5 $3.imiss | awk -v x=$2 '$5<x {print $1}' | awk 'NR>1' | awk 'END {print NR - 1}')

printf "%d individuals deleted from the VCF file.\n" $NMISSINGINDS

vcftools $VCFARG $1 --remove ./MISSINGINDS --recode --recode-INFO-all --out $3

printf "Finished!\n"