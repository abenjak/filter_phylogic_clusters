# filter_phylogic_clusters
### Iterative filtering of [PhylogicNDT](https://github.com/broadinstitute/PhylogicNDT) clusters

Some PhylogicNDT clusters can consists of only few variants. Small clusters likely derive from artefactual variants and are not reliable.
The idea is to filter out variants that make up small clusters, and redo the PhylogicNDT clustering.


### !!! This is work in progress, pretty much unusable ATM !!!


`cluster.sh ` assumes we did the 1st filtering step. Something like this:
```
# Clustering round 1
r=1
mkdir Cluster.round${r} &&cd Cluster.round${r}
l ../sif/*.sif | while read fname
do
  srun -J $(basename $fname .sif) --mem 5000 -t 1000 -o $(basename $fname .sif).log -e $(basename $fname .sif).log singularity exec -B /storage/ibu_wes_pipe/postprocessing/phylogicNDT/PhylogicNDT/ -B /storage/ibu-projects/p375_HNSCC_ZimmerAebersold /storage/ibu_wes_pipe/postprocessing/phylogicNDT/images/phylogicNDT.v1.img /storage/ibu_wes_pipe/postprocessing/phylogicNDT/PhylogicNDT/PhylogicNDT.py Cluster -i $(basename $fname .sif) -sif $fname --order_by_timepoint -ni 1000 --driver_genes_file /storage/ibu-projects/p375_HNSCC_ZimmerAebersold/PhylogicNDT/IntOGen-DriverGenes_HNSC.list --seed 123&
done &&cd ..


# remove clusters with less than 5 variants
# blacklist must only have these cols: Chromosome  Start_position  Reference_Allele  Tumor_Seq_Allele
# Min clust default = 5.
mkdir Cluster.round${r}.blacklist
cd Cluster.round${r}.blacklist
for fname in ../Cluster.round${r}/*.mut_ccfs.txt
do
  srun -o $(basename $fname .mut_ccfs.txt).blacklist.log -e $(basename $fname .mut_ccfs.txt).blacklist.log singularity exec -B /storage/ibu-projects/p375_HNSCC_ZimmerAebersold/PhylogicNDT /storage/ibu_wes_pipe/postprocessing/phylogicNDT/images/phylogicNDT.v1.img Rscript ../../filter_clusters.R --cancer_genes ../../IntOGen-DriverGenes_HNSC.list $fname &
done &&cd ..

#Which samples got something blacklisted:
for fname in Cluster.round${r}.blacklist/*log; do tail -n2 $fname | head -1; done | sort -k2,2nr | grep -v -P "\t0$"
```
