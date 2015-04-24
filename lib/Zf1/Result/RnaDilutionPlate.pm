use utf8;
package Zf1::Result::RnaDilutionPlate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Zf1::Result::RnaDilutionPlate

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

=head1 TABLE: C<rna_dilution_plate>

=cut

__PACKAGE__->table("rna_dilution_plate");

=head1 ACCESSORS

=head2 rna_sample_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rna_extraction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 well_number

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 rna_volume

  data_type: 'integer'
  is_nullable: 0

=head2 water_volume

  data_type: 'integer'
  is_nullable: 0

=head2 index_tag_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 index_tag_conc

  data_type: 'integer'
  is_nullable: 0

=head2 ratio_260_280

  data_type: 'float'
  is_nullable: 0

=head2 ratio_260_230

  data_type: 'float'
  is_nullable: 0

=head2 volume_needed_for_250ngs

  data_type: 'integer'
  is_nullable: 0

=head2 dilution_library_made_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 pcr_cycles

  data_type: 'varchar'
  default_value: 'KOD6020'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "rna_sample_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rna_extraction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "well_number",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "rna_volume",
  { data_type => "integer", is_nullable => 0 },
  "water_volume",
  { data_type => "integer", is_nullable => 0 },
  "index_tag_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "index_tag_conc",
  { data_type => "integer", is_nullable => 0 },
  "ratio_260_280",
  { data_type => "float", is_nullable => 0 },
  "ratio_260_230",
  { data_type => "float", is_nullable => 0 },
  "volume_needed_for_250ngs",
  { data_type => "integer", is_nullable => 0 },
  "dilution_library_made_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "pcr_cycles",
  {
    data_type => "varchar",
    default_value => "KOD6020",
    is_nullable => 0,
    size => 255,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</rna_sample_id>

=back

=cut

__PACKAGE__->set_primary_key("rna_sample_id");

=head1 RELATIONS

=head2 index_tag

Type: belongs_to

Related object: L<Zf1::Result::IndexTag>

=cut

__PACKAGE__->belongs_to(
  "index_tag",
  "Zf1::Result::IndexTag",
  { id => "index_tag_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 rna_extraction

Type: belongs_to

Related object: L<Zf1::Result::RnaExtraction>

=cut

__PACKAGE__->belongs_to(
  "rna_extraction",
  "Zf1::Result::RnaExtraction",
  { id => "rna_extraction_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 sample

Type: belongs_to

Related object: L<Zf1::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "Zf1::Result::Sample",
  { id => "sample_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-09 11:44:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FXSEpZo3TuyFmetFMnXGaw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
