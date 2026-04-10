#!/bi
#n/bash -e
#
# genome.install_6.sh
#
set -e;
## All created files will have permission 760
umask 007;

singleGenome=true;
user='darren';

if [ "$singleGenome" = true ]; then
	## reinstall single genomes in user account.
	genome="Phaseolus_vulgaris_YP4";
	sh genome.install_6.sh $user $genome;
else
	## reinstall all genomes in user account.
	directory='/var/www/html/ymap/users/default/genomes';
	cd $directory;
	for file in *; do
		cd '/var/www/html/ymap/scripts_genomes';

		if [ -f "$file" ]; then
			# item is a file, ignore.
			echo "";
		else
			# item is a directory.
			echo $file;
			genome=$file;
			sh genome.install_6.sh $user $genome;
			echo "\tdone."
		fi
	done
fi
