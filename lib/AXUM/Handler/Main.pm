
package AXUM::Handler::Main;

use strict;
use warnings;
use YAWF ':html';


YAWF::register(
  qr{} => \&home,
  qr{password} => \&password,
  qr{upload} => \&upload,
  qr{upload_image} => \&upload_image,
  qr{ajax/account} => \&set_account,
);


sub home {
  my $self = shift;
  my $i = 1;

  $self->htmlHeader(title => $self->OEMFullProductName().' configuration pages', page => 'home');
  table;
   Tr class => 'empty'; th colspan => 2; b, i $self->OEMFullProductName().' configuration'; end; end;
   Tr; th colspan => 2, 'Global configuration'; end;
   Tr; th $i++; td; a href => '/ipclock', 'IP/Clock configuration'; end; end;
   Tr; th $i++; td; a href => '/upload', 'Upload images'; end; end;
   Tr; th $i++; td; a href => '/password', 'Change password'; end; end;
  end;
  $self->htmlFooter;
}

sub _password_col {
  my($n, $d) = @_;
  my $v = $d->{$n};

  if (($n eq 'user') or ($n eq 'password')) {
    a href => '#', onclick => sprintf('return conf_text("account", %d, "%s", "%s", this, "User", "Save")', $d->{line}, $n, $d->{$n}), $d->{$n};
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

  $self->htmlHeader(title => $self->OEMFullProductName().' configuration pages', page => 'password');
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

  $self->htmlHeader(title => $self->OEMFullProductName().' configuration pages', page => 'upload');
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
      ($f->{field_names}[0] =~ /redlight[1-8]-o[n|ff]/)) {

    my $n = $f->{field_names}[0];
    open(LOGO_FILE, ">/var/lib/axum/skins/meters/$n") or die $!;
    binmode LOGO_FILE;
    print LOGO_FILE @{$f->{field}->{$n}->{value}};
    close LOGO_FILE;
    $self->resRedirect('/upload', 'post');
  } else {
     return 404;
  }
}


1;
