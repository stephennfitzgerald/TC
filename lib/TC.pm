package TC;
  
use strict;
use warnings;
use Dancer2;
use File::Path qw(make_path);
use Excel::Writer::XLSX;
use Spreadsheet::Read;
use Spreadsheet::XLSX;
use constant INCR => 3500; ## increase the color $dec
use constant MAX_WELL_COL => 12;
use constant MAX_WELL_ROW => 8;
use constant PLATE_SIZE => 96;
use Data::Dumper;
use Carp;
use DBI;

use constant GENOTYPES_C => {
 'Blank'    => 0,
 'Hom'      => 'homozygous mutant',
 'Het'      => 'heterozygous',
 'Wildtype' => 'wild type',
 'Failed'   => 'failed',
 'Missing'  => 'missing',
};

use constant KlusterCallerCodes => {
 '0'        => 'Blank',
 '1'        => 'Hom',
 '2'        => 'Het',
 '3'        => 'Wildtype',
 '5'        => 'Failed',
 '6'        => 'Missing',
};

use constant SPIKE_IDS => {
 '0'        => 'No spike mix',
 '1'        => 'ERCC spike mix 1 (Ambion)',
 '2'        => 'ERCC spike mix 2 (Ambion)',
};

use constant VISIBILITY => {
  1         => "Public",
  2         => "Hold",
};

our $VERSION = '0.1';
my $db_name = "zfish_sf5_tc4_test";
my $exel_file_dir = "./public/zmp_exel_files"; # need to change
my $rna_dilution_dir = "./public/RNA_dilution_files";
my $image_dir = "./public/images"; 
my (@alleles, %rna_plate, %allele_combos, $dbh, $seq_plate_name);
my $schema_location = "images/schema_tables_zmp.png";

get '/' => sub {
    
 template 'index', { 
  'schema_location'               => $schema_location,

  'add_sequencing_form_url'    => uri_for('/add_sequencing_form'),
  'update_image_url'              => uri_for('/update_image'),
  'add_a_new_study_url'           => uri_for('/add_a_new_study'),
  'add_a_new_assembly_url'        => uri_for('/add_a_new_assembly'),
  'add_a_new_dev_stage_url'       => uri_for('/add_a_new_devstage'),
  'get_new_experiment_url'        => uri_for('/get_new_experiment'),
  'make_sequencing_plate_url'     => uri_for('/get_sequencing_info'),
  'make_sequencing_report_url'    => uri_for('/get_sequencing_report'),
  'get_all_sequencing_plates_url' => uri_for('/get_all_sequencing_plates'),
  'get_all_experiments_url'       => uri_for('/get_all_experiments'),
 };
       
};


get '/add_sequencing_form' => sub {

 $dbh = get_schema();

 my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
 $seq_plates_sth->execute;
 my $all_seq_plates = $seq_plates_sth->fetchall_arrayref;

 template 'add_sequencing_form', {
   'all_seq_plates'                => $all_seq_plates,
   
   'make_sequencing_report_url'    => uri_for('/get_sequencing_report'),
 }; 

};


post '/update_image' => sub {

 $dbh = get_schema();

 if(my $new_image = upload('new_image_loc')) {
  $new_image->copy_to("$image_dir");
  my $image = $new_image->tempname;
  $image=~s/.*\///xms;
  if(my $exp_id = param('exp_id')) {
   my $update_exp_sth = $dbh->prepare("CALL update_image(?,?)");
   $update_exp_sth->execute($exp_id,$image);
  }
 }

 my $std_exp_sth = $dbh->prepare("SELECT * FROM ImageView");
 $std_exp_sth->execute;
 my $image_info = $std_exp_sth->fetchall_arrayref;
 
 template 'update_image', {
  'image_info'                    => $image_info,

  'update_image_url'              => uri_for('/update_image'),
 };

};


get '/add_a_new_study' => sub {
 
 $dbh = get_schema();
 my $std_id;
 if(my $new_study_name = param('new_study')) {
  $new_study_name=trim($new_study_name);
  my $new_std_sth = $dbh->prepare("CALL add_new_study(?, \@std_id)");
  $new_std_sth->execute($new_study_name);
  ($std_id) = $dbh->selectrow_array("SELECT \@std_id");
 }

 my $std_sth = $dbh->prepare("SELECT * FROM stdView");
 $std_sth->execute;
 my $col_names = $std_sth->{'NAME'};
 my $all_studies = $std_sth->fetchall_arrayref();
 unshift @{ $all_studies }, $col_names;

 template 'new_study', {
 'studies'                      => $all_studies,
 'new_std_id'                   => $std_id, 

 'add_a_new_study_url'          => uri_for('/add_a_new_study'),
 };

};


get '/add_a_new_devstage' => sub {
 
 $dbh = get_schema();
 my $dev_id;
 my ($period, $stage, $begins, $landmarks) = (param('period'), param('stage'), param('begins'), param('landmarks'));
 
 if($period and $stage and $begins and $landmarks) {
  $period=trim($period);
  $stage=trim($stage);
  $begins=trim($begins);
  $landmarks=trim($landmarks);
  my $new_devstage_sth = $dbh->prepare("CALL add_new_devstage(?,?,?,?, \@dev_id)");
  $new_devstage_sth->execute($period, $stage, $begins, $landmarks);
  ($dev_id) = $dbh->selectrow_array("SELECT \@dev_id");
 }

 my $dev_sth = $dbh->prepare("SELECT * FROM devView");
 $dev_sth->execute;
 my $col_names = $dev_sth->{'NAME'};
 my $all_dev_stages = $dev_sth->fetchall_arrayref();
 unshift @{ $all_dev_stages }, $col_names;

 template 'new_dev_stage', {
  'dev_stages'                    => $all_dev_stages,
  'new_dev_id'                    => $dev_id,

  'add_a_new_dev_stage_url'       => uri_for('/add_a_new_devstage'),
 };

};


get '/add_a_new_assembly' => sub {
 
 $dbh = get_schema();
 my $assembly_id;
 my($species_id, $assembly_name, $gc_content) = (param('species_id'), param('assembly_name'), param('gc_content'));
 
 if($species_id and $assembly_name and $gc_content) {
  $species_id=trim($species_id);
  $assembly_name=trim($assembly_name);
  $gc_content=trim($gc_content);
  my $new_assembly_sth = $dbh->prepare("CALL add_new_assembly(?,?,?, \@ass_id)");
  $new_assembly_sth->execute($assembly_name, $species_id, $gc_content);
  ($assembly_id) = $dbh->selectrow_array("SELECT \@ass_id");
 }

 my $assembly_sth = $dbh->prepare("SELECT * FROM SpView");
 $assembly_sth->execute;
 my $col_names = $assembly_sth->{'NAME'};
 my $assemblies = $assembly_sth->fetchall_arrayref();
 unshift @{ $assemblies }, $col_names;

 my $species_sth = $dbh->prepare("SELECT * FROM SpeciesView");
 $species_sth->execute;

 template 'new_assembly', {
  'assemblies'                   => $assemblies,
  'new_assembly_id'              => $assembly_id,
  'species'                      => $species_sth->fetchall_arrayref,

  'add_a_new_assembly_url'       => uri_for('/add_a_new_assembly'),
 };

};


get '/get_all_experiments' => sub {
 
 $dbh = get_schema(); 
 my $exp_disp_sth = $dbh->prepare('SELECT * FROM ExpDisplayView');
 $exp_disp_sth->execute;
 my $col_names = $exp_disp_sth->{'NAME'};
 my $all_experiments = $exp_disp_sth->fetchall_arrayref();
 unshift @{ $all_experiments }, $col_names;
 
 my $gen_sth = $dbh->prepare("SELECT * FROM SpView");
 $gen_sth->execute;

 my %allele_info;
 my $gene_sth = $dbh->prepare("SELECT * FROM alleleGeneView");
 $gene_sth->execute;
 foreach my $alle_gen(@{ $gene_sth->fetchall_arrayref }) {
  push @{ $allele_info{ $alle_gen->[0] } }, $alle_gen->[1];
 }

 my $spikes_sth = $dbh->prepare("SELECT * FROM spikeView");
 $spikes_sth->execute;

 my $dev_sth = $dbh->prepare("SELECT * FROM DevInfoView");
 $dev_sth->execute;
 
 template 'all_experiments', {
  'all_experiments'              => $all_experiments,
  'species_info'                 => $gen_sth->fetchall_hashref('Genome_ref_name'),
  'spike_info'    => $spikes_sth->fetchall_hashref('exp_id'),
  'dev_info'    => $dev_sth->fetchall_hashref('exp_id'),
  'allele_info'                  => \%allele_info,
  
  'get_sequenced_samples_url'    => uri_for('/get_sequenced_samples'),
 };

};


get '/get_sequenced_samples' => sub {

 $dbh = get_schema();
 my $exp_info = get_study_and_exp_names(param('exp_id'));
 
 my $sequenced_samples_sth = $dbh->prepare("SELECT * FROM seqSampleView WHERE Experiment_id = ?");
 $sequenced_samples_sth->execute(param('exp_id'));
 my $col_names = $sequenced_samples_sth->{'NAME'};
 my $sequenced_samples = $sequenced_samples_sth->fetchall_arrayref();
 unshift @{ $sequenced_samples }, $col_names;

 template 'display_sequenced_samples', {
 
  'sequenced_samples'            => $sequenced_samples,         
  'exp_info'                     => $exp_info,
 };

};


get '/get_all_sequencing_plates' => sub {

 $dbh = get_schema();
 my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
 $seq_plates_sth->execute;
 my $all_seq_plates = $seq_plates_sth->fetchall_arrayref;

 template 'all_sequencing_plates', { 
  'all_seq_plates'                => $all_seq_plates,
  
  'display_well_order_url'        => uri_for('/display_well_order'),
  'display_genot_order_url'       => uri_for('/display_genot_order'),
  'display_tag_order_url'         => uri_for('/display_tag_order'),
 };

};


get '/display_well_order' => sub {

 my $color_plate = color_plate( 'well_names' );

 template 'display_sequence_plate', {
  
  display_plate_name              => param('display_plate_name'),
  sequence_plate                  => $color_plate->[0],
  legend                          => $color_plate->[1],
  plate_name                      => param('plate_name'),
 
  'display_genot_order_url'       => uri_for('/display_genot_order'),
  'display_tag_order_url'         => uri_for('/display_tag_order'),
  'display_well_order_url'        => uri_for('/display_well_order'),
 };

};


get '/display_tag_order' => sub {

 my $color_plate = color_plate( 'index_tags' );

 template 'display_sequence_plate', {
  
  display_plate_name              => param('display_plate_name'),
  sequence_plate                  => $color_plate->[0],
  plate_name                      => param('plate_name'),

  'display_genot_order_url'       => uri_for('/display_genot_order'),
  'display_tag_order_url'         => uri_for('/display_tag_order'),
  'display_well_order_url'        => uri_for('/display_well_order'),
 };

}; 


get '/display_genot_order' => sub {

 my $color_plate = color_plate( 'genotypes' );

 template 'display_sequence_plate', {
  
  display_plate_name              => param('display_plate_name'),
  sequence_plate                  => $color_plate->[0],
  legend                          => $color_plate->[1],
  geno_legend                     => $color_plate->[2],
  plate_name                      => param('plate_name'),

  'display_well_order_url'        => uri_for('/display_well_order'),
  'display_tag_order_url'         => uri_for('/display_tag_order'),
  'display_genot_order_url'       => uri_for('/display_genot_order'),
 };

}; 


get '/get_sequencing_report' => sub {

 $dbh = get_schema();
 my ($excel_file_loc, $all_seq_plates);
 my $template = 'index';

 if(my $new_seq_plate = param('new_seq_plate_name')) { ## adding a report to a pre-existing sequence plate
  $seq_plate_name = $new_seq_plate;
  $template = 'add_sequencing_form';
 }

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
     foreach my $alle_genotype( split',', $sequence_plate->{"$index_tag_id"}->{'AlleleGenotype'} ) {
      my($allele,$gene,$genotype) = split':', $alle_genotype;
      $alle_geno{$genotype}{"$gene allele $allele"}++;
     }
     my $description = "3' end enriched mRNA from a single genotyped embryo ";
     foreach my $geno(sort keys %alle_geno) {
      $description .= GENOTYPES_C->{ $geno } . " for ";
      foreach my $gene_allele(sort keys %{ $alle_geno{ $geno } }) {
       $description .= "$gene_allele, ";
      }
     }
     my $index_tag_seq = $sequence_plate->{"$index_tag_id"}->{'desc_tag_index_sequence'};
     $index_tag_seq=~s/CG$//xms; ## remove the final 2 bases - these are always "CG"
     my $zmp_exp_name = $sequence_plate->{"$index_tag_id"}->{'zmp_name'}; 
     $description .= "clutch 1 with " . SPIKE_IDS->{ $sequence_plate->{"$index_tag_id"}->{'desc_spike_mix'} } .
      ". A 8 base indexing sequence ($index_tag_seq) is bases 13 to 20 of read 1 followed by CG and polyT. " . 
      'More information describing the phenotype can be found at the ' .
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
   ($excel_file_loc) = $file_loc=~/\.\/public\/(.*)/xms;
   $seq_time_sth->execute($excel_file_loc, $date, $seq_plate_name);
  }
 }

 if($template eq 'add_sequencing_form') { ## need to re-query after updating the db
  my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
  $seq_plates_sth->execute;
  $all_seq_plates = $seq_plates_sth->fetchall_arrayref;
 }  

 template "$template", { 
  'schema_location'               => $schema_location,   
  'excel_file_loc'                => $excel_file_loc,
  'all_seq_plates'                => $all_seq_plates,

  'add_sequencing_form_url'       => uri_for('/add_sequencing_form'),
  'update_image_url'              => uri_for('/update_image'),
  'add_a_new_study_url'           => uri_for('/add_a_new_study'),
  'add_a_new_assembly_url'        => uri_for('/add_a_new_assembly'),
  'add_a_new_dev_stage_url'       => uri_for('/add_a_new_devstage'),
  'get_new_experiment_url'        => uri_for('/get_new_experiment'),
  'make_sequencing_plate_url'     => uri_for('/get_sequencing_info'),
  'make_sequencing_report_url'    => uri_for('/get_sequencing_report'),
  'get_all_sequencing_plates_url' => uri_for('/get_all_sequencing_plates'),
  'get_all_experiments_url'       => uri_for('/get_all_experiments'),
 };

};


get '/get_sequencing_info' => sub {

 $dbh = get_schema();
 my (%seq, %unseq);
 my $exp_seq_sth = $dbh->prepare("SELECT * FROM SeqExpView");
 $exp_seq_sth->execute;
 foreach my $exp_seq(@{ $exp_seq_sth->fetchall_arrayref }) {
  my($exp_id, $exp_name, $std_name, $alleles, $seq_plate, $count) = @{ $exp_seq };
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
  seq                       => \%seq,
  tag_set_names             => $tag_set_names,

  'combine_plate_data_url'  => uri_for('/combine_plate_data'), 
 };

};


post '/combine_plate_data' => sub {

 $dbh = get_schema();
 my (%combined_plate, %exp_ids, %cell_color, %exp_color, %cell_mapping, %index_tag_set);
 my $dec = 45280; 
 my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
 $exp_sth->execute;
 my $all_exps = $exp_sth->fetchall_hashref('exp_id');
 my $tag_set_prefix = param('tag_set_name');
 my $tag_seqs_sth = $dbh->prepare("SELECT * FROM tagSeqView WHERE name_prefix = ?");
 $tag_seqs_sth->execute("$tag_set_prefix");
 my $index_hash = make_grid()->[1]; ## for merging the experiment(s) onto a single plate
 my $tag_seqs = $tag_seqs_sth->fetchall_arrayref;
 
 ## try and get the spacing between experiments correct
 my $wells_per_exp_sth = $dbh->prepare("SELECT * FROM SelectedExpNumView");
 $wells_per_exp_sth->execute;
 my %plate_samples = %{ $wells_per_exp_sth->fetchall_hashref('exp_id') };
 my (@numbers, $sum, %filler);
 foreach my $exp_id(sort {$b<=>$a} keys %plate_samples) {
  if( ! param("$exp_id") ) {
    delete( $plate_samples{ $exp_id } );
  }
  else {
   my $well_no = $plate_samples{ $exp_id }{ 'numb' };
   $sum += $well_no;
   my $filler_size = MAX_WELL_COL - ($well_no % MAX_WELL_COL);
   $filler_size = $filler_size == MAX_WELL_COL ? 0 : $filler_size;
   push @numbers, [ $exp_id, $filler_size, 0];
  }
 }
 my $free_wells = PLATE_SIZE - $sum;
 pop @numbers;
 my $all_not_done = 1;
 while ($free_wells && $all_not_done) {
  $all_not_done = 0;
  foreach my $exp(@numbers){
   if($free_wells && $exp->[1] != $exp->[2]) {
    $exp->[2]++;
    $free_wells--;
    $all_not_done = 1;
   }
  }
 }
 foreach my $exp_id(@numbers){
  $filler{ $exp_id->[0] } = $exp_id->[2];
 }
 
 my $display_plate_name;
 my $ct = 0; ## array index corresponds to the index positions in $index_hash below
 foreach my $exp_id(sort {$b <=> $a} keys %{ $all_exps }) { ## most recent exp at top of plate
  if(my $exp_name = param("$exp_id")) {
   if($exp_name eq $all_exps->{"$exp_id"}->{'exp_name'}) { ## this should always be true
    $display_plate_name .= $exp_name . q{::};
    my $rdp_sth = $dbh->prepare("SELECT * FROM RnaDilPlateView WHERE experiment_id = ?");
    $rdp_sth->execute("$exp_id");
    my $hex = sprintf "0x%x", $dec;
    $hex=~s/0x/#/;
    $exp_color{ $hex }{ 'exp_name' } = $exp_name; ## legend colors for exps
    foreach my $sample(@{ $rdp_sth->fetchall_arrayref }) {
     $exp_color{ $hex }{ 'std_name' } = $sample->[4];
     $exp_ids{ $sample->[2] }++; ## experiment_ids
     my $tag_seq = shift @{ $tag_seqs };
     $index_tag_set{ $tag_seq->[0] } = $tag_seq->[1];
     $combined_plate{ $sample->[0] }{ 'rna_plate_well_name' }  = $sample->[1];
     $combined_plate{ $sample->[0] }{ 'exp_name' }             = $sample->[3];
     $combined_plate{ $sample->[0] }{ 'std_name' }             = $sample->[4];
     $combined_plate{ $sample->[0] }{ 'index_tag_id' }         = $tag_seq->[0];
     $combined_plate{ $sample->[0] }{ 'seq_plate_well_name' }  = $index_hash->{ $ct };
     $combined_plate{ $sample->[0] }{ 'color' }                = $hex;
     $cell_color{ $index_hash->{ $ct } } = $hex; ## cell colors
     $cell_mapping{ $index_hash->{ $ct } } = $sample->[1]; ## mapping betweem rna plate(s) and seq plate
     $ct++;
    }
    if( $filler{ $exp_id } ) {
     $ct += $filler{ $exp_id };
     splice @{ $tag_seqs }, 0, $filler{ $exp_id }; ## remove the corresponding number of tag sequences as well
    }
    $dec += INCR;
    
   }
  }
 }
 $seq_plate_name = join "_", keys %exp_ids;
 my $spd_sth = $dbh->prepare("CALL add_sequence_plate_data(?,?,?,?,?,?,?)");
 my $seq_array = make_grid()->[0];
 foreach my $rna_plate_id(sort {$a <=> $b} keys %combined_plate) {
  my $seq_plate_well_name = $combined_plate{ $rna_plate_id }{ 'seq_plate_well_name' };
  my $rna_plate_well_name = $combined_plate{ $rna_plate_id }{ 'rna_plate_well_name' };
  my $index_tag_id = $combined_plate{ $rna_plate_id }{ 'index_tag_id' };
  my $sample_name = join "_", $combined_plate{ $rna_plate_id }{ 'exp_name' }, $rna_plate_well_name;
  my ($tag_num) = $index_tag_set{ $index_tag_id }=~m/\.([[:digit:]]+)/xms;
  my $sample_public_name = join "_", $sample_name, $seq_plate_well_name, $tag_num;
  my $hex_color = $combined_plate{ $rna_plate_id }{ 'color' };
  $spd_sth->execute( $seq_plate_name, 
                     $seq_plate_well_name,
                     $sample_name,
                     $sample_public_name,
                     $rna_plate_id,
                     $index_tag_id,
                     $hex_color );                   
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
 $display_plate_name=~s/::$//msx;
 
 template 'display_sequence_plate', {

  display_plate_name     => $display_plate_name,
  sequence_plate         => $seq_array,
  legend    => \%exp_color,
 };
  
};


get '/get_new_experiment' => sub {

 $dbh = get_schema();
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
   last_std_name                       => $last_exp->[0],
   last_exp_name                       => $last_exp->[1],
   last_allele_name                    => $last_exp->[2],
   last_dev_stage                      => $last_exp->[3],
   last_ec_numb                        => $last_exp->[4],
   last_ec_method                      => $last_exp->[5],
   last_ec_date                        => $last_exp->[6],
   last_ec_by                          => $last_exp->[7],
   last_spike_mix                      => $last_exp->[8],
   last_spike_dil                      => $last_exp->[9],
   last_spike_vol                      => $last_exp->[10],
   last_visable                        => $last_exp->[11],
   last_genome_ref                     => $last_exp->[12],
   last_rna_ext_by                     => $last_exp->[13],
   last_rna_ext_prot_version           => $last_exp->[14],
   last_rna_ext_date                   => $last_exp->[15],
   last_library_creation_date          => $last_exp->[16],
   last_library_creation_prot_version  => $last_exp->[17],
   last_image                          => $last_exp->[18],
   last_lines_crossed                  => $last_exp->[19],
   last_founder                        => $last_exp->[20],
   last_pheno_desc                     => $last_exp->[21],
   last_asset_group                    => $last_exp->[22],
   last_library_tube_id                => $last_exp->[23],
 
   spike_ids                           => SPIKE_IDS,
   genref_names                        => $genref_names, 
   table_schema                        => $table_schema,
   dev_stages                          => $dev_stages,
   visibility                          => VISIBILITY,
   study_names                         => $std_names,

   add_experiment_data_url             => uri_for('/add_experiment_data'),
 };

};


post '/add_experiment_data' => sub {

 $dbh = get_schema();
 my $vals = [
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
   param('Asset_group'),
   param('Developmental_stage')
 ];

 ## check to see if new study and experiment names already exist
 my %std_exp_names;
 my $std_exp_sth = $dbh->prepare("SELECT * FROM ExpStdy");
 $std_exp_sth->execute;
 foreach my $std_exp(@{ $std_exp_sth->fetchall_arrayref }) {
  # study_id, exp_name, study_name
  $std_exp_names{ $std_exp->[1] }{ $std_exp->[2] } = $std_exp->[0];
 }
 if(exists( $std_exp_names{ $vals->[0] }{ $vals->[2] } )) {
  croak "Study \"$std_exp_names{ $vals->[0] }{ $vals->[2] }\" and experiment \"$vals->[2]\" already exist in the database";
 }

 ## and add alleles to the global array 
 my $alle_sth = $dbh->prepare("SELECT * FROM AlleleView WHERE name = ?");
 @alleles=(); # empty the global array
 my @no_alleles;
 my $check_alleles_sth = $dbh->prepare("SELECT * FROM CheckAlleles");
 $check_alleles_sth->execute;
 my $check_alleles = $check_alleles_sth->fetchall_hashref('name'); 

 ## check that the alleles exist in the database 
 foreach my $allele_name(split':', param('Alleles')){
  $allele_name=trim($allele_name);
  if(! exists($check_alleles->{"$allele_name"})) {
   push @no_alleles, $allele_name;
  } 
  else {
   $alle_sth->execute("$allele_name");
   push @alleles, @{ $alle_sth->fetchall_arrayref };
  }
 }
 if( scalar @no_alleles ) {
  croak 'Alleles ', join', ', @no_alleles, ' do not exist in the database';
 }
  
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
 my @rna_extraction_data = (param('RNA_extracted_by'),
                            param('RNA_extraction_protocol_version'),
                            param('RNA_extraction_date'),
                            param('RNA_library_creation_date'),
                            param('RNA_library_creation_protocol_version'),
                            param('RNA_library_tube_id')
                           );
 ## add the RNA-extraction info
 my $rna_ext_sth = $dbh->prepare("CALL add_rna_extraction_data(?,?,?,?,?,?, \@rna_ext_id)");
 $rna_ext_sth->execute(@rna_extraction_data);
 my ($rna_ext_id) = $dbh->selectrow_array("SELECT \@rna_ext_id");
 ## add a new experiment
 my $exp_sth = $dbh->prepare("CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)");
 $exp_sth->execute( $rna_ext_id, $image, @{ $vals });
 my ($exp_id) = $dbh->selectrow_array("SELECT \@exp_id");

 template 'get_genotypes_and_rna', {
    names_info                 => get_study_and_exp_names($exp_id), 
    alleles                    => \@alleles,
   
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
  foreach my $row(1..MAX_WELL_ROW) {
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
    my @wells = map { split' ', $_ } $file->content=~/\[wells\] (.*)/xms;
    foreach my $well(@wells) {
     $well=~s/\,.*//x;
     my($well_id, $geno_id) = split'=', $well;
     if( my($alpha, $num) = $well_id=~/(^[A-H])0?([1-9][0-9]?)/xms ) { 
      $well_id = $alpha . $num;
      if( exists($rna_plate{ $well_id }) ){
       my $fail_num = KlusterCallerCodes->{ $geno_id } eq "Failed" ? 0 : 1;
       $rna_plate{ $well_id }{ 'genotype' }{ $allele_name . ":" . KlusterCallerCodes->{ $geno_id } } = $fail_num; 
      }
     }   
    }   
   }   
  }

  %allele_combos = (); # re-set the global
  my @wells_wo_genotypes;
  foreach my $well_id( keys %rna_plate ){
   if( (! exists($rna_plate{ $well_id }{ 'genotype' })) || ((keys %{ $rna_plate{ $well_id }{ 'genotype' } }) != scalar @alleles) ) {
    push @wells_wo_genotypes, $well_id; # discrepancy between rna-plate and genotype-plate(s)
   }
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

  if(scalar @wells_wo_genotypes) { # not all the wells on the rna plate have a genotype - this is a problem
   $dbh = get_schema();
   my $exp_del_sth = $dbh->prepare("CALL delete_exp(?)");
   $exp_del_sth->execute(param('exp_id')); # remove the experiment and rna_extraction record from the database
   croak 'Discrepancy between the wells (' . join(", ", @wells_wo_genotypes) . 
         ') in the rna-plate and the genotyping plate(s). The experiment ' . 
         param('exp_name') . ' has been removed from the database';
  }

  my %allele_geno_combinations;

  foreach my $allele_combo( keys %allele_combos ) { ## sort on the amount of RNA 
   $allele_geno_combinations{ @{ $allele_combos{ $allele_combo } } }{ $allele_combo } = 
       [ sort {$b->[1] <=> $a->[1]} @{ $allele_combos{ $allele_combo } } ];
  }

  template 'get_genotype_combinations', {
    names_info                         => get_study_and_exp_names(param('exp_id')), 
    allele_combos                      => \%allele_geno_combinations,
    rna_volume                         => $rna_volume,
    min_rna_amount                     => $min_rna_amount,
   
    'populate_rna_dilution_plate_url'  => uri_for('/populate_rna_dilution_plate'),   
  };
  
};


post '/populate_rna_dilution_plate' => sub {

 $dbh = get_schema();
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
   my($allele_name, $genotype) = split':', $allele_genotype;
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
  template_array                    => $new_arr,
 };

};


sub write_file {
 my($excel_data, $seq_plate)=@_;
 my $date_time = `date --rfc-3339=seconds | xargs echo -n`;
 my($date, $time) = split' ',$date_time;
 $time=~s/\+.*//x;
 $time=~s/:/_/xg;
 my $dir = "$exel_file_dir/$date-$time";
 make_path($dir, { verbose => 1,  mode => 0777 }); 
 
 my $file = "$dir/$seq_plate.xlsx"; 

 my $workbook  = Excel::Writer::XLSX->new( "$file" );
 my $worksheet = $workbook->add_worksheet();

 my($row,$col) = (0,0);
 for(my$i=0;$i<@{ $excel_data };$i++){
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
 my @NUM = 1..MAX_WELL_COL;
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
 
 push @{ $new_arr }, '', 1..MAX_WELL_COL, '##';
 for(my$i=0;$i<MAX_WELL_ROW;$i++){
  push @{ $new_arr }, shift @ALPH;
  for(my$j=$i;$j<PLATE_SIZE;$j=$j + MAX_WELL_ROW){
   push @{ $new_arr },  $mhash{ $j };
  }
  push @{ $new_arr }, '##';
 }
 return [ $new_arr, \%chash, \%mhash ];
}
  
sub switch_cols_rows {
 my(%al2nu, %nu2al);
 @al2nu{'A'..'L'} = (1..MAX_WELL_COL);
 @nu2al{1..MAX_WELL_ROW} = ('A'..'H');

 return join '', map { $nu2al{ $_->[1] }, $al2nu{ $_->[0] } } [ split'', shift ];
}

sub make_file_path {
 my $dir = join"/",@_;
 if("$dir") {
  make_path("$dir", { verbose => 1,  mode => 0777 });
  return $dir;
 }
 return;
}

sub trim { 
 my $s = shift; 
 $s =~ s/^\s+|\s+$//xg; 
 return $s;
}

sub get_study_and_exp_names {
 my ($exp_id) = @_;
 $dbh = get_schema();
 my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView WHERE exp_id = ?");
 $exp_sth->execute($exp_id);
 return $exp_sth->fetchrow_arrayref || undef;
}

sub color_plate {
 my $attrib = shift;
 $dbh = get_schema();
 my $seq_plate_sth = $dbh->prepare("SELECT * FROM SeqWellOrderView WHERE plate_name = ?");
 $seq_plate_sth->execute(param('plate_name'));
 my $seq_plate = $seq_plate_sth->fetchall_hashref('seq_well_name');
 my $template = make_grid()->[0];
 my (%exp_legend, %genot_legend, %num2geno);
 foreach my $well_id( @{ $template } ) {
  if(exists( $seq_plate->{$well_id} )) {
   $exp_legend{ $seq_plate->{$well_id}->{'color'} }{ 'exp_name' } = $seq_plate->{$well_id}->{'exp_name'};
   $exp_legend{ $seq_plate->{$well_id}->{'color'} }{ 'std_name' } = $seq_plate->{$well_id}->{'std_name'};
   if($attrib eq 'well_names') {
    $well_id = [ $seq_plate->{$well_id}->{'color'}, $seq_plate->{$well_id}->{'rna_well_name'} ];
   }
   elsif($attrib eq 'genotypes') {
    foreach my $genotype_str( split',', $seq_plate->{$well_id}->{'AlleleGenotype'} ) {
     my $well_genot = join ":", ( split':', $genotype_str )[0,2];
     $genot_legend{ $well_id }{ $well_genot }++;
     $num2geno{ $well_genot } = undef;
    }
   }
   elsif($attrib eq 'index_tags') {
    $well_id = [ $seq_plate->{$well_id}->{'color'}, $seq_plate->{$well_id}->{'tag_name'}, $seq_plate->{$well_id}->{'tag_seq'} ];
   } 
  }
  elsif( $well_id=~/[[:alpha:]][[:digit:]]+/xms ) {
   $well_id = [ '#D8D8D8', undef ]; ## grey for blank well
  }
  elsif( $well_id ne "##" ) { 
   $well_id = [ '#FFFFFF', $well_id ]; ## white
  }
 }
 if( keys %num2geno ) {
  my $ct = 1;
  foreach my $well_genot( sort keys %num2geno ) {
   $num2geno{ $well_genot } = $ct;
   $ct++;
  }
  foreach my $well_id( @{ $template } ) { ## set the wells for the genotypes
   if(exists($genot_legend{ $well_id })) {
    $well_id = [ $seq_plate->{$well_id}->{'color'}, join ":", sort map { $num2geno{$_} } keys %{ $genot_legend{ $well_id } } ];
   }
  }
 }
 return [ $template, \%exp_legend, \%num2geno, param('plate_name')];
}

sub get_schema {
  return DBI->connect("DBI:mysql:$db_name;host=utlt-db;port=3307", $ENV{'TC_USER'}, $ENV{'TC_PASS'})
    or die "Cannot connect to database\n";
}

1;
