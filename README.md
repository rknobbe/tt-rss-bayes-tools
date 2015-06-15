#tt-rss-bayes-tools

#Dependencies
This works with a running instance of http://tt-rss.org/
Requires you have downloaded and installed AI::Categorize (not AI::Categories!) https://github.com/gitpan/AI-Categorize

#Concepts

Scoring leverages labels in tt-rss. Current code expects the reader to use a series of labels (for example, "!! INTERESTING", and "!! UNINTERESTING") to train the bayesian categorizer.  Results from the bayesian scoring are also reflected in these labels; the script adds labels to articles based on the bayesian score of previously learned articles.

#Customization
To use, edit the "my $url = " line in the script to point to your tt-rss instance.

Script will query your TT-RSS instance for all defined labels,  use naive bayesian learning to deduce your manually applied labeling criteria, and try to apply appropriate labels for unread articles.

Current script doesn't use authentication.  See the API description https://tt-rss.org/redmine/projects/tt-rss/wiki/JsonApiReference to learn how to add username and password to the login() subroutine.

#Usage
$ feedapi.pl -h

$ feedapi.pl -l -s
