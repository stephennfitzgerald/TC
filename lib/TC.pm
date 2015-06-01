package TC;
  
use Dancer2;
use File::Path qw(make_path);
use Excel::Writer::XLSX;
use Data::Dumper;
use Carp;
use DBI;

our $VERSION = '0.1';
our $db_name = "zfish_sf5_tc2_test";
our %check_hash = ();
our @alleles;
our $exel_file_dir = "./public/zmp_exel_files"; # need to change
our $image_dir = "./public/images"; 

our %genotypes_c = (
     'Blank'    => 0,
     'Hom'      => 'homozygous mutant',
     'Het'      => 'heterozygous',
     'Wildtype' => 'wild type',
     'Failed'   => 0,
     'Missing'  => 0,
);

our %spike_ids = ( 
     '0'        => 'No spike mix',
     '1'        => 'ERCC spike mix 1 (Ambion)',
     '2'        => 'ERCC spike mix 2 (Ambion)',
);

our %visability = (
  1 => "Public",
  2 => "Hold",
);


get '/' => sub {
    
 template 'index', { 
  'existing_experiments_url' => uri_for('/existing_experiments'),
  'get_new_experiment_url'   => uri_for('/get_new_experiment'),
 };
       
};

get '/get_new_experiment' => sub {

 my $dbh = get_schema();

 my $sth1 = $dbh->prepare("DESC showExpView");
 my $sth2 = $dbh->prepare("SELECT Genome_ref_name FROM speciesView"); 
 my $dev_sth = $dbh->prepare("SELECT id, GROUP_CONCAT(begins, '  ', stage) time_stage \
                             FROM developmental_stage GROUP BY id ORDER BY id");
 my $prev_exp = $dbh->prepare("SELECT exp.name, std.name, ale.name, exp.phenotype_description, exp.lines_crossed, \
                              exp.founder, GROUP_CONCAT(dev.begins, ':', dev.stage) time_stage, \
                              exp.spike_mix, exp.spike_dilution, exp.spike_volume, exp.embryo_collection_method, \
                              exp.embryo_collected_by, exp.embryo_collection_date, exp.number_embryos_collected, \
                              exp.sample_visability, exp.asset_group, exp.image, gr.name
                              FROM experiment exp INNER JOIN \
                              (SELECT MAX(id) max_id FROM experiment) last_exp ON last_exp.max_id = exp.id \
                              INNER JOIN study std ON exp.study_id = std.id \
                              INNER JOIN allele_experiment_link ael ON ael.experiment_id = exp.id \
                              INNER JOIN allele ale ON ale.id = ael.allele_id \
                              INNER JOIN developmental_stage dev ON exp.developmental_stage_id = dev.id
                              INNER JOIN genome_reference gr ON gr.id = exp.genome_reference_id");
 $sth1->execute();
 $sth2->execute();
 $dev_sth->execute();
 $prev_exp->execute();

 my $table_schema = $sth1->fetchall_arrayref;
 my $genRef_names = $sth2->fetchall_arrayref; 
 my $dev_stages   = $dev_sth->fetchall_hashref('id');
 my $last_exp     = $prev_exp->fetchrow_arrayref;

 template 'get_new_experiment', {
   last_exp_name            => $last_exp->[0],
   last_std_name            => $last_exp->[1],
   last_allele_name         => $last_exp->[2],
   last_pheno_desc          => $last_exp->[3],
   last_lines_crossed       => $last_exp->[4],
   last_founder             => $last_exp->[5],
   last_dev_stage           => $last_exp->[6],
   last_spike_mix	    => $last_exp->[7],
   last_spike_dil           => $last_exp->[8],
   last_spike_vol           => $last_exp->[9],
   last_ec_method           => $last_exp->[10],
   last_ec_by               => $last_exp->[11],
   last_ec_date             => $last_exp->[12],
   last_ec_numb	            => $last_exp->[13],
   last_visable             => $last_exp->[14],
   last_asset_group         => $last_exp->[15],
   last_image               => $last_exp->[16],
   last_genome_ref          => $last_exp->[17],
   spike_ids                => \%spike_ids,
   genRef_names             => $genRef_names, 
   table_schema             => $table_schema,
   dev_stages		    => $dev_stages,
   visibility               => \%visability,

   add_experiment_data_url  => uri_for('/add_experiment_data'),
 };

};

get '/existing_experiments' => sub {
 
 my $dbh = get_schema();
 
 template 'existing_experiments', {
   experiments              => exp_info($dbh),
   experiment_id            => param('exp_id'),
   excel_file_locs          => get_file_locs($dbh),
   spike_ids                => \%spike_ids,
   
   existing_samples_url     => uri_for('/existing_samples'),
   refGenome_info_url       => uri_for('/refGenome_info'),
   get_sample_data_url      => uri_for('/get_sample_data'),
   get_sequence_report_url  => uri_for('/get_sequence_report'), 
 };

};

get '/get_sequence_report' => sub {
 
 my $dbh = get_schema();

 my $exp_id = param('exp_id');
 my $exp_name = get_exp_name($dbh, $exp_id);
 my $seq_sth = $dbh->prepare("SELECT * FROM seqView where Experiment_id = ?");
 $seq_sth->execute($exp_id);
 my $col_names = $seq_sth->{NAME};
 my $samples = $seq_sth->fetchall_hashref('Sample_Name');

 if( ! keys %{ $samples } ) {
   croak "No samples found for $exp_name->[1]";
 }
  
 my $excel_samples = sample_description($samples);
 my ($date, $file_loc) = write_file($excel_samples, $exp_name);
 
 if( $date && $file_loc) {
  my $seq_time_sth = $dbh->prepare("Call update_seq_sub_date(?,?,?)");
  $seq_time_sth->execute($date, $file_loc, $exp_id); 
 }

 template 'existing_experiments', {
  experiment_id            => $exp_id,
  experiments              => exp_info($dbh),
  excel_file_locs          => get_file_locs($dbh),
  spike_ids                => \%spike_ids,
  
  existing_experiments_url => uri_for('/existing_experiments'),
  existing_samples_url     => uri_for('/existing_samples'),
  refGenome_info_url       => uri_for('/refGenome_info'),
  get_sample_data_url      => uri_for('/get_sample_data'),
 };

};

post '/add_experiment_data' => sub {
 
  my $dbh = get_schema();
  
 
  my $vals =  [ 
   param('Experiment_name'), 
   param('Lines_crossed'), 
   param('Founder'),
   param('Spike_mix'),
   param('Spike_dilution'),
   param('Spike_volume'), 
   param('Embryo_collection_method'),
   param('Embryos_collected_by'), 
   param('Embryo_collection_date'),
   param('Number_of_embryos_collected'),
   param('Phenotype_description'),
   param('Developmental_stage')
 ];

   my $study_name = param('Study_name');

   my $study_sth = $dbh->prepare("CALL add_study_data(?, \@study_id)");
   $study_sth->execute($study_name);

   ## copy the image
   my $image;
   if(param('Image') ne 'No image') {
    my $file = upload('Image');
    if($file) {
     $file->copy_to("$image_dir");
      $image = $file->tempname;
     $image=~s/.*\///xms;
    }
    else {
     $image = 'No image';
    }
   }

   ## get the study_id
   $study_sth = $dbh->prepare("SELECT id FROM study where name = ?");
   $study_sth->execute($study_name);
   my ($study_id) = $study_sth->fetchrow_array;
     
   ## get the genome_ref_id
   my $genome_ref_name = param('Genome_ref_name');
   my $genref_sth = $dbh->prepare("SELECT id FROM genome_reference WHERE name = ?");
   $genref_sth->execute($genome_ref_name);
   my ($genome_ref_id) = $genref_sth->fetchrow_array;
   
   ## add a new experiment 
   my $exp_sth = $dbh->prepare("CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)");
   $exp_sth->execute( $image, $study_id, $genome_ref_id, @$vals );
   my ($exp_id) = $dbh->selectrow_array("SELECT \@exp_id");

   ## get the allele ids
   my $allele_sth = $dbh->prepare("SELECT id FROM allele WHERE name = ?");
   ## and add vales to allele_experiment_link table
   my $all_exp_sth = $dbh->prepare("CALL add_allele_exp_link(?,?)");
   foreach my $allele_name (split":", param('Alleles')){
    $allele_sth->execute($allele_name);
    my ($allele_id) = $allele_sth->fetchrow_array;
    $all_exp_sth->execute($allele_id,$exp_id); 
   }

   my $expv_sth = $dbh->prepare("SELECT * FROM expView");
   $expv_sth->execute();
   my $col_names = $expv_sth->{NAME};
   my $res = $expv_sth->fetchall_arrayref();
   unshift @$res, $col_names;


 template 'existing_experiments', {
   experiments             => $res,
   experiment_id           => $exp_id,
   spike_ids               => \%spike_ids,
   excel_file_locs         => get_file_locs($dbh),

   existing_samples_url => uri_for('/existing_samples'),
   get_sample_data_url  => uri_for('/get_sample_data'),
   get_sequence_report_url => uri_for('/get_sequence_report'),
 };

};


post '/get_sample_data' => sub {
   
  my $dbh = get_schema();

  @alleles = (); # re-set global
  my $tag_sets = $dbh->selectall_arrayref("SELECT * FROM tagSet");
  my $exp_id = param('exp_id'); 
  my $allele_id_sth = $dbh->prepare("SELECT id, allele_name FROM alleExp WHERE exp_id = ?");
  $allele_id_sth->execute($exp_id);
  @alleles = @{ $allele_id_sth->fetchall_arrayref };
  
  template 'get_sample_data', { 
    alleles => \@alleles,
    tag_sets => $tag_sets,
    experiment_info => get_exp_name( $dbh, $exp_id ),
    experiment_id => $exp_id,
    check_sample_data_url => uri_for('/check_sample_data'),
  };

};


post '/check_sample_data' => sub {
   
  my $dbh = get_schema();
  
  my $tag_set_name = param('tag_set_name');

  my %KlusterCallerCodes = (
   '0' => 'Blank',
   '1' => 'Hom',
   '2' => 'Het',
   '3' => 'Wildtype',
   '5' => 'Failed',
   '6' => 'Missing',
  );

  my @ALPH = 'A'..'H';
  my @NUM = 1..12;
  my $ct = 0;
  my (@marr, %mhash, @new_arr);
  %check_hash = (); # reset the global
  for(my$i=0;$i<@ALPH;$i++){
   for(my$j=0;$j<@NUM;$j++){
    my $well_index = $ALPH[$i] . $NUM[$j];
    $marr[$ct] = $well_index;
    $mhash{ $well_index } = $ct;
    $ct++;
   }
  }
   
  ## get the index sequences
  my @tag_well_order = split",", param('tag_well_order');
  if( @tag_well_order ){
   foreach my $tag_well_pos( @{ well_order(\@tag_well_order) } ){
    my $tag_range = $tag_well_pos->[2];
    $tag_range=~s/[[:alpha:]]//g;
    my($tag_from, $tag_to) = split"-",$tag_range;
    my $index_start = $mhash{ $tag_well_pos->[0] };
    my $index_end = $mhash{ $tag_well_pos->[1] };
    if($tag_to - $tag_from != $index_end - $index_start + 1){
    # die;
     # the number of wells does not match the number of tags
    }
 
    # need to add the from and to variables here, otherwise it does not work, don't know why
    my $tags_sth = $dbh->prepare("SELECT id, name, index_sequence FROM \
                                  tagSeq WHERE name_prefix = ? \
                                  AND name_postfix \
                                  BETWEEN $tag_from AND $tag_to");
   
    $tags_sth->execute($tag_set_name);
    my $tag_set = $tags_sth->fetchall_arrayref();
 
    for(my$i=$index_start;$i <= $index_end;$i++) {
     my($tag_id,$tag_name,$tag_seq) = @{ shift @$tag_set };
     $check_hash{ '#' . $marr[$i] }{ 'tag_info' }{ 'tag_id' } = $tag_id;
     $check_hash{ '#' . $marr[$i] }{ 'tag_info' }{ 'tag_name' } = $tag_name;
     $check_hash{ '#' . $marr[$i] }{ 'tag_info' }{ 'tag_seq' } = $tag_seq;
    }
   }
  }
  
  ## get the klusterCaller files
  foreach my $allele(@alleles) { # uses a global variable - need to change
   my $allele_name = $allele->[1];
   if( my $file = upload("$allele_name") ){
     my @wells = map { split" ",$_ } $file->content=~/\[wells\] (.*)/xms;
     foreach my $well(@wells) {
      $well=~s/\,.*//;
      my($well_id, $geno_id) = split'=',$well;
      if( my($alpha, $num) = $well_id=~/(^[A-H])0?([1-9][0-9]?)/xms ) {
       $well_id = $alpha . $num;
       $check_hash{ '#' . $well_id }{ 'genotype' }{ $allele_name . ":" . $KlusterCallerCodes{ $geno_id } }++; 
      }
     } 
   }
  }


  ## get the wells that the original embryos were collected in
  my @ec_well_order = split",", param('embryo_collection_well_order');
  if( @ec_well_order ) {
   foreach my $ec_well_pos( @{ well_order(\@ec_well_order) } ) {
    if( ! $ec_well_pos=~/ec/i ){
     # die - must have "ec" prifix somewhere
    }
    my $index_start = $mhash{ $ec_well_pos->[0] };
    my $index_end = $mhash{ $ec_well_pos->[1] };
    my ($ec_from, $ec_to) = split"-",$ec_well_pos->[2];
    $ec_from=~s/ec//i;
    my ($alpha_from) = $ec_from=~/([[:alpha:]])/g;
    my ($alpha_to) = $ec_to=~/([[:alpha:]])/g;
    $alpha_to = $alpha_to ? $alpha_to : $alpha_from;
    my ($digit_to) = $ec_to=~/([[:digit:]])/g;
    my $ec_start = $mhash{ $ec_from };
    $ec_to = uc($alpha_to) . $digit_to;
    my $ec_end = $mhash{ $ec_to };
    if( $index_end - $index_start != $ec_end - $ec_start) {
     # die - not the same size ranges
    }
    for(my$i=$index_start;$i <= $index_end;$i++) {
     $check_hash{ '#' .$marr[$i] }{ 'ec_well' } = "ec_well:" . $marr[ $ec_start ];
     $ec_start++;
    }
   }
  }
 
 
  ## get the observed phenotype well order (used to form the sample public name)
  my $exp_info = get_exp_name( $dbh, param('exp_id') );
  my $exp_name = $exp_info->[1];
  my @opwo = split",", param('observed_phenotype_well_order');
  if((split":",$opwo[0]) > 1) { # not just unobserved
   foreach my $phenotype_well_pos( @{ well_order(\@opwo) } ) {
    my $index_start = $mhash{ $phenotype_well_pos->[0] };
    my $index_end = $mhash{ $phenotype_well_pos->[1] };
    for(my$i=$index_start;$i <= $index_end;$i++) {
     $check_hash{ '#' .$marr[$i] }{ 'public_name' } = $exp_name . '_' . $phenotype_well_pos->[2] . '_' . ($i + 1); 
    }
   }
  }
  else {
   my $i;
   foreach my $well(keys %check_hash) {
    $check_hash{ $well }{ 'public_name' } = $exp_name . '_' . $opwo[0] . '_' . ++$i;
   } 
  }
 
  push @new_arr, '', 'A'..'H', '##';
  for(my$i=0;$i<12;$i++){
   push @new_arr, $i+1;
   for(my$j=$i;$j<96;$j=$j+12){
    push @new_arr,  '#' . $marr[$j];
   }
   push @new_arr, '##';
  } 


  template 'check_sample_data', { 
    experiment_id => param('exp_id'),
    experiment_info => $exp_info,
    well_order => \@new_arr,
    well_attributes => \%check_hash,
    tag_set_name => $tag_set_name,
    add_sample_data_url => uri_for('/add_sample_data'),
  };

};


post '/add_sample_data' => sub {
  
  my %samples;
  my $dbh = get_schema();
  
  my $exp_id = param('experiment_id'); 
  my $experiment_name = get_exp_name( $dbh, $exp_id )->[1];

  foreach my $sample_well(keys %check_hash) { # use the global
   if( exists( $check_hash{ $sample_well }{ 'ec_well' } ) ) {
    my $ec_well = $check_hash{ $sample_well }{ 'ec_well' };
    $ec_well=~s/ec_well://;
    my $sample_name = $experiment_name . "_" . $ec_well;
    my %genotypes;
    foreach my$genotype(keys %{ $check_hash{ $sample_well }{ 'genotype' } }){
     my $sample_well_id = $sample_well;
     $sample_well_id=~s/#//;
     push(@{ $samples{ $sample_well_id }{ 'genotype' } }, $genotype);
    }
    my $index_tag_id = $check_hash{ $sample_well }{ 'tag_info' }{ 'tag_id' }; 
    my $public_name = $check_hash{ $sample_well }{ 'public_name' };
    my $sample_well_id = $sample_well;
    $sample_well_id=~s/#//;
    $samples{ $sample_well_id }{ 'ec_well' } = $ec_well;
    $samples{ $sample_well_id }{ 'sample_name' } = $sample_name;
    $samples{ $sample_well_id }{ 'public_name' } = $public_name;
    $samples{ $sample_well_id }{ 'index_tag_id' } = $index_tag_id; 
   }
  } 

  my $sample_sth = $dbh->prepare("CALL add_sample_data(?,?,?,?,?,?)");
  foreach my $sample_well_id(sort {$a cmp $b} keys %samples){
   $sample_sth->execute( $samples{ $sample_well_id }{ 'sample_name' },
                         $samples{ $sample_well_id }{ 'public_name' },
                         $samples{ $sample_well_id }{ 'ec_well' },
                         $sample_well_id,
                         $exp_id,
                         $samples{ $sample_well_id }{ 'index_tag_id' }
                       );
   my $sample_id_sth = $dbh->prepare("SELECT id FROM sample WHERE experiment_id = ? AND rna_dilution_well_number = ?");
   $sample_id_sth->execute($exp_id, $sample_well_id);
   my $sample_id = $sample_id_sth->fetchrow_arrayref();
 
   my $allele_sth = $dbh->prepare("SELECT id FROM allele WHERE name = ?");

   my $genotype_sth = $dbh->prepare("CALL add_genotype_data(?,?,?)");

   foreach my $al_genotype(@{ $samples{ $sample_well_id }{ 'genotype' } }) {
    my($allele, $genotype) = split":",$al_genotype;
    $allele_sth->execute($allele);
    my $allele_id = $allele_sth->fetchrow_arrayref();
    $genotype_sth->execute($allele_id->[0], $sample_id->[0], $genotype);
   }
   
                                        
  }

  my $exp_info = exp_info($dbh); 

  template 'existing_experiments', {
   experiment_id            => $exp_id,
   experiments              => $exp_info,   
   excel_file_locs          => get_file_locs($dbh),
   spike_ids                => \%spike_ids,

   existing_samples_url     => uri_for('/existing_samples'),
   get_sample_data_url      => uri_for('/get_sample_data'), 
   get_sequence_report_url  => uri_for('/get_sequence_report'),
  };

};


get '/existing_samples' => sub {
   
  my $dbh = get_schema();
  
  my $sth = $dbh->prepare("SELECT * FROM smpView WHERE Experiment_id = ?");
  my $exp_id = param('exp_id');
  $sth->execute($exp_id);
  my $exp_info = get_exp_name( $dbh, $exp_id );

  my $col_names = $sth->{NAME};
  my $res = $sth->fetchall_arrayref();
  unshift @$res, $col_names;

  template 'existing_samples', { 
            experiment_info => $exp_info,
            samples => $res, 
            experiment_id => $exp_id, 
  };

};


get '/refGenome_info' => sub {

  my $dbh = get_schema();

  my $sth = $dbh->prepare("SELECT * FROM genrefView WHERE Geome_reference = ?");
  my $genRef_name = param('refGenome_info');
  $sth->execute($genRef_name);

  my $col_names = $sth->{NAME};
  my $res = $sth->fetchall_arrayref();
  unshift @$res, $col_names;

  template 'refGenome_info', { ref_gen => $res,};

};

## sub routines

sub well_order {
 my $well_order = shift;

 if(! $well_order) { 
  return;
 }

 my ($return_wells, $wells, $attribs);
 foreach my $well( @$well_order ){
  next unless $well;
  my($wa1, $wa2) = split":",$well; # which is the well or attribute
  if($wa1=~m/^[a-h]\d+/i) {
    $wells = $wa1;
    $attribs = $wa2
  }
  elsif($wa2=~m/^[a-h]\d+/i) {
   $wells = $wa2;
   $attribs = $wa1;
  }
  else {
   #return 0; # incorrect naming of wells
  }

  my($well_from, $well_to) = split"-",$wells;
  my($wf_alph, $wf_num) = $well_from=~m/^([[:alpha:]]?)(\d+)/;
  my($wt_alph, $wt_num) = $well_to=~m/^([[:alpha:]]?)(\d+)/;
  if(! $wt_alph){
   $wt_alph = $wf_alph;
  }
  $wt_alph=uc($wt_alph);
  $wf_alph=uc($wf_alph);
  push(@$return_wells, [ "$wf_alph$wf_num", "$wt_alph$wt_num", $attribs ]);
 }
 return $return_wells;

}

sub exp_info {
 my ($dbh) = shift;

 my $sth = $dbh->prepare("SELECT * FROM expView");
 $sth->execute();
  
 my $col_names = $sth->{'NAME'};
 my $res = $sth->fetchall_arrayref();
 unshift @$res, $col_names;
 
 return $res; 
}

sub get_exp_name {
 my ($dbh, $exp_id) = @_;
 my $exp_sth = $dbh->prepare("SELECT Experiment, Study FROM expView WHERE ID = ?");
 $exp_sth->execute($exp_id);
 return [ $exp_id, $exp_sth->fetchrow_array ] || []; 
}

sub get_schema {
  return DBI->connect("DBI:mysql:$db_name;host=utlt-db;port=3307", 'tillingrw', 'tillingrw') 
    or die "Cannot connect to database\n";
}

sub sample_description {
 my $samples = shift;
   
 my @samples_for_excel = ( ## column names for the excel sheet
  'Library_Tube_ID',
  'Tag_ID',
  'Asset_Group',
  'Sample_Name',
  'Public_Name',
  'Organism',
  'Common_Name',
  'Sample_Visability',
  'GC_Content',
  'Taxon_ID',
  'Strain',
  'Sample_Description',
  'Gender',
  'DNA_Source',
  'Reference_Genome',
  'Age',
  'Cell_type',
  'Compound',
  'Developmental_Stage',
  'Disease',
  'Disease_State',
  'Dose',
  'Genotype',
  'Growth_Condition',
  'Immunoprecipitate',
  'Organism_Part',
  'Phenotype',
  'Time_Point',
  'Treatment',
  'Donor_ID',
  '###'
 );

my @data;

 foreach my $sample_name( keys %{ $samples } ) {
  my ($allele,$genotype) = split":",$samples->{"$sample_name"}->{'desc_allele:genotype'};
  my $desc_genotype = $genotypes_c{ $genotype };
  unless( $desc_genotype ){ ## remove any samples which do not have a het, hom or wt genotype
   delete( $samples->{"$sample_name"} );
   next;
  }
  my $public_name = $samples->{"$sample_name"}->{'Public_Name'};
  my($zmp_number, $pheno) = $public_name=~m/zmp_ph(\d+)_([[:alpha:]]+)/;
  my $spike_mix = $samples->{"$sample_name"}->{'desc_spike_mix'};
  my $spike_mix_desc = $spike_ids{ $spike_mix };
  my $ensembl_id = $samples->{"$sample_name"}->{'ensembl_gene_id'};
  my $index_tag_seq = $samples->{"$sample_name"}->{'desc_tag_index_sequence'};
  $index_tag_seq=~s/CG$//xms; # remove the final 2 bases - these are always "CG"
  my ($zmp_page) = $sample_name=~m/(\w+_\w+)_/;

  my $description = "3' end enriched mRNA from a single genotyped $desc_genotype embryo for $ensembl_id, " .
                    "allele $allele, ZMP $pheno $zmp_number clutch 1 plus $spike_mix_desc. " . 
                    "The 8 base indexing sequence ($index_tag_seq) is bases 13 to 20 of read 1 followed by CG " .
                    "and polyT. More information describing the $desc_genotype phenotype can be found at the " .
                    'Wellcome Trust Sanger Institute Zebrafish Mutation Project website ' .
                    "http://www.sanger.ac.uk/sanger/Zebrafish_Zmpsearch/$zmp_page";
                      
  $samples->{"$sample_name"}{'Sample_Description'} = $description;
 }

 foreach my $sample_name( keys %{ $samples } ) {
  foreach my $col_name(@samples_for_excel){
   if($col_name eq '###'){
    push @data, $col_name;
   }
   else {
    push @data, $samples->{"$sample_name"}->{"$col_name"};
   }
  }
 }
 push @samples_for_excel, @data; 
 return \@samples_for_excel;
} 

sub write_file {
 my($excel_data, $exp_info)=@_;
 my $date_time = `date --rfc-3339=seconds | xargs echo -n`;
 my($date, $time) = split" ",$date_time;
 $time=~s/\+.*//;
 $time=~s/:/_/g;
 my $exp_name = $exp_info->[1];
 my $dir = "$exel_file_dir/$exp_name/$date";
 make_path($dir, { verbose => 1,  mode => 0777 });
 my $file = "$dir/$exp_name-$time.xlsx"; 

 my $workbook  = Excel::Writer::XLSX->new( "$file" );
 my $worksheet = $workbook->add_worksheet();

 my($row,$col) = (0,0);
 for(my$i=0;$i<@$excel_data;$i++){
  if(defined($excel_data->[$i]) && $excel_data->[$i] eq '###') {
   $row++;
   $col=0;
   next;
  }
  else {
   $worksheet->write( $row, $col, $excel_data->[$i] );
   $col++;
  }
 }
 
 $workbook->close();
 
 return($date, $file);
 
}

sub get_file_locs {
 my $dbh = shift;
 my $sth_excel_file = $dbh->prepare("SELECT excel_file_location, id FROM experiment");
 $sth_excel_file->execute;
 my $file_loc = $sth_excel_file->fetchall_hashref('id');

 foreach my $id( keys %{ $file_loc } ){
  if(defined( $file_loc->{$id}->{'excel_file_location'} )) {
   $file_loc->{$id}->{'excel_file_location'}=~s/\.?\/public\///;
  }
 }
 return $file_loc || undef;
}

true;
