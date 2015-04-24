use utf8;
package Zf1::Result::Sample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::Sample

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

=head1 TABLE: C<sample>

=cut

__PACKAGE__->table("sample");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 visability

  data_type: 'enum'
  default_value: 'Public'
  extra: {list => ["Hold","Public"]}
  is_nullable: 0

=head2 public_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 embryo_collection_well_number

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genome_reference_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype

  data_type: 'enum'
  extra: {list => ["Wild Type","Het","Mutant"]}
  is_nullable: 0

=head2 strain_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 gender

  data_type: 'varchar'
  default_value: 'Unknown'
  is_nullable: 0
  size: 255

=head2 dna_source

  data_type: 'varchar'
  default_value: 'Whole Genome'
  is_nullable: 0
  size: 255

=head2 submitted_for_sequencing

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 asset_group

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 array_express_data_id

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "visability",
  {
    data_type => "enum",
    default_value => "Public",
    extra => { list => ["Hold", "Public"] },
    is_nullable => 0,
  },
  "public_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "embryo_collection_well_number",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genome_reference_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype",
  {
    data_type => "enum",
    extra => { list => ["Wild Type", "Het", "Mutant"] },
    is_nullable => 0,
  },
  "strain_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "gender",
  {
    data_type => "varchar",
    default_value => "Unknown",
    is_nullable => 0,
    size => 255,
  },
  "dna_source",
  {
    data_type => "varchar",
    default_value => "Whole Genome",
    is_nullable => 0,
    size => 255,
  },
  "submitted_for_sequencing",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "asset_group",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "array_express_data_id",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head2 C<public_name>

=over 4

=item * L</public_name>

=back

=cut

__PACKAGE__->add_unique_constraint("public_name", ["public_name"]);

=head1 RELATIONS

=head2 array_express_data

Type: belongs_to

Related object: L<Zf1::Result::ArrayExpressData>

=cut

__PACKAGE__->belongs_to(
  "array_express_data",
  "Zf1::Result::ArrayExpressData",
  { id => "array_express_data_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 experiment

Type: belongs_to

Related object: L<Zf1::Result::Experiment>

=cut

__PACKAGE__->belongs_to(
  "experiment",
  "Zf1::Result::Experiment",
  { id => "experiment_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 genome_reference

Type: belongs_to

Related object: L<Zf1::Result::GenomeReference>

=cut

__PACKAGE__->belongs_to(
  "genome_reference",
  "Zf1::Result::GenomeReference",
  { id => "genome_reference_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 rna_dilution_plates

Type: has_many

Related object: L<Zf1::Result::RnaDilutionPlate>

=cut

__PACKAGE__->has_many(
  "rna_dilution_plates",
  "Zf1::Result::RnaDilutionPlate",
  { "foreign.sample_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k7nUmB0QwKFtGdSAtB/Q2Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
