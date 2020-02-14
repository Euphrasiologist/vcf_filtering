# Filtering VCF files by missing data.

## vcftools

For these scripts to work, you will need to download vcftools:

https://vcftools.github.io/index.html


## Usage

These are BASH scripts with options. I haven't yet added flags to be more explicit, but maybe one day! For example the script filter_snps.sh:

`bash filter_snps.sh [vcf OR vcf.gz] [missing data tolerated] [output prefix]`

The help should be printed if the script is supplied with zero arguments.
