use utf8;
package Zf1::Result::RnaExtraction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::RnaExtraction

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

=head1 TABLE: C<rna_extraction>

=cut

__PACKAGE__->table("rna_extraction");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 extracted_by

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 extraction_protocol

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 extraction_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 library_creation_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 library_tube_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "extracted_by",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "extraction_protocol",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "extraction_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "library_creation_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "library_tube_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 rna_dilution_plates

Type: has_many

Related object: L<Zf1::Result::RnaDilutionPlate>

=cut

__PACKAGE__->has_many(
  "rna_dilution_plates",
  "Zf1::Result::RnaDilutionPlate",
  { "foreign.rna_extraction_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aLoLb2pWdSG4JxaJYy5pCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
