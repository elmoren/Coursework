#!/usr/bin/perl -w

#~ -------------------------------------------------------------------------------------
#~ GA Subs:
#~ Author: Nathan Elmore
#~ 
#~ SUBS: The subroutines for the program. Handles the reading, training,
#~ optimization, and command line arguments
#~ -------------------------------------------------------------------------------------
use vars qw / %opt /;

my $opt_string = 'f:e:m:t:h';

#~
#~ init: parses command line args
#~
sub init()
{
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
}

#~
#~ read_csv: reads in csv and creates bit vector
#~
#~ @param file : File to read knapsack data from
#~ @param vector_ref : Reference to an array used as a bit vector
#~ @param data_ref : Reference to an 2d array that holds the csv data
#~
sub read_csv
{
	my $file       = shift;
	my $vector_ref = shift;
	my $data_ref   = shift;

	open IN, "<", $file or die $!;
	foreach (<IN>) {
		chomp;
		$_ =~ s/\r//g;
		
		 #~ each line of the csv is an object, so add a "bit" for it in the bit vector
		push (@$vector_ref, 0);
		push (@$data_ref, [split(",", $_)]);
	}
	close(IN);
}

#~
#~ init_population: Randomly initialize a population of given size, for the given vector
#~                  size. 50% chance for a bit to be 1 or 0.
#~
#~ @param p_size : population size
#~ @param v_size : size of bit vector
#~
#~ @return reference to a 2d array population
#~ 
sub init_population
{
	#~ Population and Vector size
	my $p_size = shift;
	my $v_size = shift;
	
	my @pop;

	for (my $i = 0; $i < $p_size; $i++) {
		my @v;
		for (my $j = 0; $j < $v_size; $j++) {
			push (@v, int(rand(2))*int(rand(2)));
		}
		push(@pop, \@v);
	}
	return (\@pop);
}

#~
#~ get_weight: Returns weight of given vector
#~
#~ @param v : reference to a bit vector
#~ @param items : reference to a 2d array of items 
#~
#~ @return total weight for given vector
#~
sub get_weight
{
	my $v = shift;
	my $items = shift;
	
	my $total = 0;
	my $idx = 0;
	foreach my $val (@$v) {
		if($val > 0) {
			$total += $items->[$idx][0];
		}
		$idx++;
	}
	return $total;	
}

#~
#~ get_value: Returns total value of the knapsack vector
#~
#~ @param v : reference to a bit vector
#~ @param items : reference to a 2d array of items
#~
#~ @return total value of a bit vector
#~
sub get_value
{
	my $v = shift;
	my $items = shift;
	
	my $total = 0;
	my $idx = 0;
	foreach my $val (@$v) {
		if($val > 0) {
			$total += $items->[$idx][1];
		}
		$idx++;
	}
	return $total;	
}

#~
#~ get_fitness: Returns fitness of a vector. The fitness for this problem is simply the 
#~              total value of the items in the knapsack. However, if the weight is
#~              greater than the max (200)
#~ 
#~ @param v : Reference to a bit vector
#~ @param items : Reference to a 2d array of items
#~
sub get_fitness
{
	my $v     = shift;
	my $items = shift;
	
	my $w     = get_weight($v, $items);
	my $total = get_value($v, $items);
	
	#~ penalize for too much weight
	if($w > 200) {
		$total = 200/$w;
	}
	
	return $total;
}

#~
#~ natural_selection: Sorts the population by its fitness. The top $elite_rate get to
#~                      "live", and the rest "die". Returns the new population.
#~
#~ @param p : reference to 2d array of the population
#~ @param items : reference to 2d array of items
#~
#~ @return : Returns the new population with the set of the "elite population" plus 
#~           (100 - $elite_rate) random individuals
#~
sub natural_selection
{
	my $p     = shift;
	my $items = shift;
	#~ elite_rate = How many of the best to save
	my $elite_rate = shift;
	
    #~ Sort by fitness.
    my @sorted = sort {get_fitness($b, $items) <=> get_fitness($a, $items)} @$p;
	$p = [];

	for (my $i = 0; $i < $elite_rate; $i++) {
		push (@$p, shift(@sorted));
	}

	while (@$p < 100) {
		push (@$p, $sorted[ int(rand(@sorted)) ]);
	}
	return $p;
}

#~
#~ produce_offspring: Adds offspring to population
#~ Note: This method uses one parent with the population because it was able to acquire a 
#~ good result.
#~
#~ @param p : reference to population
#~ @param parents : reference to parents
#~ @param items : reference to items array
#~
#~
sub produce_offspring
{
	my $p       = shift;
	my $parents = shift;
	my $items   = shift;
	
	my @offspring;

	for (my $i = 0; $i < @$p; $i++) {
		my $o = crossover($parents->[0], $p->[$i], $items);
		push (@offspring, $o);
	}
	
	foreach (@offspring) {
		push (@$p, $_);
	}	
}

#~
#~ crossover: Takes 2 parents, performs random point crossover. Returns the best fit 
#~            offspring
#~
#~ @param p1 : reference to first parent
#~ @param p2 : reference to second parent
#~ @param items : reference to items array
#~
#~ @return : reference to the offspring with the best fitness
#~
sub crossover
{
	my $p1 = shift;
	my $p2 = shift;
	my $items = shift;
	
	my $len = @{$p1};
	my $cross_point = int(rand($len));
	my @c1 = ((0) x $len);
	my @c2 = ((0) x $len);
	
	#~ Perform the point crossover
	for(my $i = 0; $i < $len; $i++) {	
		if( $i <= $cross_point) {
			$c1[$i] = $p1->[$i];
			$c2[$i] = $p2->[$i];
		} else {
			$c2[$i] = $p1->[$i];
			$c1[$i] = $p2->[$i];
		}
	}
	
	#~ return best fit child
	if(get_fitness(\@c1, $items) > get_fitness(\@c2, $items) ) {
		return \@c1;
	} else {
		return \@c2;
	} 
}

#~
#~ mutate_population: adds random mutations based on the mutation rate
#~ 
#~ @param p : Reference to the population
#~ @param rate : the mutation rate
#~
sub mutate_population
{
	my $p = shift;
	my $rate = shift;
	my $vlen = @{$p->[0]};
	
	#~ For every chromosome in our population
	for (my $i = 0; $i < @{$p}; $i++) {
		for (my $j = 0; $j < $vlen; $j++) {
			my $r_num = int(rand($vlen));
			#~ do we mutate?
			if($r_num < $rate) {
				if($p->[$i][$j] == 0) {
					$p->[$i][$j] = 1;
				} else {
					$p->[$i][$j] = 0;
				}
			}
		}
	}
}

#~
#~ tournament_selection: The larger the tournament size $k, the less chance weak
#~                       individuals have to be selected
#~
#~ @param p : reference to population
#~ @param items : reference to set of items
#~ @param k : the tournament size
#~
#~ @return : the return tournament
#~
sub tournament_selection
{
	#~ population, items, number of members
	my $p     = shift;
	my $items = shift;
	my $k     = shift;
	
	my @p_copy = @{$p};
	my @random_set;
	
	#~ Get k random individuals
	for (my $i = 0; $i < $k; $i++) {
		my $idx = rand @p_copy;
		push   (@random_set, $p_copy[$idx]);
		splice (@p_copy, $idx, 1);
	}
	
	#~ sort them by fitness
	@random_set = sort {get_fitness($b, $items) <=> get_fitness($a, $items)} @random_set;

	return \@random_set;
}

#~
#~ greed: Greedy approach for the knapsack problem to compare to the genetic algorithm
#~
#~ @param gv : reference to the greedy bit vector
#~ @param items : reference to set of items
#~
#~ @returns Total value
#~ @returns Total Weight
#~
sub greed
{
	my $gv    = shift;
	my $items = shift;

	#~ Use a hash so we can sort and keep track of indices
	#~ key   = index
	#~ value = value / weight ratio
	my %ratios;

	#~ get ratios
	my $idx = 0;
	foreach $item (@$items) {
		my $ratio = $item->[1] / $item->[0];
		$ratios{$idx} = $ratio;
		$idx++;
	}

	#~ Be greedy
	#~ Sort hash by descending values
	my $w   = 0; # weight
	my $val = 0; # total
	foreach my $key ( sort {$ratios{$b} <=> $ratios{$a}} (keys(%ratios)) ) {
		#print "Key: $key, weight: " . $items->[$key][1] . "ratio: " . $ratios{$key} . "\n";
		
		#~If it adds too much weight, skip it, otherwise add it!
		if ($w + $items->[$key][0] < 200) {
			$gv->[$key] = 1;
			$w += $items->[$key][0];
			$val += $items->[$key][1];
		} else {
			$gv->[$key] = 0;
		}
	}
	return ($val, $w);
}

#~
#~ usage: Prints the usage the the genetic algorithm
#~
sub usage()
{

    print STDERR << "EOF";

Genetic Algorithm program: Takes in a CSV file

    usage: $0 -f [file]

     -f CSV file        : <String>  CSV file path of items
     -e elite rate      : <Integer> Number of elite fitness members to save (default 75)
     -t tournament size : <Integer> Specifies size of tournament (default 15)
     -m mutation rate   : <Integer> Specifies random mutation rate m / (len of vector) (default 1)
     -h Help            : Shows this message
EOF
     exit;
}

return 1;
