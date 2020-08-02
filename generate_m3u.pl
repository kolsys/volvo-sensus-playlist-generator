#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use File::Basename;
use Music::Tag;
use Lingua::Translit;
use POSIX ':sys_wait_h';

my @PATHES = @ARGV;
my $PATH;
my %FLD = ();
my %MAP = ();
my $tr = new Lingua::Translit('GOST 7.79 RUS');

# Rename dir first
sub translit {
	if (!-d && !/^.+\.(mp3|flac|mp4)/is) {
		return;
	}
	my $tn = $tr->translit($_);
	unless ($tn eq $_) {
		if (-d $_) {
			open(my $fh, '>', $_.'/.dirname') || die('Cant '.$!);
			print($fh $_);
			close($fh);
		}
		print('Rename: ', $_, ' to ', $tn, $/);
		rename($_, $tn);
	}
}

sub make_playlists {
	if (!/^.+\.(mp3|flac|mp4)/is) {
		return;
	}
	if ($File::Find::name !~ /^$PATH\/([^\/]+)\/.+$/) {
		return;
	}
	my $root = $1;
	my $name = $_;
	my $dir = dirname($File::Find::name);
	if ($dir =~ /CD\d/ || $dir =~ /skazok\.\d$/) {
		$dir = dirname($dir);
	}
	my $workdir = dirname($dir);
	my $playlist;
	my $is_translit = 0;
	my $fh;
	if (!$MAP{$dir}) {
		$playlist = $workdir.'/'.$root.' - '.basename($dir).'.m3u';
		if ( -f $dir.'/.dirname' && open(my $fhp, '<', $dir.'/.dirname')) {
	        local $/;
	        my $origin = <$fhp>;
	        chomp($origin);
			close($fhp);
			$playlist = $workdir.'/'.$root.' - '.$origin.'.m3u';
			$is_translit = 1;
		}
		$MAP{$dir} = [$playlist, $is_translit];
	} else {
		($playlist, $is_translit) = @{$MAP{$dir}};
	}

	if (!$FLD{$playlist}) {
		print('Init: ', $playlist, $/);
		open($FLD{$playlist}, '>', $playlist) || die('Cant '.$!);
		$fh = $FLD{$playlist};
		print($fh '#EXTM3U'.$/);
	}

	$fh = $FLD{$playlist};
	my $fname = $File::Find::name =~ s|^$workdir/||r;

	$fname =~ s|/|\\|g;
	my $duration = 0;
	eval {
		die(1) if ($fname =~ /\.mp4$/); # It's too slow. Comment if you need mp4 tags
		my $tag = Music::Tag->new($File::Find::name, { quiet => 1 });
		$tag->get_tag();
		$duration = int($tag->duration()/1000);
		if ($tag->has_artist() && $tag->has_title()) {
			$name = $tag->artist().' - '.$tag->title();
		} else {
			die(1);
		}
	} or do {
		$name =~ s|\.[a-z]{2,5}$||;
		$name = $tr->translit_reverse($name) if ($is_translit);
	};
	print($fh '#EXTINF:', $duration, ',', $name, $/, $fname, $/);
}

unless (scalar(@PATHES)) {
	print('Usage:', $/, $0, ' PATH_TO_FOLDER[ PATH_TO_FOLDER_2 ... PATH_TO_FOLDER_N]', $/, $/);
	exit(1);
}

foreach $PATH (@PATHES) {
	unless (-d $PATH) {
		print('"', $PATH, '" is not valid path. Skiping.', $/);
		next;
	}
	finddepth(\&translit, $PATH);
	find(\&make_playlists, $PATH);
	print($PATH, ' complete.', $/);
}

foreach(keys(%FLD)) {
	print $_, $/;
	close($FLD{$_});
}