/** views **/

CREATE OR REPLACE VIEW enaView AS
 SELECT rdp.experiment_id exp_id,
        seqp.sample_public_name,
        seqp.ena_accession
 FROM sequence_plate seqp INNER JOIN rna_dilution_plate rdp
 ON seqp.rna_dilution_plate_id = rdp.id
 WHERE seqp.selected = 1
 ORDER BY rdp.experiment_id, seqp.id;

CREATE OR REPLACE VIEW alleleView AS
 SELECT ale.id allele_id,
        ale.name allele_name,
        ale.snp_id,
        group_concat(DISTINCT(ale.gene_name) SEPARATOR ' :: ') gene_name
 FROM allele ale 
 GROUP BY allele_id
 ORDER BY allele_id DESC;

CREATE OR REPLACE VIEW treatmentView AS
 SELECT rdp.experiment_id,
        seqp.id well_id,
        seqp.well_name,
        GROUP_CONCAT(DISTINCT(seqp.phenotype)) phenotypes,
        GROUP_CONCAT(DISTINCT(gt.name)) genotypes,
        GROUP_CONCAT(DISTINCT(av.allele_name)) allele_names,
        GROUP_CONCAT(DISTINCT(av.gene_name)) gene_names,
        GROUP_CONCAT(tm.treatment_type SEPARATOR ', ') treatment_types,
        GROUP_CONCAT(tm.treatment_description SEPARATOR ' ') treatment_descriptions
 FROM sequence_plate seqp INNER JOIN rna_dilution_plate rdp 
 ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN genotype gt
 ON gt.rna_dilution_plate_id = rdp.id INNER JOIN alleleView av
 ON av.allele_id = gt.allele_id LEFT OUTER JOIN treatment tm
 ON seqp.id = tm.sequence_plate_id
 WHERE seqp.selected = 1
 GROUP BY rdp.experiment_id, seqp.id
 ORDER BY SUBSTR(seqp.well_name,1,1),
          LENGTH(SUBSTR(seqp.well_name,2)),
          SUBSTR(seqp.well_name,2);  

CREATE OR REPLACE VIEW ontologyTermsView AS
 SELECT exp.id exp_id,
        exp.name experiment_name,
        std.name study_name,
        seqp.sample_public_name, 
        seqp.phenotype,
        dev.zfs_id stage, 
        zap.tag tag, 
        zap.quality quality, 
        zap.entity1 entity 
 FROM experiment exp inner join study std 
 ON exp.study_id = std.id INNER JOIN rna_dilution_plate rdp 
 ON exp.id = rdp.experiment_id INNER JOIN sequence_plate seqp
 ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN genotype gt  
 ON gt.rna_dilution_plate_id = rdp.id INNER JOIN allele alle 
 ON gt.allele_id = alle.id INNER JOIN zmp_allele_phenotype_eq zap 
 ON zap.allele_id = alle.id INNER JOIN developmental_stage dev 
 ON dev.zfs_id = zap.stage 
 WHERE seqp.selected = 1
 ORDER BY exp_id DESC;

CREATE OR REPLACE VIEW phenoCountView AS
 SELECT exp.id, 
        seq.phenotype, 
        count(*) pheno_count 
 FROM experiment exp INNER JOIN rna_dilution_plate rdp 
 ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seq 
 ON seq.rna_dilution_plate_id = rdp.id 
 WHERE seq.selected = 1
 GROUP BY exp.id, seq.phenotype 
 ORDER BY exp.id, seq.phenotype;

CREATE OR REPLACE VIEW alleleOntologyView AS
 SELECT zap.id zap_id,
        alle.id allele_id,
        alle.name allele_name, 
        alle.snp_id snp_id, 
        avw.gene_name gene_name,
        zap.stage stage,
        zap.entity1 entity1,
        zap.entity2 entity2,
        zap.quality quality,
        zap.tag tag
 FROM allele alle LEFT OUTER JOIN zmp_allele_phenotype_eq zap   
 ON alle.id = zap.allele_id INNER JOIN alleleView avw 
 ON alle.id = avw.allele_id
 ORDER BY alle.snp_id;

CREATE OR REPLACE VIEW genotAlleleView AS
 SELECT genot.rna_dilution_plate_id rna_well_id, 
        group_concat(alle.name, '(', genot.name, ')') AlleleGenotype 
 FROM allele alle INNER JOIN genotype genot
        ON genot.allele_id = alle.id 
 GROUP BY genot.rna_dilution_plate_id;

CREATE OR REPLACE VIEW phenoView AS
 SELECT exp.id exp_id, 
        seqp.id seqp_id,
        exp.name exp_name, 
        std.name study_name, 
        seqp.well_name, 
        gav.AlleleGenotype genotype, 
        seqp.phenotype 
 FROM experiment exp INNER JOIN study std 
 ON exp.study_id = std.id INNER JOIN rna_dilution_plate rdp 
 ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seqp 
 ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN genotAlleleView gav 
 ON gav.rna_well_id = rdp.id 
 WHERE seqp.selected = 1
 ORDER BY SUBSTR(seqp.well_name,1,1),
          LENGTH(SUBSTR(seqp.well_name,2)),
          SUBSTR(seqp.well_name,2);  

CREATE OR REPLACE VIEW libSampleIdView AS 
 SELECT exp.id exp_id, seqp.id seq_id
 FROM experiment exp INNER JOIN rna_dilution_plate rdp
 ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seqp
 ON seqp.rna_dilution_plate_id = rdp.id; 

CREATE OR REPLACE VIEW libSamplesView AS
 SELECT exp.id exp_id, 
        seqp.id seq_id,
        seqp.well_name well_id, 
        seqp.sample_name sample_name, 
        tag.tag_index_sequence index_sequence, 
        seqp.library_volume 'library_volume', 
        seqp.library_amount 'library_conc (ug/ul)', 
        seqp.library_qc, 
        std.name study_name, 
        exp.name exp_name, 
        genot.AlleleGenotype genotypes,
        seqp.selected
 FROM experiment exp INNER JOIN study std 
 ON exp.study_id = std.id INNER JOIN rna_dilution_plate rdp 
 ON rdp.experiment_id = exp.id INNER JOIN genotAlleleView genot 
 ON genot.rna_well_id = rdp.id INNER JOIN sequence_plate seqp 
 ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN index_tag tag 
 ON tag.id = seqp.index_tag_id
 ORDER BY SUBSTR(well_id,1,1),
          LENGTH(SUBSTR(well_id,2)),
          SUBSTR(well_id,2); 

CREATE OR REPLACE VIEW expAlleGeno AS
 SELECT DISTINCT(CONCAT_WS('::', exp.id, alle.name, gt.name)) exp_alle_geno 
 FROM experiment exp INNER JOIN rna_dilution_plate rdp 
 ON rdp.experiment_id = exp.id INNER JOIN genotype gt 
 ON gt.rna_dilution_plate_id = rdp.id INNER JOIN sequence_plate sp 
 ON sp.rna_dilution_plate_id = rdp.id INNER JOIN allele alle 
 ON alle.id = gt.allele_id;

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
        zfs_id,
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
 SELECT seq.selected Selected_for_sequencing,
        seq.sample_name Sample_name,
        seq.sample_public_name Sample_public_name,
        seq.sanger_plate_id Sanger_plate_id,
        seq.sanger_sample_id Sanger_sample_id,
        seq.well_name Sequence_plate_well,
        rdp.well_name Collection_plate_well, 
        ind.name Index_tag_name,
        ind.tag_index_sequence Index_tag_sequence,
        rdp.rna_amount "RNA_amount (ng/ul)",
        ROUND(rdp.cut_off_amount / rdp.rna_amount) "RNA_volume (ul)",
        exp.spike_volume "Spike_volume (ul)",
        seq.water_volume "Water_volume (ul)",
        rdp.final_sample_volume "Final_sample_volume (ul)",
        rdp.cut_off_amount "Required_RNA_amount (ng)",
        rdp.experiment_id Experiment_id
 FROM rna_dilution_plate rdp INNER JOIN sequence_plate seq 
        ON seq.rna_dilution_plate_id = rdp.id INNER JOIN index_tag ind
        ON ind.id = seq.index_tag_id INNER JOIN experiment exp 
        ON exp.id = rdp.experiment_id
 ORDER BY SUBSTR(Sequence_plate_well,1,1),
        LENGTH(SUBSTR(Sequence_plate_well,2)),
        SUBSTR(Sequence_plate_well,2); 

CREATE OR REPLACE VIEW DevView AS
 SELECT id, 
        GROUP_CONCAT(begins, '  ', stage, '  ',zfs_id) time_stage
 FROM developmental_stage 
 GROUP BY id 
 ORDER BY id;

CREATE OR REPLACE VIEW DevInfoView AS
 SELECT exp.id exp_id,
        dev.period,
        dev.stage,
        dev.begins,
        dev.developmental_landmarks,
        dev.zfs_id
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
   ON std.id = exp.study_id
 ORDER BY exp_id DESC;

CREATE OR REPLACE VIEW ImageView AS
 SELECT std.name study_name,
        exp.name exp_name,
        exp.id exp_id,
        exp.image image
 FROM study std INNER JOIN experiment exp
   ON std.id = exp.study_id
 ORDER BY exp_id DESC;

CREATE OR REPLACE VIEW CheckAlleles AS 
 SELECT name 
 FROM allele
 ORDER BY name;

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
        GROUP_CONCAT(dev.begins, " : ", dev.stage, " : ", zfs_id) dev_stage
 FROM experiment exp INNER JOIN developmental_stage dev 
   ON exp.developmental_stage_id = dev.id
 GROUP BY exp.id;

CREATE OR REPLACE VIEW SeqReportView AS
 SELECT ind_tag.id "index_tag_id",
        seq.id "seq_plate_id",
        seq.plate_name "seq_plate_name",
        exp.name "zmp_name",
        rna_ext.library_tube_id "Library_Tube_ID",
        seq.well_name "Well",
        seq.library_volume "Sample_Volume",
        seq.library_amount "Sample_Conc",
        EXTRACT(YEAR FROM exp.embryo_collection_date) "Embryo_Collection_Date",
        EXTRACT(YEAR FROM rna_ext.extraction_date) "RNA_Extraction_Date",
        exp.id "Experiment_id",
        ind_tag.name "Tag_ID",
        seq.sample_name "Sample_Name",
        seq.sample_public_name "Public_Name",
        sp.name "Organism",
        sp.binomial_name "Common_Name",
        exp.sample_visibility "Sample_Visibility",
        gr.gc_content "GC_Content",
        sp.taxon_id "Taxon_ID",
        exp.strain_name "Strain",
        gav.AlleleGenotype "AlleleGenotype",
        exp.spike_mix "desc_spike_mix",
        ind_tag.tag_index_sequence "desc_tag_index_sequence",
        rdp.gender "Gender",
        exp.dna_source "DNA_Source",
        exp.collection_description "Collection_Description",
        gr.name "Reference_Genome",
        array_exp.cell_type "Cell_type",
        array_exp.compound "Compound",
        dev.dev_stage "Developmental_Stage",
        REPLACE(dev_s.begins, "_", " ") "Age",
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
        array_exp.donor_id "Donor_ID",
        exp.description 'experiment_description'
 FROM experiment exp INNER JOIN array_express_data array_exp 
        ON exp.array_express_data_id = array_exp.id INNER JOIN rna_dilution_plate rdp 
        ON rdp.experiment_id = exp.id INNER JOIN sequence_plate seq 
        ON seq.rna_dilution_plate_id = rdp.id INNER JOIN genome_reference gr
        ON exp.genome_reference_id = gr.id INNER JOIN species sp
        ON gr.species_id = sp.id INNER JOIN index_tag ind_tag
        ON seq.index_tag_id = ind_tag.id INNER JOIN groupDevStageView dev 
        ON dev.experiment_id = exp.id INNER JOIN genotAlleleView gav
        ON gav.rna_well_id = rdp.id LEFT OUTER JOIN rna_extraction rna_ext
        ON exp.rna_extraction_id = rna_ext.id INNER JOIN developmental_stage dev_s
        ON dev_s.id = exp.developmental_stage_id 
 WHERE seq.selected = 1
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
        exp.sample_visibility Sample_visibility,
        grf.name Genome_ref_name,
        rna.extracted_by RNA_extracted_by,
        rna.extraction_protocol_version RNA_extraction_protocol_version,
        rna.extraction_date RNA_extraction_date,
        rna.library_creation_date RNA_library_creation_date,
        rna.library_creation_protocol_version RNA_library_creation_protocol_version,
        exp.collection_description Collection_description,
        exp.image Image, 
        exp.lines_crossed Lines_crossed, 
        exp.founder Founder, 
        rna.library_tube_id RNA_library_tube_id,
        exp.description Experiment_description,
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
        exp.embryo_collection_date Embryo_collection_date,
        exp.spike_mix Spike_mix,
        exp.sample_visibility Sample_visibility,
        grf.name Genome_ref_name,
        exp.image Image, 
        exp.collection_description Collection_description,
        count(rdp.id) Sequenced_samples,
        seqp.excel_report_created_date Excel_file_creation_date,
        seqp.excel_report_file_location Excel_file,
        exp.description Experiment_description,
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
        SUBSTRING_INDEX(tag.name, '.', 1) tag_set,
        seqp.sample_volume,
        seqp.water_volume,
        exp.spike_volume,
        seqp.sample_amount,
        seqp.selected
 FROM sequence_plate seqp INNER JOIN rna_dilution_plate rdp
        ON seqp.rna_dilution_plate_id = rdp.id INNER JOIN experiment exp
        ON rdp.experiment_id = exp.id INNER JOIN study std 
        ON exp.study_id = std.id INNER JOIN genotAlleleView gav
        ON gav.rna_well_id = rdp.id INNER JOIN index_tag tag
        ON seqp.index_tag_id = tag.id
 ORDER BY plate_name; 

CREATE OR REPLACE VIEW RnaDilPlateView AS
 SELECT rdp.id rna_plate_id,
        rdp.well_name rdp_well_name,
        rdp.experiment_id,
        exp.name experiment_name,
        std.name study_name,
        rdp.cut_off_amount min_rna_amount,
        rdp.rna_volume,
        rdp.rna_amount,
        rdp.final_sample_volume,
        exp.spike_volume
 FROM rna_dilution_plate rdp INNER JOIN experiment exp
        ON exp.id = rdp.experiment_id INNER JOIN study std
        ON std.id = exp.study_id 
 WHERE rdp.selected_for_sequencing
 ORDER BY experiment_id, 
        SUBSTR(rdp_well_name,1,1), 
        LENGTH(SUBSTR(rdp_well_name,2)), 
        SUBSTR(rdp_well_name,2);

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

CREATE OR REPLACE VIEW ExpStdy AS 
 SELECT std.name study_name,
        std.id study_id,
        exp.name exp_name
 FROM study std INNER JOIN experiment exp 
        ON exp.study_id = std.id
  ORDER BY std.name;

CREATE OR REPLACE VIEW AlleleGeneView AS
 SELECT id, name, GROUP_CONCAT(gene_name SEPARATOR '::') gene_name
 FROM allele GROUP BY name 
 ORDER BY name;

CREATE OR REPLACE VIEW AlleleExperimentView AS
 SELECT std.name study_name, 
        exp.name exp_name, 
        gr.name genome_ref, 
        alle.name allele_name, 
        alle_gene.gene_name gene_name,
        alle.snp_id location,
        dev.zfs_id stage_id
  FROM study std INNER JOIN experiment exp
  ON exp.study_id = std.id INNER JOIN genome_reference gr
  ON exp.genome_reference_id = gr.id INNER JOIN rna_dilution_plate rdp
  ON rdp.experiment_id = exp.id INNER JOIN genotype gt
  ON gt.rna_dilution_plate_id = rdp.id INNER JOIN allele alle 
  ON gt.allele_id = alle.id INNER JOIN AlleleGeneView alle_gene
  ON alle_gene.id = alle.id INNER JOIN developmental_stage dev 
  ON dev.id = exp.developmental_stage_id LEFT OUTER JOIN zmp_allele_phenotype_eq zape
  ON alle.id = zape.allele_id 
  WHERE zape.allele_id IS NULL
  GROUP BY std.name, exp.name, alle.name
  ORDER BY exp.id DESC;


/** experiment ids to delete **/
CREATE OR REPLACE VIEW expsToDelete AS
 SELECT exp.id exp_id 
 FROM experiment exp LEFT OUTER JOIN rna_extraction rna_ext
   ON rna_ext.id = exp.rna_extraction_id LEFT OUTER JOIN rna_dilution_plate rdp 
   ON rdp.experiment_id = exp.id 
 GROUP BY exp.id
 HAVING COUNT(rdp.id) = 0;

