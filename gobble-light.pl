#!/usr/bin/env perl

use Mojolicious::Lite;

# Documentation browser under "/perldoc" (this plugin requires Perl 5.10)
plugin 'pod_renderer';

get '/(.me)' => sub {
    my $self = shift;
    $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to Mojolicious <%= $me %>!

@@ layouts/default.html.ep
<!doctype html><html>
    <head>
        <title><%= title %></title>
        <%= base_tag %>
    </head>
    <body><%= content %></body>
</html>
