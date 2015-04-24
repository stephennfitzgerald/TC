use utf8;
package Zf1::Result::ArrayExpressData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::ArrayExpressData

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

=head1 TABLE: C<array_express_data>

=cut

__PACKAGE__->table("array_express_data");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 age

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 cell_type

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 compaund

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 disease

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 disease_state

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 dose

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 genotype

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 growth_condition

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 immunoprecipitate

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 organism_part

  data_type: 'varchar'
  default_value: 'Whole Embryo'
  is_nullable: 0
  size: 255

=head2 phenotype

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 time_point

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 treatment

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=head2 donor_id

  data_type: 'varchar'
  default_value: 'N/A'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "age",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "cell_type",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "compaund",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "disease",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "disease_state",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "dose",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "genotype",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "growth_condition",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "immunoprecipitate",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "organism_part",
  {
    data_type => "varchar",
    default_value => "Whole Embryo",
    is_nullable => 0,
    size => 255,
  },
  "phenotype",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "time_point",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "treatment",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
  "donor_id",
  {
    data_type => "varchar",
    default_value => "N/A",
    is_nullable => 0,
    size => 255,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 samples

Type: has_many

Related object: L<Zf1::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "Zf1::Result::Sample",
  { "foreign.array_express_data_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R/2Ovqi0Y8AImPhNiCspWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
