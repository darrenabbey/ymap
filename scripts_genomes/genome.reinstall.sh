#!/bi
#n/bash -e
#
# genome.install_6.sh
#
set -e;
## All created files will have permission 760
umask 007;

user="default";
genome="Candida_parapsilosis_CDC317_s01-m03-r62_CGD";

sh genome.install_6.sh $user $genome;
