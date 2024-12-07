#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use File::Basename;
use File::Path  qw(make_path);
use Time::HiRes qw(gettimeofday tv_interval);

sub minify_js {
	my ($code) = @_;

	# Remove multi-line comments (/* ... */)
	$code =~ s|/\*.*?\*/||gs;

	# Remove single-line comments (// ...)
	$code =~ s|//.*?$||gm;

	# Remove unnecessary whitespace (newlines, tabs, extra spaces)
	$code =~ s/\s+/ /g;    # Replace multiple whitespace with a single space
	$code =~ s/ ?([{};,:]) ?/$1/g;    # Remove spaces around common symbols
	$code =~ s/^\s+|\s+$//g;          # Trim leading and trailing whitespace

	return $code;
}

sub minify_css {
	my ($code) = @_;

	# Remove comments (/* ... */)
	$code =~ s|/\*.*?\*/||gs;

	# Remove unnecessary whitespace (newlines, tabs, extra spaces)
	$code =~ s/\s+/ /g;    # Replace multiple whitespace with a single space
	$code =~ s/\s*([{};:,])\s*/$1/g;   # Remove spaces around common CSS symbols
	$code =~ s/^\s+|\s+$//g;           # Trim leading and trailing whitespace

	return $code;
}

my $old_size = 0;
my $new_size = 0;
my $time     = 0;

# Color codes for output
my $RED   = "\033[31m";
my $GREEN = "\033[32m";
my $RESET = "\033[0m";

sub print_size_diff {
	my ( $original_size, $minified_size ) = @_;
	my $diff = $minified_size - $original_size;

	if ( $diff < 0 ) {
		print $GREEN
		  . "Size reduced by "
		  . abs($diff)
		  . " bytes"
		  . $RESET . "\n\n";
	}
	else {
		print $RED . "Size increased by $diff bytes" . $RESET . "\n\n";

		# just in case haha
	}
}

sub measure_time {
	my ($code_ref) = @_;
	my $start_time = [gettimeofday];
	$code_ref->();
	my $end_time = [gettimeofday];
	my $elapsed  = tv_interval( $start_time, $end_time );
	return $elapsed;
}

sub process_file {
	my ( $input_file, $output_file, $minify_sub ) = @_;

	my $time_taken = measure_time(
		sub {
			open my $in, '<', $input_file
			  or die "Cannot open '$input_file': $!\n";
			my $code = do { local $/; <$in> };
			close $in;

			my $minified_code = $minify_sub->($code);

			open my $out, '>', $output_file
			  or die "Cannot write to '$output_file': $!\n";
			print $out $minified_code;
			close $out;

			print "Minified '$input_file' saved to '$output_file'\n";
		}
	);

	my $original_size = -s $input_file;
	my $minified_size = -s $output_file;
	print "Time taken: $time_taken seconds\n";
	print "Original file size: $original_size bytes\n";
	print "Minified file size: $minified_size bytes\n";
	print_size_diff( $original_size, $minified_size );

	$old_size += $original_size;
	$new_size += $minified_size;
	$time     += $time_taken;
}

my $config_file = 'config.json';
open my $config_fh, '<', $config_file or die "Cannot open '$config_file': $!\n";
my $config_content = do { local $/; <$config_fh> };
close $config_fh;

my $config = decode_json($config_content);

my $input_dir_js = $config->{js}->{input}
  || die "Input directory for JS not specified in config\n";
my $output_dir_js = $config->{js}->{output}
  || die "Output directory for JS not specified in config\n";
my $input_dir_css = $config->{css}->{input}
  || die "Input directory for CSS not specified in config\n";
my $output_dir_css = $config->{css}->{output}
  || die "Output directory for CSS not specified in config\n";

make_path($output_dir_js)  unless -d $output_dir_js;
make_path($output_dir_css) unless -d $output_dir_css;

my $param = shift;

if ( defined $param ) {
	if ( -f $param && $param =~ /\.js$/ ) {
		process_file( $param, basename($param), \&minify_js );
	}
	elsif ( -f $param && $param =~ /\.css$/ ) {
		process_file( $param, basename($param), \&minify_css );
	}
	else {
		print
"You can only pass one parameter and it must be either a JS or CSS file.\n";
	}
}
else {
	for my $dir (
		[ $input_dir_js,  $output_dir_js,  \&minify_js,  '.js' ],
		[ $input_dir_css, $output_dir_css, \&minify_css, '.css' ]
	  )
	{
		my ( $input_dir, $output_dir, $minify_sub, $ext ) = @$dir;
		if ( -d $input_dir ) {
			opendir my $dh, $input_dir
			  or die "Cannot open directory '$input_dir': $!\n";
			while ( my $file = readdir $dh ) {
				next unless $file =~ /\Q$ext\E$/;
				process_file( "$input_dir/$file", "$output_dir/$file",
					$minify_sub );
			}
			closedir $dh;
		}
		else {
			print "The input directory for $ext files does not exist.\n";
		}
	}
}

print "-" x 50, "\n";
print "Summary:\n";
print "Total time taken: $time seconds\n";
print "Total original size: $old_size bytes\n";
print "Total minified size: $new_size bytes\n";
my $total_diff = $old_size - $new_size;
my $percentage_reduction =
  $old_size > 0
  ? sprintf( "%.2f", ( $total_diff / $old_size ) * 100 )
  : 0;
print "Total size reduced: $total_diff bytes ($percentage_reduction%)\n";
print "-" x 50, "\n";
