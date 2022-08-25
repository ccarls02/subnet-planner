#!/usr/bin/perl

&print_header;
@subnet_list;
our $supernetcidr;
our $supernetaddy;
our $addypointer;
our $cidrpointer;

 
while (1) {
  ## first get supernet block:
  $supernet = &prompt("Enter Supernet/cidr: ");
  my $goodsupernet = &validate_ipcidr($supernet);

  if ($goodsupernet) { 
	print "\n\n ** Using Supernet: $supernet ** \n\n";
	last;	
  } else { print "\n\n ** Bad Supernet entered: $supernet **\n\n"; }

}


do{
   $hostnumber = &prompt("Enter the number of hosts for a subnet in this block: ");
   ## add net/broadcast addys
   $posthostnumber = $hostnumber + 2;
   push @subnet_list, $posthostnumber;
}while( $hostnumber && $hostnumber =~ /\d+/ );


system("clear");

print "\n\n ** Using Supernet: $supernet ** \n\n";

pop @subnet_list;

@sorted_list = sort { $b <=> $a } @subnet_list;

my $ctr=1;
for (@sorted_list) {

  ($sizeneeded,$lcidr) = find_subsize($_);

  $networkbitsavail = 32 - $cidrpointer;
  $netbitsneeded = $networkbitsavail - $lcidr;
  $supernetbitsleft = 32 - $cidrpointer; 
  print "\n";
  print "Subnet $ctr:\n";
  print "  hosts requested: ". ($_ -2) . " | block size: $sizeneeded | " . 2**$lcidr . "-2 hosts available\n";
  printf("%30s%s\n","  host bits needed: ",$lcidr);
  if ($lcidr > ($networkbitsavail-1)) { 
	print "** subnet too large/no network bits available **\n"; 
	printf("%30s%s\n","  host bits needed: ",$lcidr);
	printf("%30s%s\n","remaining bits for network: ",$netbitsneeded);
	}
  else {
  printf("%30s%s\n","  supernet bits left: ",$supernetbitsleft);
  printf("%30s%s\n","  subnet bits available: ",$networkbitsavail);
  printf("%30s%s\n","  host bits needed: ", $lcidr);
  printf("%30s%s%s\n","  remaining bits for network: ",$netbitsneeded,"(" . 2**$netbitsneeded . " subnets this size available)");
 
  $binz = &decip2binip($addypointer);
  #$binzsubnet = substr($binz,$supernetcidr,$netbitsneeded);
  #substr($binz,$supernetcidr+$netbitsneeded,0) = "|  ";
  #substr($binz,$supernetcidr,0) = "  |";
  printf("%30s%s\n","subnet: ",$addypointer);
  printf("%30s%s\n","bin: ", $binz); 
  printf("%30s%s%s\n",("","X" x $supernetcidr),("^" x $netbitsneeded));
  printf("%30s%s\n","subnet substr: ",substr($binz,$cidrpointer,$netbitsneeded));
  $ctr++;

## get next network
  &get_next_network($netbitsneeded);
  }
  print "\n\n";
  $ctr++;

  }


exit;

##############################
##
sub increment_binary {
$inbin = shift;
$carry = 1;
@binarr = split //, $inbin;

for ($i=$#binarr; $i>=0;$i--) {

	if ($binarr[$i] == 0) { 
	  if ($carry) {
		$binarr[$i] = 1; 
		$carry = 0;
		}
	  else { } #pass
		}
	elsif ($binarr[$i] == 1) { 
	  if ($carry) {
		$binarr[$i] = 0;
		$carry = 1;
		}
		}
	  else { } #pass
	}
$sran = join "", @binarr;
return $sran;
}
################################
##
sub decip2binip {
  my $inip = shift;
  @sip = split /\./, $inip;
#  for (@sip) { $retval .= dec2bin($_) . " "; }
   for (@sip) { $retval .= dec2bin($_);}
  return $retval;
}
###################################
sub get_next_network {
my $netbits = shift;
my $nextnet = $netbits + $cidrpointer;
print "next network is $addypointer / $nextnet\n";

(my $subnetdec,my $wilddec) = cidr2dec($nextnet);
print "\n";
printf("%20s%s\n"," /$subnet Subnet Mask: ",$subnetdec);
printf("%20s%s\n\n"," Wildcard Mask: ",$wilddec);
print "\n\n";
fullsubnetinfo($addypointer,$nextnet);
$cidrpointer = $nextnet;
}
################################
##  subnet cidr to dec

sub cidr2dec {

my $cidr = shift;

my $binsub = ("1" x $cidr);
my $padlen = 32 - length($binsub);
my $rightpad =  "0" x $padlen;

my $subnetdec = &bin2ip("$binsub$rightpad");

my $wcsub = ("0" x $cidr);
my $wcpad = "1" x $padlen;
my $wildcarddec = &bin2ip("$wcsub$wcpad");
return $subnetdec,$wildcarddec;
}
#############################################
## input: binary IP
## output: decimal IP

sub bin2ip {

my $bin = shift;

my $boct1 = substr($bin,0,8);
my $boct2 = substr($bin,8,8);
my $boct3 = substr($bin,16,8);
my $boct4 = substr($bin,24,8,);

return oct("0b".$boct1) . "." . oct("0b".$boct2)  . "." . oct("0b".$boct3)  . "." . oct("0b".$boct4);
}
####################################
sub find_subsize {
my $target = shift;
for (my $i=0;$i<32;$i++) {
	my $retval = 2**$i;
	if ($target <= $retval) { return $retval,$i; }	
	}

}
#########################################
sub prompt {
my $prompt = shift;
print "$prompt";
$retval =  <STDIN>;
chomp $retval;
return $retval;
}

###########################################
sub validate_ipcidr {
my $ipin = shift;
$ipin =~ m{(\d+)\.(\d+)\.(\d+)\.(\d+)(\/)(\d+)};
my $oct1 = $1;
my $oct2 = $2;
my $oct3 = $3;
my $oct4 = $4;
my $cslash = $5;

$supernetcidr = $6;
$cidrpointer = $supernetcidr;

$supernetaddy ="$oct1.$oct2.$oct3.$oct4";
$addypointer = $supernetaddy;

if (!$supernetcidr) { return 0; }
if ($supernetcidr < 1 || $supernetcidr > 32) {return 0; }
if ($cslash ne "/") { return 0; }

push(my @octs, ($oct1, $oct2, $oct3,$oct4));

foreach (my $i=0;$i<4;$i++) {
  if ($octs[$i] < 0 || $octs[$i] > 255) {return 0; }
  if ($octs[$i] eq "") { return 0; }
}
return 1;
}
#####################################
sub print_header {
print <<COUT;


 ** Supernet/Subnet Calculator **

        1. enter the Supernet/cidr  (i.e. 192.168.1.1/24)
        2. enter the separate subnets by the number of required hosts
        3. when finished hit <enter> or 'exit'


COUT
}
#######################################
## main sub to calculate info
##

sub fullsubnetinfo {

my $subnetaddy = shift;
my $cidr = shift;

my @subnet = split /\./, $subnetaddy;
my $activeoctet = 0;
my $activecidr = 0;
my $cct = $cidr;


##
## examine IP for active octet/mask and calculate block size
##
for my $x (1..4) {
   if ($cct >= 8) {
        $cct -= 8;
        }
   elsif ($cct < 8) {
        $activeoctet = $x;
        $activecidr = $cct;
        if (!$activecidr) { $activecidr = 8; $activeoctet--;}
        last;
        }
}

my $blocksize = 2**(8-$activecidr);

my $workingoctetbin = dec2bin($subnet[$activeoctet-1]);
my $workingoctetdec = $subnet[$activeoctet-1];

##
## calculate next network from block size
##

my @nextnetwork = @subnet;
$nextnetwork[$activeoctet-1] += $blocksize;

##  account for increments above 255
if ($nextnetwork[3] eq 256) {
        $nextnetwork[3] = 0;
        $nextnetwork[2]++;
        }
if ($nextnetwork[2] eq 256) {
        $nextnetwork[2] = 0;
        $nextnetwork[1]++;
        }
if ($nextnetwork[1] eq 256) {
        $nextnetwork[1] = 0;
        $nextnetwork[0]++;
        }

my $nextnetdec = join(".", @nextnetwork);
if ($nextnetwork[0] eq 256) { $nextnetdec = "N/A"; }

## calculate broadcast
my @broadcast = @nextnetwork;
my $broadcastdec = decrement_ip(join(".", @broadcast));


## calculate subnet range
my @rangehi = split /\./, $broadcastdec;
my @rangelow = @subnet;

my $rangehidec = decrement_ip(join(".", @rangehi));
my $rangelowdec= increment_ip(join(".", @rangelow));

printf("%20s%s\n\n"," Subnet: ",$subnetaddy);
printf("%20s%s\n"," Subnet Range: ","$rangelowdec -");
printf("%20s%s\n\n","", $rangehidec);
printf("%20s%s\n\n"," Broadcast Addy: ",$broadcastdec);
printf("%20s%s\n\n"," Next Network Addy: ",$nextnetdec);
printf("%20s%s\n"," Usable IPs: ",hostslookuptable($cidr));
print "\n\n";
$addypointer = $nextnetdec;
}
####################################################
## in: decimal number
## out: binary octet (padded to 8 chars)

sub dec2bin {
my $dec = shift;
return sprintf("%0*b",8,$dec);
}
#################################
##

sub increment_ip {

my $ip = shift;
my @lip = split /\./, $ip;
$lip[3]++;

if ($lip[3] eq 256) {
        $lip[2]++;
        $lip[3] = 0;
        }
if ($lip[2] eq 256) {
        $lip[1]++;
        $lip[2] = 0;
        }
if ($lip[1] eq 256) {
        $lip[0]++;
        $lip[1] = 0;
        }
if ($lip[0] eq 256) {
        return "<Error>";
        }
return join(".", @lip);
}
# # # # # # ###  # # # #
sub decrement_ip {
my $ip = shift;
my @lip = split /\./, $ip;
$lip[3]--;

if ($lip[3] eq -1) {
        $lip[2]--;
        $lip[3] = 255;
        }
if ($lip[2] eq -1) {
        $lip[1]--;
        $lip[2] = 255;
        }
if ($lip[1] eq -1) {
        $lip[0]--;
        $lip[1] = 255;
        }
if ($lip[0] eq -1) {
        return "<Error>";
        }
return join(".", @lip);
}

##################################
##hosts lookup table

sub hostslookuptable {

my $cidr = shift;

if ($cidr eq 32) {
        return "(/32 points to one address)";
        }
elsif ($cidr eq 31) {
        return "0";
        }
else {

        $cidr = 32-$cidr;
        my $cidnets = addcommas(2**$cidr);

        return "$cidnets - 2";
        }

}
###################################
#
sub addcommas {
my $int = shift;
my @intarr = split //, $int;
my $lc = 1;
my $retstr;
for (my $i = $#intarr; $i>-1; $i-- ) {
        $retstr .= $intarr[$i];
        if (!($lc % 3) && ($i != 0)) { $retstr.= ","; }
        $lc++;
        }
return reverse($retstr);
}
