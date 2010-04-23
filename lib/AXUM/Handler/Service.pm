
package AXUM::Handler::Main;

use strict;
use warnings;
use YAWF ':html';


YAWF::register(
  qr{service} => \&service,
  qr{service/versions} => \&versions,
  qr{service/password} => \&password,
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
   Tr; th 1; td; a href => '/service/versions?pkg=axum', 'Package versions'; end; end;
   Tr; th 2; td; a href => '#', onclick => "window.location = 'http://'+window.location.host+':6565'", 'Download backup'; end; end;
   Tr; th 3; td; a href => '/service/password', 'Change password'; end; end;
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

sub _password_col {
  my($n, $d) = @_;
  my $v = $d->{$n};

  if (($n eq 'user') or ($n eq 'password')) {
    a href => '#', onclick => sprintf('return conf_text("service/account", %d, "%s", "%s", this, "User", "Save")', $d->{line}, $n, $d->{$n}), $d->{$n};
  }
}

sub password {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'line', template => 'int' },
  );
  my $line = $f->{line};
  $line = 1 if ($line eq '');

  my $user = "";
  my $pass = "";
  open(FILE, '/etc/lighttpd/.lighttpdpassword');
  my @array = <FILE>;

  $array[$line] =~ m/(.*):(.*)/;

  my $account = { line => $line, user => $1, password => $2 };

  close FILE;

  $self->htmlHeader(title => $self->OEMFullProductName().' service pages', page => 'service', section => 'password');
  table;
   Tr; th 'User'; th 'Password'; end;
   Tr;
    td; _password_col 'user', $account; end;
    td; _password_col 'password', $account; end;
   end;
  end;
  $self->htmlFooter;
}

sub set_account {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'item', required => 1, template => 'int' },
    { name => 'field', required => 1, template => 'asciiprint' },
    { name => 'user', required => 0, template => 'asciiprint' },
    { name => 'password', required => 0, template => 'asciiprint' },
  );
  return 404 if $f->{_err};

  my @array;
  open(FILE, '/etc/lighttpd/.lighttpdpassword');
  @array = <FILE>;

  if (defined $f->{user}) {
    $array[$f->{item}] =~ s/^(.*):(.*)/$f->{user}:$2/;
  }
  if (defined $f->{password}) {
    $array[$f->{item}] =~ s/^(.*):(.*)/$1:$f->{password}/;
  }

  my @result = grep(/[^\s]/,@array);
  close FILE;

  open(FILE, '>/etc/lighttpd/.lighttpdpassword');
  print FILE @result;
  close FILE;

  $array[$f->{item}] =~ m/(.*):(.*)/;
  _password_col $f->{field}, { line => $f->{item}, user => $1, password => $2};
}

1;

