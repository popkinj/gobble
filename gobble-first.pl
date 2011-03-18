#!/usr/bin/perl
use Mojolicious::Lite;
get '/' => {text => "This is just the beginning!"};
app->start;
