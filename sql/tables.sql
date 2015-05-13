CREAT TABLE IF NOT EXISTS array_express_data (
 id			INT(10) DEFAULT 1 NOT NULL,
 age			VARCHAR(255) DEFAULT "N/A" NOT NULL,
 cell_type		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 compaund		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 disease		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 disease_state		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 dose			VARCHAR(255) DEFAULT "N/A" NOT NULL,
 genotype		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 growth_condition	VARCHAR(255) DEFAULT "N/A" NOT NULL,
 immunoprecipitate	VARCHAR(255) DEFAULT "N/A" NOT NULL,
 organism_part          VARCHAR(255) DEFAULT "Whole Embryo" NOT NULL, 
 phenotype		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 time_point		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 treatment		VARCHAR(255) DEFAULT "N/A" NOT NULL,
 donor_id		VARCHAR(255) DEFAULT "N/A" NOT NULL,

 PRIMARY		KEY(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS allele (

 id				INT(10) NOT NULL AUTO_INCREMENT,
 name				VARCHAR(255) NOT NULL,
 gene_name			VARCHAR(255) NOT NULL,

 PRIMARY 			KEY(id),
 UNIQUE				KEY(name,gene_name)

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
 zfs_id				VARCHAR(255) NULL,	
 name				VARCHAR(255) NULL, 
 description			VARCHAR(255) NULL,

 PRIMARY			KEY(id),
 UNIQUE				KEY(zfs_id, name, description)
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


CREATE TABLE rna_extraction (
 id					INT(10) NOT NULL AUTO_INCREMENT,
 extracted_by				VARCHAR(255) NOT NULL,
 extraction_protocol			VARCHAR(255) NOT NULL,
 extraction_date			DATE NOT NULL,
 library_creation_date			DATE NOT NULL,
 library_tube_id			VARCHAR(255) NULL,

 PRIMARY				KEY(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS experiment (

 id					INT(10) AUTO_INCREMENT,
 name					VARCHAR(255) NOT NULL,
 genome_reference_id			INT(10) NOT NULL,
 lines_crossed				VARCHAR(255) NULL,
 founder				VARCHAR(255) NULL,
 strain_name                            VARCHAR(255) DEFAULT "mixed" NULL,
 developmental_stage_id    		INT(10) NOT NULL,
 phenotype_description			VARCHAR(255) NULL,
 dna_source                             VARCHAR(255) DEFAULT 'Whole Genome' NOT NULL,
 image					ENUM("Yes", "No") DEFAULT "No" NOT NULL,
 spike_dilution				VARCHAR(255) DEFAULT "No spike" NOT NULL,
 spike_volume				INT(10) DEFAULT 0 NOT NULL,
 study_id				INT(10) NOT NULL, 
 embryo_collection_method		VARCHAR(255) DEFAULT "2ml assay block" NOT NULL,
 embryo_collected_by			VARCHAR(255) DEFAULT "Neha" NOT NULL,
 embryo_collection_date			DATE DEFAULT '0000-00-00' NOT NULL, 
 number_embryos_collected		INT(10) NOT NULL,
 submitted_for_sequencing               DATE DEFAULT '0000-00-00' NOT NULL,
 sample_visability			ENUM('Hold', 'Public') DEFAULT 'Public' NOT NULL,	 
 asset_group                            VARCHAR(255) NULL,
 rna_extraction_id			INT(10) NULL,
 array_express_data_id			INT(10) DEFAULT 1 NOT NULL,

 PRIMARY				KEY(id),
 UNIQUE					KEY(name,study_id),
 FOREIGN				KEY(developmental_stage_id) REFERENCES developmental_stage(id),
 FOREIGN				KEY(genome_reference_id) REFERENCES genome_reference(id), 
 FOREIGN				KEY(study_id) REFERENCES study(id),
 FOREIGN				KEY(array_express_data_id) REFERENCES array_express_data(id),
 FOREIGN				KEY(rna_extraction_id) REFERENCES rna_extraction(id)
 
) COLLATE=latin1_swedish_ci ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS allele_experiment_link (

 id					INT(10) AUTO_INCREMENT,
 allele_id				INT(10) NOT NULL,
 experiment_id				INT(10) NOT NULL,

 PRIMARY 				KEY(id),
 UNIQUE					KEY(allele_id,experiment_id),
 FOREIGN				KEY(allele_id) REFERENCES allele(id),
 FOREIGN				KEY(experiment_id) REFERENCES experiment(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;
 

CREATE TABLE IF NOT EXISTS sample (
 
 id					INT(10) NOT NULL AUTO_INCREMENT,
 name					VARCHAR(255) NOT NULL,
 public_name				VARCHAR(255) NOT NULL,
 embryo_collection_well_number		VARCHAR(255) NOT NULL,
 rna_dilution_well_number		VARCHAR(255) NOT NULL,
 experiment_id				INT(10) NOT NULL,
 gender					VARCHAR(255) DEFAULT 'Unknown' NOT NULL,
 index_tag_id                           INT(10) NOT NULL,
 

 PRIMARY 				KEY(id),
 UNIQUE 				KEY(name),
 UNIQUE					KEY(public_name),
 FOREIGN				KEY(index_tag_id) REFERENCES index_tag(id),
 FOREIGN				KEY(experiment_id) REFERENCES experiment(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;



CREATE TABLE IF NOT EXISTS rna_dilution_plate ( /** one to one relationship with sample table **/

 rna_sample_id				INT(10) NOT NULL AUTO_INCREMENT,
 sample_id				INT(10) NOT NULL,
 rna_volume				INT(10) NOT NULL,
 water_volume				INT(10) NOT NULL,
 index_tag_conc				INT(10) NOT NULL,
 ratio_260_280				FLOAT NOT NULL,
 ratio_260_230				FLOAT NOT NULL,
 volume_needed_for_250ngs		INT(10) NOT NULL,
 dilution_library_made_date		DATE NOT NULL,
 pcr_cycles				VARCHAR(255) DEFAULT "KOD6020" NOT NULL,

 PRIMARY    	    			KEY(rna_sample_id),
 UNIQUE					KEY(sample_id),
 FOREIGN				KEY(sample_id) REFERENCES sample(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS genotype (
 
 id					INT(10) NOT NULL AUTO_INCREMENT,
 allele_experiment_id			INT(10) NOT NULL,
 sample_id				INT(10) NOT NULL,
 genotype				ENUM('Het','Hom','Wildtype','Failed'),
 description				VARCHAR(255) NULL,

 PRIMARY				KEY(id),
 FOREIGN				KEY(allele_experiment_id) REFERENCES allele_experiment_link(id),
 FOREIGN				KEY(sample_id) REFERENCES sample(id),
 UNIQUE					KEY(allele_experiment_id,sample_id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;

/** views **/

CREATE OR REPLACE VIEW alleExp AS
 SELECT allexp.id id,
        alle.name allele_name,
        allexp.experiment_id exp_id
 FROM allele_experiment_link allexp INNER JOIN allele alle
        ON alle.id = allexp.allele_id
 ORDER BY id;


CREATE OR REPLACE VIEW tagSeq AS
 SELECT id, 
        name,
        SUBSTRING_INDEX(name,'.', 1) name_prefix, 
        SUBSTRING_INDEX(name,'.', -1) name_postfix, 
        tag_index_sequence index_sequence 
 FROM index_tag
 ORDER BY id;

CREATE OR REPLACE VIEW tagSet AS
 SELECT DISTINCT(SUBSTRING_INDEX(name, '.', 1)) Tag_set_name 
 FROM index_tag
 ORDER BY Tag_set_name;

CREATE OR REPLACE VIEW expView AS
 SELECT exp.id ID, 
        exp.name Experiment, 
        std.name Study, 
        sp.name Species_name, 
        dvs.name Developmental_stage,
        GROUP_CONCAT(DISTINCT(ale.name) SEPARATOR " : ") Alleles,
        exp.spike_dilution Spike_dilution, 
        exp.image Image, 
        exp.submitted_for_sequencing,
        COUNT(smp.name) Sample_count 
  FROM experiment exp INNER JOIN study std 
        ON std.id = exp.study_id INNER JOIN genome_reference gr
        ON exp.genome_reference_id = gr.id LEFT OUTER JOIN developmental_stage dvs
        ON dvs.id = exp.developmental_stage_id INNER JOIN species sp
        ON sp.id = gr.species_id LEFT OUTER JOIN sample smp
        ON smp.experiment_id = exp.id INNER JOIN allele_experiment_link ael 
        ON ael.experiment_id = exp.id INNER JOIN allele ale
        ON ale.id = ael.allele_id
  GROUP BY exp.id
  ORDER BY exp.id;

CREATE OR REPLACE VIEW smpView AS
 SELECT smp.id ID, 
        exp.id Experiment_id, 
        smp.name Sample_name, 
        smp.public_name Sample_public_name, 
        exp.sample_visability Sample_visability, 
        indt.name Tag_name, 
        indt.tag_index_sequence Tag_index_sequence, 
        smp.embryo_collection_well_number Embryo_collection_well_number, 
        smp.rna_dilution_well_number RNA_dilution_well_number,
        exp.submitted_for_sequencing Submitted_for_sequencing
 FROM sample smp INNER JOIN experiment exp 
        ON exp.id = smp.experiment_id INNER JOIN index_tag indt
        ON smp.index_tag_id = indt.id
 GROUP BY smp.id
 ORDER BY exp.id;


CREATE OR REPLACE VIEW get_smpView AS
SELECT  exp.id Experiment_id,
        GROUP_CONCAT(smp.rna_dilution_well_number SEPARATOR " : ") RNA_dilution_well_order,
        GROUP_CONCAT(ind_tag.name SEPARATOR " : ") Tag_name_order,
        exp.name Experiment_name,
        exp.sample_visability Sample_visability, 
        GROUP_CONCAT(smp.embryo_collection_well_number SEPARATOR " : ") Embryo_collection_well_order, 
        exp.submitted_for_sequencing Submitted_for_sequencing
 FROM experiment exp LEFT OUTER JOIN sample smp 
        ON exp.id = smp.experiment_id LEFT OUTER JOIN rna_dilution_plate rna_dlip
        ON smp.id = rna_dlip.sample_id LEFT OUTER JOIN index_tag ind_tag 
        ON smp.index_tag_id = ind_tag.id
 GROUP BY smp.rna_dilution_well_number
 ORDER BY exp.id;

CREATE OR REPLACE VIEW showExpView AS
 SELECT std.name Study_name, 
        exp.name Experiment_name, 
        GROUP_CONCAT(ale.name SEPARATOR " : ") Alleles,
        exp.lines_crossed Lines_crossed, 
        exp.founder Founder, 
        devs.name Developmental_stage, 
        devs.description Developmental_description,
        exp.spike_dilution Spike_dilution, 
        exp.spike_volume Spike_volume, 
        exp.embryo_collection_method Embryo_collection_method,
        exp.image Image, 
        exp.phenotype_description Phenotype_description,
        exp.embryo_collected_by Embryos_collected_by, 
        exp.embryo_collection_date Embryo_collection_date, 
        exp.number_embryos_collected Number_of_embryos_collected,
        exp.submitted_for_sequencing Submitted_for_sequencing,
        exp.sample_visability Sample_visability,
        exp.asset_group Asset_group,
        grf.name Genome_ref_name 
 FROM experiment exp INNER JOIN study std
        ON exp.study_id = std.id INNER JOIN genome_reference grf
        ON grf.id = exp.genome_reference_id LEFT OUTER JOIN developmental_stage devs
        ON exp.developmental_stage_id = devs.id INNER JOIN allele_experiment_link ael
        ON ael.experiment_id = exp.id INNER JOIN allele ale
        ON ael.allele_id = ale.id
 GROUP BY exp.name
 ORDER BY std.name, exp.name;

CREATE OR REPLACE VIEW speciesView AS
 SELECT sp.name Species_name, 
        sp.binomial_name Binomial_name, 
        sp.taxon_id Taxon_id, 
        gr.name Genome_ref_name, 
        gr.gc_content GC_content
 FROM species sp INNER JOIN genome_reference gr 
        ON gr.species_id = sp.id
 ORDER BY sp.name; 


/** procedures **/


/** study **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_study_data$$

CREATE PROCEDURE add_study_data(
 IN study_name_param VARCHAR(255),
 OUT study_id int(10)
)
BEGIN

INSERT IGNORE INTO study (
 name
)
VALUES (
study_name_param
);
SET study_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** allele_experiment_link **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_allele_exp_link$$

CREATE PROCEDURE add_allele_exp_link(
 IN allele_id_param int(10),
 IN experiment_id_param int(10)
)
BEGIN

INSERT IGNORE INTO allele_experiment_link(
 allele_id, 
 experiment_id
)
VALUES (
 allele_id_param,
 experiment_id_param
);
END$$
DELIMITER ;



/** developmental_stage **/ 
DELIMITER $$
DROP PROCEDURE IF EXISTS add_developmental_stage$$

CREATE PROCEDURE add_developmental_stage(
 IN zfs_id_param VARCHAR(255),
 IN name_param VARCHAR(255),
 IN description_param VARCHAR(255),
 OUT dev_id int(10)
)
BEGIN

INSERT IGNORE INTO developmental_stage (
 zfs_id,
 name,
 description
)
VALUES (
 zfs_id_param,
 name_param,
 description_param
);
SET dev_id = LAST_INSERT_ID();
END$$
DELIMITER ;


/** sample **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_sample_data$$

CREATE PROCEDURE add_sample_data(
 IN name_param VARCHAR(255),
 IN public_name_param VARCHAR(255),
 IN embryo_collection_well_number_param VARCHAR(255),
 IN rna_dilution_well_number_param VARCHAR(255),
 IN experiment_id_param INT(10),
 IN index_tag_id_param INT(10)
)
BEGIN

INSERT IGNORE INTO sample (
 name,
 public_name,
 embryo_collection_well_number,
 rna_dilution_well_number,
 experiment_id,
 index_tag_id
)
VALUES (
 name_param,
 public_name_param,
 embryo_collection_well_number_param,
 rna_dilution_well_number_param,
 experiment_id_param,
 index_tag_id_param
);
END$$
DELIMITER ;


/** experiment **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_experiment_data$$
 
CREATE PROCEDURE add_experiment_data(
 IN study_id_param INT(10),
 IN developmental_stage_id_param INT(10),
 IN genome_reference_id_param INT(10),
 IN experiment_name_param VARCHAR(255),
 IN lines_crossed_param VARCHAR(255),
 IN founder_param VARCHAR(255),
 IN spike_dilution_param VARCHAR(255),
 IN spike_volume_param INT(10),
 IN embryo_collection_method_param VARCHAR(255),
 IN embryos_collected_by_param VARCHAR(255),
 IN embryo_collection_date_param DATE,
 IN number_of_embryos_collected_param INT(10),
 IN image_param enum('Yes','No'),
 IN phenotype_description_param VARCHAR(255),
 OUT exp_id int(10)
)
BEGIN 

INSERT INTO experiment (
 study_id,
 developmental_stage_id,
 genome_reference_id,
 name,
 lines_crossed,
 founder,
 spike_dilution,
 spike_volume,
 embryo_collection_method,
 embryo_collected_by,
 embryo_collection_date,
 number_embryos_collected,
 image,
 phenotype_description
) 
VALUES ( 
 study_id_param,
 developmental_stage_id_param,
 genome_reference_id_param,
 experiment_name_param,
 lines_crossed_param,
 founder_param,
 spike_dilution_param,
 spike_volume_param,
 embryo_collection_method_param,
 embryos_collected_by_param,
 embryo_collection_date_param,
 number_of_embryos_collected_param,
 image_param,
 phenotype_description_param
);
SET exp_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** Auto add data to array_express_data **/

INSERT INTO array_express_data 
   (id,age,cell_type,compaund,disease,disease_state,dose,
    genotype,growth_condition,immunoprecipitate,
    organism_part,phenotype,time_point,treatment,donor_id) 
VALUES (
    1,"N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A",
    "WholeEmbryo","N/A","N/A","N/A","N/A");
