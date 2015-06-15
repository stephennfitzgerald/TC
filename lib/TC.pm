package TC;
  
use Dancer2;
use File::Path qw(make_path);
use Excel::Writer::XLSX;
use Spreadsheet::Read;
use Spreadsheet::XLSX;
use Data::Dumper;
use Carp;
use DBI;

our $VERSION = '0.1';
my $db_name = "zfish_sf5_tc2_test";
my $dbh = get_schema();
my $exel_file_dir = "./public/zmp_exel_files"; # need to change
my $rna_dilution_dir = "./public/RNA_dilution_files";
my $image_dir = "./public/images"; 
my (@alleles, %rna_plate, %allele_combos);
my $dec = 55280; ## hex=00FF00
my $inc = 3500; ## increase the color $dec 
my $seq_plate_name;

my %genotypes_c = (
 'Blank'    => 0,
 'Hom'      => 'homozygous mutant',
 'Het'      => 'heterozygous',
 'Wildtype' => 'wild type',
 'Failed'   => 0,
 'Missing'  => 0,
);

my %spike_ids = ( 
 '0'        => 'No spike mix',
 '1'        => 'ERCC spike mix 1 (Ambion)',
 '2'        => 'ERCC spike mix 2 (Ambion)',
);

my %visability = (
  1         => "Public",
  2         => "Hold",
);

my %KlusterCallerCodes = (
 '0'        => 'Blank',
 '1'        => 'Hom',
 '2'        => 'Het',
 '3'        => 'Wildtype',
 '5'        => 'Failed',
 '6'        => 'Missing',
);



get '/' => sub {
    
 template 'index', { 
  'get_new_experiment_url'     => uri_for('/get_new_experiment'),
  'make_sequencing_plate_url'  => uri_for('/get_sequencing_info'),
  'make_sequencing_report_url' => uri_for('/get_sequencing_report'),
 };
       
};


get '/get_sequencing_report' => sub {

 if($seq_plate_name) {

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
  'Country of origin',
  'Geographical region',
  'Ethnicity',
  'DNA_Source',
  'ENA Sample Accession Number',
  'Cohort',
  'Volume (µl)',
  'Mother',
  'Father',
  'Replicate',
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
  'RNAi',
  'Subject',
  'Time_Point',
  'Treatment',
  'Donor_ID',
  '###'
  );

  my @data;
  my $seq_plate_sth = $dbh->prepare("SELECT * FROM SeqReportView WHERE seq_plate_name = ?");
  $seq_plate_sth->execute("$seq_plate_name");
  my $sequence_plate = $seq_plate_sth->fetchall_hashref('index_tag_id'); 
  foreach my $index_tag_id( sort {$a <=> $b} keys %{ $sequence_plate } ) {
   foreach my $col( @samples_for_excel ) {
    if($col eq '###') {
     push @data, $col;
    } 
    elsif( exists($sequence_plate->{"$index_tag_id"}->{"$col"}) ) {
     push @data, $sequence_plate->{"$index_tag_id"}->{"$col"};
    }
    elsif( $col eq 'Sample_Description' ) {
     my %alle_geno;
     foreach my $alle_genotype( split',',$sequence_plate->{"$index_tag_id"}->{'AlleleGenotype'} ) {
      my($allele,$gene,$genotype) = split':',$alle_genotype;
      $alle_geno{$genotype}{"$gene allele $allele"}++;
     }
     my $description = "3' end enriched mRNA from a single genotyped ";
     foreach my $geno(sort keys %alle_geno) {
      $description .= $genotypes_c{ $geno } . " embryo for ";
      foreach my $gene_allele(sort keys %{ $alle_geno{ $geno } }) {
       $description .= "$gene_allele, ";
      }
     }
     my $index_tag_seq = $sequence_plate->{"$index_tag_id"}->{'desc_tag_index_sequence'};
     $index_tag_seq=~s/CG$//xms; ## remove the final 2 bases - these are always "CG"
     my $zmp_exp_name = $sequence_plate->{"$index_tag_id"}->{'zmp_name'}; 
     $description .= "clutch 1 with " . $spike_ids{ $sequence_plate->{"$index_tag_id"}->{'desc_spike_mix'} } .
      ". The 8 base indexing sequence ($index_tag_seq) is bases 13 to 20 of read 1 followed by CG " . 
      'and polyT. More information describing the phenotype can be found at the ' .
      'Wellcome Trust Sanger Institute Zebrafish Mutation Project website ' .
      "http://www.sanger.ac.uk/sanger/Zebrafish_Zmpsearch/$zmp_exp_name";
     push @data, $description;
    }
    else {
     push @data, undef;
    }
   }
  }
  push @samples_for_excel, @data;
  my ($date, $file_loc) = write_file(\@samples_for_excel, $seq_plate_name);

  if($date && $file_loc) {
   my $seq_time_sth = $dbh->prepare("Call update_excel_file_location_and_date(?,?,?)");
   $seq_time_sth->execute($file_loc, $date, $seq_plate_name);
  }
 }

};

get '/get_sequencing_info' => sub {

 my (%seq, %unseq);
 my $exp_seq_sth = $dbh->prepare("SELECT * FROM SeqExpView");
 $exp_seq_sth->execute;
 foreach my $exp_seq(@{ $exp_seq_sth->fetchall_arrayref }) {
  my($exp_id, $exp_name, $std_name, $alleles, $seq_plate, $count) = @$exp_seq;
  if($seq_plate){
   push(@{ $seq{ $exp_id } }, $exp_name, $std_name, $alleles, $count);
  }
  else {
   push(@{ $unseq{ $exp_id } }, $exp_name, $std_name, $alleles, $count);
  }
 }
 
 my $tag_set_sth = $dbh->prepare("SELECT * FROM tagSetView");
 $tag_set_sth->execute;
 my $tag_set_names = $tag_set_sth->fetchall_arrayref;
 $seq_plate_name = undef; ## re-set global 

 template 'make_seq_plate', {
  unseq                     => \%unseq,
  seq		            => \%seq,
  tag_set_names             => $tag_set_names,

  'combine_plate_data_url'  => uri_for('/combine_plate_data'), 
 };

};


post '/combine_plate_data' => sub {

  my (%combined_plate, %exp_ids, %cell_color, %exp_color, %cell_mapping, %index_tag_set);
  my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
  $exp_sth->execute;
  my $all_exps = $exp_sth->fetchall_hashref('exp_id');
  my $dec = 55280; ## hex=00FF00
  my $tag_set_prefix = param('tag_set_name');
  my $tag_seqs_sth =  $dbh->prepare("SELECT * FROM tagSeqView WHERE name_prefix = ?");
  $tag_seqs_sth->execute("$tag_set_prefix");
  my $tag_seqs = $tag_seqs_sth->fetchall_arrayref;
  
  my $ct = 0; ## array index corresponds to the index positions in $index_hash below
  my $index_hash = make_grid()->[1]; ## for merging the experiment(s) onto a single plate
  foreach my $exp_id(keys %{ $all_exps }) {
   if(my $exp_name = param("$exp_id")) {
    if($exp_name eq $all_exps->{"$exp_id"}->{'exp_name'}) { ## this should always be true
     my $rdp_sth = $dbh->prepare("SELECT * FROM RnaDilPlateView WHERE experiment_id = ?");
     $rdp_sth->execute("$exp_id");
     my $hex = sprintf "0x%x", $dec;
     $hex=~s/0x/#/;
     $exp_color{ $hex }{ 'exp_name' } = $exp_name; ## legend colors for exps
     foreach my $sample(@{ $rdp_sth->fetchall_arrayref }) {
      $exp_color{ $hex }{ 'std_name' } = $sample->[4];
      $exp_ids{ $sample->[2] }++; ## experiment_ids
      my $tag_seq = shift @$tag_seqs;
      $index_tag_set{ $tag_seq->[0] } = $tag_seq->[1];
      $combined_plate{ $sample->[0] }{ 'rna_plate_well_name' }  = $sample->[1];
      $combined_plate{ $sample->[0] }{ 'exp_name' }             = $sample->[3];
      $combined_plate{ $sample->[0] }{ 'std_name' }             = $sample->[4];
      $combined_plate{ $sample->[0] }{ 'index_tag_id' }         = $tag_seq->[0];
      $combined_plate{ $sample->[0] }{ 'seq_plate_well_name' }  = $index_hash->{ $ct };
      $cell_color{ $index_hash->{ $ct } } = $hex; ## cell colors
      $cell_mapping{ $index_hash->{ $ct } } = $sample->[1]; ## mapping betweem rna plate(s) and seq plate
      $ct++;
     }
     $dec += $inc;
    }
   }
  }
  $seq_plate_name = join "_", keys %exp_ids;
  my $spd_sth = $dbh->prepare("CALL add_sequence_plate_data(?,?,?,?,?,?)");
  my $seq_array = make_grid()->[0];
  foreach my $rna_plate_id(sort {$a <=> $b} keys %combined_plate) {
   my $seq_plate_well_name = $combined_plate{ $rna_plate_id }{ 'seq_plate_well_name' };
   my $rna_plate_well_name = $combined_plate{ $rna_plate_id }{ 'rna_plate_well_name' };
   my $index_tag_id = $combined_plate{ $rna_plate_id }{ 'index_tag_id' };
   my $sample_name = join "_", $combined_plate{ $rna_plate_id }{ 'exp_name' }, $rna_plate_well_name;
   my ($tag_num) = $index_tag_set{ $index_tag_id }=~m/\.([[:digit:]]+)/xms;
   my $sample_public_name = join "_", $sample_name, $seq_plate_well_name, $tag_num;
   $spd_sth->execute( $seq_plate_name, 
                      $seq_plate_well_name,
                      $sample_name,
                      $sample_public_name,
                      $rna_plate_id,
                      $index_tag_id );                   
  }
  foreach my $cell( @{ $seq_array } ) {
   if(exists($cell_color{ $cell })) {
    $cell = [ $cell_color{ $cell }, $cell_mapping{ $cell } ];
   }
   elsif( $cell=~/[[:alpha:]][[:digit:]]+/xms ){
    $cell = [ '#D8D8D8', undef ];
   }
   elsif( $cell ne "##" ) {
    $cell = [ '#FFFFFF', $cell ];
   }
  }

  template 'display_sequence_plate', {
   
   sequence_plate         => $seq_array,
   legend		  => \%exp_color,
  };
  

};

get '/get_new_experiment' => sub {

 my $exp_sth = $dbh->prepare("DESC ExpView");
 my $gen_sth = $dbh->prepare("SELECT Genome_ref_name, Genome_ref_id FROM SpView"); 
 my $dev_sth = $dbh->prepare("SELECT * FROM DevView"); 
 my $lst_sth = $dbh->prepare("SELECT * FROM LstExpView");
 my $std_sth = $dbh->prepare("SELECT * FROM StdView");
 
 $exp_sth->execute;
 $gen_sth->execute;
 $dev_sth->execute;
 $lst_sth->execute;
 $std_sth->execute;

 my $table_schema = $exp_sth->fetchall_arrayref;
 my $genref_names = $gen_sth->fetchall_arrayref; 
 my $dev_stages   = $dev_sth->fetchall_hashref('id');
 my $last_exp     = $lst_sth->fetchrow_arrayref;
 my $std_names    = $std_sth->fetchall_arrayref;
 $seq_plate_name = undef; ## re-set global

 template 'get_new_experiment', {
   last_std_name            => $last_exp->[0],
   last_exp_name            => $last_exp->[1],
   last_allele_name         => $last_exp->[2],
   last_lines_crossed       => $last_exp->[3],
   last_founder             => $last_exp->[4],
   last_dev_stage           => $last_exp->[5],
   last_spike_mix	    => $last_exp->[6],
   last_spike_dil           => $last_exp->[7],
   last_spike_vol           => $last_exp->[8],
   last_image               => $last_exp->[9],
   last_pheno_desc          => $last_exp->[10],
   last_ec_method           => $last_exp->[11],
   last_ec_by               => $last_exp->[12],
   last_ec_date             => $last_exp->[13],
   last_ec_numb	            => $last_exp->[14],
   last_visable             => $last_exp->[15],
   last_asset_group         => $last_exp->[16],
   last_genome_ref          => $last_exp->[17],
 
   spike_ids                => \%spike_ids,
   genref_names             => $genref_names, 
   table_schema             => $table_schema,
   dev_stages		    => $dev_stages,
   visibility               => \%visability,
   study_names              => $std_names,

   add_experiment_data_url  => uri_for('/add_experiment_data'),
 };

};

post '/add_experiment_data' => sub {

  my $vals =  [
   param('Study_name'),
   param('Genome_ref_name'),
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

 ## copy the image file
 my $image;
 if(param('Image') ne 'No image') {
  my $image_file = upload('Image');
  if($image_file) {
   $image_file->copy_to("$image_dir");
   $image = $image_file->tempname;
   $image=~s/.*\///xms; 
  }
  else {
   $image = 'No image';
  }
 }
 
 ## add a new experiment
 my $exp_sth = $dbh->prepare("CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)");
 $exp_sth->execute( $image, @$vals );
 my ($exp_id) = $dbh->selectrow_array("SELECT \@exp_id");

 ## and add alleles to the global array 
 my $alle_sth = $dbh->prepare("SELECT * FROM AlleleView WHERE name = ?");
 @alleles=(); # empty the global array
 foreach my $allele_name(split":", param('Alleles')){
  $alle_sth->execute("$allele_name");
  push @alleles, @{ $alle_sth->fetchall_arrayref };
 }
  
 template 'get_genotypes_and_rna', {
    names_info     => get_study_and_exp_names($exp_id), 
    alleles        => \@alleles,
   
    get_genotypes_and_rna_url  => uri_for('/get_genotypes_and_rna'),
   
 };

};

post '/get_genotypes_and_rna' => sub {

  my $rna_file = upload('rna_dilution_file');
 
  my $workbook;
  %rna_plate = (); # re-set the global

  if($rna_file) {
   my $copy_dir = make_file_path("$exel_file_dir", param('std_name'), param('exp_name'));
   $rna_file->copy_to("$copy_dir");
   my $file_name = $rna_file->tempname;
   $file_name=~s/.*\///xms;
   $workbook = ReadData("$copy_dir/$file_name");
  }
  
  my $min_rna_amount = param('minimum_rna_amount');
  my $rna_volume  = param('rna_volume');

  ## read in the file for the RNA concentrations
  foreach my $row(1..8) {
   foreach my $col("A".."L") {
    my $index = $col . $row;
    if(defined($workbook->[1]{$index})){
     my $rna_amount = $workbook->[1]{$index};
     my $sw_index = switch_cols_rows($index); ## need to switch rows and cols 
     $rna_plate{ $sw_index }{ 'rna' } = $rna_amount;
     my $total_rna = $rna_volume * $rna_amount;
     my $qc_ok = $total_rna >= $min_rna_amount ? 1 : 0;
     $rna_plate{ $sw_index }{ 'qc_ok' } = $qc_ok;
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
      if( exists($rna_plate{ $well_id }) ){
       my $fail_num = $KlusterCallerCodes{ $geno_id } eq "Failed" ? 0 : 1;
       $rna_plate{ $well_id }{ 'genotype' }{ $allele_name . ":" . $KlusterCallerCodes{ $geno_id } } = $fail_num; 
      }
     }   
    }   
   }   
  }
 
  %allele_combos = (); # re-set the global
  foreach my $well_id( keys %rna_plate ){
   my ($geno_combos, $fail_count);
   foreach my $genotype(sort keys %{ $rna_plate{ $well_id }{ 'genotype' } }) {
    $fail_count += $rna_plate{ $well_id }{ 'genotype' }{ $genotype }; 
    $geno_combos .= "::" . $genotype;
   }
   if(! $fail_count) { # all genotyping failed for this well
    $rna_plate{ $well_id }{ 'all_failed' }++;
   } 
   else {
    if($rna_plate{ $well_id }{ 'qc_ok' }) { # there is enough RNA
     $geno_combos=~s/^:://xms;
     push(@{ $allele_combos{ $geno_combos } }, [ $well_id, $rna_plate{ $well_id }{ 'rna' } ]);
    }
   }
  }

  my %allele_geno_combinations;

  foreach my $allele_combo( keys %allele_combos ) { ## sort on the amount of RNA 
   $allele_geno_combinations{ @{ $allele_combos{ $allele_combo } } }{ $allele_combo } = 
       [ sort {$b->[1] <=> $a->[1]} @{ $allele_combos{ $allele_combo } } ];
  }

  template 'get_genotype_combinations', {
    names_info                        => get_study_and_exp_names(param('exp_id')), 
    allele_combos                     => \%allele_geno_combinations,
    rna_volume                        => $rna_volume,
    min_rna_amount                    => $min_rna_amount,
   
    'populate_rna_dilution_plate_url'  => uri_for('/populate_rna_dilution_plate'),   
  };
  
};

post '/populate_rna_dilution_plate' => sub {

  my $exp_id = param('exp_id');

  my (%selected_wells, $selected_for_seq, $new_arr);
  foreach my $allele_geno(keys %allele_combos) {
   if(my $selected_number = param("$allele_geno")) {
    for(my$i=0;$i<$selected_number;$i++) {
     $selected_wells{ $allele_combos{$allele_geno}->[$i]->[0] } = $allele_geno;
    }
   }
  }
  
  my $rna_sth    = $dbh->prepare("CALL add_rna_dilution_data(?,?,?,?,?,?,?, \@rna_dil_id)");
  my $geno_sth   = $dbh->prepare("CALL add_genotype_data(?,?,?)");

  foreach my $well_id( keys %rna_plate ) {
   my $rna_amount = $rna_plate{ $well_id }{ 'rna' };
   my $qc_pass    = $rna_plate{ $well_id }{ 'qc_ok' };

   if(exists( $selected_wells{ $well_id } )) {
    $selected_for_seq = 1;
    $rna_plate{ $well_id }{ 'sfs' } = 1;
   }
   else {
    $selected_for_seq = 0;
    $rna_plate{ $well_id }{ 'sfs' } = 0;
   }

   ## add one well 
   $rna_sth->execute($exp_id, 
                     $rna_amount, 
                     param('rna_volume'), 
                     $well_id, 
                     param('min_rna_amount'), 
                     $qc_pass,
                     $selected_for_seq);
   my ($rna_dil_id) = $dbh->selectrow_array("SELECT \@rna_dil_id");
   my $alle_sth = $dbh->prepare("SELECT id FROM AlleleView WHERE name = ?");

   ## add one or more genotypes
   foreach my $allele_genotype( keys %{ $rna_plate{ $well_id }{ 'genotype' } } ) {
    my($allele_name, $genotype) = split":", $allele_genotype;
    $alle_sth->execute("$allele_name");
    my $allele_id = $alle_sth->fetchrow_arrayref;
    $geno_sth->execute($allele_id->[0], $rna_dil_id, $genotype);
   }
  }
  $new_arr = make_grid()->[0];
  
  foreach my $cell( @{ $new_arr } ) {
   if( exists( $rna_plate{ $cell } ) ) {
    if( $rna_plate{ $cell }{ 'sfs' } ) {
     $cell = '#00FF00'; ## selected for sequencing - green
    }
    elsif( ! $rna_plate{ $cell }{ 'qc_ok' } ) {
     $cell = '#FF0000'; ## RNA conc too low - red
    }
    elsif( $rna_plate{ $cell }{ 'all_failed' } ) {
     $cell = '#FFA500'; ## all the allele genotyping failed - orange
    }
    else {
     $cell = '#FFFFFF';
    }
   }
  }
 
  template 'display_rna_plates', {
   names_info                        => get_study_and_exp_names($exp_id),
   template_array 		     => $new_arr,
  };
  

};

sub write_file {
 my($excel_data, $seq_plate_name)=@_;
 my $date_time = `date --rfc-3339=seconds | xargs echo -n`;
 my($date, $time) = split" ",$date_time;
 $time=~s/\+.*//;
 $time=~s/:/_/g;
 my $dir = "$exel_file_dir/$date-$time";
 make_path($dir, { verbose => 1,  mode => 0777 }); 
 
 my $file = "$dir/$seq_plate_name.xlsx"; 

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

sub make_grid {

 my $new_arr;
 my @ALPH = 'A'..'H';
 my @NUM = 1..12;
 my $ct = 0;
 my (%mhash, %chash);
 for(my$j=0;$j<@NUM;$j++){
  for(my$i=0;$i<@ALPH;$i++){
   my $well_index = $ALPH[$i] . $NUM[$j];
   $mhash{ $ct } = $well_index;
   $ct++;
  }
 }

 $ct = 0;
 for(my$i=0;$i<@ALPH;$i++){
  for(my$j=0;$j<@NUM;$j++){
   my $well_index = $ALPH[$i] . $NUM[$j];
   $chash{ $ct } = $well_index;
   $ct++;
  }
 }
 
 push @{ $new_arr }, '', 1..12, '##';
 for(my$i=0;$i<8;$i++){
  push @{ $new_arr }, shift @ALPH;
  for(my$j=$i;$j<96;$j=$j+8){
   push @{ $new_arr },  $mhash{ $j };
  }
  push @{ $new_arr }, '##';
 }
 return [ $new_arr, \%chash, \%mhash ];
}
  
sub switch_cols_rows {
 my(%al2nu, %nu2al);
 @al2nu{"A".."L"} = (1..12);
 @nu2al{1..8} = ("A".."H");

 return join "", map { $nu2al{ $_->[1] }, $al2nu{ $_->[0] } } [ split "", shift ];
}

sub make_file_path {
 my $dir = join"/",@_;
 if("$dir") {
  make_path("$dir", { verbose => 1,  mode => 0777 });
  return $dir;
 }
 undef;
}

sub get_study_and_exp_names {
 my ($exp_id) = @_;
 my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView WHERE exp_id = ?");
 $exp_sth->execute($exp_id);
 return $exp_sth->fetchrow_arrayref || undef;
}

sub get_schema {
  return DBI->connect("DBI:mysql:$db_name;host=utlt-db;port=3307", 'tillingrw', 'tillingrw')
    or die "Cannot connect to database\n";
}

true;
