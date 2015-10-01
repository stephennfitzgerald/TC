CREATE TABLE IF NOT EXISTS array_express_data (
 id			INT(10) DEFAULT 1 NOT NULL,
 age			VARCHAR(255) DEFAULT "N/A" NOT NULL,
 cell_type		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 compound		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 disease		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 disease_state		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 dose			VARCHAR(255) DEFAULT "N/A" NOT NULL,
 genotype		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 growth_condition	VARCHAR(255) DEFAULT "N/A" NOT NULL,
 immunoprecipitate	VARCHAR(255) DEFAULT "N/A" NOT NULL,
 organism_part          VARCHAR(255) DEFAULT 'Whole_Embryo' NOT NULL, 
 phenotype		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 time_point		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 treatment		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 donor_id		VARCHAR(255) DEFAULT "N/A" NOT NULL,

 PRIMARY		KEY(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS allele (

 id				INT(10) NOT NULL AUTO_INCREMENT,
 name				VARCHAR(255) NOT NULL,
 gene_name			VARCHAR(255) NULL,
 snp_id                         VARCHAR(255) NULL,

 PRIMARY 			KEY(id)
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS study (

 id			int(10) NOT NULL AUTO_INCREMENT,
 name			VARCHAR(255) NOT NULL,

 PRIMARY 		KEY(id),
 
 UNIQUE			KEY name(name) 

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS species (
 id			INT(10) NOT NULL AUTO_INCREMENT,
 name			VARCHAR(255) DEFAULT "zebrafish" NOT NULL,
 binomial_name		VARCHAR(255) DEFAULT "Danio rerio" NOT NULL,
 taxon_id		INT(10) DEFAULT 7955 NOT NULL,
 
 PRIMARY		KEY(id)
  
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS index_tag (
 id			INT(10) NOT NULL AUTO_INCREMENT,
 name			VARCHAR(255) NOT NULL,
 tag_random_sequence	VARCHAR(255) NOT NULL,
 tag_index_sequence	VARCHAR(255) NOT NULL,	

 PRIMARY   		KEY(id),
 UNIQUE			KEY tag_seq(tag_random_sequence,tag_index_sequence)
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;
 

CREATE TABLE IF NOT EXISTS developmental_stage (
 id				INT(10) AUTO_INCREMENT,
 period				VARCHAR(255) NULL,
 stage				VARCHAR(255) NULL,
 begins				VARCHAR(255) NULL,
 developmental_landmarks	VARCHAR(255) NULL,
 zfs_id				VARCHAR(255) NOT NULL,
 namespace                      VARCHAR(255) DEFAULT 'zebrafish_stages' NOT NULL,

 PRIMARY			KEY(id),
 UNIQUE                         KEY(stage),
 UNIQUE                         KEY(zfs_id)
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS zmp_ontology_term ( 
 id                             INT(10) NOT NULL AUTO_INCREMENT,
 ontology_id                    VARCHAR(255) NOT NULL,
 name                           VARCHAR(255) NOT NULL,
 namespace                      VARCHAR(255) NOT NULL,
 def                            MEDIUMTEXT NULL,

 PRIMARY                        KEY(id),
 UNIQUE                         KEY(ontology_id)
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS genome_reference (
 id				INT(10) NOT NULL AUTO_INCREMENT,
 name  				VARCHAR(255) NOT NULL,
 species_id			INT(10) NOT NULL,
 gc_content			VARCHAR(255) DEFAULT "Neutral" NOT NULL,

 PRIMARY 			KEY(id),
 UNIQUE				KEY(name),
 FOREIGN 			KEY(species_id) REFERENCES species(id)
 
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS zmp_allele_phenotype_eq (
 id                             INT(10) NOT NULL AUTO_INCREMENT,
 genome_reference_id		INT(10) NOT NULL,
 allele_id                      INT(10) NOT NULL,
 stage                          VARCHAR(255) NULL,
 entity1                        VARCHAR(255) NULL,
 entity2                        VARCHAR(255) DEFAULT " " NULL,
 quality                        VARCHAR(255) NULL,
 tag                            VARCHAR(255) NULL,

 PRIMARY                        KEY(id),
 FOREIGN                        KEY(tag) REFERENCES zmp_ontology_term(ontology_id),
 FOREIGN                        KEY(quality) REFERENCES zmp_ontology_term(ontology_id),
 FOREIGN                        KEY(entity1) REFERENCES zmp_ontology_term(ontology_id),
 FOREIGN                        KEY(entity2) REFERENCES zmp_ontology_term(ontology_id),
 FOREIGN                        KEY(stage) REFERENCES developmental_stage(zfs_id),
 FOREIGN                        KEY(genome_reference_id) REFERENCES genome_reference(id),
 FOREIGN                        KEY(allele_id) REFERENCES allele(id)
) COLLATE=latin1_swedish_ci ENGINE=InnoDB; 


CREATE TABLE IF NOT EXISTS rna_extraction (
 id					INT(10) NOT NULL AUTO_INCREMENT,
 extracted_by				VARCHAR(255) DEFAULT "Neha" NOT NULL,
 extraction_protocol_version		VARCHAR(255) DEFAULT 'V3' NOT NULL,
 extraction_date			DATE DEFAULT '00-00-0000' NOT NULL,
 library_creation_date			DATE DEFAULT '00-00-0000' NOT NULL,
 library_creation_protocol_version      VARCHAR(255) DEFAULT 'V7.6' NOT NULL,
 library_tube_id			VARCHAR(255) NULL,

 PRIMARY				KEY(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS experiment (
 id					INT(10) AUTO_INCREMENT,
 name					VARCHAR(255) NOT NULL,
 genome_reference_id			INT(10) NOT NULL,
 lines_crossed				VARCHAR(255) NULL,
 founder				VARCHAR(255) NULL,
 strain_name                            VARCHAR(255) DEFAULT "Mixed" NOT NULL,
 developmental_stage_id    		INT(10) NOT NULL,
 collection_description			ENUM('Blind', 'Phenotypic') DEFAULT 'Blind' NOT NULL,
 dna_source                             VARCHAR(255) DEFAULT 'Whole Genome' NOT NULL,
 image					VARCHAR(255) DEFAULT 'No image' NULL,
 spike_mix				ENUM('0', '1', '2') DEFAULT '0' NOT NULL,
 spike_dilution				VARCHAR(255) NOT NULL DEFAULT 0,
 spike_volume				FLOAT NOT NULL DEFAULT 0.0,
 study_id				INT(10) NOT NULL, 
 embryo_collection_method		VARCHAR(255) DEFAULT "2ml assay block" NOT NULL,
 embryo_collected_by			VARCHAR(255) DEFAULT "Neha" NOT NULL,
 embryo_collection_date			DATE DEFAULT '00-00-0000' NOT NULL, 
 number_embryos_collected		INT(10) NULL,
 sample_visibility			ENUM('Hold', 'Public') DEFAULT 'Hold' NOT NULL,	 
 rna_extraction_id			INT(10) NULL,
 array_express_data_id			INT(10) DEFAULT 1 NOT NULL,
 description                            MEDIUMTEXT NULL,
 library_conc_file			VARCHAR(255) NULL,

 PRIMARY				KEY(id),
 UNIQUE					KEY(name,study_id),
 FOREIGN				KEY(developmental_stage_id) REFERENCES developmental_stage(id),
 FOREIGN				KEY(genome_reference_id) REFERENCES genome_reference(id), 
 FOREIGN				KEY(study_id) REFERENCES study(id),
 FOREIGN				KEY(array_express_data_id) REFERENCES array_express_data(id),
 FOREIGN				KEY(rna_extraction_id) REFERENCES rna_extraction(id)
 
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS rna_dilution_plate (

 id					INT(10) NOT NULL AUTO_INCREMENT,
 experiment_id				INT(10) NOT NULL,
 rna_amount				FLOAT NOT NULL,
 rna_volume				FLOAT NOT NULL,
 well_name				VARCHAR(255) NOT NULL,
 cut_off_amount				FLOAT NOT NULL,
 final_sample_volume                    FLOAT NOT NULL,
 qc_pass				TINYINT(1) DEFAULT 1 NOT NULL,
 selected_for_sequencing		TINYINT(1) DEFAULT 0 NOT NULL,
 gender				        ENUM('Male', 'Female', 'Unknown') DEFAULT 'Unknown' NOT NULL,

 PRIMARY    	    			KEY(id),
 UNIQUE					KEY(experiment_id, well_name),
 FOREIGN				KEY(experiment_id) REFERENCES experiment(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS sequence_plate (
 id					INT(10) NOT NULL AUTO_INCREMENT,
 plate_name				VARCHAR(255) NOT NULL,
 sanger_plate_id			VARCHAR(255) NULL,
 sanger_sample_id			VARCHAR(255) NULL,
 sample_volume				FLOAT NOT NULL,
 sample_amount				FLOAT NOT NULL,
 water_volume                           FLOAT NOT NULL,
 excel_report_created_date		DATE NULL,
 excel_report_file_location             VARCHAR(255) NULL,
 well_name				VARCHAR(255) NOT NULL,
 sample_name				VARCHAR(255) NOT NULL,
 sample_public_name			VARCHAR(255) NOT NULL,
 rna_dilution_plate_id			INT(10) NOT NULL,
 index_tag_id                           INT(10) NOT NULL,
 color					VARCHAR(255) NULL,
 library_amount				FLOAT NULL,
 library_volume				FLOAT NULL,
 library_qc				TINYINT(1) DEFAULT 1 NOT NULL,
 selected                               TINYINT(1) DEFAULT 1 NOT NULL,
 phenotype                              ENUM('Phenotypic','Non-Phenotypic','Unknown') DEFAULT 'Unknown',
 ena_accession                          VARCHAR(255) NULL, 

 PRIMARY 				KEY(id),
 UNIQUE 				KEY(plate_name, well_name),
 UNIQUE					KEY(rna_dilution_plate_id), /** allow an experiment to be on ONE sequence plate at most **/ 
 FOREIGN				KEY(index_tag_id) REFERENCES index_tag(id),
 FOREIGN				KEY(rna_dilution_plate_id) REFERENCES rna_dilution_plate(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS treatment (
 sequence_plate_id                      INT(10) NOT NULL,
 treatment_type                         ENUM('Small molecule screen','Infection challenge','Gene knockout','No treatment') DEFAULT 'No treatment',
 treatment_description                  MEDIUMTEXT NULL,
 compound				MEDIUMTEXT NULL, /** should be populated only when the treatment_type = 'Small molecule screen' **/
 dose					MEDIUMTEXT NULL, /** should be populated only when the treatment_type = 'Small molecule screen' **/

 FOREIGN                                KEY(sequence_plate_id) REFERENCES sequence_plate(id),
 UNIQUE                                 KEY(sequence_plate_id,treatment_type)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS genotype (
 id					INT(10) NOT NULL AUTO_INCREMENT,
 allele_id				INT(10) NOT NULL,
 rna_dilution_plate_id			INT(10) NOT NULL,
 name					ENUM('Het','Hom','Wildtype','Failed','Missing','Blank'),
 sample_comment			        MEDIUMTEXT NULL,	

 PRIMARY				KEY(id),
 FOREIGN				KEY(allele_id) REFERENCES allele(id),
 FOREIGN				KEY(rna_dilution_plate_id) REFERENCES rna_dilution_plate(id),
 UNIQUE					KEY(allele_id,rna_dilution_plate_id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;

/** Auto add data to array_express_data **/

INSERT IGNORE INTO array_express_data 
   (id,age,cell_type,compound,disease,disease_state,dose,
    genotype,growth_condition,immunoprecipitate,
    organism_part,phenotype,time_point,treatment,donor_id) 
VALUES (
    1,"N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A",
    'Whole Embryo',"N/A","N/A","N/A","N/A");
