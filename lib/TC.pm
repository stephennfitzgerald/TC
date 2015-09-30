package TC;

use strict;
use warnings;
use Dancer2;
use File::Path qw(make_path);
use Excel::Writer::XLSX;
use Spreadsheet::Read;
use Spreadsheet::XLSX;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::SaveParser;
use Scalar::Util qw(looks_like_number);
use Data::Dumper;
use Carp;
use DBI;

use constant INCR                  => 3500;    ## increase the color $dec
use constant MAX_WELL_COL          => 12;
use constant MAX_WELL_ROW          => 8;
use constant PLATE_SIZE            => 96;
use constant ADD_ONT_TERMS         => 5; ## max number of undef fields = ADD_ONT_TERMS - 1, for db insertion

use constant GENOTYPES_C => {
    'Blank'    => 0,
    'Hom'      => 'homozygous mutant',
    'Het'      => 'heterozygous',
    'Wildtype' => 'wild type',
    'Failed'   => 'failed',
    'Missing'  => 'missing',
};

use constant KlusterCallerCodes => {
    '0' => 'Blank',
    '1' => 'Hom',
    '2' => 'Het',
    '3' => 'Wildtype',
    '5' => 'Failed',
    '6' => 'Missing',
};

use constant SPIKE_IDS => {
    '0' => 'No spike mix',
    '1' => 'ERCC spike mix 1 (Ambion)',
    '2' => 'ERCC spike mix 2 (Ambion)',
};

use constant VISIBILITY => {
    1 => 'Hold',
    2 => 'Public',
};

use constant COLLECTION_DESCRIPTION => {
    1 => 'Blind',
    2 => 'Phenotypic',
};

use constant TREATMENT_TYPES => {
    1 => undef, 
    2 => 'No treatment',
    3 => 'Infection challenge',
    4 => 'Gene knockout',
    5 => 'Small molecule screen',
};

use constant PHENOTYPES => {
    1 => 'Phenotypic',
    2 => 'Non-Phenotypic',
    3 => 'Unknown',
};

use constant HEADER_ROW => 9;

use constant SANGER_COLS => {
    'SANGER TUBE ID'                                => 'A',    
    'SANGER SAMPLE ID'                               => 'B',
    'SUPPLIER SAMPLE NAME'                           => 'C',
    'COHORT'                                         => 'D',
    'VOLUME (ul)'                                    => 'E',
    'CONC. (ng/ul)'                                  => 'F',
    'GENDER'                                         => 'G',
    'COUNTRY OF ORIGIN'                              => 'H',
    'GEOGRAPHICAL REGION'                            => 'I',
    'ETHNICITY'                                      => 'J',
    'DNA SOURCE'                                     => 'K',
    'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)' => 'L',
    'DATE OF DNA EXTRACTION (MM/YY or YYYY only)'    => 'M',
    'IS SAMPLE A CONTROL?'                           => 'N',
    'IS RE-SUBMITTED SAMPLE?'                        => 'O',
    'DNA EXTRACTION METHOD'                          => 'P',
    'SAMPLE PURIFIED?'                               => 'Q',
    'PURIFICATION METHOD'                            => 'R',
    'CONCENTRATION DETERMINED BY'                    => 'S',
    'DNA STORAGE CONDITIONS'                         => 'T',
    'MOTHER (optional)'                              => 'U',
    'FATHER (optional)'                              => 'V',
    'SIBLING (optional)'                             => 'W',
    'GC CONTENT'                                     => 'X',
    'PUBLIC NAME'                                    => 'Y',
    'TAXON ID'                                       => 'Z',
    'COMMON NAME'                                    => 'AA',
    'SAMPLE DESCRIPTION'                             => 'AB',
    'STRAIN'                                         => 'AC',
    'SAMPLE VISIBILITY'                              => 'AD',
    'SAMPLE TYPE'                                    => 'AE',
    'GENOTYPE'                                       => 'AF',
    'PHENOTYPE (required for EGA)'                   => 'AG',
    'AGE (with units)'                               => 'AH',
    'Developmental stage'                            => 'AI',
    'Cell Type'                                      => 'AJ',
    'Disease State'                                  => 'AK',
    'Compound'                                       => 'AL',
    'Dose'                                           => 'AM',
    'Immunoprecipitate'                              => 'AN',
    'Growth condition'                               => 'AO',
    'RNAi'                                           => 'AP',
    'RNAi'                                           => 'AQ',
    'Organism part'                                  => 'AR',
    'Time Point'                                     => 'AS',
    'Treatment'                                      => 'AT',
    'Subject'                                        => 'AU',
    'Disease'                                        => 'AV',
    'SAMPLE ACCESSION NUMBER (optional)'             => 'AW',
    'DONOR ID (required for cancer samples)'         => 'AX',
}; 

use constant HC => {
    1 => undef,
    2 => 'N',
    3 => 'Y',
    4 => 'Other',
    5 => '-20C',
    6 => 'Library',
};

use constant ONT => { ## ontology information input by user to associate with an allele
    1 => 'snp_id',
    2 => 'allele_id',
    3 => 'stage',
    4 => 'entity1',
    5 => 'entity2',
    6 => 'quality',
    7 => 'tag',
};

my @EXCEL_FIELDS =
  (    ## column names in the excel sheet - most are hard-coded (numbers)
    [ 'SANGER TUBE ID',      undef ],
    [ 'SANGER SAMPLE ID',     undef ],
    [ 'SUPPLIER SAMPLE NAME', 'Sample_Name' ],
    [ 'COHORT',               1 ],
    [ 'VOLUME (ul)',          'Sample_Volume' ],
    [ 'CONC. (ng/ul)',        'Sample_Conc' ],
    [ 'GENDER',               1 ],
    [ 'COUNTRY OF ORIGIN',    1 ],
    [ 'GEOGRAPHICAL REGION',  1 ],
    [ 'ETHNICITY',            1 ],
    [ 'DNA SOURCE',           'DNA_Source' ],
    [
        'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',
        'Embryo_Collection_Date'
    ],
    [ 'DATE OF DNA EXTRACTION (MM/YY or YYYY only)', 'RNA_Extraction_Date' ],
    [ 'IS SAMPLE A CONTROL?',                        2 ],
    [ 'IS RE-SUBMITTED SAMPLE?',                     2 ],
    [ 'DNA EXTRACTION METHOD',                       1 ],
    [ 'SAMPLE PURIFIED?',                            3 ],
    [ 'PURIFICATION METHOD',                         4 ],
    [ 'CONCENTRATION DETERMINED BY',                 4 ],
    [ 'DNA STORAGE CONDITIONS',                      5 ],
    [ 'MOTHER (optional)',                           1 ],
    [ 'FATHER (optional)',                           1 ],
    [ 'SIBLING (optional)',                          1 ],
    [ 'GC CONTENT',                                  'GC_Content' ],
    [ 'PUBLIC NAME',                                 'Public_Name' ],
    [ 'TAXON ID',                                    'Taxon_ID' ],
    [ 'COMMON NAME',                                 'Common_Name' ],
    [ 'SAMPLE DESCRIPTION',                          undef ],
    [ 'STRAIN',                                      'Strain' ],
    [ 'SAMPLE VISIBILITY',                           'Sample_Visibility' ],
    [ 'SAMPLE TYPE',                                 6 ],
    [ 'GENOTYPE',                                    'Genotype' ],
    [ 'PHENOTYPE (required for EGA)',                'Phenotype_Description' ],
    [ 'AGE (with units)',                            1 ],
    [ 'Developmental stage',                         'Developmental_Stage' ],
    [ 'Cell Type',                                   1 ],
    [ 'Disease State',                               1 ],
    [ 'Compound',                                    1 ],
    [ 'Dose',                                        1 ],
    [ 'Immunoprecipitate',                           1 ],
    [ 'Growth condition',                            1 ],
    [ 'RNAi',                                        1 ],
    [ 'RNAi',                                        1 ],
    [ 'Organism part',                               'Organism_Part' ],
    [ 'Time Point',                                  1 ],
    [ 'Treatment',                                   1 ],
    [ 'Subject',                                     1 ],
    [ 'Disease',                                     1 ],
    [ 'SAMPLE ACCESSION NUMBER (optional)',          1 ],
    [ 'DONOR ID (required for cancer samples)',      'DONOR_ID' ],
  );

our $VERSION = '0.1';

my $db_name = "zfish_sf5_tc5_test";
#my $db_name          = "zfish_tilling_tc";
my $exel_file_dir    = "./public/zmp_exel_files";
my $rna_dilution_dir = "./public/RNA_dilution_files";
my $image_dir        = "./public/images";
my $kc_file_dir     = "./public/kc_files";
my ( @alleles, %rna_plate, %allele_combos, $dbh, $seq_plate_name, $expAlleGeno );
my $schema_location = "images/schema_tables_zmp.png";

get '/' => sub {

    template 'index', {
        'schema_location' => $schema_location,

        'make_sequencing_form_url'  => uri_for('/make_sequencing_form'),
        'update_image_url'          => uri_for('/update_image'),
        'add_a_new_study_url'       => uri_for('/add_a_new_study'),
        'add_a_new_assembly_url'    => uri_for('/add_a_new_assembly'),
        'add_a_new_dev_stage_url'   => uri_for('/add_a_new_devstage'),
        'get_new_experiment_url'    => uri_for('/get_new_experiment'),
        'make_sequencing_plate_url' => uri_for('/get_sequencing_info'),
        'get_all_sequencing_plates_url' =>
          uri_for('/get_all_sequencing_plates'),
        'get_all_experiments_url' => uri_for('/get_all_experiments'),
        'get_ontology_for_allele_url' => uri_for('/get_ontology_for_allele'),  
        'delete_experiment_url'     => uri_for('/delete_experiment'),
        'add_sequencing_plate_data_url' => uri_for('/add_sequencing_plate_data'),
        'choose_a_tc_experiment_url'    => uri_for('/choose_a_tc_experiment'),
        'update_a_phenotype_url'    => uri_for('/update_a_phenotype'),  
        'update_an_ena_id_url'      => uri_for('/update_an_ena_id'),
        'add_a_treatment_url'       => uri_for('/add_a_treatment'),
        'add_a_new_allele_url'      => uri_for('/add_a_new_allele'),
        'modify_a_kc_plate_url'     => uri_for('/modify_a_kc_plate'),
    };

};

get '/update_an_ena_id' => sub {

 $dbh = get_schema();
 my ($study_exp, $ena_res, $ena_upd);
 if(my $exp_name_id = param('exp_to_check')) {
  my($exp_name, $exp_id) = split'::', $exp_name_id;
  my $wh_dbh = get_wh_schema(); 
  my ($name_stem) = $exp_name=~/(\w*[-_]?\w*).*/xms;
  my $ena_res_sth = $wh_dbh->prepare("SELECT name, 
                                      accession_number 
                                      FROM current_samples 
                                      WHERE name LIKE ? 
                                      AND accession_number IS NOT NULL 
                                      GROUP BY name"); 

  $ena_res_sth->execute("$name_stem" . '%');
  $ena_res = $ena_res_sth->fetchall_arrayref;
  my $ena_update_sth = $dbh->prepare("CALL updateENAid(?,?,?)");
  foreach my $ena(@{ $ena_res }) {
   $ena_update_sth->execute(@{ $ena }, $exp_id);
  }
  my $ena_upd_sth = $dbh->prepare("SELECT * FROM enaView WHERE exp_id = ?");
  $ena_upd_sth->execute($exp_id);
  my $col_names = $ena_upd_sth->{'NAME'};
  $ena_upd = $ena_upd_sth->fetchall_arrayref;
  unshift @{ $ena_upd }, $col_names;
 }
 my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
 $exp_sth->execute;
 $study_exp = $exp_sth->fetchall_arrayref;
 unshift @{ $study_exp }, [ 'NullOption' ];

 template 'update_an_ena_id', {
  
  'study_exp' => $study_exp,
  'ena_upd'   => $ena_upd,
 
  'update_an_ena_id_url'      => uri_for('/update_an_ena_id'),
 };

};

get '/add_a_treatment' => sub {
 
 $dbh = get_schema();
 my ($treatments_info, $std_exp);
 my $chosen_exp_id = param('exp_id');

 if(! $chosen_exp_id) {
  my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
  $exp_sth->execute;
  my $col_names = $exp_sth->{'NAME'};
  $std_exp = $exp_sth->fetchall_arrayref;
  unshift @$std_exp, $col_names;
  foreach (@$std_exp) { @{ $_ }[0,2] = @{ $_ }[2,0]; }
  $chosen_exp_id = param('exp_id');
 }
 else{
  my $treatment_sth = $dbh->prepare("SELECT * FROM treatmentView WHERE experiment_id = ?");
  $treatment_sth->execute($chosen_exp_id);
  my $col_names = $treatment_sth->{'NAME'};
  $treatments_info = $treatment_sth->fetchall_arrayref;
  unshift @{ $treatments_info }, $col_names; 
 }

 template 'add_a_treatment', {

  'std_exp'                 => $std_exp,
  'treatment_types'         => TREATMENT_TYPES,
  'treatments_info'         => $treatments_info,

  'chosen_exp_id'           => $chosen_exp_id,
  'add_a_treatment_url'     => uri_for('/add_a_treatment'),
  'update_a_treatment_url'  => uri_for('/update_a_treatment'),
 };
};

get '/update_a_treatment' => sub {

 $dbh = get_schema();
 my $chosen_exp_id = param('chosen_exp_id'); 
 my $treatment_sth = $dbh->prepare("SELECT * FROM treatmentView WHERE experiment_id = ?");
 $treatment_sth->execute($chosen_exp_id);
 my $col_names = $treatment_sth->{'NAME'};
 my $treatments_info = $treatment_sth->fetchall_arrayref;
 my $add_treatment_sth = $dbh->prepare("CALL addTreatment(?,?,?)");
 foreach my $seqp(@{ $treatments_info }){
  my $seqp_id = 'seqp::' . $seqp->[1];
  if(my $selected = param("$seqp_id")) {
   $add_treatment_sth->execute($seqp->[1], param('chosen_treatment'), param('treatment_desc'));
  }
 }
 $treatment_sth->execute($chosen_exp_id);
 $treatments_info = $treatment_sth->fetchall_arrayref;
 unshift @{ $treatments_info }, $col_names;

 template 'add_a_treatment', {

  'treatments_info'         => $treatments_info,
  'treatment_types'         => TREATMENT_TYPES,
  'chosen_exp_id'           => $chosen_exp_id,

  'add_a_treatment_url'     => uri_for('/add_a_treatment'),
 };

};

get '/update_a_phenotype' => sub {

 $dbh = get_schema();

 my ($std_exp, @pheno_info, %exp_ids, $chosen_exp_id, $pheno_col_names);

 my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
 $exp_sth->execute;
 my $col_names = $exp_sth->{'NAME'};
 $std_exp = $exp_sth->fetchall_arrayref;

 my $phenoct_sth = $dbh->prepare("SELECT * FROM phenoCountView WHERE id = ?");

 foreach my $exp_std(@{ $std_exp }) {
  @{ $exp_std }[0,2] = @{ $exp_std }[2,0];  
  $phenoct_sth->execute($exp_std->[0]);
  $exp_ids{ $exp_std->[0] }++;
  my $pheno_ct_str;
  foreach my $pct(@{ $phenoct_sth->fetchall_arrayref }) {
   $pheno_ct_str .= $pct->[1] . '(' . $pct->[2] . ') ';
  }
  push@{ $exp_std }, $pheno_ct_str;
 }
 unshift @{ $std_exp }, [ @{ $col_names }[2,1,0], 'phenotypes' ];

 my $pheno_sth = $dbh->prepare("SELECT * FROM phenoView WHERE exp_id = ?");
 
 foreach my $exp_id(sort {$b <=> $a} keys %exp_ids) {
  if(param('exp_id') && param('exp_id') ==  $exp_id){
   $pheno_sth->execute($exp_id);    
   $pheno_col_names = $pheno_sth->{'NAME'};
   push @pheno_info, @{ $pheno_sth->fetchall_arrayref };
   splice(@{ $pheno_col_names },1,1, 'Select');
   unshift @pheno_info, $pheno_col_names;
   $chosen_exp_id = $exp_id;
  }
 }
 
 template 'update_a_phenotype', {
  
  std_exp           => $std_exp,
  pheno_info        => \@pheno_info,
  pheno_types       => PHENOTYPES,
  chosen_exp_id     => $chosen_exp_id,
 
  'add_phenotypes_to_db_url' => uri_for('/add_phenotypes_to_db'),
 };

};

get '/add_phenotypes_to_db' => sub {

 my $pheno_sth = $dbh->prepare("SELECT * FROM phenoView WHERE exp_id = ?");
 my $chosen_exp_id = param('chosen_exp_id');
 $pheno_sth->execute($chosen_exp_id);
 my $pheno_col_names = $pheno_sth->{'NAME'};
 
 my (@rows2update, @pheno_info);
 foreach my $selected(@{ $pheno_sth->fetchall_arrayref }) {
  my $pheno_id = "pheno::" . $selected->[1];
  if(param("$pheno_id")) {
   push @rows2update, $selected->[1];
  }
 }
 
 my $chosen_pheno = param('chosen_pheno'); 

 foreach my $row2update(@rows2update) {
  my $update_pheno_sth = $dbh->prepare("CALL update_pheno(?,?)");
  $update_pheno_sth->execute($row2update, $chosen_pheno);
 }
 
 $pheno_sth->execute($chosen_exp_id);
 push @pheno_info, @{ $pheno_sth->fetchall_arrayref };
 splice(@{ $pheno_col_names },1,1, 'Select');
 unshift @pheno_info, $pheno_col_names;

 template 'update_a_phenotype', {
  
  std_exp           => undef,
  pheno_info        => \@pheno_info,
  pheno_types       => PHENOTYPES,
  chosen_exp_id     => $chosen_exp_id, 
  
  'add_phenotypes_to_db_url' => uri_for('/add_phenotypes_to_db'),
 };

};

post '/modify_a_kc_plate' => sub {
 
 my @a2h = 'A'..'H';
 unshift @a2h, 0;
 my @one2twelve = 0..MAX_WELL_COL;
 my $mod_content;
 
 if ( my $kc_file = upload('kc_file') ) {
  my $kcf_content = $kc_file->content;
  
  my @wells2keep;
  my $from_well = param('from_well');
  my ($fwa,$fwn) = $from_well=~/([[:alpha:]]):([[:digit:]]+)/xms;
  my $to_well = param('to_well');
  my ($twa,$twn) = $to_well=~/([[:alpha:]]):([[:digit:]]+)/xms;
  my @alpha=$fwa..$twa;
 
  for(my$i=0;$i<@alpha;$i++){
   my $j = $i == 0 ? $fwn : 1;
   my $k = $i == $#alpha ? $twn : MAX_WELL_COL;
   for(;$j<=$k;$j++){
    my $jpad = $j < 10 ? '0'.$j : $j; 
    my $well = $alpha[$i] . $jpad;
    my ($cwell) = $kcf_content=~/(^$well[^\n]+)/xms;
    $cwell=~s/\s+//xmsg;
    push @wells2keep, $cwell;
   }
  }
  
  my %kc_ind;
  my $acc = 0;
  my@kc_num=('01','02','03','04','05','06','07','08','09','10','11','12');
  for(my$i=1;$i<@a2h;$i++) {
   for(my$j=0;$j<@kc_num;$j++) {
    $kc_ind{ $acc } = $a2h[$i] . $kc_num[$j];
    $acc++;
   }
  }

  for(my$i=0;$i<@wells2keep;$i++) {
   my $subs = $kc_ind{ $i };
   $wells2keep[$i]=~s/^\w+/$subs/;
  }

  ($mod_content) = $kcf_content=~/(.*\[wells\])/xms;
  $mod_content .= "\n" . join "\n", @wells2keep;
 } 

 template 'modify_a_kc_plate', {
  
  'a2h'         => \@a2h,
  'one2twelve'  => \@one2twelve,
  'mod_content' => $mod_content,

 };

};

post '/add_sequencing_plate_data' => sub {

## adds library conc values and comments to alleles + genotypes
  $dbh = get_schema();
  my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
  $exp_sth->execute;
  my $study_exp = $exp_sth->fetchall_arrayref;
  unshift @{ $study_exp }, [ 'NullOption' ];

  my $exp_id = param('exp_to_update');
  my $lib_con_file = param('library_conc_file');
  my $template = 'add_sequencing_plate_data';
  my $lib_samples;
  if($exp_id && $exp_id=~/\d+/ && ! $lib_con_file) {
   $expAlleGeno = undef;
   my $ag_sth = $dbh->prepare("SELECT * FROM expAlleGeno");
   $ag_sth->execute;
   foreach my $row(@{ $ag_sth->fetchall_arrayref }) {
    my($exp,$allele,$genot,$genot_id) = split'::',$row->[0];
    if($exp == $exp_id) {
     push@{ $expAlleGeno }, [$exp, $allele, $genot];
    }
   }
  }
  elsif($lib_con_file) {
   if ( my $lib_conc_file = upload('library_conc_file') ) {
    my $rec_library_amount = param('rec_library_amount');
    my $lib_resusp_vol =param('resusp_library_vol');
    my $copy_dir = make_file_path( "$exel_file_dir", 'library_dir' );
    my $library_file_name = $lib_conc_file->tempname;
    $library_file_name =~ s/.*\///xms;
    $lib_conc_file->copy_to("$copy_dir");
    my $xlf = "$copy_dir/$library_file_name";

    ## read in the file for the library concentrations
    my $workbook = ReadData( "$xlf", strip => 3 );
    my %lib_plate;
    foreach my $row ( 1 .. MAX_WELL_ROW ) {
        foreach my $col ( "A" .. "L" ) {
            my $index = $col . $row;
            if ( defined( $workbook->[1]{$index} ) ) {
                my $lib_amount = $workbook->[1]{$index};
                my $sw_index =
                  switch_cols_rows($index);    ## need to switch rows and cols
                $lib_plate{$sw_index}{'lib_amt'} = $lib_amount;
                if($lib_amount != 0) {
                 my $lib_vol = sprintf "%.2f", $rec_library_amount / $lib_amount;
                 $lib_plate{$sw_index}{'lib_vol'} = $lib_vol;
                 if($lib_vol >= $lib_resusp_vol) { ## not enough library 
                   $lib_plate{$sw_index}{'lib_qc_fail'} = 1;
                 }
                 else {
                  $lib_plate{$sw_index}{'lib_qc_fail'} = 0;
                 }
                }
                else { ## little or no library 
                 $lib_plate{$sw_index}{'lib_amt'} = 0;
                 $lib_plate{$sw_index}{'lib_vol'} = undef;
                 $lib_plate{$sw_index}{'lib_qc_fail'} = 1;
                }
            }
        }
    }
    my $addLibFile_sth = $dbh->prepare("CALL addLibFile(?,?)");
    $addLibFile_sth->execute($exp_id, $xlf);
    my $addLibAmts_sth = $dbh->prepare("CALL addLibAmts(?,?,?,?,?)");
    foreach my $well_id(keys %lib_plate){
     my $lib_qc = $lib_plate{$well_id}{'lib_qc_fail'};
     $lib_qc = $lib_qc ? 0 : 1;
     $addLibAmts_sth->execute($exp_id, $well_id, 
                 $lib_plate{$well_id}{'lib_amt'},
                 $lib_plate{$well_id}{'lib_vol'},
                 $lib_qc);
    }
   }
   # reset all the allele-genotype comments to null 
   my $reset_comment_sth = $dbh->prepare("CALL resetGenotComments(?)");
   $reset_comment_sth->execute($exp_id);
   my $add_comment_sth = $dbh->prepare("CALL addGenotComments(?,?,?,?)");
   foreach my $allele_geno ( @{ $expAlleGeno } ) {
    my $ag_name = join'::',@{ $allele_geno };
    if(my $comment = param($ag_name)) {
     $add_comment_sth->execute(@{ $allele_geno }, $comment);
    }
   }
   my $lib_samples_sth = $dbh->prepare("SELECT * FROM libSamplesView WHERE exp_id = ?");
   $lib_samples_sth->execute($exp_id);
   my $col_names  = $lib_samples_sth->{'NAME'};   
   $lib_samples = $lib_samples_sth->fetchall_arrayref();
   unshift @{$lib_samples}, $col_names;
   
   if(@{ $lib_samples }){ 
    $template = 'check_library_wells';
   } 
  }
  
  template "$template", {
   
   'study_exp' => $study_exp,
   'exp_id'    => $exp_id,
   'alle_geno' => $expAlleGeno,
   'lib_samples' => $lib_samples,
   
   'add_sequencing_plate_data_url' => uri_for('/add_sequencing_plate_data'),
   'update_sequence_plate_url'     => uri_for('/update_sequence_plate'),
  };

};

get '/update_sequence_plate' => sub {

  my $dbh = get_schema();
  my $exp_id = param('exp_id');
  my $seqp_view_sth = $dbh->prepare("SELECT * FROM libSampleIdView WHERE exp_id = ?"); 
  $seqp_view_sth->execute($exp_id);
  ## reset all wells to selected (set to 1)
  my $reset_seqp_sth = $dbh->prepare("CALL resetSeqPlateSel(?)");
  $reset_seqp_sth->execute($exp_id);
  ## de-select chosen wells (set to 0)
  my $upd_seqp_sth = $dbh->prepare("CALL updateSeqPlateSel(?)");
  
  foreach my $seqp(@{ $seqp_view_sth->fetchall_arrayref }) {
   my $name = 'SEQID:' . $seqp->[1];
   if(param($name)) {
    $upd_seqp_sth->execute( $seqp->[1] );
   }
  }
  my $lib_samples_sth = $dbh->prepare("SELECT * FROM libSamplesView WHERE exp_id = ?");
  $lib_samples_sth->execute($exp_id);
  my $col_names  = $lib_samples_sth->{'NAME'};   
  my $lib_samples = $lib_samples_sth->fetchall_arrayref();
  unshift @{$lib_samples}, $col_names;
 
  template 'check_library_wells', {

   'exp_id'    => $exp_id,
   'lib_samples' => $lib_samples,
  };

};


get '/make_sequencing_form' => sub {

    $dbh = get_schema();

    my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
    $seq_plates_sth->execute;
    my $all_seq_plates = $seq_plates_sth->fetchall_arrayref;

    template 'make_sequencing_form', {
        'all_seq_plates' => $all_seq_plates,

        'get_sequencing_report_url' => uri_for('/get_sequencing_report'),
    };

};

get '/delete_experiment' => sub {

    $dbh = get_schema();
    if(my $exp_id = param('exp_to_delete')) {
      roll_back({ $exp_id => undef });
    }

    my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
    $exp_sth->execute;
    my $study_exp = $exp_sth->fetchall_arrayref;
    unshift @{ $study_exp }, [ 'NullOption' ];

    template 'delete_experiment', {
 
    'study_exp' => $study_exp,
    
    'delete_experiment_url'     => uri_for('/delete_experiment'),
    };

};

post '/update_image' => sub {

    $dbh = get_schema();

    if ( my $new_image = upload('new_image_loc') ) {
        $new_image->copy_to("$image_dir");
        my $image = $new_image->tempname;
        $image =~ s/.*\///xms;
        if ( my $exp_id = param('exp_id') ) {
            my $update_exp_sth = $dbh->prepare("CALL update_image(?,?)");
            $update_exp_sth->execute( $exp_id, $image );
        }
    }

    my $std_exp_sth = $dbh->prepare("SELECT * FROM ImageView");
    $std_exp_sth->execute;
    my $image_info = $std_exp_sth->fetchall_arrayref;

    template 'update_image', {
        'image_info' => $image_info,

        'update_image_url' => uri_for('/update_image'),
    };

};

get '/add_a_new_study' => sub {

    $dbh = get_schema();
    my $std_id;
    if ( my $new_study_name = param('new_study') ) {
        $new_study_name = trim($new_study_name);
        my $new_std_sth = $dbh->prepare("CALL add_new_study(?, \@std_id)");
        $new_std_sth->execute($new_study_name);
        ($std_id) = $dbh->selectrow_array("SELECT \@std_id");
    }

    my $std_sth = $dbh->prepare("SELECT * FROM stdView");
    $std_sth->execute;
    my $col_names   = $std_sth->{'NAME'};
    my $all_studies = $std_sth->fetchall_arrayref();
    unshift @{$all_studies}, $col_names;

    template 'new_study', {
        'studies'    => $all_studies,
        'new_std_id' => $std_id,

        'add_a_new_study_url' => uri_for('/add_a_new_study'),
    };

};

get '/add_a_new_devstage' => sub {

    $dbh = get_schema();
    my $dev_id;
    my ( $period, $stage, $begins, $landmarks, $zfs_id ) = (
        param('period'), param('stage'),
        param('begins'), param('landmarks'),
        param('zfs_id')
    );

    if ( $period and $stage and $begins and $landmarks and $zfs_id ) {
        $period    = trim($period);
        $stage     = trim($stage);
        $begins    = trim($begins);
        $landmarks = trim($landmarks);
        $zfs_id    = trim($zfs_id);
        my $new_devstage_sth =
          $dbh->prepare("CALL add_new_devstage(?,?,?,?,?, \@dev_id)");
        $new_devstage_sth->execute( $period, $stage, $begins, $landmarks,
            $zfs_id );
        ($dev_id) = $dbh->selectrow_array("SELECT \@dev_id");
    }

    my $dev_sth = $dbh->prepare("SELECT * FROM devView");
    $dev_sth->execute;
    my $col_names      = $dev_sth->{'NAME'};
    my $all_dev_stages = $dev_sth->fetchall_arrayref();
    unshift @{$all_dev_stages}, $col_names;

    template 'new_dev_stage', {
        'dev_stages' => $all_dev_stages,
        'new_dev_id' => $dev_id,

        'add_a_new_dev_stage_url' => uri_for('/add_a_new_devstage'),
    };

};

get '/add_a_new_devstage' => sub {

    $dbh = get_schema();
    my $dev_id;
    my ( $period, $stage, $begins, $landmarks, $zfs_id ) = (
        param('period'), param('stage'),
        param('begins'), param('landmarks'),
        param('zfs_id')
    );

    if ( $period and $stage and $begins and $landmarks and $zfs_id ) {
        $period    = trim($period);
        $stage     = trim($stage);
        $begins    = trim($begins);
        $landmarks = trim($landmarks);
        $zfs_id    = trim($zfs_id);
        my $new_devstage_sth =
          $dbh->prepare("CALL add_new_devstage(?,?,?,?,?, \@dev_id)");
        $new_devstage_sth->execute( $period, $stage, $begins, $landmarks,
            $zfs_id );
        ($dev_id) = $dbh->selectrow_array("SELECT \@dev_id");
    }

    my $dev_sth = $dbh->prepare("SELECT * FROM devView");
    $dev_sth->execute;
    my $col_names      = $dev_sth->{'NAME'};
    my $all_dev_stages = $dev_sth->fetchall_arrayref();
    unshift @{$all_dev_stages}, $col_names;

    template 'new_dev_stage', {
        'dev_stages' => $all_dev_stages,
        'new_dev_id' => $dev_id,

        'add_a_new_dev_stage_url' => uri_for('/add_a_new_devstage'),
    };

};

get '/add_a_new_allele' => sub {

    $dbh = get_schema();
    my $last_allele_id;
    my ( $allele_name, $gene_name, $snp_id ) =
      ( param('allele_name'), param('gene_name'), param('snp_id') );

    if ( $allele_name ) {
        $allele_name = trim($allele_name);
        if( $gene_name ) {
          $gene_name = trim($gene_name);
        }
        if( $snp_id ) {
          $snp_id = trim($snp_id) if($snp_id);
        }
        my $new_allele_sth =
          $dbh->prepare("CALL add_a_new_allele(?,?,?, \@allele_id)");
        $new_allele_sth->execute( $allele_name, $gene_name, $snp_id );
       ($last_allele_id) = $dbh->selectrow_array("SELECT \@allele_id");
    }

    my $allele_sth = $dbh->prepare("SELECT * FROM alleleView LIMIT 10");
    $allele_sth->execute;
    my $col_names  = $allele_sth->{'NAME'};
    my $alleles = $allele_sth->fetchall_arrayref();
    unshift @{$alleles}, $col_names;

    template 'new_allele', {
        'alleles'         => $alleles,
        'last_allele_id'  => $last_allele_id,

        'add_a_new_allele_url' => uri_for('/add_a_new_allele'),
    };

};

get '/get_all_experiments' => sub {

    $dbh = get_schema();
    my $exp_disp_sth = $dbh->prepare('SELECT * FROM ExpDisplayView');
    $exp_disp_sth->execute;
    my $col_names       = $exp_disp_sth->{'NAME'};
    my $all_experiments = $exp_disp_sth->fetchall_arrayref();
    unshift @{$all_experiments}, $col_names;

    my $gen_sth = $dbh->prepare("SELECT * FROM SpView");
    $gen_sth->execute;

    my %allele_info;
    my $gene_sth = $dbh->prepare("SELECT * FROM alleleGeneView");
    $gene_sth->execute;
    foreach my $alle_gen ( @{ $gene_sth->fetchall_arrayref } ) {
        push @{ $allele_info{ $alle_gen->[0] } }, $alle_gen->[1];
    }

    my $spikes_sth = $dbh->prepare("SELECT * FROM spikeView");
    $spikes_sth->execute;

    my $dev_sth = $dbh->prepare("SELECT * FROM DevInfoView");
    $dev_sth->execute;

    template 'all_experiments', {
        'all_experiments' => $all_experiments,
        'species_info'    => $gen_sth->fetchall_hashref('Genome_ref_name'),
        'spike_info'      => $spikes_sth->fetchall_hashref('exp_id'),
        'dev_info'        => $dev_sth->fetchall_hashref('exp_id'),
        'allele_info'     => \%allele_info,

        'get_sequenced_samples_url' => uri_for('/get_sequenced_samples'),
    };

};

get '/get_sequenced_samples' => sub {

    $dbh = get_schema();
    my $exp_info = get_study_and_exp_names( param('exp_id') );

    my $sequenced_samples_sth =
      $dbh->prepare("SELECT * FROM seqSampleView WHERE Experiment_id = ?");
    $sequenced_samples_sth->execute( param('exp_id') );
    my $col_names         = $sequenced_samples_sth->{'NAME'};
    my $sequenced_samples = $sequenced_samples_sth->fetchall_arrayref();
    unshift @{$sequenced_samples}, $col_names;

    template 'display_sequenced_samples', {

        'sequenced_samples' => $sequenced_samples,
        'exp_info'          => $exp_info,
    };

};

get '/get_all_sequencing_plates' => sub {

    $dbh = get_schema();
    my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
    $seq_plates_sth->execute;
    my $all_seq_plates = $seq_plates_sth->fetchall_arrayref;

    template 'all_sequencing_plates', {
        'all_seq_plates' => $all_seq_plates,

        'display_well_order_url'  => uri_for('/display_well_order'),
        'display_genot_order_url' => uri_for('/display_genot_order'),
        'display_tag_order_url'   => uri_for('/display_tag_order'),
    };

};

get '/display_well_order' => sub {

    my $color_plate = color_plate('well_names');

    template 'display_sequence_plate', {

        display_plate_name => param('display_plate_name'),
        sequence_plate     => $color_plate->[0],
        legend             => $color_plate->[1],
        plate_name         => param('plate_name'),
        well_legend        => [ 'well_id', 'RNA', 'H2O', 'spike' ],
        current_view       => 'well_names',

        'flip_url'                => uri_for('/flip'),
        'display_genot_order_url' => uri_for('/display_genot_order'),
        'display_tag_order_url'   => uri_for('/display_tag_order'),
        'display_well_order_url'  => uri_for('/display_well_order'),
    };

};

get '/display_tag_order' => sub {

    my $color_plate = color_plate('index_tags');

    template 'display_sequence_plate', {

        display_plate_name => param('display_plate_name'),
        sequence_plate     => $color_plate->[0],
        legend             => $color_plate->[1],
        plate_name         => param('plate_name'),

        'display_genot_order_url' => uri_for('/display_genot_order'),
        'display_tag_order_url'   => uri_for('/display_tag_order'),
        'display_well_order_url'  => uri_for('/display_well_order'),
    };

};

get '/display_genot_order' => sub {

    my $color_plate = color_plate('genotypes');

    template 'display_sequence_plate', {

        display_plate_name => param('display_plate_name'),
        sequence_plate     => $color_plate->[0],
        legend             => $color_plate->[1],
        geno_legend        => $color_plate->[2],
        plate_name         => param('plate_name'),

        'display_well_order_url'  => uri_for('/display_well_order'),
        'display_tag_order_url'   => uri_for('/display_tag_order'),
        'display_genot_order_url' => uri_for('/display_genot_order'),
    };

};

get '/flip' => sub {

    my $color_plate = color_plate( param('current_view') );
    my ( @trans, @splice );

    for ( my $i = 0 ; $i < @{ $color_plate->[0] } ; $i++ ) {
        if ( $color_plate->[0]->[$i] ne '##' ) {
            push @splice, $color_plate->[0]->[$i];
        }
    }

    my $n           = 0;
    my $cols2rows   = MAX_WELL_COL + 1;           # 13
    my $rows2cols   = MAX_WELL_ROW + 1;           # 9
    my $total_cells = $cols2rows * $rows2cols;    # 117
    my $end_row     = $rows2cols + 1;             # 10
    for ( my $i = 0 ; $i < $cols2rows ; $i++ ) {
        for ( my $j = MAX_WELL_COL ; $j < $total_cells ; $j += $cols2rows ) {
            if ( !( $n % $end_row ) ) {
                push @trans, '##';
                $n++;
            }
            push @trans, $splice[ ( $j - $i ) ];
            $n++;
        }
    }

    template 'flip', { flip_plate => \@trans, };

};

post '/get_sequencing_report' => sub {

    $dbh = get_schema();

    if ( my $seq_plate_name = param('new_seq_plate_name') ) {
        if ( my $sanger_sample_file = upload('sanger_sample_file') ) {
            my $copy_dir = make_file_path( "$exel_file_dir", 'sanger_dir' );
            $sanger_sample_file->copy_to("$copy_dir");
            my $sample_file_name = $sanger_sample_file->tempname;
            $sample_file_name =~ s/.*\///xms;
            my $xlf = "$copy_dir/$sample_file_name";

            my $workbook_r = ReadData( "$xlf", strip => 3 );
            my @mismatched_fields;
            foreach my $col_hash (SANGER_COLS) {

                foreach my $sanger_field ( sort keys %{$col_hash} ) {
                    my $cell_id = SANGER_COLS->{"$sanger_field"} . HEADER_ROW;
                    my $file_field_header = $workbook_r->[1]{$cell_id};
                    $file_field_header =~ s/ +/ /gms;
                    if ( "$file_field_header" ne "$sanger_field" ) {
                        push @mismatched_fields,
                          [ "$file_field_header", "$sanger_field", "$cell_id" ];
                    }
                }
            }
            if (@mismatched_fields) {
                my $err_vals;
                foreach my $mismatch (@mismatched_fields) {
                    $err_vals .= join( q{ : }, @{$mismatch} ) . "<br>";
                }
                croak
"The following fields do not match between the file and the values in SANGER_COLS:<br>$err_vals";
            }
            else {
                my @sanger_samples;
                my $row_value        = HEADER_ROW + 1;
                my $sanger_plate_id  = SANGER_COLS->{'SANGER TUBE ID'};
                my $sanger_sample_id = SANGER_COLS->{'SANGER SAMPLE ID'};
                my ( $s_tube_cell, $s_sample_cell ) = (
                    $sanger_plate_id . $row_value,
                    $sanger_sample_id . $row_value
                );
                while ($workbook_r->[1]{$s_tube_cell}
                    && $workbook_r->[1]{$s_sample_cell} )
                {
                    push @sanger_samples,
                      [
                        $workbook_r->[1]{$s_tube_cell},
                        $workbook_r->[1]{$s_sample_cell}
                      ];
                    $row_value++;
                    ( $s_tube_cell, $s_sample_cell ) = (
                        $sanger_plate_id . $row_value,
                        $sanger_sample_id . $row_value
                    );
                }
                my @data;
                my $seq_plate_sth = $dbh->prepare(
                    "SELECT * FROM SeqReportView WHERE seq_plate_name = ?");
                $seq_plate_sth->execute("$seq_plate_name");
                my $sequence_plate =
                  $seq_plate_sth->fetchall_hashref('index_tag_id');
                if ( scalar keys %{$sequence_plate} != @sanger_samples ) {
                    croak 'The number of samples ('
                      . scalar( keys %{$sequence_plate} )
                      . ') in the database is not equal to the number of rows in the excel file ('
                      . scalar(@sanger_samples) . ')';
                }
                my $row_index = 0;
                foreach my $index_tag_id (
                    sort { $a <=> $b }
                    keys %{$sequence_plate}
                  )
                {
                    my ( $sanger_plate_id, $sanger_sample_id ) =
                      map { $_->[0], $_->[1] } shift @sanger_samples;
                    if ( $sanger_plate_id && $sanger_sample_id ) {
                        foreach my $col (@EXCEL_FIELDS) {
                            if ( $col->[0] eq 'SANGER TUBE ID' ) {
                                push @{ $data[$row_index] }, $sanger_plate_id;
                            }
                            elsif ( $col->[0] eq 'SANGER SAMPLE ID' ) {
                                push @{ $data[$row_index] }, $sanger_sample_id;
                            }
                            elsif ( $col->[1] && $col->[1] eq 'DONOR_ID' ) {
                                push @{ $data[$row_index] }, $sanger_sample_id;
                                $row_index++;
                            }
                            elsif ( $col->[0] eq 'COMMON NAME' ) {
                                my $species_name =
                                  $sequence_plate->{"$index_tag_id"}
                                  ->{ $col->[1] };
                                $species_name =~ s/_/ /gms;
                                push @{ $data[$row_index] }, $species_name;
                            }
                            elsif ( $col->[0] eq 'SAMPLE DESCRIPTION' ) {
                                my %alle_geno;
                                foreach my $alle_genotype ( split ',',
                                    $sequence_plate->{"$index_tag_id"}
                                    ->{'AlleleGenotype'} )
                                {
                                    my ( $allele, $gene, $genotype, $samp_comment ) =
                                      split '::', $alle_genotype;
                                    $alle_geno{$genotype}
                                      {"$gene allele $allele"} = $samp_comment;
                                }
                                my $description =
"3' end enriched mRNA from a single genotyped embryo ";
                                foreach my $geno ( sort keys %alle_geno ) {
                                    $description .=
                                      GENOTYPES_C->{$geno} . " for ";
                                    foreach my $gene_allele (
                                        sort keys %{ $alle_geno{$geno} } )
                                    {
                                        $description .= $gene_allele;
                                        if($alle_geno{$geno}->{$gene_allele}=~/[[:alpha:]]+/xms) {
                                          $description .=  ' (' . $alle_geno{$geno}->{$gene_allele} . '), ';
                                        }
                                        else {
                                         $description .=  ', ';
                                        }
                                    }
                                }
                                my $index_tag_seq =
                                  $sequence_plate->{"$index_tag_id"}
                                  ->{'desc_tag_index_sequence'};
                                $index_tag_seq =~ s/CG$//xms
                                  ; ## remove the final 2 bases - these are always "CG"
                                my $zmp_exp_name =
                                  $sequence_plate->{"$index_tag_id"}
                                  ->{'zmp_name'};
                                my $free_text =
                                  $sequence_plate->{"$index_tag_id"}
                                  ->{'experiment_description'};
                                if ($free_text) {
                                    $free_text = trim($free_text);
                                    $free_text =~ s/\s+\.$//xms;
                                    $free_text .= q{. };
                                }
                                else {
                                    $free_text = q{ };
                                }
                                $description .=
                                  "clutch 1 with "
                                  . SPIKE_IDS
                                  ->{ $sequence_plate->{"$index_tag_id"}
                                      ->{'desc_spike_mix'} }
                                  . ". A 8 base indexing sequence ($index_tag_seq) is bases 13 to 20 of read 1 followed by CG and polyT. "
                                  . $free_text
                                  . 'More information describing the phenotype can be found at the '
                                  . 'Wellcome Trust Sanger Institute Zebrafish Mutation Project website '
                                  . "http://www.sanger.ac.uk/sanger/Zebrafish_Zmpsearch/$zmp_exp_name";
                                push @{ $data[$row_index] }, $description;
                            }
                            elsif ( looks_like_number( $col->[1] ) ) {
                                push @{ $data[$row_index] }, HC->{ $col->[1] };
                            }
                            else {
                                push @{ $data[$row_index] },
                                  $sequence_plate->{"$index_tag_id"}
                                  ->{ $col->[1] };
                            }
                        }
                        my $sanger_info_sth = $dbh->prepare(
                            "Call update_sanger_plate_and_sample(?,?,?)");
                        my $seq_id =
                          $sequence_plate->{"$index_tag_id"}->{'seq_plate_id'};
                        $sanger_info_sth->execute( $sanger_plate_id,
                            $sanger_sample_id, $seq_id );
                    }
                }
                my ( $date, $file_loc ) =
                  overwrite_file( "$xlf", \@data, $seq_plate_name );

                if ( $date && $file_loc ) {
                    my $seq_time_sth = $dbh->prepare(
                        "Call update_excel_file_location_and_date(?,?,?)");
                    my ($excel_file_loc) = $file_loc =~ /\.\/public\/(.*)/xms;
                    $seq_time_sth->execute( $excel_file_loc, $date,
                        $seq_plate_name );
                }
            }
        }
    }
    my $seq_plates_sth = $dbh->prepare('SELECT * FROM SeqPlateView');
    $seq_plates_sth->execute;
    my $all_seq_plates = $seq_plates_sth->fetchall_arrayref;

    template 'make_sequencing_form', {
        'all_seq_plates' => $all_seq_plates,

        'make_sequencing_form_url' => uri_for('/make_sequencing_form'),
    };

};

get '/get_sequencing_info' => sub {

    $dbh = get_schema();
    my ( %seq, %unseq );
    my $exp_seq_sth = $dbh->prepare("SELECT * FROM SeqExpView");
    $exp_seq_sth->execute;
    foreach my $exp_seq ( @{ $exp_seq_sth->fetchall_arrayref } ) {
        my ( $exp_id, $exp_name, $std_name, $alleles, $seq_plate, $count ) =
          @{$exp_seq};
        if ($seq_plate) {
            push( @{ $seq{$exp_id} }, $exp_name, $std_name, $alleles, $count );
        }
        else {
            push( @{ $unseq{$exp_id} }, $exp_name, $std_name, $alleles,
                $count );
        }
    }

    my $tag_set_sth = $dbh->prepare("SELECT * FROM tagSetView");
    $tag_set_sth->execute;
    my $tag_set_names = $tag_set_sth->fetchall_arrayref;
    $seq_plate_name = undef;    ## re-set global

    template 'make_seq_plate', {
        unseq         => \%unseq,
        seq           => \%seq,
        tag_set_names => $tag_set_names,

        'combine_plate_data_url' => uri_for('/combine_plate_data'),
    };

};

post '/combine_plate_data' => sub {

    $dbh = get_schema();
    my ( %combined_plate, %exp_ids, %cell_color, %exp_color, %cell_mapping,
        %index_tag_set );
    my $dec     = 45280;
    my $exp_sth = $dbh->prepare("SELECT * FROM ExpStdNameView");
    $exp_sth->execute;
    my $all_exps       = $exp_sth->fetchall_hashref('exp_id');
    my $tag_set_prefix = param('tag_set_name');
    my $tag_seqs_sth =
      $dbh->prepare("SELECT * FROM tagSeqView WHERE name_prefix = ?");
    $tag_seqs_sth->execute("$tag_set_prefix");
    my $index_hash =
      make_grid()->[1];    ## for merging the experiment(s) onto a single plate
    my $tag_seqs = $tag_seqs_sth->fetchall_arrayref;
    
    ## $tag_offset_num is the tag_seq_id from which to start (default = 1)
    my $tag_offset_num = param('tag_offset');
    splice @{$tag_seqs}, 0, ($tag_offset_num - 1);

    ## try and get the spacing between experiments correct
    my $wells_per_exp_sth = $dbh->prepare("SELECT * FROM SelectedExpNumView");
    $wells_per_exp_sth->execute;
    my %plate_samples = %{ $wells_per_exp_sth->fetchall_hashref('exp_id') };
    my ( @numbers, $sum, %filler );
    foreach my $exp_id ( sort { $b <=> $a } keys %plate_samples ) {
        if ( !param("$exp_id") ) {
            delete( $plate_samples{$exp_id} );
        }
        else {
            my $well_no = $plate_samples{$exp_id}{'numb'};
            $sum += $well_no;
            my $filler_size = MAX_WELL_COL - ( $well_no % MAX_WELL_COL );
            $filler_size = $filler_size == MAX_WELL_COL ? 0 : $filler_size;
            push @numbers, [ $exp_id, $filler_size, 0 ];
        }
    }
    my $free_wells = PLATE_SIZE - $sum;
    pop @numbers;
    my $all_not_done = 1;
    while ( $free_wells && $all_not_done ) {
        $all_not_done = 0;
        foreach my $exp (@numbers) {
            if ( $free_wells && $exp->[1] != $exp->[2] ) {
                $exp->[2]++;
                $free_wells--;
                $all_not_done = 1;
            }
        }
    }
    foreach my $exp_id (@numbers) {
        $filler{ $exp_id->[0] } = $exp_id->[2];
    }

    my $display_plate_name;
    my $ct =
      0;  ## array index corresponds to the index positions in $index_hash below
    foreach my $exp_id ( sort { $b <=> $a } keys %{$all_exps} )
    {     ## most recent exp at top of plate
        if ( my $exp_name = param("$exp_id") ) {
            if ( $exp_name eq $all_exps->{"$exp_id"}->{'exp_name'} )
            {    ## this should always be true
                $display_plate_name .= $exp_name . q{::};
                my $rdp_sth = $dbh->prepare(
                    "SELECT * FROM RnaDilPlateView WHERE experiment_id = ?");
                $rdp_sth->execute("$exp_id");
                my $hex = sprintf "0x%x", $dec;
                $hex =~ s/0x/#/;
                $exp_color{$hex}{'exp_name'} =
                  $exp_name;    ## legend colors for exps
                foreach my $sample ( @{ $rdp_sth->fetchall_arrayref } ) {

                    # get the volume of RNA required
                    my $min_rna_amount   = $sample->[5];
                    my $rna_volume       = $sample->[6];
                    my $rna_amount       = $sample->[7];
                    my $final_sample_vol = $sample->[8];
                    my $spike_vol        = $sample->[9];
                    my $total_rna        = $rna_volume * $rna_amount;
                    my $required_rna_vol =
                      int( ( ( $min_rna_amount / $total_rna ) * $rna_volume ) +
                          0.5 );    # round off to nearest int
                    my $water_vol = sprintf "%.2f",
                      $final_sample_vol - $required_rna_vol - $spike_vol;
                    my $required_rna_amount = sprintf "%.2f",
                      $rna_amount * $required_rna_vol;

                    $exp_color{$hex}{'std_name'} = $sample->[4];
                    $exp_ids{ $sample->[2] }++;    ## experiment_ids
                 
                    my $tag_seq;
                    if( ! @{ $tag_seqs } ) { ## we have run out of tag seqs - delete exps from db and throw error
        	     roll_back(\%exp_ids);
                     die("tag off_set position ( $tag_offset_num ) is too large.\n" . 
                     " ** All associated experiments have been deleted from the database **\n$?");
                    }
                    else {
                     $tag_seq = shift @{$tag_seqs};
                    }

                    $index_tag_set{ $tag_seq->[0] } = $tag_seq->[1];
                    $combined_plate{ $sample->[0] }{'rec_rna_vol'} =
                      $required_rna_vol;
                    $combined_plate{ $sample->[0] }{'water_vol'} = $water_vol;
                    $combined_plate{ $sample->[0] }{'rec_rna_amt'} =
                      $required_rna_amount;
                    $combined_plate{ $sample->[0] }{'rna_plate_well_name'} =
                      $sample->[1];
                    $combined_plate{ $sample->[0] }{'exp_name'} = $sample->[3];
                    $combined_plate{ $sample->[0] }{'std_name'} = $sample->[4];
                    $combined_plate{ $sample->[0] }{'index_tag_id'} =
                      $tag_seq->[0];
                    $combined_plate{ $sample->[0] }{'seq_plate_well_name'} =
                      $index_hash->{$ct};
                    $combined_plate{ $sample->[0] }{'color'} = $hex;
                    $cell_color{ $index_hash->{$ct} } = $hex;    ## cell colors
                    $cell_mapping{ $index_hash->{$ct} } = $sample->[1]
                      ;    ## mapping betweem rna plate(s) and seq plate
                    $ct++;
                }
                if ( $filler{$exp_id} ) {
                    $ct += $filler{$exp_id};
                    splice @{$tag_seqs}, 0, $filler{$exp_id}
                      ; ## remove the corresponding number of tag sequences as well
                }
                $dec += INCR;

            }
        }
    }
    $seq_plate_name = join "_", keys %exp_ids;
    my $spd_sth =
      $dbh->prepare("CALL add_sequence_plate_data(?,?,?,?,?,?,?,?,?,?)");
    my $seq_array = make_grid()->[0];

    foreach my $rna_plate_id ( sort { $a <=> $b } keys %combined_plate ) {
        my $seq_plate_well_name =
          $combined_plate{$rna_plate_id}{'seq_plate_well_name'};
        my $rna_plate_well_name =
          $combined_plate{$rna_plate_id}{'rna_plate_well_name'};
        my $index_tag_id = $combined_plate{$rna_plate_id}{'index_tag_id'};
        my $sample_volume = $combined_plate{$rna_plate_id}{'rec_rna_vol'};
        my $water_volume  = $combined_plate{$rna_plate_id}{'water_vol'};
        my $sample_amount = $combined_plate{$rna_plate_id}{'rec_rna_amt'};
        my $sample_name = join "_", $combined_plate{$rna_plate_id}{'exp_name'},
          $rna_plate_well_name;
        my ($tag_num) = $index_tag_set{$index_tag_id} =~ m/\.([[:digit:]]+)/xms;
        my $sample_public_name = join "_", $combined_plate{$rna_plate_id}{'exp_name'}, $seq_plate_well_name;
        my $hex_color = $combined_plate{$rna_plate_id}{'color'};
        $spd_sth->execute(
            $seq_plate_name,     $seq_plate_well_name, $sample_name,
            $sample_public_name, $rna_plate_id,        $index_tag_id,
            $hex_color,          $sample_volume,       $water_volume,
            $sample_amount
        );
    }
    foreach my $cell ( @{$seq_array} ) {
        if ( exists( $cell_color{$cell} ) ) {
            $cell = [ undef, $cell_color{$cell}, $cell_mapping{$cell} ];
        }
        elsif ( $cell =~ /[[:alpha:]][[:digit:]]+/xms ) {
            $cell = [ '#D8D8D8', undef ];
        }
        elsif ( $cell ne "##" ) {
            $cell = [ undef, '#FFFFFF', $cell ];
        }
    }
    $display_plate_name =~ s/::$//msx;

    template 'display_sequence_plate', {

        display_plate_name => $display_plate_name,
        sequence_plate     => $seq_array,
        legend             => \%exp_color,
    };

};

get '/get_new_experiment' => sub {

    $dbh = get_schema();
    my $exp_sth = $dbh->prepare("DESC ExpView");
    my $gen_sth =
      $dbh->prepare("SELECT Genome_ref_name, Genome_ref_id FROM SpView");
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
    $seq_plate_name = undef;    ## re-set global

    template 'get_new_experiment', {
        last_std_name                      => $last_exp->[0],
        last_exp_name                      => $last_exp->[1],
        last_allele_name                   => $last_exp->[2],
        last_dev_stage                     => $last_exp->[3],
        last_ec_numb                       => $last_exp->[4],
        last_ec_method                     => $last_exp->[5],
        last_ec_date                       => $last_exp->[6],
        last_ec_by                         => $last_exp->[7],
        last_spike_mix                     => $last_exp->[8],
        last_spike_dil                     => $last_exp->[9],
        last_spike_vol                     => $last_exp->[10],
        last_visable                       => $last_exp->[11],
        last_genome_ref                    => $last_exp->[12],
        last_rna_ext_by                    => $last_exp->[13],
        last_rna_ext_prot_version          => $last_exp->[14],
        last_rna_ext_date                  => $last_exp->[15],
        last_library_creation_date         => $last_exp->[16],
        last_library_creation_prot_version => $last_exp->[17],
        last_pheno_desc                    => $last_exp->[18],
        last_image                         => $last_exp->[19],
        last_lines_crossed                 => $last_exp->[20],
        last_founder                       => $last_exp->[21],
        last_library_tube_id               => $last_exp->[22],
        last_exp_desc                      => $last_exp->[23],

        spike_ids                          => SPIKE_IDS,
        genref_names                       => $genref_names,
        table_schema                       => $table_schema,
        dev_stages                         => $dev_stages,
        visibility                         => VISIBILITY,
        collection_description             => COLLECTION_DESCRIPTION,
        study_names                        => $std_names,

        add_experiment_data_url => uri_for('/add_experiment_data'),
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
        param('Collection_description'),
        param('Developmental_stage'),
        param('Experiment_description')
    ];

    ## check to see if new study and experiment names already exist
    my ( %std_exp_names, %allele_dups );
    my $std_exp_sth = $dbh->prepare("SELECT * FROM ExpStdy");
    $std_exp_sth->execute;
    foreach my $std_exp ( @{ $std_exp_sth->fetchall_arrayref } ) {

        # study_id, exp_name, study_name
        $std_exp_names{ $std_exp->[1] }{ $std_exp->[2] } = $std_exp->[0];
    }
    if ( exists( $std_exp_names{ $vals->[0] }{ $vals->[2] } ) ) {
        croak
"Study \"$std_exp_names{ $vals->[0] }{ $vals->[2] }\" and experiment \"$vals->[2]\" already exist in the database";
    }

    ## and add alleles to the global array
    my $alle_sth = $dbh->prepare("SELECT * FROM AlleleView WHERE name = ?");
    @alleles = ();    ## empty the global array
    my @no_alleles;
    my $check_alleles_sth = $dbh->prepare("SELECT * FROM CheckAlleles");
    $check_alleles_sth->execute;
    my $check_alleles = $check_alleles_sth->fetchall_hashref('name');

    ## check that the alleles exist in the database
    foreach my $allele_name ( split /[:,\s]+/, param('Alleles') ) {
        $allele_name = trim($allele_name);
        if ( !exists( $check_alleles->{"$allele_name"} ) ) {
            push @no_alleles, $allele_name;
        }
        else {
            $alle_sth->execute("$allele_name");
            ## hack: in case there is more than one gene associated with one allele,
            ## choose the first (random) allele/gene, ignore the rest
            push @alleles, shift @{ $alle_sth->fetchall_arrayref };
        }
    }
    if ( scalar @no_alleles ) {
        croak 'Alleles ', join ', ', @no_alleles,
          ' do not exist in the database';
    }

    ## copy the image file
    my $image;
    if ( param('Image') && param('Image') ne 'No image' ) {
        my $image_file = upload('Image');
        if ($image_file) {
            $image_file->copy_to("$image_dir");
            $image = $image_file->tempname;
            $image =~ s/.*\///xms;
        }
        else {
            $image = 'No image';
        }
    }

    my @rna_extraction_data = (
        param('RNA_extracted_by'),
        param('RNA_extraction_protocol_version'),
        param('RNA_extraction_date'),
        param('RNA_library_creation_date'),
        param('RNA_library_creation_protocol_version'),
        param('RNA_library_tube_id')
    );
    ## add the RNA-extraction info
    my $rna_ext_sth =
      $dbh->prepare("CALL add_rna_extraction_data(?,?,?,?,?,?, \@rna_ext_id)");
    $rna_ext_sth->execute(@rna_extraction_data);
    my ($rna_ext_id) = $dbh->selectrow_array("SELECT \@rna_ext_id");
    ## add a new experiment
    my $exp_sth = $dbh->prepare(
"CALL add_experiment_data(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, \@exp_id)"
    );
    $exp_sth->execute( $rna_ext_id, $image, @{$vals} );
    my ($exp_id) = $dbh->selectrow_array("SELECT \@exp_id");

    template 'get_genotypes_and_rna', {
        names_info => get_study_and_exp_names($exp_id),
        alleles    => \@alleles,

        get_genotypes_and_rna_url => uri_for('/get_genotypes_and_rna'),
    };

};

post '/get_genotypes_and_rna' => sub {

    my $rna_file = upload('rna_dilution_file');
    my $workbook;
    %rna_plate = ();    # re-set the global

    if ($rna_file) {
        my $copy_dir =
          make_file_path( "$exel_file_dir", param('std_name'),
            param('exp_name') );
        $rna_file->copy_to("$copy_dir");
        my $file_name = $rna_file->tempname;
        $file_name =~ s/.*\///xms;
        $workbook = ReadData("$copy_dir/$file_name");
    }

    my $min_rna_amount = param('minimum_rna_amount');
    my $rna_volume     = param('rna_volume');

    ## read in the file for the RNA concentrations
    foreach my $row ( 1 .. MAX_WELL_ROW ) {
        foreach my $col ( "A" .. "L" ) {
            my $index = $col . $row;
            if ( defined( $workbook->[1]{$index} ) ) {
                my $rna_amount = $workbook->[1]{$index};
                my $sw_index =
                  switch_cols_rows($index);    ## need to switch rows and cols
                $rna_plate{$sw_index}{'rna'} = $rna_amount;
                my $total_rna = $rna_volume * $rna_amount;
                my $qc_ok = $total_rna >= $min_rna_amount ? 1 : 0;
                $rna_plate{$sw_index}{'qc_ok'} = $qc_ok;
            }
        }
    }

    ## get the klusterCaller files
    foreach my $allele (@alleles) {    # uses a global variable - need to change
        my $allele_name = $allele->[1];
        if ( my $file = upload("$allele_name") ) {
            my @wells =
              map { split ' ', $_ } $file->content =~ /\[wells\] (.*)/xms;
            foreach my $well (@wells) {
                $well =~ s/\,.*//x;
                my ( $well_id, $geno_id ) = split '=', $well;
                if ( my ( $alpha, $num ) =
                    $well_id =~ /(^[A-H])0?([1-9][0-9]?)/xms )
                {
                    $well_id = $alpha . $num;
                    if ( exists( $rna_plate{$well_id} ) ) {
                        my $fail_num =
                          KlusterCallerCodes->{$geno_id} eq "Failed" ? 0 : 1;
                        $rna_plate{$well_id}{'genotype'}{ $allele_name . ":"
                              . KlusterCallerCodes->{$geno_id} } = $fail_num;
                    }
                }
            }
        }
    }

    %allele_combos = ();    # re-set the global
    my @wells_wo_genotypes;
    foreach my $well_id ( keys %rna_plate ) {
        if (
            ( !exists( $rna_plate{$well_id}{'genotype'} ) )
            || ( ( keys %{ $rna_plate{$well_id}{'genotype'} } ) !=
                scalar @alleles )
          )
        {
            push @wells_wo_genotypes,
              $well_id;    # discrepancy between rna-plate and genotype-plate(s)
        }
        my ( $geno_combos, $fail_count );
        foreach my $genotype ( sort keys %{ $rna_plate{$well_id}{'genotype'} } )
        {
            $fail_count += $rna_plate{$well_id}{'genotype'}{$genotype};
            $geno_combos .= "::" . $genotype;
        }
        if ( !$fail_count ) {    # all genotyping failed for this well
            $rna_plate{$well_id}{'all_failed'}++;
        }
        else {
            if ( $rna_plate{$well_id}{'qc_ok'} ) {    # there is enough RNA
                $geno_combos =~ s/^:://xms;
                push(
                    @{ $allele_combos{$geno_combos} },
                    [ $well_id, $rna_plate{$well_id}{'rna'} ]
                );
            }
        }
    }

    if ( scalar @wells_wo_genotypes )
    {   # not all the wells on the rna plate have a genotype - this is a problem
        $dbh = get_schema();
        my $exp_del_sth = $dbh->prepare("CALL delete_exp(?)");
        $exp_del_sth->execute( param('exp_id') )
          ;  # remove the experiment and rna_extraction record from the database
        croak 'Discrepancy between the wells ('
          . join( ", ", @wells_wo_genotypes )
          . ') in the rna-plate and the genotyping plate(s). The experiment '
          . param('exp_name')
          . ' has been removed from the database';
    }

    my %allele_geno_combinations;

    foreach my $allele_combo ( keys %allele_combos )
    {        ## sort on the amount of RNA
        $allele_geno_combinations{ @{ $allele_combos{$allele_combo} } }
          {$allele_combo} =
          [ sort { $b->[1] <=> $a->[1] } @{ $allele_combos{$allele_combo} } ];
    }

    template 'get_genotype_combinations', {
        names_info          => get_study_and_exp_names( param('exp_id') ),
        allele_combos       => \%allele_geno_combinations,
        rna_volume          => $rna_volume,
        min_rna_amount      => $min_rna_amount,
        final_sample_volume => param('final_sample_volume'),

        'populate_rna_dilution_plate_url' =>
          uri_for('/populate_rna_dilution_plate'),
    };

};

post '/populate_rna_dilution_plate' => sub {

    $dbh = get_schema();
    my $exp_id = param('exp_id');

    my ( %selected_wells, $selected_for_seq, $new_arr );
    foreach my $allele_geno ( keys %allele_combos ) {
        if ( my $selected_number = param("$allele_geno") ) {
            for ( my $i = 0 ; $i < $selected_number ; $i++ ) {
                $selected_wells{ $allele_combos{$allele_geno}->[$i]->[0] } =
                  $allele_geno;
            }
        }
    }

    my $rna_sth = $dbh->prepare(
        "CALL add_rna_dilution_data(?,?,?,?,?,?,?,?, \@rna_dil_id)");
    my $geno_sth = $dbh->prepare("CALL add_genotype_data(?,?,?,?)");

    foreach my $well_id ( keys %rna_plate ) {
        my $rna_amount = $rna_plate{$well_id}{'rna'};
        my $qc_pass    = $rna_plate{$well_id}{'qc_ok'};

        if ( exists( $selected_wells{$well_id} ) ) {
            $selected_for_seq = 1;
            $rna_plate{$well_id}{'sfs'} = 1;
        }
        else {
            $selected_for_seq = 0;
            $rna_plate{$well_id}{'sfs'} = 0;
        }

        ## add one well
        $rna_sth->execute(
            $exp_id,                 $rna_amount,
            param('rna_volume'),     $well_id,
            param('min_rna_amount'), $qc_pass,
            $selected_for_seq,       param('final_sample_volume')
        );
        my ($rna_dil_id) = $dbh->selectrow_array("SELECT \@rna_dil_id");
        my $alle_sth =
          $dbh->prepare("SELECT id FROM AlleleView WHERE name = ?");

        ## add one or more genotypes
        foreach
          my $allele_genotype ( keys %{ $rna_plate{$well_id}{'genotype'} } )
        {
            my ( $allele_name, $genotype ) = split ':', $allele_genotype;
            $alle_sth->execute("$allele_name");
            my $allele_id = $alle_sth->fetchrow_arrayref;
            $geno_sth->execute( $allele_id->[0], $rna_dil_id, $genotype, '' );
        }
    }
    $new_arr = make_grid()->[0];

    foreach my $cell ( @{$new_arr} ) {
        if ( exists( $rna_plate{$cell} ) ) {
            if ( $rna_plate{$cell}{'sfs'} ) {
                $cell = '#00FF00';    ## selected for sequencing - green
            }
            elsif ( !$rna_plate{$cell}{'qc_ok'} ) {
                $cell = '#FF0000';    ## RNA conc too low - red
            }
            elsif ( $rna_plate{$cell}{'all_failed'} ) {
                $cell = '#FFA500';  ## all the allele genotyping failed - orange
            }
            else {
                $cell = '#FFFFFF';
            }
        }
    }

    template 'display_rna_plates',
      {
        names_info     => get_study_and_exp_names($exp_id),
        template_array => $new_arr,
      };

};

### Handlers for ontology data 

get '/get_ontology_for_allele' => sub {
 
 $dbh = get_schema();

 my $allele_name = param('allele_name');
 my $mod_allele = param('mod_allele');
 $allele_name = trim($allele_name);
 my ($allele_info, $all_allele_sth);
 if($mod_allele && $mod_allele == 1) { ## add an entry
  $all_allele_sth = $dbh->prepare(
   "SELECT av.*, 'stage', 'entity1', 'entity2', 'quality', 'tag' FROM alleleView av WHERE av.allele_name = ?");
 }
 elsif($mod_allele && ($mod_allele == 2 || $mod_allele == 3)) { ## delete or view an entry
  $all_allele_sth = $dbh->prepare("SELECT * FROM alleleOntologyView WHERE allele_name = ?");
 }
 if($all_allele_sth) {
  $all_allele_sth->execute($allele_name);
  my $col_names = $all_allele_sth->{'NAME'};
  $allele_info = $all_allele_sth->fetchall_arrayref;
  if(@{ $allele_info }) {
   unshift @{ $allele_info }, $col_names;
  }
  else {
   die "no allele with name \"$allele_name\" found in database\n$?";
  }
 }

 template 'get_ontology_for_allele',
  {
    'allele_info'        => $allele_info, 
    'mod_allele'         => $mod_allele,

    'get_ontology_for_allele_url'  => uri_for('/get_ontology_for_allele'),
    'add_ontology_eq_terms_url'    => uri_for('/add_ontology_eq_terms'),
    'delete_ontology_eq_terms_url' => uri_for('delete_ontology_eq_terms'),
  };

};

get '/delete_ontology_eq_terms' => sub {

 $dbh = get_schema();
 
 my $zap_alleles = $dbh->prepare("SELECT zap_id FROM alleleOntologyView WHERE zap_id");
 $zap_alleles->execute;
 foreach my $zap_id(@{ $zap_alleles->fetchall_arrayref }) {
  my $zap_id_to_delete = 'radio::' . $zap_id->[0];
  if(param($zap_id_to_delete)) {
   my $zap2del_sth = $dbh->prepare("CALL delete_zap(?)");
   $zap2del_sth->execute($zap_id->[0]);
  }
 }

 template 'get_ontology_for_allele',
  {
    'get_ontology_for_allele_url'  => uri_for('/get_ontology_for_allele'),
  };
};

get '/choose_a_tc_experiment' => sub {

 $dbh = get_schema();

 my (@zap_info,%exp_ids,%no_zap_info);

 my $exp_id = param('');
 
 my $tc_exp_sth = $dbh->prepare("SELECT *, 'ontology_terms' FROM ExpStdNameView");
 $tc_exp_sth->execute;
 my $col_names = $tc_exp_sth->{'NAME'};
 my $tc_exp_std = $tc_exp_sth->fetchall_arrayref;

 my $exp_exists_sth = $dbh->prepare("SELECT 1 FROM DUAL WHERE NOT EXISTS(SELECT exp_id FROM ontologyTermsView WHERE exp_id = ?)");

 foreach my $exp_std(@{ $tc_exp_std }) {
  @{ $exp_std }[0,2] = @{ $exp_std }[2,0]; 
  $exp_ids{ $exp_std->[0] }++;
  $exp_exists_sth->execute($exp_std->[0]);
  if( @{ $exp_exists_sth->fetchall_arrayref }[0] ) {
   $no_zap_info{ $exp_std->[0] }++;
   @{ $exp_std }[3] = 'No'; 
  }
  else {
   @{ $exp_std }[3] = 'Yes';
  }
 }
 unshift @{ $tc_exp_std }, [ @{ $col_names }[2,1,0,3] ]; # have to reorder the col names

 my $zap_col_names;
 my $zap_sth = $dbh->prepare("SELECT * FROM ontologyTermsView WHERE exp_id = ?");
 foreach my $exp_id(sort {$b <=> $a} keys %exp_ids) {
  my $pkey = 'radio::' . $exp_id;
  if(param("$pkey")){
   $zap_sth->execute($exp_id);    
   if(! $zap_col_names) {
    $zap_col_names = $zap_sth->{'NAME'};
   }
   push@zap_info, @{ $zap_sth->fetchall_arrayref };
  }
 }
 if($zap_col_names) {
  unshift@zap_info, $zap_col_names;
 }
 
 template 'choose_a_tc_experiment',
  {
    'std_exp' => $tc_exp_std,
    'zap_info' => \@zap_info,
    'no_zap_info' => \%no_zap_info,
    'choose_a_tc_experiment_url'    => uri_for('/choose_a_tc_experiment'), 
  };
};

get '/add_ontology_eq_terms' => sub {

 $dbh = get_schema();

 my (@vals, @mod_vals, %K);
 foreach my $ont_key(sort {$a <=> $b} keys %{ +ONT }){
  my $ont_val = trim( ${ +ONT }{$ont_key} ); 
  my $in_val = param("$ont_val"); # can be an array - if more than 1 db entry for a given allele name
  if($in_val) {
   push @vals, $in_val;
  }
  else {
   push @vals, undef;
  }
 }
 
 if(ref($vals[0]) eq 'ARRAY') {
  for(my$i=0;$i<@{ $vals[0] };$i++) {
   my $temp_arr;
   for(my$j=0;$j<@vals;$j++) {
    my $in_val = $vals[$j]->[$i] eq '' ? undef : $vals[$j]->[$i];
    push@{ $temp_arr }, $in_val;
   }
   push@mod_vals, $temp_arr;
  }
 }
 else {
  push@mod_vals, [ @vals ];
 }

 for(my$i=0;$i<@mod_vals;$i++) {
  for(my$j=0;$j<@{ $mod_vals[$i] };$j++) {
   $K{$i} += $mod_vals[$i]->[$j] ? 0 : 1;
  }
 }

 my @failed_inserts;
 for(my$i=0;$i<@mod_vals;$i++) {
  if( $K{$i} < ADD_ONT_TERMS ) { ## something to add
   my $gen_ref_sth = $dbh->prepare("SELECT Genome_ref_id FROM SpView WHERE Genome_ref_name = ?");
   my $gen_ref_name = ( split":",$mod_vals[$i]->[0] )[0];
   $gen_ref_sth->execute($gen_ref_name);
   unshift @{ $mod_vals[$i] }, @{ $gen_ref_sth->fetchrow_arrayref }[0];
   my $zmp_alle_sth = $dbh->prepare("CALL insert_zmp_allele_phenotype_eq(?,?,?,?,?,?,?,?, \@insert_id)");
   $zmp_alle_sth->execute( @{ $mod_vals[$i] } );
   my ($insert_id) = $dbh->selectrow_array("SELECT \@insert_id");
   if(! $insert_id) {
    my $allele_name_sth = $dbh->prepare("SELECT allele_name FROM alleleView WHERE allele_id = ?");
    $allele_name_sth->execute($mod_vals[$i]->[2]);
    push @failed_inserts, @{ $allele_name_sth->fetchall_arrayref }[0]->[0];
   }
  }
 }

 if(scalar(@failed_inserts)) {
  my $names = join(', ', @failed_inserts);
  die("insertion into table zmp_allele_phenotype_eq failed for alleles: $names\n\n",$?);
 }

 template 'get_ontology_for_allele',
  {
    'get_ontology_for_allele_url'  => uri_for('/get_ontology_for_allele'),
  };
};

sub overwrite_file {
    my ( $excel_file, $excel_data, $seq_plate ) = @_;
    my $date_time = `date --rfc-3339=seconds | xargs echo -n`;
    my ( $date, $time ) = split ' ', $date_time;
    my $parser    = Spreadsheet::ParseExcel::SaveParser->new();
    my $template  = $parser->Parse("$excel_file");
    my $worksheet = $template->worksheet(0);
    my $row       = HEADER_ROW;
    foreach my $row_array ( @{$excel_data} ) {
        my $col = 0;
        foreach my $row_value ( @{$row_array} ) {
            my $format = $worksheet->{Cells}[$row][$col]->{FormatNo};
            if ($row_value) {
                $worksheet->AddCell( $row, $col, "$row_value", $format );
            }
            $col++;
        }
        $row++;
    }
    $template->SaveAs("$excel_file");
    return ( $date, $excel_file );
}

sub make_grid {
    my $new_arr;
    my @ALPH = 'A' .. 'H';
    my @NUM  = 1 .. MAX_WELL_COL;
    my $ct   = 0;
    my ( %mhash, %chash );
    for ( my $j = 0 ; $j < @NUM ; $j++ ) {
        for ( my $i = 0 ; $i < @ALPH ; $i++ ) {
            my $well_index = $ALPH[$i] . $NUM[$j];
            $mhash{$ct} = $well_index;
            $ct++;
        }
    }

    $ct = 0;
    for ( my $i = 0 ; $i < @ALPH ; $i++ ) {
        for ( my $j = 0 ; $j < @NUM ; $j++ ) {
            my $well_index = $ALPH[$i] . $NUM[$j];
            $chash{$ct} = $well_index;
            $ct++;
        }
    }

    push @{$new_arr}, '', 1 .. MAX_WELL_COL, '##';
    for ( my $i = 0 ; $i < MAX_WELL_ROW ; $i++ ) {
        push @{$new_arr}, shift @ALPH;
        for ( my $j = $i ; $j < PLATE_SIZE ; $j = $j + MAX_WELL_ROW ) {
            push @{$new_arr}, $mhash{$j};
        }
        push @{$new_arr}, '##';
    }
    return [ $new_arr, \%chash, \%mhash ];
}

sub switch_cols_rows {
    my ( %al2nu, %nu2al );
    @al2nu{ 'A' .. 'L' } = ( 1 .. MAX_WELL_COL );
    @nu2al{ 1 .. MAX_WELL_ROW } = ( 'A' .. 'H' );

    return join '',
      map { $nu2al{ $_->[1] }, $al2nu{ $_->[0] } }[ split '', shift ];
}

sub make_file_path {
    my $dir = join "/", @_;
    if ("$dir") {
        make_path( "$dir", { verbose => 1, mode => 0777 } );
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
    my $exp_sth =
      $dbh->prepare("SELECT * FROM ExpStdNameView WHERE exp_id = ?");
    $exp_sth->execute($exp_id);
    return $exp_sth->fetchrow_arrayref || undef;
}

sub color_plate {
    my $attrib = shift;
    $dbh = get_schema();
    my $seq_plate_sth =
      $dbh->prepare("SELECT * FROM SeqWellOrderView WHERE plate_name = ?");
    $seq_plate_sth->execute( param('plate_name') );
    my $seq_plate = $seq_plate_sth->fetchall_hashref('seq_well_name');
    my $template  = make_grid()->[0];
    my ( %exp_legend, %genot_legend, %num2geno );
    foreach my $well_id ( @{$template} ) {

        if ( exists( $seq_plate->{$well_id} ) ) {
            $exp_legend{ $seq_plate->{$well_id}->{'color'} }{'exp_name'} =
              $seq_plate->{$well_id}->{'exp_name'};
            $exp_legend{ $seq_plate->{$well_id}->{'color'} }{'std_name'} =
              $seq_plate->{$well_id}->{'std_name'};
            if ( $attrib eq 'well_names' ) {

                # to allow template toolkit display a spike_voume of 0
                my $spike_vol =
                    $seq_plate->{$well_id}->{'spike_volume'}
                  ? $seq_plate->{$well_id}->{'spike_volume'}
                  : -1;
                $well_id = [
                    $seq_plate->{$well_id}->{'selected'},
                    $seq_plate->{$well_id}->{'color'},
                    $seq_plate->{$well_id}->{'rna_well_name'},
                    $seq_plate->{$well_id}->{'sample_volume'},
                    $seq_plate->{$well_id}->{'water_volume'},
                    $spike_vol
                ];
            }
            elsif ( $attrib eq 'genotypes' ) {
                foreach my $genotype_str ( split ',',
                    $seq_plate->{$well_id}->{'AlleleGenotype'} )
                {
                    my $well_genot = join ":",
                      ( split ':', $genotype_str )[ 0, 2 ];
                    $genot_legend{$well_id}{$well_genot}++;
                    $num2geno{$well_genot} = undef;
                }
            }
            elsif ( $attrib eq 'index_tags' ) {
                my $tag_set = $seq_plate->{$well_id}->{'tag_set'};
                my $tag_seq = $seq_plate->{$well_id}->{'tag_seq'};
                if ( $tag_set =~ m/^TC:12:10:r[12]$/xms ) {
                    $tag_seq =~ s/CG$//;
                }
                $well_id = [
                    $seq_plate->{$well_id}->{'selected'},
                    $seq_plate->{$well_id}->{'color'},
                    $seq_plate->{$well_id}->{'tag_name'},
                    $tag_seq
                ];
            }
        }
        elsif ( $well_id =~ /[[:alpha:]][[:digit:]]+/xms ) {
            $well_id = [ undef, '#D8D8D8', undef ];    ## grey for blank well
        }
        elsif ( $well_id ne "##" ) {
            $well_id = [ undef, '#FFFFFF', $well_id ];    ## white
        }
    }
    if ( keys %num2geno ) {
        my $ct = 1;
        foreach my $well_genot ( sort keys %num2geno ) {
            $num2geno{$well_genot} = $ct;
            $ct++;
        }
        foreach my $well_id ( @{$template} )
        {    ## set the wells for the genotypes
            if ( exists( $genot_legend{$well_id} ) ) {
                $well_id = [
                    $seq_plate->{$well_id}->{'selected'},
                    $seq_plate->{$well_id}->{'color'},
                    join ":",
                    sort map { $num2geno{$_} } keys %{ $genot_legend{$well_id} }
                ];
            }
        }
    }
    return [ $template, \%exp_legend, \%num2geno, param('plate_name') ];
}

sub roll_back { # delete experiment(s) from the database 
 my $exp_ids = shift;
 my $dbh = get_schema();
 my $del_sth = $dbh->prepare("CALL delete_exp(?)");
 foreach my $exp_id(keys %{ $exp_ids }){
  $del_sth->execute($exp_id);
 } 
}

sub get_schema { ## export $ENV{...} values in your .bashrc
  my($host, $port)=($ENV{'TC_HOST'}, $ENV{'TC_PORT'});
  return DBI->connect( "DBI:mysql:$db_name;host=$host;port=$port",
      $ENV{'TC_USER'}, $ENV{'TC_PASS'} )
    or die "Cannot connect to database $db_name\n$?";
}

sub get_wh_schema {
 my($host,$port,$user,$db_name) = ($ENV{'WH_HOST'}, $ENV{'WH_PORT'}, $ENV{'WH_USER'}, $ENV{'WH_DBNAME'});
 return DBI->connect( "DBI:mysql:$db_name;host=$host;port=$port",$user) 
  or die "Cannot connect to database $db_name\n$?";
}
  

1;
