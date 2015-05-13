package TC;
  
use Dancer2;
use DBI;

our $VERSION = '0.1';
our $db_name = "zfish_sf5_tc4_test";
our @allele_types = ();
our %check_hash = ();

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
 $sth1->execute();
 $sth2->execute();

 my $table_schema = $sth1->fetchall_arrayref;
 my $genRef_names = $sth2->fetchall_arrayref; 

 template 'get_new_experiment', {
   genRef_names => $genRef_names, 
   table_schema => $table_schema,
   add_experiment_data_url  => uri_for('/add_experiment_data'),
 };

};

get '/existing_experiments' => sub {
 
 my $dbh = get_schema();
 
 my $exp_info = exp_info($dbh);
 
 my $exp_id = param('experiment_id');

 template 'existing_experiments', {
   experiments => $exp_info,
   experiment_id => $exp_id,   
   existing_samples_url => uri_for('/existing_samples'),
   refGenome_info_url => uri_for('/refGenome_info'),
   get_sample_data_url  => uri_for('/get_sample_data'),
 };

};

post '/add_experiment_data' => sub {
 
  my $dbh = get_schema();
  
 
  my $vals =  [ 
   param('Experiment_name'), 
   param('Lines_crossed'), 
   param('Founder'),
   param('Spike_dilution'),
   param('Spike_volume'), 
   param('Embryo_collection_method'),
   param('Embryos_collected_by'), 
   param('Embryo_collection_date'),
   param('Number_of_embryos_collected'),
   param('Image'), 
   param('Phenotype'),
 ];
   
   my $study_name = param('Study_name');

   my $study_sth = $dbh->prepare("CALL add_study_data(?, \@study_id)");
   $study_sth->execute($study_name);

   ## get the study_id
   $study_sth = $dbh->prepare("SELECT id FROM study where name = ?");
   $study_sth->execute($study_name);
   my ($study_id) = $study_sth->fetchrow_array;
     
   my ($dev_stage, $dev_desc) = ( param('Developmental_stage'), param('Developmental_description') );
   my $zfs_id = ""; # need a sub to get the zfs_id
   my $dev_sth = $dbh->prepare("CALL add_developmental_stage(?,?,?, \@dev_id)");
   $dev_sth->execute($zfs_id,$dev_stage,$dev_desc);
  
   ## get the development_stage_id 
   $dev_sth = $dbh->prepare("SELECT id FROM developmental_stage WHERE zfs_id = ? AND name = ? AND description = ?"); 
   $dev_sth->execute($zfs_id,$dev_stage,$dev_desc);
   my ($developmental_stage_id) = $dev_sth->fetchrow_array;

   ## get the genome_ref_id
   my $genome_ref_name = param('Genome_ref_name');
   my $genref_sth = $dbh->prepare("SELECT id FROM genome_reference WHERE name = ?");
   $genref_sth->execute($genome_ref_name);
   my ($genome_ref_id) = $genref_sth->fetchrow_array;
   
   ## add a new experiment 
   my $exp_sth = $dbh->prepare("CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)");
   $exp_sth->execute( $study_id, $developmental_stage_id, $genome_ref_id, @$vals );
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
   experiments => $res,
   experiment_id => $exp_id,
   existing_samples_url => uri_for('/existing_samples'),
   get_sample_data_url  => uri_for('/get_sample_data'),
 };

};


get '/get_sample_data' => sub {
   
  my $dbh = get_schema();
  
  @allele_types = (); # re-set global variable
  my $tag_sets = $dbh->selectall_arrayref("SELECT * FROM tagSet");
  my $exp_id = param('exp_id'); 
  my $allele_id_sth = $dbh->prepare("SELECT id, allele_name FROM alleExp WHERE exp_id = ?");
  $allele_id_sth->execute($exp_id);
  my $alleles = $allele_id_sth->fetchall_arrayref;
  
  my $exp_sth = $dbh->prepare("SELECT COLUMN_TYPE FROM \
                  information_schema.COLUMNS \
                  WHERE table_schema = ? AND TABLE_NAME = \
                  'genotype' AND COLUMN_NAME = 'genotype'");

  $exp_sth->execute($db_name); 
  my $db_types =  $exp_sth->fetchrow_arrayref;
  foreach my $types(@$db_types){
   foreach my $type( $types=~/\'(\w+)/g ){
    foreach my $allele(@$alleles){
     push@allele_types, [ join("-", $allele->[1], $type), $allele->[0] ];
    }
   }
  }
  
  template 'get_sample_data', { 
    allele_types => \@allele_types, 
    tag_sets => $tag_sets,
    experiment_info => get_exp_name( $dbh, $exp_id ),
    experiment_id => $exp_id,
    check_sample_data_url => uri_for('/check_sample_data'),
  };

};


post '/check_sample_data' => sub {
   
  my $dbh = get_schema();
  
  my $tag_set_name = param('tag_set_name');

  my @ALPH = "A".."H";
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
  
 ## get the genotypes
 foreach my $genotype(@allele_types) { # uses a global variable - need to change
  my @genotype_well_order = split",", param("$genotype->[0]");
  if( @genotype_well_order ){
   foreach my $genotype_well_pos( @{ well_order(\@genotype_well_order) } ) {
    my $index_start = $mhash{ $genotype_well_pos->[0] };
    my $index_end = $mhash{ $genotype_well_pos->[1] };
    for(my$i=$index_start;$i <= $index_end;$i++) {
     $check_hash{ '#' .$marr[$i] }{ 'genotype' }{ $genotype->[0] }++;
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

 push @new_arr, "", "A".."H", "##";
 for(my$i=0;$i<12;$i++){
  push @new_arr, $i+1;
  for(my$j=$i;$j<96;$j=$j+12){
   push @new_arr,  '#' . $marr[$j];
  }
  push @new_arr, '##';
 } 


  template 'check_sample_data', { 
    experiment_id => param('exp_id'),
    experiment_info => get_exp_name( $dbh, param('exp_id') ),
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
    my @genotypes;
    foreach my$genotype(keys %{ $check_hash{ $sample_well }{ 'genotype' } }){
     push(@genotypes, [$exp_id,$sample_well, $genotype]);
    }
    my $index_tag_id = $check_hash{ $sample_well }{ 'tag_info' }{ 'tag_id' }; 
    $sample_well=~s/#//;
    $samples{ $sample_well }{ 'ec_well' } = $ec_well;
    $samples{ $sample_well }{ 'sample_name' } = $sample_name;
    $samples{ $sample_well }{ 'public_name' } = $sample_name;
    $samples{ $sample_well }{ 'index_tag_id' } = $index_tag_id; 
   }
  } 
  
  my $sample_sth = $dbh->prepare("CALL add_sample_data(?,?,?,?,?,?)");
  foreach my $sample_well(sort {$a cmp $b} keys %samples){
   $sample_sth->execute( $samples{ $sample_well }{ 'sample_name' },
                         $samples{ $sample_well }{ 'public_name' },
                         $samples{ $sample_well }{ 'ec_well' },
                         $sample_well,
                         $exp_id,
                         $samples{ $sample_well }{ 'index_tag_id' }
                       );
  }

  my $exp_info = exp_info($dbh); 

  template 'existing_experiments', {
   experiment_id => $exp_id,
   experiments => $exp_info,   
   existing_samples_url => uri_for('/existing_samples'),
  };

};


get '/existing_samples' => sub {
   
  my $dbh = get_schema();
  
  my $sth = $dbh->prepare("SELECT * FROM smpView WHERE Experiment_id = ?");
  my $exp_id = param('exp_id');
  $sth->execute($exp_id);

  my $col_names = $sth->{NAME};
  my $res = $sth->fetchall_arrayref();
  unshift @$res, $col_names;

  template 'existing_samples', { 
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

true;
