use utf8;
package Zf1::Result::GenomeReference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::GenomeReference

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

=head1 TABLE: C<genome_reference>

=cut

__PACKAGE__->table("genome_reference");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 species_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 gc_content

  data_type: 'varchar'
  default_value: 'Neutral'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "species_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "gc_content",
  {
    data_type => "varchar",
    default_value => "Neutral",
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
  { "foreign.genome_reference_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<Zf1::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "Zf1::Result::Species",
  { id => "species_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TP2MCwVUh/xI24VMOXH3Ug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
