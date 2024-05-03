#!/bin/sh 

#write stdout to txt file
exec > Pre-processing_StdOut.txt

#make sure to module load cutadapt in Terminal prior to running script
#make sure that NGmerge and FastX are downloaded and available in this environment
which cutadapt
which NGmerge
echo ""


#trim gene-specific primers via Cutadapt
#expect to trim read 1 (33 nt 5' + 84 nt 3') / read 2 (32 nt 5' + 85 nt 3'),
#leaving total size of 33 nt

cutadapt --cores=0 -a ^CAAGTGAGCTCTCCGAAACCACAGATAATATAT...AATTTCAATTATTGTACTGGCATCCTGGGCTC -A ^GAGCCCAGGATGCCAGTACAATAATTGAAATT...ATATATTATCTGTGGTTTCGGAGAGCTCACTTG -o HsD_1a3_trimmed.1.fastq.gz -p HsD_1a3_trimmed.2.fastq.gz HsD_1a3_CKDL220025217-1A_HJ2W5CCX2_L7_1.fq.gz HsD_1a3_CKDL220025217-1A_HJ2W5CCX2_L7_2.fq.gz



#get consensus b/w PE reads (overlap matching) using NGmerge
#dovetail mode (remove 3' overhangs)
#use slightly rounded up error rate to accommodate 39nt -> 4nt mismatch allowed
#add unzip output mode (-y) for fastx input in next step
#add -u 41 argument for Phred+33 (0,41) encoding that includes J
#use modified qual_profile.txt matrix that treats J the same as I

echo "" ; echo "NGmerge"

NGmerge -d -p 0.105 -1 HsD_1a3_trimmed.1.fastq.gz -2 HsD_1a3_trimmed.2.fastq.gz -u 41 -w /fh/fast/malik_h/user/jtenthor/Scripts/qual_profile_41.txt -y -o HsD_1a3_trimmed_merged.fastq -l mergelog.txt

#count successfully merged sequences
echo "Succesful merge count"
cat HsD_1a3_trimmed_merged.fastq | echo $((`wc -l`/4))

#find length distribution of overlaps and stitched reads
echo "Number of seqs with 33nt overlap"
awk -F '\t' '{print $2}' mergelog.txt | grep "^33$" | wc -l
echo "Number of seqs with 33nt merge length"
awk -F '\t' '{print $3}' mergelog.txt | grep "^33$" | wc -l



#use fastX to filter reads that don't meet min Q score of 20 or 25 at every remaining base
echo ""; echo "FastX quality filter"
fastq_quality_filter -v -q 20 -p 100 -i HsD_1a3_trimmed_merged.fastq -o HsD_1a3_trimmed_merged_filter20.fastq
	
fastq_quality_filter -v -q 25 -p 100 -i HsD_1a3_trimmed_merged.fastq -o HsD_1a3_trimmed_merged_filter25.fastq



#collapse remaining reads to unique sequences and counts/seq using fastX
echo ""; echo "FastX collapser"

fastx_collapser -v -i HsD_1a3_trimmed_merged_filter20.fastq -o HsD_1a3_preprocessedQ20.fasta
	
fastx_collapser -v -i HsD_1a3_trimmed_merged_filter25.fastq -o HsD_1a3_preprocessedQ25.fasta