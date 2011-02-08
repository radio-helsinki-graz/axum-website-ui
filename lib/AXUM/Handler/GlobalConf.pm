
package AXUM::Handler::GlobalConf;

use strict;
use warnings;
use YAWF ':html';

YAWF::register(
  qr{ipclock} => \&ipclock,
  qr{setdatetime} => \&setdatetime,
  qr{ajax/tz_lst} => \&timezone_lst,
  qr{ajax/set_tz} => \&set_tz,
  qr{ajax/ip} => \&set_ip,
  qr{ajax/ntp} => \&set_ntp,
  qr{ajax/itf} => \&set_itf,
);


sub _col {
  my($n, $v) = @_;
  if ($n =~ /net_(ip|mask|gw|dns)/) {
    a href => '#', onclick => sprintf('return conf_text("ip", 0, "%s", "%s", this)', $n, $v), $v;
  }
  if ($n eq 'ntp_server') {
    $v = "0.0.0.0" if not $v;
    txt "0.pool.ntp.org\n";
    txt "1.pool.ntp.org\n";
    txt "2.pool.ntp.org\n";
    txt "NMEA GPS on USB (/dev/ttyUSB0)\n";
    a href => '#', onclick => sprintf('return conf_text("ntp", 0, "%s", "%s", this)', $n, $v), ($v eq "0.0.0.0" ? ("optional ntp server") : ($v));
  }
  if ($n eq 'timezone') {
    a href => '#', onclick => sprintf('return conf_tz(this)'), $v ? ($v) : ('Select timezone');
  }
  if (($n eq 'udp') or ($n eq 'tcp')) {
    a href => '#', onclick => sprintf('return conf_text("itf", 0, "%s", "%s", this)', $n, $v), $v;
  }
  if ($n eq 'itf') {
    my $itf_names = { 'ETH' => 'Ethernet', 'UDP' => 'UDP/IP', 'TCP' => 'TCP/IP'};
    a href => '#', onclick => sprintf('return conf_select("itf", "1", "%s", "%s", this, "itf_list")', "itf", $v), $itf_names->{$v};
  }
}

sub ipclock
{
  my $self = shift;
  my @array;

  my ($ip, $mask, $gw, $dns);
  open(FILE, '/etc/conf.d/ip');
  @array = <FILE>;
  for my $i (0..$#array)
  {
    $array[$i] =~ m/^net_ip="(.*)"/ ? ($ip = $1) : ();
    $array[$i] =~ m/^net_mask="(.*)"/ ? ($mask = $1) : ();
    $array[$i] =~ m/^net_gw="(.*)"/ ? ($gw = $1) : ();
    $array[$i] =~ m/^net_dns="(.*)"/ ? ($dns = $1) : ();
  }
  close FILE;

  my $tz;
  open(FILE, '/etc/conf.d/timezone');
  @array = <FILE>;
  for my $i (0..$#array)
  {
    $array[$i] =~ m/^user_timezone="(.*)"/;
    $tz = $1;
  }
  close FILE;

  my $ntp_server = "0.0.0.0";
  open(FILE, '/etc/conf.d/ntp');
  @array = <FILE>;
  for my $i (0..$#array)
  {
    $array[$i] =~ m/^server (.*)/;
    $ntp_server = $1;
  }
  close FILE;

  my $sync_url = 'none';
  my $sync_st = '16';
  my $ntpq = `ntpq -pn`;
  my @lines = split "\n", $ntpq;

  for (@lines)
  {
    if ($_ =~ /^\*(\S+)\s+\S+\s+(\d+).*/)
    {
      $sync_url = $1;
      $sync_st = $2;
    }
  }

  open(FILE, '/etc/conf.d/axum-ui.conf');
  @array = <FILE>;
  my $eth = "-";
  my $udp = "-";
  my $tcp = "-";
  my $itf = "ETH";
  for my $i (0..$#array) {
    if ($array[$i] =~ /^ETHARG="-e (eth\d+)"/) {
      $eth = $1;
    }
    if ($array[$i] =~ /^UDPARG="-h ([a-z0-9-.]*)\.([a-z0-9]{2,3})(\:[0-9]{2,5})?"/) {
      $udp  = "$1.$2$3";
      if (not defined $3) {
        $udp .= ":34848";
      }
    }
    if ($array[$i] =~ /^TCPARG="-r ([a-z0-9-.]*)\.([a-z0-9]{2,3})(\:[0-9]{2,5})?"/) {
      $tcp  = "$1.$2$3";
      if (not defined $3) {
        $tcp .= ":34848";
      }
    }
    if ($array[$i] =~ /^ITF=\$(ETH|UDP|TCP)ARG/)
    {
      $itf = $1;
    }
  }
  close FILE;

  my $mac = "-";
  if (`/sbin/ifconfig -a | grep $eth` =~ /HWaddr (.*)/) {
    $mac = $1;
  }

  $self->htmlHeader(page => 'ipclock', section => 'timezonde', title => "Timezone configuration");
  div id => 'itf_list', class => 'hidden';
   Select;
    option value => 'ETH', 'Ethernet';
    option value => 'UDP', 'UDP/IP';
    option value => 'TCP', 'TCP/IP';
   end;
  end;

  table;
   Tr; th colspan => 2, style => 'height: 40px; background: url("/images/table_head_40.png")'; txt "IP\n"; i "(effective after reboot)"; end; end;
   Tr; th "Address"; td; _col 'net_ip', $ip; end; end;
   Tr; th "Subnet mask:"; td; _col 'net_mask', $mask; end; end;
   Tr; th "Gateway"; td; _col 'net_gw', $gw; end; end;
   Tr; th "DNS server"; td; _col 'net_dns', $dns; end; end;
  end;
  br;
  table;
   Tr; th colspan => 2, style => 'height: 40px; background: url("/images/table_head_40.png")'; txt "Pre-configured engine connections\n"; i "(effective after reboot)"; end; end;
   Tr; th ''; th 'Address'; end;
   Tr;
    th 'Ethernet';
    td "$eth - $mac";
   end;
   Tr;
    th 'UDP/IP';
    td; _col 'udp', $udp; end;
    td style => 'text-align: left; background-color: transparent', class => 'empty'; i '<host>:<port>, default port is 34848'; end;
   end;
   Tr;
    th 'TCP/IP';
    td; _col 'tcp', $tcp; end;
    td style => 'text-align: left; background-color: transparent'; i 'e.g. 192.168.0.200:34848'; end;
   end;
   Tr; th colspan => 2, 'Selected interface'; end;
   Tr;
    th 'MambaNet over';
    td;
     _col 'itf', $itf;
    end;
   end;
  end;
  br;
  table;
   Tr; th colspan => 3, style => 'height: 40px; background: url("/images/table_head_40.png")'; txt "Clock\n"; i "(effective after reboot)"; end; end;
   Tr; th rowspan => 2, style => 'height: 40px; background: url("/images/table_head_40.png")', "Current"; td colspan => 2, `date`;
   Tr; td $sync_url; td "stratum: $sync_st"; end;
   Tr; th "time zone"; td colspan => 2; _col 'timezone', $tz; end;
   Tr; th style => 'height: 100px; background: url("/images/table_head_100.png")', "NTP Servers"; td colspan => 2; _col 'ntp_server', $ntp_server; end;
   Tr;
    th "Set date/time";
    td colspan => 2;
     input type=>'Text', name=>'datetime', size=>'25', maxlength=>'25', id=>'datetime', class => 'hidden';
     a href => "javascript: NewCssCal('datetime', 'yyyymmdd','dropdown',true,24,false)";
      img width=>'16', height=>'16', alt=>'Pick a date', src=>'images/cal.gif';
     end;
    end;
   end;
  end;

  $self->htmlFooter;
}

sub timezone_lst {
  my $self = shift;

  my %cnames;

  open(FILE, '/usr/share/zoneinfo/iso3166.tab');
  while (<FILE>) {
    next if /^\#/;
    chomp;
    (my $ccode, my $cname) = split("\t");

    push @{ $cnames{$ccode} }, $cname;
  }

  my %categories;
  my %countries;
  my %localarea;
  my %tzcomment;

  open(FILE, '/usr/share/zoneinfo/zone.tab');
  while (<FILE>) {
    next if /^\#/;
    chomp;
    (my $ccode, undef, my $tz, my $comment) = split("\t");
    (my $cat, my $name, my $place) = split /\//, $tz;

    push(@{ $tzcomment{$tz} }, $comment);

    my $add = 1;
    foreach my $i (@{ $localarea{$name}}) {
      if ($i eq $place) {
        $add = 0;
      }
    }
    push(@{ $localarea{$name} }, $place) if ($add == 1);

    $add = 1;
    foreach my $i (@{ $countries{$ccode}}) {
      if ($i eq $name) {
        $add = 0;
      }
    }
    push(@{ $countries{$ccode} }, $name) if ($add == 1);

    $add = 1;
    foreach my $i (@{ $categories{$cat} }) {
      if ($i eq $ccode) {
       $add = 0;
     }
    }
    push(@{ $categories{$cat} }, $ccode) if ($add == 1);
  }

  my %tz_lst;
  my $cnt_continent = 0;
  for my $c (sort keys %categories )
  {
    foreach my $d (@{$categories{$c}}) {
      foreach my $e (@{$countries{$d}}) {
        foreach my $f (@{$localarea{$e}}) {
          my $tz = "$c/$e";
          my $locationname = "$e";
          if ($f) {
            $locationname .= "/$f";
            $tz .= "/$f";
          }
          my $comment = @{$tzcomment{$tz}}[0];

          if (not $comment)
          {
            my @cats;
            for my $k (sort keys %categories) {
              foreach (@{$categories{$k}}) {
                if ($_ eq $d) {
                  my $new_tz = "$k/$e";
                  if ($f) {
                    $new_tz .= "/$f";
                  }
                  if (not $comment)
                  {
                    $comment = @{$tzcomment{$new_tz}}[0];
                    $tz = $new_tz;
                  }
                }
              }
            }
          }
          if ($comment) {
            $tz_lst{$c}{"@{$cnames{$d}}"}{$comment} = $tz;
          } else {
            $tz_lst{$c}{"@{$cnames{$d}}"}{''} = $tz;
          }
        }
      }
    }
  }

  #make continents and oceans
  div id => 'tz_main';
  Select;
  my $cnt_c = 0;
  for (sort keys %tz_lst)
  {
    option value => $cnt_c, "$_";
    $cnt_c++;
  }
  end;
  end;

  #make countries in continents and oceans
  $cnt_c=0;
  for my $c (sort keys %tz_lst)
  {
    div id => "cont_$cnt_c";
    Select;
    my $cnt_d = 0;
    for (sort keys %{$tz_lst{$c}})
    {
      option value => $cnt_d, "$_";
      $cnt_d++;
    }
    end;
    end;
    $cnt_c++;
  }

  #make local area's
  $cnt_c=0;
  for my $c (sort keys %tz_lst)
  {
    my $cnt_d = 0;
    for my $d (sort keys %{$tz_lst{$c}})
    {
      my $size = keys( %{$tz_lst{$c}{$d}});
      {
        div id => "region_$cnt_c/$cnt_d";
         Select;
         for (sort keys %{$tz_lst{$c}{$d}})
         {
          option value => $tz_lst{$c}{$d}{$_}, "$_";
         }
         end;
        end;
      }
      $cnt_d++;
    }
    $cnt_c++;
  }
}

sub set_tz {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'tz', required => 1, 'asciiprint' },
  );
  return 404 if $f->{_err};

  my @array;
  open(FILE, '/etc/conf.d/timezone');
  @array = <FILE>;
  for my $i (0..$#array)
  {
    $array[$i] =~ s/^user_timezone="(.*)"/user_timezone="$f->{tz}"/;
  }
  my @result = grep(/[^\s]/,@array);
  close FILE;

  open(FILE, '>/etc/conf.d/timezone');
  print FILE @result;
  close FILE;

  _col 'timezone', $f->{tz};
}

sub set_ip {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'field', template => 'asciiprint' },
    { name => 'net_ip', required => 0, regex => [ qr/\b(?:\d{1,3}\.){3}\d{1,3}\b/ ], 0},
    { name => 'net_mask', required => 0, regex => [ qr/\b(?:\d{1,3}\.){3}\d{1,3}\b/ ], 0},
    { name => 'net_gw', required => 0, regex => [ qr/\b(?:\d{1,3}\.){3}\d{1,3}\b/ ], 0},
    { name => 'net_dns', required => 0, regex => [ qr/\b(?:\d{1,3}\.){3}\d{1,3}\b/ ], 0},
  );
  return 404 if $f->{_err};

  my @array;
  open(FILE, '/etc/conf.d/ip');
  @array = <FILE>;
  for my $i (0..$#array) {
    if ($f->{$f->{field}}) {
      $array[$i] =~ s/^$f->{field}="(.*)"/$f->{field}="$f->{$f->{field}}"/;
    }
  }
  my @result = grep(/[^\s]/,@array);
  close FILE;

  open(FILE, '>/etc/conf.d/ip');
  print FILE @result;
  close FILE;

  _col $f->{field}, $f->{$f->{field}};
}

sub set_ntp {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'ntp_server', required => 1, 'url'},
  );
  return 404 if $f->{_err};

  my @array;
  open(FILE, '/etc/conf.d/ntp');
  @array = <FILE>;
  for my $i (0..$#array) {
    $array[$i] =~ s/^server (.*) prefer iburst/server $f->{ntp_server} prefer iburst/;
  }
  my @result = grep(/[^\s]/,@array);
  close FILE;

  open(FILE, '>/etc/conf.d/ntp');
  print FILE @result;
  close FILE;

  _col 'ntp_server', $f->{ntp_server};
}

sub setdatetime {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'date', required => '1', regex => [ qr/\d{4}-\d{2}-\d{2}/ ]},
    { name => 'time', required => '1', regex => [ qr/\d{2}:\d{2}:\d{2}/ ]},
  );
  return 404 if $f->{_err};

  #set date time from here...
  my $cmd = "date -s \"$f->{date} $f->{time}\"";
  my $cmdstdout = `$cmd`;

  $self->resRedirect('/ipclock');
}

sub set_itf {
  my $self = shift;

  my $f = $self->formValidate(
    { name => 'field', required => '1', template => 'asciiprint' },
    { name => 'itf', required => '0', regex => [ qr/(ETH|UDP|TCP)/ ] },
    { name => 'udp', required => '0', regex => [ qr/([a-z0-9-.]*)\.([a-z0-9]{2,3})(\:[0-9]{2,5})?/ ] },
    { name => 'tcp', required => '0', regex => [ qr/([a-z0-9-.]*)\.([a-z0-9]{2,3})(\:[0-9]{2,5})?/ ] },
  );
  return 404 if $f->{_err};

  my @array;
  open(FILE, '/etc/conf.d/axum-ui.conf');
  @array = <FILE>;
  for my $i (0..$#array) {
    $array[$i] =~ s/^ITF=\$(ETH|UDP|TCP)ARG/ITF=\$$f->{itf}ARG/ if defined $f->{itf};
    $array[$i] =~ s/^UDPARG="-h (.*)"/UDPARG="-h $f->{udp}"/ if defined $f->{udp};
    $array[$i] =~ s/^TCPARG="-r (.*)"/TCPARG="-r $f->{tcp}"/ if defined $f->{tcp};
  }
  my @result = grep(/[^\s]/,@array);
  close FILE;

  open(FILE, '>/etc/conf.d/axum-ui.conf');
  print FILE @result;
  close FILE;

   _col $f->{field}, $f->{$f->{field}};
}

1;

