#!/usr/bin/perl -w

use strict;
use scigen;

my $tmp_dir = "/tmp";
my $tmp_pre = "/$tmp_dir/scimakediagram.$$";
my $viz_file = "$tmp_pre.viz";
my $eps_file = "$tmp_pre.eps";

my $sysname = shift;
my $filename = shift;

if( defined $filename ) {
    $eps_file = $filename;
}

my @label_types = qw( NODE_LABEL_LET NODE_LABEL_PROG 
		      NODE_LABEL_NET NODE_LABEL_IP NODE_LABEL_HW 
		      NODE_LABEL_DEC);
my @edge_label_types = ( "\"\"", "\"\"", "\"\"", "\"\"", "\"\"", 
			 "EDGE_LABEL_YESNO" );
my %types = ("digraph" => "DIR_LAYOUT",
	     "graph" => "UNDIR_LAYOUT" );
my %edges = ("digraph" => "->",
	     "graph" => "--" );

my $dat = {};
my $RE = undef;

my $fh = new IO::File ("<graphviz.in");
scigen::read_rules ($fh, $dat, \$RE, 0);

my $num_nodes = scigen::generate ($dat, "NUM_NODES", $RE, 0, 0);
my $graph_type = scigen::generate ($dat, "PICK_GRAPH_TYPE", $RE, 0, 0);
my $label_type = scigen::generate ($dat, "PICK_LABEL_TYPE", $RE, 0, 0);
my $shape_type = scigen::generate ($dat, "PICK_SHAPE_TYPE", $RE, 0, 0);
my $edge_label_type = $edge_label_types[$label_type];
$label_type = $label_types[$label_type];
my $dir_rule = $types{$graph_type};
my $edge_type = $edges{$graph_type};
my $program = scigen::generate ($dat, $dir_rule, $RE, 0, 0);

#good number of edges: n-1 -> 2n-1
my $num_edges = int rand($num_nodes-1);
$num_edges += $num_nodes;
if( $num_edges > 16 ) {
    $num_edges = 16;
} elsif( $num_edges == 0 ) {
    $num_edges = 1;
}

my @a = ($graph_type);
$dat->{"GRAPH_DIR"} = \@a;
my @b = ($label_type);
$dat->{"NODE_LABEL"} = \@b;
my @c = ($edge_type);
$dat->{"EDGEOP"} = \@c;
# can't be in italics
if( $sysname =~ /\{\\em (.*)\}/ ) {
    $sysname = $1;
}
my @d = ($sysname); 
$dat->{"SYSNAME"} = \@d;
my @e = ();
my @shapes = split( /\s+/, $shape_type );
foreach my $s (@shapes) {
    push @e, $s
}
$dat->{"SHAPE_TYPE"} = \@e;
my @f = ($edge_label_type);
$dat->{"EDGE_LABEL"} = \@f;
my @g = ("NODES_$num_nodes");
$dat->{"NODES"} = \@g;
my @h = ("EDGES_$num_edges");
$dat->{"EDGES"} = \@h;

scigen::compute_re( $dat, \$RE );
my $graph_file = scigen::generate ($dat, "GRAPHVIZ", $RE, 0, 0);

open( VIZ, ">$viz_file" ) or die( "Can't open $viz_file for writing" );
print VIZ $graph_file;
close( VIZ );

system( "$program -Tps $viz_file > $eps_file.tmp; ps2epsi $eps_file.tmp $eps_file" ) and
    die( "Can't run $program on $viz_file" );

if( !defined $filename ) {
    system( "gv $eps_file" ) and
	die( "Can't run $program on $viz_file" );
}

system( "rm -f $tmp_pre*" ) and die( "Couldn't rm" );
