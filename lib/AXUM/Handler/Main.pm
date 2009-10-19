
package AXUM::Handler::Main;

use strict;
use warnings;
use YAWF ':html';


YAWF::register(
  qr{} => \&home,
);


sub home {
  my $self = shift;
  my $i = 1;

  $self->htmlHeader(title => $self->OEMFullProductName().' configuration pages', page => 'home');
  table;
   Tr; th colspan => 2, $self->OEMFullProductName().' configuration'; end;
   Tr; th colspan => 2, 'Global configuration'; end;
   Tr; th $i++; td; a href => '/ipclock', 'IP/Clock configuration'; end; end;
  end;
  $self->htmlFooter;
}


1;

