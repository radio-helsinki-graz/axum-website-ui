
package AXUM::Util::HTML;

use strict;
use warnings;
use YAWF ':html';
use Exporter 'import';

our @EXPORT = qw| htmlHeader htmlFooter OEMFullProductName OEMShortProductName |;


sub htmlHeader {
  my($self, %o) = @_;
  html;
   head;
    title $o{title};
    Link href => '/style.css', rel => 'stylesheet', type => 'text/css';
    script type => 'text/javascript', src => '/scripts.js', ' ';
    script type => 'text/javascript', src => '/datetimepicker_css.js', ' ';
   end;
   body;
    div id => $_, '' for (qw| header header_left header_right border_left border_right
      footer footer_left footer_right hinge_top hinge_bottom|);
    div id => 'loading', 'Saving changes, please wait...';

    div id => 'navigate';
     a href => '/', OEMFullProductName();
     lit " &raquo; ";
     a href => '/', 'Main menu' if $o{page} eq 'home';
     a href => '/ipclock', 'IP/Clock configuration' if $o{page} eq 'ipclock';
     a href => '/ipclock', 'Upload images' if $o{page} eq 'upload';
     a href => '/ipclock', 'Set account' if $o{page} eq 'password';
     a href => '/service', 'Service' if $o{page} eq 'service';
    end;
    div id => 'content';
}


sub htmlFooter {
    end; # /div content
   end; # /body
  end; # /html
}

sub OEMFullProductName {
  open my $F, "/var/lib/axum/OEMFullProductName" or die "Couldn't open file /var/lib/axum/OEMFullProductName: $!";
  my $n =  <$F>;
  close FILE;
  $n =~ s/\s+$//;
  return $n;
}

sub OEMShortProductName {
  open my $F, "/var/lib/axum/OEMShortProductName" or die "Couldn't open file /var/lib/axum/OEMFullProductName: $!";
  my $n =  <$F>;
  close FILE;
  $n =~ s/\s+$//;
  return $n;
}


1;
