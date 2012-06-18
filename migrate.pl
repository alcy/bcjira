use strict;
use warnings;
use UNIVERSAL 'isa';
use WebService::Basecamp;

my $bc = WebService::Basecamp->new(
  url => "https://example.com",
  user => "foo",
  pass => "pass"
);
my $csv = '/tmp/jira.csv';
open my $fh, '>>', $csv;
print $fh "IssueType, Summary, Reporter, Date Created, Date Modified, Labels, Project Name, Project Key\n"; #headers for jira

my $projects = $bc->projects;
for my $project (@$projects) { 
  my $project_key = uc(substr($project->{name}, 0, 4)); 
  my $todo_lists = $bc->lists($project->{id});
  for my $list (@$todo_lists) {
    # replace space/commans with hyphens to avoid breaking label into sep strings
    $list->{name} =~ s/(\ |,)/-/g;  
    my $todo = $bc->list($list->{id});
    my $tasks = $todo->{'todo-items'}->{'todo-item'};
    
    my $prepare = sub { 
      my $task = shift;
      my $created = $task->{'created-on'};
      $created =~ s/(T|Z|-|:)//g;
      if (defined($task->{'updated-at'})) { 
        my $updated = $task->{'updated-at'};
        $updated =~ s/(T|Z|-|:)//g;
        return ($created,$updated);
      } else { return ($created, "") }
    };

    my $data = sub {
      my $task = shift;
      my ($created, $updated) = $prepare->($task);
      my $str = qq(task, "$task->{content}", "$task->{'creator-name'}", "$created", "$updated", "$list->{name}", "$project->{name}", "$project_key"\n);
      return $str;
    };
     
    if (isa($tasks, 'ARRAY')) { 
      foreach (@$tasks) {
        print $fh $data->($_);
      }
    } elsif (isa($tasks, 'HASH')) {
        print $fh $data->($tasks);
    }
  }
}
close $fh;	 
