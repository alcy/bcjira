use strict;
use warnings;
use UNIVERSAL 'isa';
use WebService::Basecamp;
my $bc = WebService::Basecamp->new(
  url => "https://example.com",
  user => "foo",
  pass => "pass"
);

my $projects = $bc->projects;
open my $fh, '>>', '/tmp/jira.csv';
print $fh "IssueType, Summary, Labels, Project Name, Project Key\n";
for my $project (@$projects) { 
  my $project_key = uc(substr($project->{name}, 0, 4)); 
  my $todo_lists = $bc->lists($project->{id});
  for my $list (@$todo_lists) {
    # replace space/commans with hyphens to avoid breaking label into sep strings
    $list->{name} =~ s/\ /-/g;  
    $list->{name} =~ s/,/-/g; 
    my $todo = $bc->list($list->{id});
    my $tasks = $todo->{'todo-items'}->{'todo-item'};
    if (isa($tasks, 'ARRAY')) { 
      foreach (@$tasks) {
	print $fh "task, \"$_->{content}\", \"$list->{name}\", \"$project->{name}\", $project_key\n";
      }
    } elsif (isa($tasks, 'HASH')) { 
      print $fh "task, \"$tasks->{content}\", \"$list->{name}\", \"$project->{name}\", $project_key\n";
    }
  }
}
close $fh;	 
