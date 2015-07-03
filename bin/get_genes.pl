use strict;
use warnings;
use Data::Dumper;
use Bio::EnsEMBL::Registry;


my $reg = "Bio::EnsEMBL::Registry";
$reg->load_registry_from_url('mysql://anonymous@ensembldb.ensembl.org');

my $gene_adaptor = $reg->get_adaptor("zebrafish", "core", "Gene"); 

while(<>) {
 chomp;
 my($allele, $ens_id) = split/\s+/,$_;
 my $gene = $gene_adaptor->fetch_by_stable_id("$ens_id");
 my $ext_name;
 eval { $ext_name = $gene->external_name };
 if (defined($ext_name)){
  print join("\t", $allele, $ext_name), "\n";
 } else {
  print join("\t", $allele, $ens_id), "\n";
 }
}

