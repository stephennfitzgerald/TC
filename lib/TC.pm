package TC;
use Dancer2;
use DBI;

our $VERSION = '0.1';

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
  
  my $sth = $dbh->prepare("SELECT * FROM expView");
  $sth->execute();
   
  my $col_names = $sth->{NAME};
  my $res = $sth->fetchall_arrayref();
  unshift @$res, $col_names;
  
 template 'existing_experiments', {
   experiments => $res,
   existing_samples_url => uri_for('/existing_samples'),
   refGenome_info_url => uri_for('/refGenome_info'),
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
   
   ## get the study_id
   my $study_name = param('Study_name');

   my $study_sth = $dbh->prepare("CALL add_study_data(?, \@study_id)");
   $study_sth->execute($study_name);
   my ($study_id) = $dbh->selectrow_array("SELECT \@study_id");
   if( ! $study_id ){ # its already in the db
    $study_sth = $dbh->prepare("SELECT id FROM study where name = ?");
    $study_sth->execute($study_name);
    ($study_id) = $study_sth->fetchrow_array;
   }
     
   ## get the development_stage_id
   my ($dev_stage, $dev_desc) = ( param('Developmental_stage'), param('Developmental_description') );
   my $zfs_id = ""; # need a sub to get the zfs_id
   my $dev_sth = $dbh->prepare("CALL add_developmental_stage(?,?,?, \@dev_id)");
   $dev_sth->execute($zfs_id,$dev_stage,$dev_desc);
   my ($developmental_stage_id) = $dbh->selectrow_array("SELECT \@dev_id");
  
   if( ! $developmental_stage_id ){ # its already in the db
    $dev_sth = $dbh->prepare("SELECT id FROM developmental_stage WHERE zfs_id = ? AND name = ? AND description = ?"); 
    $dev_sth->execute($zfs_id,$dev_stage,$dev_desc);
    ($developmental_stage_id) = $dev_sth->fetchrow_array;
   }

   ## get the genome_ref_id
   my $genome_ref_name = param('Genome_ref_name');
   my $genref_sth = $dbh->prepare("SELECT id FROM genome_reference WHERE name = ?");
   $genref_sth->execute($genome_ref_name);
   my ($genome_ref_id) = $genref_sth->fetchrow_array;
   
   ## add a new experiment 
   my($experiment_name,
      $lines_crossed, 
      $founder,
      $spike_dilution, 
      $spike_volume,
      $embryo_collection_method, 
      $embryos_collected_by, 
      $embryo_collection_date, 
      $number_of_embryos_collected,
      $image,
      $phenotype) = @$vals;
   
   my $exp_sth = $dbh->prepare("CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)");
   $exp_sth->execute( $study_id, $developmental_stage_id, $genome_ref_id, @$vals );
   my ($exp_id) = $dbh->selectrow_array("SELECT \@exp_id");

   ## check the allale data
   my $alleles = param('Alleles'); # colon separated list
   my $gene_name = param('Gene_name');
   foreach my $allele( split":", $alleles ){
    my $alle_sth = $dbh->prepare("CALL add_allele(?,?,?)");
    $alle_sth->execute( $allele, $gene_name, $exp_id ); 
   }

   my $expv_sth = $dbh->prepare("SELECT * FROM expView");
   $expv_sth->execute();
   my $col_names = $expv_sth->{NAME};
   my $res = $expv_sth->fetchall_arrayref();
   unshift @$res, $col_names;

 template 'existing_experiments', {
# template 'test_samples', {
#   ids => [ $study_id, $developmental_stage_id, $genome_ref_id, @$vals ], 
   experiments => $res,
   existing_samples_url => uri_for('/existing_samples'),
   get_sample_data_url      => uri_for('/get_sample_data'),
 };

};


get '/get_sample_data' => sub {
   
  my $dbh = get_schema();
  
  my $exp_id = param('exp_id');

  template 'get_sample_data', { experiment_id => $exp_id, 
    add_sample_data_url => uri_for('/add_sample_data'),
  };

};


post '/add_sample_data' => sub {
   
  my $dbh = get_schema();
  
  my $exp_id = param('exp_id');

  template 'get_sample_data', { experiment_id => $exp_id, 
    add_sample_data_url => uri_for('/add_sample_data'),
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

  template 'existing_samples', { samples => $res, experiment_id => $exp_id, };

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

sub get_schema {
  return DBI->connect('DBI:mysql:zfish_sf5_tc4_test;host=mcs11;port=3307', 'tillingrw', 'tillingrw') 
    or die "Cannot connect to database\n";
}

true;
