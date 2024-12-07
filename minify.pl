#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use File::Basename;
use File::Path qw(make_path);

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

		my $input_file  = $param;
		my $output_file = basename($input_file);

		open my $in, '<', $input_file or die "Cannot open '$input_file': $!\n";
		my $code = do { local $/; <$in> };
		close $in;

		my $minified_code = minify_js($code);

		open my $out, '>', $output_file
		  or die "Cannot write to '$output_file': $!\n";
		print $out $minified_code;
		close $out;

		print "Minified '$param' saved to '$output_file'\n";

	}
	elsif ( -f $param && $param =~ /\.css$/ ) {

		my $input_file  = $param;
		my $output_file = basename($input_file);

		open my $in, '<', $input_file or die "Cannot open '$input_file': $!\n";
		my $code = do { local $/; <$in> };
		close $in;

		my $minified_code = minify_css($code);

		open my $out, '>', $output_file
		  or die "Cannot write to '$output_file': $!\n";
		print $out $minified_code;
		close $out;

		print "Minified '$param' saved to '$output_file'\n";

	}
	else {
		print
"You can only pass one parameter and it must be either a JS or CSS file.\n";
	}
}
else {
	if ( -d $input_dir_js ) {
		opendir my $dir, $input_dir_js
		  or die "Cannot open directory '$input_dir_js': $!\n";
		while ( my $file = readdir $dir ) {
			next unless $file =~ /\.js$/;
			my $input_file  = "$input_dir_js/$file";
			my $output_file = "$output_dir_js/$file";

			open my $in, '<', $input_file
			  or die "Cannot open '$input_file': $!\n";
			my $code = do { local $/; <$in> };
			close $in;

			my $minified_code = minify_js($code);

			open my $out, '>', $output_file
			  or die "Cannot write to '$output_file': $!\n";
			print $out $minified_code;
			close $out;

			print "Minified '$file' saved to '$output_dir_js/$file'\n";
		}
		closedir $dir;
	}
	else {
		print "The input directory for JS does not exist.\n";
	}

	if ( -d $input_dir_css ) {
		opendir my $dir, $input_dir_css
		  or die "Cannot open directory '$input_dir_css': $!\n";
		while ( my $file = readdir $dir ) {
			next unless $file =~ /\.css$/;
			my $input_file  = "$input_dir_css/$file";
			my $output_file = "$output_dir_css/$file";

			open my $in, '<', $input_file
			  or die "Cannot open '$input_file': $!\n";
			my $code = do { local $/; <$in> };
			close $in;

			my $minified_code = minify_css($code);

			open my $out, '>', $output_file
			  or die "Cannot write to '$output_file': $!\n";
			print $out $minified_code;
			close $out;

			print "Minified '$file' saved to '$output_dir_css/$file'\n";
		}
		closedir $dir;
	}
	else {
		print "The input directory for CSS does not exist.\n";
	}
}
