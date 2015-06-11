#tt-rss-bayes-tools

This works with a running instance of http://tt-rss.org/

Scoring leverages labels in tt-rss. Current code expects the reader to use 2 labels ("!! INTERESTING", and "!! UNINTERESTING") to train the bayesian categorizer.  Results from the bayesian scoring are also reflected in these labels; the script adds labels to interesting and uninteresting articles based on the bayesian score of previously learned articles.

To use, edit the "my $url = " line in the script to point to your tt-rss instance.
Feel free to use different labels than the ones I've chosen, just make sure the spelling of the label names in your preferences matches the spelling in the script, under $ham_cat and $spam_cat.

Current script doesn't use authentication.  See the API description https://tt-rss.org/redmine/projects/tt-rss/wiki/JsonApiReference to learn how to add username and password to the login() subroutine.

