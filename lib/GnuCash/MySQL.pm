package GnuCash::MySQL;

use 5.018002;
use strict;
use warnings;

use UUID::Tiny ':std';
use DBI;
use DateTime;
use Carp;
use Path::Tiny;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GnuCash::MySQL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

### The module makes the connection to the DB.
### This to me doesn't sound right ... the DB should already be passed opened.

sub new {
	my $class = shift;
	my %attr = @_;
	my $self = {};
	
	### Need to define the DB calls here to Mysql
	croak 'No GnuCash MYSQL Db name defined.' unless defined( $attr{dbname} );
	croak 'No GnuCash MYSQL DB Host defined.' unless defined( $attr{dbhost} );
		
	### Need to add a few checks to the DB
	my $dbi_string = "dbi:mysql:" . $attr{dbname} . ":" . $attr{dbhost};
	
	$self->{db} = $attr{db};
	$self->{dbh} = DBI->connect( $dbi_string, $attr{dbuser}, $attr{dbpass})
									or die "Connection Error: $DBI::errstr\n";
	
	bless $self, $class;
	return $self;
}

# Create a 32-character UUID
sub create_guid {
	my $uuid = create_uuid_as_string(UUID_V1);
	$uuid =~ s/-//g;
	return $uuid;
}

# Given an account name, return the GUID of the currency (aka commodity)
# associated with that account
sub commodity_guid {
	my $self = shift;
	my $account_name = shift;
	my $sql = "SELECT commodity_guid FROM accounts " .
						 "WHERE guid = " .	$self->account_guid_sql($account_name);
	return $self->_runsql($sql)->[0][0];
}

# Given an SQL statement and optionally a list of arguments
# execute the SQL with those arguments
sub _runsql {
	my $self = shift;
	my ($sql,@args) = @_;
	
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute(@args);
	
	my $data = $sth->fetchall_arrayref();
	$sth->finish;
	
	return $data;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

  GnuCash::MySQL - A module to access GnuCash MySQL database

=head1 VERSION

  version 0.01

=head1 SYNOPSIS

  use GnuCash::MySQL;

  # create the book
  
  I need to write some stuff here

=head1 DESCRIPTION

GnuCash::SQLite provides an API to read account balances and write
transactions against a GnuCash set of accounts (only MySQL backend
supported).

When using the module, always provide account names in full e.g. "Assets:Cash"
rather than just "Cash". This lets the module distinguish between accounts
with the same name but different parents e.g. Assets:Misc and
Expenses:Misc

=head1 METHODS

=head2 Constructor

  $book = GnuCash::SQLite->new(db => 'my_account.gnucash');

I have not yet writen the constructor.

Returns a new C<GnuCash::SQLite> object that accesses a GnuCash with and
SQLite backend. The module assumes you have already created a GnuCash file
with an SQLite backend and that is the file that should be passed as the
parameter.

If no file parameter is passed, or if the file is missing, the program will
terminate.

=head2 account_balance

  $book->account_balance('Assets:Cash');   # always provide account names in full
  $book->account_balance('Assets');        # includes child accounts e.g. Assets:Cash

Given an account name, return the balance in the account. Account names must
be provided in full to distinguish between accounts with the same name but
different parents e.g. Assets:Alice:Cash and Assets:Bob:Cash

If a parent account name is provided, the total balance, which includes all
children accounts, will be returned.

=head2 add_transaction

  $deposit = {
      date         => '20140102',
      description  => 'Deposit monthly savings',
      from_account => 'Assets:Cash',
      to_account   => 'Assets:aBank',
      amount       => 2540.15,
      number       => ''
  };
  $book->add_transaction($deposit);

A transaction is defined to have the fields as listed in the example above.
All fields are mandatory and hopefully self-explanatory. Constraints on some
of the fields are listed below:

    date         Date of the transaction. Formatted as YYYYMMDD.
    from_account Full account name required.
    to_account   Full account name required.


=head1 CAVEATS/LIMITATIONS

Some things to be aware of:

    1. You should have created a GnuCash file with an MySQL backend already
    2. Module accesses the GnuCash MySQL db directly; i.e. use at your own risk.
    
    ### At this point nothing had been tested.

This module works with GnuCash v2.6.5 on Linux.

=head1 SEE ALSO

GnuCash wiki pages includes a section on C API and a section on Python
bindings which may be of interest.

    C API          : http://wiki.gnucash.org/wiki/C_API
    Python bindings: http://wiki.gnucash.org/wiki/Python_Bindings

This module was inspired by Hoe Kit CHEW's work.
https://github.com/hoekit/GnuCash-SQLite

This module does not rely on the C API (maybe it should). Instead it relies on
some reverse engineering work to understand the changes a transaction makes
to the sqlite database. See
http://wideopenstudy.blogspot.com/search/label/GnuCash for details.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker at
L<https://github.com/theochino/GnuCash-MySQL/issues>. You will be notified
automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for public
review and contribution under the terms of the license.

    <https://github.com/hoekit/GnuCash-MySQL>

    git clone git@github.com:theochino/GnuCash-MySQL.git

=head1 AUTHOR

Theo CHINO, E<lt>GitPerlModuleGNUCash at theochino.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Theo Chino

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
