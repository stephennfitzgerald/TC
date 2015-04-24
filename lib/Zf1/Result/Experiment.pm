use utf8;
package Zf1::Result::Experiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::Experiment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<experiment>

=cut

__PACKAGE__->table("experiment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 lines_crossed

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 founder

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 developmental_stage_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 image

  data_type: 'enum'
  default_value: 'No'
  extra: {list => ["Yes","No"]}
  is_nullable: 0

=head2 spike_type

  data_type: 'varchar'
  default_value: '1:5000 dilution'
  is_nullable: 0
  size: 255

=head2 spike_volume

  data_type: 'integer'
  is_nullable: 0

=head2 study_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 embryo_collection_method

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 embryo_collected_by

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 embryo_collection_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 number_embryos_collected

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "lines_crossed",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "founder",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "developmental_stage_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "image",
  {
    data_type => "enum",
    default_value => "No",
    extra => { list => ["Yes", "No"] },
    is_nullable => 0,
  },
  "spike_type",
  {
    data_type => "varchar",
    default_value => "1:5000 dilution",
    is_nullable => 0,
    size => 255,
  },
  "spike_volume",
  { data_type => "integer", is_nullable => 0 },
  "study_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "embryo_collection_method",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "embryo_collected_by",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "embryo_collection_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "number_embryos_collected",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 alleles

Type: has_many

Related object: L<Zf1::Result::Allele>

=cut

__PACKAGE__->has_many(
  "alleles",
  "Zf1::Result::Allele",
  { "foreign.experiment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 developmental_stage

Type: belongs_to

Related object: L<Zf1::Result::DevelopmentalStage>

=cut

__PACKAGE__->belongs_to(
  "developmental_stage",
  "Zf1::Result::DevelopmentalStage",
  { id => "developmental_stage_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 samples

Type: has_many

Related object: L<Zf1::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "Zf1::Result::Sample",
  { "foreign.experiment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 study

Type: belongs_to

Related object: L<Zf1::Result::Study>

=cut

__PACKAGE__->belongs_to(
  "study",
  "Zf1::Result::Study",
  { id => "study_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GQMGLmwwwh4w3tlnMTc+/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
