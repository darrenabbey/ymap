#!/bin/bash
#
# cleaning_WGseq.sh
set -e

## All created files will have permission 760
umask 007;

user="$1";
project="$2";
main_dir="$3";
projectDirectory="$main_dir/users/$user/projects/$project";
scriptDirectory=$PWD;
logName="$projectDirectory/process_log.txt";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "Something went wrong. cleaning_WGseq.sh:$LINENO"; install /dev/null "$projectDirectory/error.txt"; echo -e "Something went wrong. cleaning_WGseq.sh:$LINENO" > "$projectDirectory/error.txt"; cd $main_dir; exit 1;' ERR;

condensedLog="$projectDirectory/condensed_log.txt";

##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------

. $main_dir"/config.sh";
if [[ "$debug" -eq 1 ]]; then
	echo -e "\tReached cleanup stage, but skipping it because the debug flag is on." >> $logName;
	echo -e "\tCreating complete.txt, so that the front-end recognizes the completion." >> $logName;

	completeFile="$projectDirectory/complete.txt";
	echo -e "complete" > "$completeFile";
	timestamp=$(date +%T);
	echo "$timestamp" >> "$completeFile";
	echo -e "\tGenerated 'complete.txt' file." >> $logName;
	chmod 0774 "$completeFile";

	## changing working.txt to working_done.txt
	if [[ -f "$projectDirectory/working.txt" ]]
	then
		mv "$projectDirectory/working.txt" "$projectDirectory/working_done.txt";
		echo -e "\t changed working.txt to working_done.txt" >> $logName;
	fi

	exit 0;
fi

echo -e "#=======================================#" >> $logName;
echo -e "# Cleaning up intermediate WGseq files. #" >> $logName;
echo -e "#=======================================#" >> $logName;
echo -e "Cleaning and archiving." >> $condensedLog;

if [[ -f "$projectDirectory/zipTemp.txt" ]]; then
	rm "$projectDirectory/zipTemp.txt";
	echo -e "\tzipTemp.txt" >> $logName;
fi

if [[ -f "$projectDirectory/processing1.m" ]]; then
	rm "$projectDirectory/processing1.m";
	echo -e "\tprocessing1.m" >> $logName;
fi

if [[ -f "$projectDirectory/processing2.m" ]]; then
	rm "$projectDirectory/processing2.m";
	echo -e "\tprocessing2.m" >> $logName;
fi

if [[ -f "$projectDirectory/processing3.m" ]]; then
	rm "$projectDirectory/processing3.m";
	echo -e "\tprocessing3.m" >> $logName;
fi

if [[ -f "$projectDirectory/processing4.m" ]]; then
	rm "$projectDirectory/processing4.m";
	echo -e "\tprocessing4.m" >> $logName;
fi

if [[ -f "$projectDirectory/data_sorted.bam.bai" ]]; then
	rm "$projectDirectory/data_sorted.bam.bai";
	echo -e "\tdata_sorted.bam.bai" >> $logName;
fi

if [[ -f "$projectDirectory/data_sorted.bam" ]]; then
	rm "$projectDirectory/data_sorted.bam";
	echo -e "\tdata_sorted.bam" >> $logName;
fi
if [[ -f "$projectDirectory/data.bam" ]]; then
	rm "$projectDirectory/data.bam";
	echo -e "\tdata.bam" >> $logName;
fi
if [[ -f "$projectDirectory/data.pileup" ]]; then
	rm "$projectDirectory/data.pileup";
	echo -e "\tdata.pileup" >> $logName;
fi
if [[ -f "$projectDirectory/data_indelRealigned.bam" ]]; then
	rm "$projectDirectory/data_indelRealigned.bam";
	echo -e "\tdata_indelRealigned.bam" >> $logName;
fi
if [[ -f "$projectDirectory/data_indelRealigned.bai" ]]; then
	rm "$projectDirectory/data_indelRealigned.bai";
	echo -e "\tdata_indelRealigned.bai" >> $logName;
fi

if [[ -d "$projectDirectory/fastqc_temp/" ]]; then
	rm -rf "$projectDirectory/fastqc_temp/";
	echo -e "\tfastqc_temp/" >> $logName;
fi
if [[ -f "$projectDirectory/datafiles.txt" ]]; then
	# Get first data file name from "datafiles.txt";
	datafile1=$(head -n 1 "$projectDirectory/datafiles.txt");
	echo -e "\tdatafile 1 = $datafile1" >> $logName;
	# Get second data file name from "datafiles.txt";
	datafile2=$(tail -n 1 "$projectDirectory/datafiles.txt");
	echo -e "\tdatafile 2 = $datafile2" >> $logName;
	if [[ "$datafile1" = "$datafile2" ]]
	then
		# deleting only if a valid file name is written
		if [[ "$datafile1" != "null1" ]]
		then
			if [[ -f "$projectDirectory/$datafile1" ]]
			then
				rm "$projectDirectory/$datafile1";
				echo -e "\t$datafile1" >> $logName;
			fi
		fi
	else
		if [[ -f "$projectDirectory/$datafile1" ]]
		then
			rm "$projectDirectory/$datafile1";
			echo -e "\t$datafile1" >> $logName;
		fi
		if [[ -f "$projectDirectory/$datafile2" ]]
		then
			rm "$projectDirectory/$datafile2";
			echo -e "\t$datafile2" >> $logName;
		fi
	fi
	rm "$projectDirectory/datafiles.txt";
	echo -e "\tdatafiles.txt" >> $logName;
fi


##==============================================================================
## Generate ZIP archives
##------------------------------------------------------------------------------
cd "$projectDirectory";

# Compress octave log files.
if [[ -f octave_logs.zip ]]; then
        rm octave_logs.zip;
fi
zip -j -9 octave_logs.zip octave.*.log;

# Compress 'putative_SNPs_v1.txt' and 'SNP_CNVs_v1.txt'.
if [[ -f putative_SNPs_v4.txt ]]; then
	zip -j -9 putative_SNPs_v4.zip putative_SNPs_v4.txt;
	rm putative_SNPs_v4.txt;
	echo -e "\tputative_SNPs_v4.txt => putative_SNPs_v4.zip" >> $logName;
fi
if [[ -f SNP_CNV_v1.txt ]]; then
	zip -j -9 SNP_CNV_v1.zip SNP_CNV_v1.txt;
	rm SNP_CNV_v1.txt;
	echo -e "\tSNP_CNV_v1.txt => SNP_CNV_v1.zip" >> $logName;
fi

# Compress output files.
if [[ -f output_figures.zip ]]; then
	rm output_figures.zip;
fi
zip -j output_figures.zip fig.*.eps fig.*.png *.bed *.gff3 -x "fig.Rsquared*" "fig.Charm*" @;

cd "$scriptDirectory";


## Generate "complete.txt" to indicate processing has completed normally.
timestamp=$(date +%T);
completeFile="$projectDirectory/complete.txt";
echo -e "complete" > $completeFile;
echo -e "$timestamp" >> $completeFile;
echo -e "\tGenerated 'complete.txt' file." >> $logName;
chmod 0774 "$completeFile";

if [[ -f "$projectDirectory/working.txt" ]]; then
	mv "$projectDirectory/working.txt" "$projectDirectory/working_done.txt";
	echo -e "\tworking.txt" >> $logName;
fi
