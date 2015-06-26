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
 period				VARCHAR(255) NOT NULL,
 stage				VARCHAR(255) NOT NULL,
 begins				VARCHAR(255) NOT NULL,
 developmental_landmarks	VARCHAR(255) NOT NULL,

 PRIMARY			KEY(id),
 UNIQUE				KEY(stage)
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
 extracted_by				VARCHAR(255) DEFAULT "Neha" NOT NULL,
 extraction_protocol_version		VARCHAR(255) DEFAULT 'V3' NOT NULL,
 extraction_date			DATE DEFAULT '0000-00-00' NOT NULL,
 library_creation_date			DATE DEFAULT '0000-00-00' NOT NULL,
 library_creation_protocol_version      VARCHAR(255) DEFAULT 'V7.5' NOT NULL,
 library_tube_id			VARCHAR(255) NULL,

 PRIMARY				KEY(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS experiment (

 id					INT(10) AUTO_INCREMENT,
 name					VARCHAR(255) NOT NULL,
 genome_reference_id			INT(10) NOT NULL,
 lines_crossed				VARCHAR(255) NULL,
 founder				VARCHAR(255) NULL,
 strain_name                            VARCHAR(255) DEFAULT "mixed" NOT NULL,
 developmental_stage_id    		INT(10) NOT NULL,
 phenotype_description			VARCHAR(255) NULL,
 dna_source                             VARCHAR(255) DEFAULT 'Whole Genome' NOT NULL,
 image					VARCHAR(255) DEFAULT 'No image' NOT NULL,
 spike_mix				ENUM('0', '1', '2') DEFAULT '0' NOT NULL,
 spike_dilution				VARCHAR(255) NOT NULL DEFAULT 0,
 spike_volume				INT(10) NOT NULL DEFAULT 0,
 study_id				INT(10) NOT NULL, 
 embryo_collection_method		VARCHAR(255) DEFAULT "2ml assay block" NOT NULL,
 embryo_collected_by			VARCHAR(255) DEFAULT "Neha" NOT NULL,
 embryo_collection_date			DATE DEFAULT '0000-00-00' NOT NULL, 
 number_embryos_collected		INT(10) NULL,
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


CREATE TABLE IF NOT EXISTS rna_dilution_plate (

 id					INT(10) NOT NULL AUTO_INCREMENT,
 experiment_id				INT(10) NOT NULL,
 rna_amount				FLOAT NOT NULL,
 rna_volume				FLOAT NOT NULL,
 well_name				VARCHAR(255) NOT NULL,
 cut_off_amount				FLOAT NOT NULL,
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
 excel_report_created_date		DATE NULL,
 excel_report_file_location             VARCHAR(255) NULL,
 well_name				VARCHAR(255) NOT NULL,
 sample_name				VARCHAR(255) NOT NULL,
 sample_public_name			VARCHAR(255) NOT NULL,
 rna_dilution_plate_id			INT(10) NOT NULL,
 index_tag_id                           INT(10) NOT NULL,
 color					VARCHAR(255) NULL,
 

 PRIMARY 				KEY(id),
 UNIQUE 				KEY(plate_name, well_name),
 UNIQUE					KEY(rna_dilution_plate_id), /** allow an experiment to be on ONE sequence plate at most **/ 
 FOREIGN				KEY(index_tag_id) REFERENCES index_tag(id),
 FOREIGN				KEY(rna_dilution_plate_id) REFERENCES rna_dilution_plate(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS genotype (
 
 id					INT(10) NOT NULL AUTO_INCREMENT,
 allele_id				INT(10) NOT NULL,
 rna_dilution_plate_id			INT(10) NOT NULL,
 name					ENUM('Het','Hom','Wildtype','Failed','Missing','Blank'),

 PRIMARY				KEY(id),
 FOREIGN				KEY(allele_id) REFERENCES allele(id),
 FOREIGN				KEY(rna_dilution_plate_id) REFERENCES rna_dilution_plate(id),
 UNIQUE					KEY(allele_id,rna_dilution_plate_id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;

/** views **/

CREATE OR REPLACE VIEW genotAlleleView AS
 SELECT genot.rna_dilution_plate_id rna_well_id, 
        group_concat(alle.name,":", alle.gene_name, ":", genot.name) AlleleGenotype 
 FROM allele alle INNER JOIN genotype genot
        ON genot.allele_id = alle.id 
 GROUP BY genot.rna_dilution_plate_id;

CREATE OR REPLACE VIEW alleleGeneView AS 
 SELECT rdp.experiment_id exp_id, 
        GROUP_CONCAT(DISTINCT(ale.name), ":",ale.gene_name) allele_gene 
 FROM allele ale INNER JOIN genotype geno
      ON geno.allele_id = ale.id INNER JOIN rna_dilution_plate rdp 
      ON rdp.id = geno.rna_dilution_plate_id
 GROUP BY rdp.experiment_id, ale.name;

CREATE OR REPLACE VIEW tagSetView AS        
 SELECT DISTINCT(SUBSTRING_INDEX(name, '.', 1)) tag_set_name
 FROM index_tag
 ORDER BY tag_set_name;

CREATE OR REPLACE VIEW stdView AS
 SELECT name, 
        id
 FROM study
 ORDER BY id DESC;

CREATE OR REPLACE VIEW devView AS
 SELECT period,
        stage,
        begins,
        developmental_landmarks,
        id
 FROM developmental_stage
 ORDER BY id DESC;

CREATE OR REPLACE VIEW spikeView AS 
 SELECT id exp_id, 
        spike_mix, 
        spike_dilution, 
        spike_volume 
 FROM experiment 
 WHERE spike_mix <> '0';

CREATE OR REPLACE VIEW tagSeqView AS
 SELECT id,
        name,
        SUBSTRING_INDEX(name,'.', 1) name_prefix,
        SUBSTRING_INDEX(name,'.', -1) name_postfix,
        tag_index_sequence index_sequence
 FROM index_tag
 ORDER BY id;

CREATE OR REPLACE VIEW seqSampleView AS
 SELECT seq.sample_name Sample_name,
        seq.sample_public_name Sample_public_name,
        seq.well_name Sequence_plate_well,
        rdp.well_name Collection_plate_well, 
        ind.name Index_tag_name,
        ind.tag_index_sequence Index_tag_sequence,
        rdp.rna_amount RNA_amount,
        rdp.rna_volume RNA_volume,
        rdp.cut_off_amount RNA_amount_threshold,
        rdp.experiment_id Experiment_id
 FROM rna_dilution_plate rdp INNER JOIN sequence_plate seq 
        ON seq.rna_dilution_plate_id = rdp.id INNER JOIN index_tag ind
        ON ind.id = seq.index_tag_id
 ORDER BY SUBSTR(Sequence_plate_well,1,1),
        LENGTH(SUBSTR(Sequence_plate_well,2)),
        SUBSTR(Sequence_plate_well,2); 

CREATE OR REPLACE VIEW DevView AS
 SELECT id, 
        GROUP_CONCAT(begins, '  ', stage) time_stage
 FROM developmental_stage 
 GROUP BY id 
 ORDER BY id;

CREATE OR REPLACE VIEW DevInfoView AS
 SELECT exp.id exp_id,
        dev.period,
        dev.stage,
        dev.begins,
        dev.developmental_landmarks
 FROM developmental_stage dev INNER JOIN experiment exp
        ON dev.id = exp.developmental_stage_id;

CREATE OR REPLACE VIEW StdView AS
 SELECT name, id
 FROM study
 ORDER BY id DESC;


CREATE OR REPLACE VIEW ExpStdNameView AS
 SELECT std.name study_name, 
        exp.name exp_name, 
        exp.id exp_id
 FROM study std INNER JOIN experiment exp 
   ON std.id = exp.study_id;


CREATE OR REPLACE VIEW groupAlleleView AS
 SELECT exp.id experiment_id,
        GROUP_CONCAT(DISTINCT(ale.name) SEPARATOR " : ") Alleles
 FROM experiment exp INNER JOIN rna_dilution_plate rdp
   ON exp.id = rdp.experiment_id INNER JOIN genotype gt
   ON gt.rna_dilution_plate_id = rdp.id INNER JOIN allele ale
   ON ale.id = gt.allele_id
 GROUP BY exp.id;


CREATE OR REPLACE VIEW groupDevStageView AS
 SELECT exp.id experiment_id,
        GROUP_CONCAT(dev.begins, " : ", dev.stage) dev_stage
 FROM experiment exp INNER JOIN developmental_stage dev 
   ON exp.developmental_stage_id = dev.id
 GROUP BY exp.id;


CREATE OR REPLACE VIEW SeqReportView AS
 SELECT ind_tag.id "index_tag_id",
        seq.id "seq_plate_id",
        seq.plate_name "seq_plate_name",
        exp.name "zmp_name",
        rna_ext.library_tube_id "Library_Tube_ID",
        exp.id "Experiment_id",
        ind_tag.name "Tag_ID",
        exp.asset_group "Asset_Group",
        seq.sample_name "Sample_Name",
        seq.sample_public_name "Public_Name",
        sp.name "Organism",
        sp.binomial_name "Common_Name",
        exp.sample_visability "Sample_Visability",
        gr.gc_content "GC_Content",
        sp.taxon_id "Taxon_ID",
        exp.strain_name "Strain",
        gav.AlleleGenotype "AlleleGenotype",
        exp.spike_mix "desc_spike_mix",
        ind_tag.tag_index_sequence "desc_tag_index_sequence",
        rdp.gender "Gender",
        exp.dna_source "DNA_Source",
        gr.name "Reference_Genome",
        array_exp.age "Age",
        array_exp.cell_type "Cell_type",
        array_exp.compound "Compound",
        dev.dev_stage "Developmental_Stage",
        array_exp.disease "Disease",
        array_exp.disease_state "Disease_State",
        array_exp.dose "Dose",
        array_exp.genotype "Genotype",
        array_exp.growth_condition "Growth_Condition",
        array_exp.immunoprecipitate "Immunoprecipitate",
        array_exp.organism_part "Organism_Part",
        array_exp.phenotype "Phenotype",
        array_exp.time_point "Time_Point",
        array_exp.treatment "Treatment",
        array_exp.donor_id "Donor_ID"
 FROM experiment exp INNER JOIN array_express_data array_exp 
        ON exp.array_express_data_id = array_exp.id INNER JOIN rna_dilution_plate rdp 
        ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seq 
        ON seq.rna_dilution_plate_id = rdp.id INNER JOIN genome_reference gr
        ON exp.genome_reference_id = gr.id INNER JOIN species sp
        ON gr.species_id = sp.id INNER JOIN index_tag ind_tag
        ON seq.index_tag_id = ind_tag.id INNER JOIN groupDevStageView dev 
        ON dev.experiment_id = exp.id INNER JOIN genotAlleleView gav
        ON gav.rna_well_id = rdp.id LEFT OUTER JOIN rna_extraction rna_ext
        ON exp.rna_extraction_id = rna_ext.id 
 ORDER BY seq.plate_name, exp.id, ind_tag.id;


CREATE OR REPLACE VIEW ExpView AS
 SELECT std.name Study_name, 
        exp.name Experiment_name, 
        ale.Alleles Alleles,
        dev.dev_stage Developmental_stage,
        exp.number_embryos_collected Number_of_embryos_collected,
        exp.embryo_collection_method Embryo_collection_method,
        exp.embryo_collection_date Embryo_collection_date, 
        exp.embryo_collected_by Embryos_collected_by, 
        exp.spike_mix Spike_mix,
        exp.spike_dilution Spike_dilution,
        exp.spike_volume Spike_volume,
        exp.sample_visability Sample_visability,
        grf.name Genome_ref_name,
        rna.extracted_by RNA_extracted_by,
        rna.extraction_protocol_version RNA_extraction_protocol_version,
        rna.extraction_date RNA_extraction_date,
        rna.library_creation_date RNA_library_creation_date,
        rna.library_creation_protocol_version RNA_library_creation_protocol_version,
        exp.image Image, 
        exp.lines_crossed Lines_crossed, 
        exp.founder Founder, 
        exp.phenotype_description Phenotype_description,
        exp.asset_group Asset_group,
        rna.library_tube_id RNA_library_tube_id,
        exp.id Experiment_id
 FROM experiment exp INNER JOIN study std
        ON exp.study_id = std.id INNER JOIN genome_reference grf
        ON grf.id = exp.genome_reference_id INNER JOIN groupDevStageView dev
        ON exp.id = dev.experiment_id INNER JOIN groupAlleleView ale
        ON ale.experiment_id = exp.id LEFT OUTER JOIN rna_extraction rna
        ON exp.rna_extraction_id = rna.id
 GROUP BY std.name, exp.name
 ORDER BY std.name, exp.name;

CREATE OR REPLACE VIEW ExpDisplayView AS
 SELECT std.name Study_name, 
        exp.name Experiment_name, 
        ale.Alleles Alleles,
        dev.dev_stage Developmental_stage,
        exp.number_embryos_collected Number_of_embryos_collected,
        exp.spike_mix Spike_mix,
        exp.sample_visability Sample_visability,
        grf.name Genome_ref_name,
        exp.image Image, 
        exp.phenotype_description Phenotype_description,
        count(rdp.id) Sequenced_samples,
        seqp.excel_report_file_location Excel_file,
        exp.id Experiment_id
 FROM experiment exp INNER JOIN study std
        ON exp.study_id = std.id INNER JOIN genome_reference grf
        ON grf.id = exp.genome_reference_id INNER JOIN groupDevStageView dev
        ON exp.id = dev.experiment_id INNER JOIN groupAlleleView ale
        ON ale.experiment_id = exp.id INNER JOIN rna_dilution_plate rdp
        ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seqp
        ON seqp.rna_dilution_plate_id = rdp.id
 WHERE rdp.selected_for_sequencing = 1
 GROUP BY std.name, exp.name
 ORDER BY exp.id DESC;

CREATE OR REPLACE VIEW SeqExpView AS
 SELECT exp.id exp_id,
        exp.name exp_name,
        std.name std_name,
        ale.Alleles alleles,
        seq_plate.plate_name seq_plate_name,
        count(DISTINCT(rdp.id)) sample_count
 FROM experiment exp INNER JOIN study std 
        ON exp.study_id = std.id INNER JOIN groupAlleleView ale
        ON ale.experiment_id = exp.id INNER JOIN rna_dilution_plate rdp
        ON rdp.experiment_id = exp.id LEFT OUTER JOIN sequence_plate seq_plate
        ON seq_plate.rna_dilution_plate_id = rdp.id
 WHERE rdp.selected_for_sequencing
 GROUP BY exp.id
 ORDER BY exp.id DESC;

CREATE OR REPLACE VIEW SeqWellOrderView AS
 SELECT seqp.plate_name, 
        seqp.well_name seq_well_name, 
        rdp.well_name rna_well_name, 
        exp.name exp_name, 
        std.name std_name,
        seqp.color,
        gav.AlleleGenotype,
        SUBSTRING_INDEX(tag.name, ':', -2) tag_name,
        tag.tag_index_sequence tag_seq,
        SUBSTRING_INDEX(tag.name, '.', 1) tag_set
 FROM sequence_plate seqp INNER JOIN rna_dilution_plate rdp
        ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN experiment exp
        ON rdp.experiment_id = exp.id INNER JOIN study std 
        ON exp.study_id = std.id INNER JOIN genotAlleleView gav
        ON gav.rna_well_id = rdp.id INNER JOIN index_tag tag
        ON seqp.index_tag_id = tag.id
 ORDER BY plate_name; 

CREATE OR REPLACE VIEW RnaDilPlateView AS
 SELECT rdp.id rna_plate_id,
        rdp.well_name,
        rdp.experiment_id,
        exp.name experiment_name,
        std.name study_name
 FROM rna_dilution_plate rdp INNER JOIN experiment exp
        ON exp.id = rdp.experiment_id INNER JOIN study std
        ON std.id = exp.study_id
 WHERE rdp.selected_for_sequencing
 ORDER BY experiment_id, 
        SUBSTR(well_name,1,1), 
        LENGTH(SUBSTR(well_name,2)), 
        SUBSTR(well_name,2);

CREATE OR REPLACE VIEW SelectedExpNumView AS
 SELECT exp.id exp_id, 
        count(*) numb
 FROM experiment exp INNER JOIN rna_dilution_plate rdp 
        ON exp.id = rdp.experiment_id 
 WHERE rdp.selected_for_sequencing 
 GROUP BY exp.id 
 ORDER BY exp.id;
        
CREATE OR REPLACE VIEW MaxExpId AS
 SELECT MAX(id) max_id 
 FROM experiment;

CREATE OR REPLACE VIEW SeqPlateView AS
 SELECT sp.plate_name, 
        sp.excel_report_file_location excel_file_loc, 
        GROUP_CONCAT(DISTINCT(exp.name)) exp_names, 
        GROUP_CONCAT(DISTINCT(std.name)) std_names
 FROM sequence_plate sp INNER JOIN rna_dilution_plate rdp
        ON rdp.id = sp.rna_dilution_plate_id INNER JOIN experiment exp
        ON rdp.experiment_id = exp.id INNER JOIN study std
        ON std.id = exp.study_id 
 GROUP BY sp.plate_name 
 ORDER BY sp.id DESC;

CREATE OR REPLACE VIEW SpView AS
 SELECT sp.id Species_id,
        sp.name Species_name, 
        sp.binomial_name Binomial_name, 
        sp.taxon_id Taxon_id, 
        gr.id Genome_ref_id,
        gr.name Genome_ref_name, 
        gr.gc_content GC_content
 FROM species sp INNER JOIN genome_reference gr  
        ON gr.species_id = sp.id
 ORDER BY Genome_ref_id DESC;

CREATE OR REPLACE VIEW SpeciesView AS
 SELECT sp.id,
        sp.name
 FROM species sp
 ORDER BY id DESC;


CREATE OR REPLACE VIEW LstExpView AS
 SELECT *
 FROM ExpView ev INNER JOIN MaxExpId mei
  ON ev.Experiment_id = mei.max_id;


CREATE OR REPLACE VIEW AlleleView AS
 SELECT * 
 FROM allele;


/** procedures **/

/** genotype **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_genotype_data$$

CREATE PROCEDURE add_genotype_data (
 IN allele_id_param INT(10),
 IN rna_dilution_plate_id_param INT(10),
 IN name_param ENUM('Het','Hom','Wildtype','Failed','Missing','Blank')
)
BEGIN

INSERT IGNORE INTO genotype (
 allele_id,
 rna_dilution_plate_id,
 name
)
VALUES (
 allele_id_param,
 rna_dilution_plate_id_param,
 name_param
);
END$$
DELIMITER ;

/** sequence_plate **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_sequence_plate_data$$

CREATE PROCEDURE add_sequence_plate_data (
 IN plate_name_param VARCHAR(255),
 IN well_name_param VARCHAR(255),
 IN sample_name_param VARCHAR(255),
 IN sample_public_name_param VARCHAR(255),
 IN rna_dilution_plate_id_param INT(10),
 IN index_tag_id_param INT(10),
 IN color_param VARCHAR(255)
)
BEGIN

INSERT IGNORE INTO sequence_plate (
 plate_name,
 well_name,
 sample_name,
 sample_public_name,
 rna_dilution_plate_id,
 index_tag_id,
 color
)
VALUES (
 plate_name_param,
 well_name_param,
 sample_name_param,
 sample_public_name_param,
 rna_dilution_plate_id_param,
 index_tag_id_param,
 color_param
);
END$$
DELIMITER ;


/** rna_dilution_plate **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_rna_dilution_data$$

CREATE PROCEDURE add_rna_dilution_data (
 IN experiment_id_param INT(10),
 IN rna_amount_param FLOAT,
 IN rna_volume_param FLOAT,
 IN well_name_param VARCHAR(255),
 IN cut_off_amount_param FLOAT,
 IN qc_pass_param TINYINT(1),
 IN selected_for_sequencing_param TINYINT(1),
 OUT rna_dilution_plate_id int(10)
)
BEGIN

INSERT INTO rna_dilution_plate (
 experiment_id,
 rna_amount,
 rna_volume,
 well_name,
 cut_off_amount,
 qc_pass,
 selected_for_sequencing
)
VALUES (
 experiment_id_param,
 rna_amount_param,
 rna_volume_param,
 well_name_param,
 cut_off_amount_param,
 qc_pass_param,
 selected_for_sequencing_param
);
SET rna_dilution_plate_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** new study **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_new_study$$

CREATE PROCEDURE add_new_study (
 IN name_param VARCHAR(255),
 OUT study_id INT(10)
)
BEGIN

INSERT INTO study (
 name
)
VALUES (
 name_param
);
SET study_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** new assembly **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_new_assembly$$

CREATE PROCEDURE add_new_assembly (
 IN name_param VARCHAR(255),
 IN species_id_param INT(10),
 IN gc_content_param VARCHAR(255),
 OUT assembly_id INT(10)
)
BEGIN

INSERT INTO genome_reference (
 name,
 species_id,
 gc_content
)
VALUES (
 name_param,
 species_id_param,
 gc_content_param
);
SET assembly_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** new developmental_stage **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_new_devstage$$

CREATE PROCEDURE add_new_devstage (
 IN period_param VARCHAR(255),
 IN stage_param VARCHAR(255),
 IN begins_param VARCHAR(255),
 IN landmarks_param VARCHAR(255),
 OUT dev_id INT(10)
)
BEGIN

INSERT INTO developmental_stage (
 period,
 stage,
 begins,
 developmental_landmarks
)
VALUES (
 period_param,
 stage_param,
 begins_param,
 landmarks_param
);
SET dev_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** rna-extraction **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_rna_extraction_data$$

CREATE PROCEDURE add_rna_extraction_data (
 IN extracted_by_param VARCHAR(255),
 IN extraction_protocol_version_param VARCHAR(255),
 IN extraction_date_param DATE,
 IN library_creation_date_param DATE,
 IN library_creation_protocol_version_param VARCHAR(255),
 IN library_tube_id_param VARCHAR(255),
 OUT rna_ext_id INT(10)
)
BEGIN

INSERT INTO rna_extraction (
 extracted_by,
 extraction_protocol_version,
 extraction_date,
 library_creation_date,
 library_creation_protocol_version,
 library_tube_id
)
VALUES (
 extracted_by_param,
 extraction_protocol_version_param,
 extraction_date_param,
 library_creation_date_param,
 library_creation_protocol_version_param,
 library_tube_id_param
);
SET rna_ext_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** experiment **/
DELIMITER $$
DROP PROCEDURE IF EXISTS add_experiment_data$$
 
CREATE PROCEDURE add_experiment_data (
 IN rna_extraction_id_param INT(10),
 IN image_param VARCHAR(255),
 IN study_id_param INT(10),
 IN genome_reference_id_param INT(10),
 IN experiment_name_param VARCHAR(255),
 IN lines_crossed_param VARCHAR(255),
 IN founder_param VARCHAR(255),
 IN spike_mix_param ENUM('0', '1', '2'), 
 IN spike_dilution_param VARCHAR(255),
 IN spike_volume_param INT(10),
 IN embryo_collection_method_param VARCHAR(255),
 IN embryos_collected_by_param VARCHAR(255),
 IN embryo_collection_date_param DATE,
 IN number_of_embryos_collected_param INT(10),
 IN phenotype_description_param VARCHAR(255),
 IN developmental_stage_id_param INT(10),
 OUT exp_id int(10)
)
BEGIN 

INSERT INTO experiment (
 rna_extraction_id,
 image,
 study_id,
 genome_reference_id,
 name,
 lines_crossed,
 founder,
 spike_mix,
 spike_dilution,
 spike_volume,
 embryo_collection_method,
 embryo_collected_by,
 embryo_collection_date,
 number_embryos_collected,
 phenotype_description,
 developmental_stage_id
) 
VALUES ( 
 rna_extraction_id_param,
 image_param,
 study_id_param,
 genome_reference_id_param,
 experiment_name_param,
 lines_crossed_param,
 founder_param,
 spike_mix_param,
 spike_dilution_param,
 spike_volume_param,
 embryo_collection_method_param,
 embryos_collected_by_param,
 embryo_collection_date_param,
 number_of_embryos_collected_param,
 phenotype_description_param,
 developmental_stage_id_param
);
SET exp_id = LAST_INSERT_ID();
END$$
DELIMITER ;

/** adding excel file location and creation date to sequence_plate **/
DELIMITER $$
DROP PROCEDURE IF EXISTS update_excel_file_location_and_date$$

CREATE PROCEDURE update_excel_file_location_and_date (
 IN excel_report_file_location_param VARCHAR(255),
 IN excel_report_created_date_param DATE,
 IN plate_name_param VARCHAR(255)
)
BEGIN

 UPDATE sequence_plate  SET 
  excel_report_file_location  = excel_report_file_location_param,
  excel_report_created_date = excel_report_created_date_param
 WHERE plate_name = plate_name_param;

END$$
DELIMITER ;


/** Auto add data to array_express_data **/

INSERT INTO array_express_data 
   (id,age,cell_type,compound,disease,disease_state,dose,
    genotype,growth_condition,immunoprecipitate,
    organism_part,phenotype,time_point,treatment,donor_id) 
VALUES (
    1,"N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A","N/A",
    "WholeEmbryo","N/A","N/A","N/A","N/A");
