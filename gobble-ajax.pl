#!/usr/bin/env perl

use Mojolicious::Lite;

# Grab the command line variables
# by accessing the @ARGV array
my $my_url = $ARGV[0]; # The first is the url parameter
my $my_command = $ARGV[1]; # The second is the command

# We need two threads. One for screen and the other
# for Mojolicious and our web page.
my $childpid = fork();

if ($childpid) { # If this is the child thread

	# Send the command to the shell as a parameter of screen
	`screen -L $my_command`;

	# I want mojo to continue running after the child
	# is done.. So just give a little reminder to kill it.
	print "Done...\n";
	print "Don't forget to kill the process 'kill -9 $childpid'\n";

	# Or kill it.
	#`kill -9 $childpid`; # for debugging only

} else { # If not this is the parent thread

	get $my_url => sub { # Set the url to $my_url
		my $self = shift; # Still not sure what this does.

		# Open the log file and store it in <FILE>
		open(FILE,"html_gobble.log");

		# Create an empty array that will hold all our content
		my @new_file = ();

		# In web land you need a <br> tag to end a line.
		# Or you can encase the line in <div> tags. Let's do the later.
		# There are tag generating tools in Mojolicious.. But let's 
		# Do it the old fashioned way.
		# 
		# Use perl's "magic open" to open and run through
		# each line of the file.
		while (<FILE>) {
			# The $_ variable holds the current line
			chomp $_; # Remove the newline character
			$_ =~ s/^/<div>/; # add <div> to the beginning
			$_ =~ s/$/<\/div>/; # add </div> to the end
			push(@new_file, $_); # add the line to our array
		}

		# Flatten the array into one long string with no spaces or
		# newline characters.
		my $one_string = join('',@new_file);

		# Tell Mojo to render the index template below
		# and pass our new data "$one_string" as a new
		# variable called "$log_data"
		$self->render('index', log_data => $one_string);
	};

	# Start Mojolicious with the light weight web server
	app->start('daemon');
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Test';
% my $testing = 'blah';

<%== $log_data %>

@@ layouts/default.html.ep
 <!doctype html><html>
  <head>
   <title><%= title %></title>

	<style type="text/css">
		body {
			background-color: #000000;
			color: #00ff00;
			font-weight: bolder;
		}
	</style>

	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>

	<script type="text/javascript">
		$(document).ready(function () {
			%# Scroll down to the bottom
			$('html, body').animate({scrollTop: $(document).height()}, 'slow');

			%# Schedule the first update in five seconds
			setTimeout("updatePage()",5000);
		});

		%# This function will update the page
		function updatePage () {

			$('#command-content').load(window.location.href + ' #command-content>div');
			$('html, body').animate({scrollTop: $(document).height()}, 'slow');

			%# Schedule the next update in five seconds
			setTimeout("updatePage()",5000);
		}

	</script>

   %# This tells phone browsers not to scale
   <meta name="viewport" content="initial-scale=1.0"/>
   <%= base_tag %>
  </head>
  <body>
	%# This will wrap the command output
   <div id='command-content'>
		%# This is the command output
		<%= content %>
	</div>
  </body>
 </html>
