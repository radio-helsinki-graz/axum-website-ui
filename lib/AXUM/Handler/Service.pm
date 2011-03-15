
package AXUM::Handler::Main;

use strict;
use warnings;
use YAWF ':html';


YAWF::register(
  qr{service} => \&service,
  qr{service/versions} => \&versions,
  qr{ajax/service} => \&ajax,
  qr{ajax/service/account} => \&set_account,
);

my @mbn_types = ('no data', 'unsigned int', 'signed int', 'state', 'octet string', 'float', 'bit string');
my @func_types = ('Module', 'Buss', 'Monitor buss', 'None', 'Global', 'Source', 'Destination');

sub service {
  my $self = shift;

  $self->htmlHeader(title => $self->OEMFullProductName().' service pages', page => 'service');
  table;
   Tr; th colspan => 2, $self->OEMFullProductName().' service'; end;
   Tr; th 1; td; a href => '/service/versions?pkg='.$self->OEMShortProductName(), 'Package versions'; end; end;
   Tr; th 2; td; a href => '#', onclick => "window.location = 'http://'+window.location.host+':6565'", 'Download backup'; end; end;
  end;
  $self->htmlFooter;
}

sub versions {
  my $self = shift;
  my $f = $self->formValidate(
    { name => 'pkg', template => 'asciiprint' },
  );

  $self->htmlHeader(title => $self->OEMFullProductName().' service pages', page => 'service', section => 'versions');

  my $n = 0;
  my @pkgs;
  my $pkgs = `pacman -Qs $f->{pkg}`;
  my @lines = split "\n", $pkgs;
  my $pkginfo;

  table;
   Tr; th colspan => 5, $self->OEMFullProductName().' Package versions'; end;
   Tr; th 'Package name'; th 'Version'; th 'Build date'; th 'Install date'; end;
   for (@lines) {
     $_ =~ s/^\S+\///g;
     if ($_ =~ /^\s+/) {
     } else {
       Tr;
        $_ =~ /(.*)\s(.*)/;
        $pkginfo = `pacman -Qi $1`;
        $pkginfo =~ /Name\s+:(.*)/;
        td $1;
        $pkginfo =~ /Version\s+:(.*)/;
        td $1;
        $pkginfo =~ /Build Date\s+:(.*)/;
        td $1;
        $pkginfo =~ /Install Date\s+:(.*)/;
        td $1;
       end;
     }
   }
  end;

  $self->htmlFooter;
}

1;

