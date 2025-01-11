#!/bi
#n/bash -e
#
# genome.install_6.sh
#
set -e;
## All created files will have permission 760
umask 007;

##
## Script changes the chr_bin_SNP width used for figures using this genome.
## After running this script, update figures for dataset of interest using YMAP:UI.
##

user="default";
genome="Candida_haemulonii_B11899__GCF_002926055.2_RefSeq";

#echo "700" > /var/www/html/ymap/users/$user/genomes/$genome/resolution.SNPs.txt;
#rm /var/www/html/ymap/users/$user/genomes/$genome/datafile_g_0.standard_bins.SNPs.fasta;

sh genome.install_6.sh $user $genome;
