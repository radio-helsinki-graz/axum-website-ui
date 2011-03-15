
package AXUM::Handler::Main;

use strict;
use warnings;
use YAWF ':html';


YAWF::register(
  qr{service} => \&service,
  qr{service/versions} => \&versions,
  qr{service/password} => \&password,
  qr{service/upload} => \&upload,
  qr{service/upload_image} => \&upload_image,
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
   Tr; th 3; td; a href => '/service/password', 'Change password'; end; end;
   Tr; th 4; td; a href => '/service/upload', 'Upload images'; end; end;
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

sub image_block {
  my($n, $x, $y) = @_;
  form action => 'upload_image', method => 'post', enctype => "multipart/form-data";
   table;
    Tr; th "Select file ($n, ${x}x${y})"; end;
    Tr;
     td;
      input type => 'file', accept => 'image/png', size => 60, name => "$n";
     end;
    end;
    Tr;
     td;
      input type => 'submit', value => "Upload $n"; br;
      i '(Requires a surface reboot to be used)';
     end;
    end;
    Tr;
     td;
      txt "Current used $n (resized to ${x}x${y}):";br;
      img src => "/images/$n", alt => "$n", width => "${x}px", height => "${y}px", style => 'border: 1px dashed #C0C0C0';
     end;
    end;
   end;
  end;
}

sub upload {
  my $self = shift;

  $self->htmlHeader(title => $self->OEMFullProductName().' service pages', page => 'service', section => 'upload');
   image_block('logo.png', 256, 150);
   for (1..8)
   {
    br;
    image_block("redlight$_-on.png", 128, 94);
    image_block("redlight$_-off.png", 128, 94);
   }
  $self->htmlFooter;
}

sub upload_image {
  my $self = shift;
  my $f = $self->{_YAWF}->{Req}->{c}->{'CGI::Minimal'};

  if (($f->{field_names}[0] eq 'logo.png') or
      ($f->{field_names}[0] =~ /redlight[1..8]-o[n|ff]/)) {

    my $n = $f->{field_names}[0];
    open(LOGO_FILE, ">/var/lib/axum/skins/meters/$n") or die $!;
    binmode LOGO_FILE;
    print LOGO_FILE @{$f->{field}->{$n}->{value}};
    close LOGO_FILE;
    $self->resRedirect('/service/upload', 'post');
  } else {
     return 404;
  }
}
1;

