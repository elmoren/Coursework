#!/usr/bin/perl -w

#~ -------------------------------------------------------------------------------------
#~ File: GA.pl
#~ Author: Nathan Elmore
#~
#~ Purpose: uses the GA subroutines (initialization, fitness, tournament selection, 
#~ reproduction, to optimize the knapsack problem.
#~ 
#~ use -h for usage
#~ -------------------------------------------------------------------------------------

use Getopt::Std;  #~ Command line argument processing
use Data::Dumper; #~ Debugging data

#~ Subroutines files
require "GA_subs.pl";

#~ init the command line processing
init();

#~ DEFAULT TUNEABLES
my $t_size = 30;
my $m_rate = 1;
my $elite_rate = 75;

#~ ------------------------------------------------------------
#~                        Help?
#~ ------------------------------------------------------------
if ($opt{'h'}) {
    usage();
    exit;
}

#~ ------------------------------------------------------------
#~                      Required Args
#~ ------------------------------------------------------------
if(!$opt{'f'}) {
    usage();
    exit;
}

#~ ------------------------------------------------------------
#~                      Tunable Args
#~ ------------------------------------------------------------

#~ The elite rate
if ($opt{'e'}) {
    if ($opt{'e'} > 100) {
        print "Warning:: Elite rate max is 100 because it cannot be greater than the population size\n";
        $elite_rate = 100;
    } else {
       $elite_rate = $opt{'e'};
    }
}

print "$elite_rate \n";

#~ The tournament size
if ($opt{'t'}) {
    $t_size = $opt{'t'};
}

#~ The mutation rate
if ($opt{'m'}) {
    $m_rate = $opt{'m'};
}

#~ ------------------------------------------------------------
#~                    The Knapsack Problem
#~ ------------------------------------------------------------

print "----------------- Nate's Genetic Algorithm ----------------\n";
#~ Best current Bit vector using an array
my @vector;

#~ List of items
my @items;

#~ Population array reference and tournament winnders
my $population;
my $t_winners;

#~ First read in the data
read_csv ($opt{'f'}, \@vector, \@items);
#~remove first of items
shift @items;
shift @vector;

#~ Greedy Approach
my @greedy_vector = ((0) x @items);
my ($greedy_total, $greed_weight) = greed (\@greedy_vector, \@items);

#~ GA APPROACH
$population = init_population (100, $#items+1);
my $iter = 0;
my $max_val = 0;
my @max_vec;

#~ Do 1000 generations
while ($iter++ < 1000) {
	$t_winners = tournament_selection ($population, \@items, $t_size);
	mutate_population ($population, $m_rate);
	produce_offspring ($population, $t_winners, \@items);
	$population = natural_selection ($population, \@items, $elite_rate);

    #~ Keep track of optimal results
	if ($max_val < get_fitness ($population->[0], \@items) && 200  >= get_weight ($population->[0], \@items)) {
	 	@max_vec = @{$population->[0]};
		$max_val = get_fitness ($population->[0], \@items);
	}
	
	#~ Calculate the average fitness of the population
	my $avg_fit = 0;
	foreach my $row (@$population) {
		$avg_fit += get_fitness ($row, \@items);
	}
	$avg_fit /= @$population;
	
	print "Iteration: $iter, ";
	print "Max Total Value: $max_val, ";
	print "Weight: " . get_weight (\@max_vec, \@items) . ", ";
	print "Avg Fitness: $avg_fit\n";
}

print "------------------------------------------------\n";
print "Greedy Approach\n";
print "Weight: $greed_weight \n";
print "Value: $greedy_total \n";
print "------------------------------------------------\n";