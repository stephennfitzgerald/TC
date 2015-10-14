1) Set up the database:
 You will need to set the following in your .bashrc file:

export TC_USER=''
export TC_PASS=''
export TC_HOST=''
export TC_PORT=''
export TC_DBNAME=''

 also set the environment variables for access to warehouse, for ENA accession update:

export WH_HOST=''
export WH_PORT=''
export WH_USER=''
export WH_DBNAME=''

 login into the mysql server and create a new database "db_name":
 
 add the tables, views and procedures to the new database:

cd sql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < tables.sql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < views.sql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < procedures.sql
```

 add the pre-existing data to the appropriate tables:

cd ../data
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Alleles/allele.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Developmental_stage/developmental_stage.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Species/species.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Genome_reference/genome_reference.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Index_seqs/index_tag.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Zmp_ontology_term/zmp_ontology_term.mysql
mysql -u$TC_USER -p$TC_PASS -h$TC_HOST -P$TC_PORT -D$TC_DBNAME < Zmp_allele_phenotype_eq/zmp_allele_phenotype_eq.mysql

2). Set the web server running:

cd ..
plackup ./bin/app.psgi -p5000
 
3). Add a new study to the database:
  
  Under 'Update tables' click 'Add a new study'
  
4). Add a new experiment:
  
  Under 'Make a sequencing plate' click 'Add a new experiment'

  You can add one or more experiments and then combine them on a single 'sequencing plate'
  
  Once you have made the 'sequencing plate' you can 'Update a phenotype' and/or 'Add a treatment' etc.

5). You can modify a sequencing plate by removing any number of wells using 'Modify sequencing plate' 
    This can happen due to failed wells at the library making stage (you will need to upload the RNA 
    quantification plate for the library)

6). Finally, make an excel file for submission to the sequencing team using 'Make a sequencing form'.
    You will need the appropriate manifest excel file, with the correct number of sample rows, 
    obtained from the sequencing team

7). A selected view of the entries in the database can be seen in a tabular form by clicking on 
    'View experiments' or in a plate layout form ('View sequencing plates'). The database schema 
    can be downloaded by clicking on 'View the schema'
