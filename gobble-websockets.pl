#!/usr/bin/env perl

use Mojolicious::Lite;

# Mojo has a nice looping interface.
my $loop = Mojo::IOLoop->singleton;

# Grab the command line variables
# by accessing the @ARGV array
my $my_url = $ARGV[0]; # The first is the url parameter
my $my_command = $ARGV[1]; # The second is the command

# We now need to keep track on line numbers
my $line_count;

# We need two threads. One for screen and the other
# for Mojolicious and our web page.
my $childpid = fork();

if ($childpid) { # If this is the child thread

	# Send the command to the shell as a parameter of screen
	`screen -L $my_command`;

	# I want mojo to continue running after the child
	# is done.. So just give a little reminder to kill it.
	print "Done...\n";
	#`kill -9 $childpid`; # for debugging only
	 print "Don't forget to kill the process 'kill -9 $childpid'\n";

} else { # If not this is the parent thread

	get $my_url => sub { # Set the url to $my_url
		my $self = shift; # Grab the current instance

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
		
		# Close the file handle.
		close(FILE);
	};

	# Set the socket to be the same url...
	# but with a "-ws" at the end.
	websocket $my_url . '-ws' => sub {
		my $self = shift;

		my $send_data;
		$send_data = sub {
			# Grab new lines from our function
			my $new_lines = updatePage();
			# If new lines are available $new_lines will exist.
			if ($new_lines) {
				# Send content to the client
				$self->send_message($new_lines);
				# Do this all again in 1 second
				$loop->timer(1, $send_data);
			}
		};
		# We need this to start our loop for the first time
		$send_data->(); # Run code.

	};
	# Start Mojolicious with the light weight web server
	app->start('daemon');
}

# The update function
sub updatePage () {
	open(FILE, "html_gobble.log");
	
	my $iteration_count = 0; # zero the counter
	my $new_content = ''; # Initialize the new content variable

	while (<FILE>) {
		++$iteration_count; # Increment
		# If there is a new line(s)
		if ($iteration_count > $line_count) {
			# We need to keep track of lines already added.
			++$line_count;

			# Here we are adding the current line to the new
			# content variable... With our html markup around it.
			$new_content = $new_content . "<div>" . $_ . "</div>";
		}
	}

	# Close the file handle.
	close (FILE);

	# Return new content
	return ($new_content);
}



# Now our web page update stuff is in the perl script

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
			background-color: #494948;
			color: #D7CA0F;
			font-weight: bolder;
		}
	</style>

	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>

	<script type="text/javascript">
		$(document).ready(function () {
			%# Grab our current location
			var ws_host = window.location.href;

			%# We are requesting websocket data...
			%# So change the http: part to ws:
			ws_host = ws_host.replace(/http:/,"ws:") + "-ws";
			%# I also tacked on the "-ws" at the end

			%# Connect the remote socket
			var socket = new WebSocket(ws_host);

			%# When we recieve data from the websocket do the following
			%# with "msg" as the content.
			socket.onmessage = function (msg) {
				%# Append the new content to the end of our page
				$('#command-content').append(msg.data);

				%# Scroll down to the bottom
				$('html, body').animate({scrollTop: $(document).height()}, 'slow');
			}

			%# Scroll down to the bottom
			$('html, body').animate({scrollTop: $(document).height()}, 'slow');
		});


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
