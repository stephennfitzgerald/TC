use utf8;
package Zf1::Result::Species;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::Species

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

=head1 TABLE: C<species>

=cut

__PACKAGE__->table("species");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: 'zebrafish'
  is_nullable: 0
  size: 255

=head2 binomial_name

  data_type: 'varchar'
  default_value: 'Danio rerio'
  is_nullable: 0
  size: 255

=head2 taxon_id

  data_type: 'integer'
  default_value: 7955
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  {
    data_type => "varchar",
    default_value => "zebrafish",
    is_nullable => 0,
    size => 255,
  },
  "binomial_name",
  {
    data_type => "varchar",
    default_value => "Danio rerio",
    is_nullable => 0,
    size => 255,
  },
  "taxon_id",
  { data_type => "integer", default_value => 7955, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 genome_references

Type: has_many

Related object: L<Zf1::Result::GenomeReference>

=cut

__PACKAGE__->has_many(
  "genome_references",
  "Zf1::Result::GenomeReference",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cn9z8P1DREcOSV4nRqmlDw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
