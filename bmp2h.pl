#!/usr/bin/perl

use strict;
use warnings;

my $negative = 0;
my $order = 1;
my $filename;
my $bitmap = "bitmap";

while ($_  = shift @ARGV){
	if (/-n/){
		$negative = 1;
		next;
	} elsif(/-b(.*)/) {
		$bitmap = $1 ? $1 : shift @ARGV;
		next;
	}
	$filename = $_;
}

print STDERR "bmpfile: $filename\n";

open my $in, '<', $filename || die("Can't read.\n");
binmode $in;

my $bmpsize = -s $in;
print STDERR "size: $bmpsize\n";
my $bmp;
read($in, $bmp, $bmpsize, 0);

undef $in;

my @bytes = unpack("C*", $bmp);

my ($bfType, $bfSize, $bfR1, $bfR2, $bfoffBits,
	$bcSize, $bcWidth, $bcHeight, $bcPlanes, $bcBitCount)
	= unpack("vVvvV VVVvv", $bmp);

if ($bcHeight < 0){
	$order = 0;
	$bcHeight = -$bcHeight;
}

print STDERR "Offset: $bfoffBits\n";

my (@data) = unpack("x$bfoffBits C*", $bmp);

if ($order){
	my @d;
	for (my $y = $bcHeight - 1; $y > -1; $y --){
		for (my $x = 0; $x < ($bcWidth / 8); $x ++){
			push @d, $data[$y * ($bcWidth / 8) + $x];
		}
	}
	@data = @d;
}

print "/* filename: $filename */\n";
print "#define ${bitmap}_w $bcWidth\n";
print "#define ${bitmap}_h $bcHeight\n";
print "const uint8_t PROGMEM ${bitmap}[] = {\n\t";

my $cnt = 0;

foreach my $b (@data){
	if ($negative){
		$b = $b ^ 0xff; # xor
	}
	printf("%#2X, ", $b);
	$cnt ++;
	if ($cnt == 7){
		print "\n\t";
		$cnt = 0;
	}
}
print "\n};\n";


