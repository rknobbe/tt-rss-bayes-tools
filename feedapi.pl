#!/usr/bin/perl -w
use strict;
use warnings;
#use diagnostics;

use HTML::Strip;
use LWP::UserAgent;
use JSON::PP;
use Data::Dumper;
use Getopt::Std;
use AI::Categorize::NaiveBayes;


our ($opt_d, $opt_l,$opt_s,$opt_h);
$opt_d = 'ham-store.db';
$opt_l = 0; # 1 = don't learn
$opt_s = 0; # 1 = don't score
$opt_h = 0;

my $ham_cat  = "!! INTERESTING";
my $ham_label = 0; # query from API
my $spam_cat = "!! UNINTERESTING";
my $spam_label = 0; # query from API
my $ua = LWP::UserAgent->new();

my $c; # AI Categorize
my $m; # AI Map

my $url = "http://diskstation/tt-rss/api/";
my $session = "Not logged in";

sub init_db {
	$c = new AI::Categorize::NaiveBayes();
	if ( -e $opt_d) {
	print "Restore from $opt_d\n";
		$c->restore_state($opt_d); # reload machine saved for later use
	}
	$m = $c->cat_map();
}

sub learn_cat {
	my ($cat,$label,$mode) = @_;
	my $hs = HTML::Strip->new();
        my $resp = fetch_json("getHeadlines", {sid => $session, op => "getHeadlines",
            feed_id => $label,      # -2 == published
            is_cat => JSON::PP::false,
            show_content => JSON::PP::true,
            view_mode => $mode,
            include_attachments => JSON::PP::false});
        # Loop through the array to build a list of article ids.
        foreach my $art (@{$resp->{content}} ){
		$c->add_document($art->{id}, $cat, $hs->parse($art->{content}));
	}
}

sub learn() {

### Supply some training documents so it can learn how to categorize
	$c->stopwords('the','a','and','but','I');  # Ignore these words

#learn from feeds
	print "Learning: ", $ham_cat,"\n";
	learn_cat($ham_cat, $ham_label, "all_articles");
	learn_cat($spam_cat, $spam_label, "all_articles");
	learn_cat($spam_cat, -6, "all_articles"); #recently read

	$c->crunch();

}

sub score {

#score all unscored articles
	my ($cat,$label,$mode) = @_;
	my $hs = HTML::Strip->new();
        my $resp = fetch_json("getHeadlines", {sid => $session, op => "getHeadlines",
            feed_id => -4,      # -4 = all articles
            is_cat => JSON::PP::false,
            show_content => JSON::PP::true,
            view_mode => $mode,
            include_attachments => JSON::PP::false});
        # Loop through the array to build a list of article ids.
        foreach my $art (@{$resp->{content}} ){
		my $res = $c->categorize($hs->parse($art->{content}));
		if ($res->in_category($cat)) {
			print $cat,": Title: ", $art->{title}, "\n";
			api_tag($art->{id}, $label);
		}
	}
}

sub fetch_json
{
    my ($loc, $jsonHash) = @_;
    my $json_text = encode_json($jsonHash);
    my $response = $ua->post($url, Content => $json_text);
    die("$loc POST error: ".$response->status) if !$response->is_success;
    my $resp = decode_json($response->decoded_content);
    die("$loc Error: ".$resp->{content}->{error}) if $resp->{status} != 0;
    return $resp;
}

sub api_tag {
	my ($art, $lid) = @_;
	my $resp = fetch_json ("setArticleLabel", {sid => $session, 
						op => "setArticleLabel", 
						article_ids => $art, 
						label_id => $lid, 
						assign => 1});
	#print Dumper $resp->{content};
	#$resp = fetch_json("getArticle", {sid=>$session, op=>'getLabels',article_id=>$art});
	#foreach my $labels ( values $resp->{content}) {
		#print Dumper $labels;
	#}
}
	
#unused
sub tag() {
	print "Tagging Articles uniquely in the ", $ham_cat, " category\n";
	foreach my $doc ($m->documents_of($ham_cat)) {
		unless ($m->contains_document($spam_cat, $doc)) {
			#print "GUID ", $doc, "\n";
			api_tag($doc, $ham_label);
			
		}
	}
}

#get label numbers for our spam and ham (uninteresting and interesting) categories
sub findTags {
	my $resp = fetch_json("getLabels", {sid => $session, op => 'getLabels'});
	foreach  my $labels ( values $resp->{content} ) {
		if ($labels->{"caption"} eq $ham_cat) {
			$ham_label = $labels->{"id"};
			#print $labels->{"caption"},":", $labels->{"id"},"\n";
		}
		if ($labels->{"caption"} eq $spam_cat) {
			$spam_label = $labels->{"id"};
			#print $labels->{"caption"},":", $labels->{"id"},"\n";
		}
	}
	#print $ham_cat,"=",$ham_label,"\n";
	#print $spam_cat,"=",$spam_label,"\n";

}

sub login() {

	my $resp = fetch_json("Login", {op => 'login'});
	$session = $resp->{content}->{session_id};
	#print "Session ID = $session\n";
	$resp = fetch_json("getVersion", {sid => $session, op => "getVersion"});
	print "Version = ".$resp->{content}->{version}."\n";
	findTags();
		
}



## main

getopts('lshd:');
if ($opt_h) {
	print "-l: learn\n";
	print "-s: score\n";
	print "-d database: use alternate database\n";
	print "-h: help\n";
	print "default: don't score, don't learn, database=$opt_d\n";
	exit;
}

init_db();
login();
unless ($opt_l) {print "not learning\n"};
if ($opt_l) {
	learn();
}
unless ($opt_s) {print "not scoring\n"};
if ($opt_s){
	score($ham_cat, $ham_label, "unread");
	score($spam_cat, $spam_label, "unread");
}

# Save machine for later use
$c->save_state($opt_d);


#end
