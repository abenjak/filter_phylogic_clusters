# reproduce the clustering in in_absolute_total_sequenza by using a bash loop

# clustering round1 already done
r=1
# for fname in Cluster.round${r}.blacklist/*log; do tail -n2 $fname | head -1; done | sort -k2,2nr | grep -v -P "\t0$" > Cluster.round${r}.blacklisted_samples.txt

if [  $(wc -l < Cluster.round${r}.blacklisted_samples.txt) -eq 0 ]; then
    echo clustering done
else
    while :
    do
        r=$(( $r + 1 ))
        # Copy everything from the previous clustering and just do the needed samples
        cp -r Cluster.round$(( $r - 1 )) Cluster.round${r} &&cd Cluster.round${r}
        # cut -f1 ../Cluster.round$(( $r - 1 )).blacklisted_samples.txt | while read fname; do
		for fname in $(cut -f1 ../Cluster.round$(( $r - 1 )).blacklisted_samples.txt); do
            srun -J $fname --mem 5000 -t 1000 -o $fname.log -e $fname.log singularity exec -B /storage/ibu_wes_pipe/postprocessing/phylogicNDT/PhylogicNDT/ -B /storage/ibu-projects/p375_HNSCC_ZimmerAebersold /storage/ibu_wes_pipe/postprocessing/phylogicNDT/images/phylogicNDT.v1.img /storage/ibu_wes_pipe/postprocessing/phylogicNDT/PhylogicNDT/PhylogicNDT.py Cluster -i $fname -sif ../sif/$fname.sif --order_by_timepoint -ni 1000 --driver_genes_file /storage/ibu-projects/p375_HNSCC_ZimmerAebersold/PhylogicNDT/IntOGen-DriverGenes_HNSC.list --seed 123 -bl ../Cluster.round$(( $r - 1 )).blacklist/$fname.blacklist.txt &
        done &&wait &&cd ..

        # filter clusters (use --old_blacklist)
        cp -r Cluster.round$(( $r - 1 )).blacklist Cluster.round${r}.blacklist &&cd Cluster.round${r}.blacklist
        for fname in ../Cluster.round${r}/*.mut_ccfs.txt; do
            srun -o $(basename $fname .mut_ccfs.txt).blacklist.log -e $(basename $fname .mut_ccfs.txt).blacklist.log singularity exec -B /storage/ibu-projects/p375_HNSCC_ZimmerAebersold/PhylogicNDT /storage/ibu_wes_pipe/postprocessing/phylogicNDT/images/phylogicNDT.v1.img Rscript ../filter_clusters.R --old_blacklist ../Cluster.round$(( $r - 1 )).blacklist/$(basename $fname .mut_ccfs.txt).blacklist.txt --cancer_genes ../../IntOGen-DriverGenes_HNSC.list $fname &
        done &&wait &&cd ..

        #Which samples got something blacklisted:
        for fname in Cluster.round${r}.blacklist/*log; do tail -n2 $fname | head -1; done | sort -k2,2nr | grep -v -P "\t0$" > Cluster.round${r}.blacklisted_samples.txt
        if [ $(wc -l < Cluster.round${r}.blacklisted_samples.txt) -eq 0 ]
            then
            echo clustering done
            break
        fi
    done
fi
