#
# To be used occassionally but admin if an installed genome needs to be reprocessed to update any figures.
#
# Arguments:
#	$1 = user account.
#	$2 = genome name.
#
bash genome.install_6.sh $1 $2 > ../users/$1/genomes/$2/process_log.txt;
