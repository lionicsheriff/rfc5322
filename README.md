FIRST USE
=========

Before you do anything, you want some accounts in the config file.  Run 
    
    fetchtweet --create --account accountname --maildir /path/to/maildir
    
and it will take you through the authentication process for the account. This only needs to be run once per account.

You can also add some queries. Unlike the previous command these don't require an account. Run 

    fetchtweet --create --query "query string here" --maildir /path/to/maildir

Since the results for queries are quickly updating and they are not as important as tweets shown in your home timeline, you may want to limit the results
    
    fetchtweet --create --count 3 --lang code --query "query string here" --maildir /path/to/maildir

USAGE
=====
## fetchtweet [options]

    Options:
         --account, -a <s>:   Account to use
           --query, -q <s>:   Query to use
         --no-accounts, -n:   Don't fetch home timelines
          --no-queries, -o:   Don't fetch queries

    Single account or query only
              --create, -c:   Add account or query to config
         --maildir, -m <s>:   Maildir to fetch to
      --last-tweet, -l <s>:   Id of last tweet retrieved
           --count, -u <i>:   Amount of tweets to retrieve (default: 100)

    Query only
            --lang, -g <s>:   Language of tweets (ISO 639-1) (default: )

                --help, -h:   Show this message

Fetchs tweets and stores them in maildir format. Unless specified all accounts and queries in ~/.rfc5322.rc are fetched. By running --query without --create, you can search twitter and store the tweets without saving status to the configuration file.
    
## sendtweet [options] [tweet]

    Options:
      --account, -a <s>:   Account to use
         --pastebin, -p:   Send extra content of body to pastebin.com
             --help, -h:   Show this message

Sends a tweet using specified account (defaults to first in config file).

### EMAIL

You can pipe an email into sendtweet. The tweet text is either the subject or the first line of the body. Sendtweet determines what account to use by the 'from:' header. For compatiblity with email clients you can use either accountname or accountname@twitter .

If --pastebin is given anything left in the body is sent to [pastebin](http://pastebin.com) and the url is appended.

Any image or video attachment is uploaded to [yfrog](http://yfrog.com) and the link is appended to the tweet.

EXAMPLES
========

Tweet from the commandline

    sendtweet Hey

Tweet with a specific account

    sendtweet --account lionicsheriff Hey! Listen!

Tweet using email format

    echo From: lionicsheriff \\n Subject: Over here! | sendtweet

Use email format with specific account

    cat email | sendtweet --account lionicsheriff

CONFIG
======

## ~/.rfc5322.rc
    
Simplest config file is:
    
    ---
    :accounts: 
        :accountname: 
            :maildir: /path/to/maildir
    

Queries can be added with:

    :queries:
        your query string here:
            :maildir: /path/to/maildir

Queries have a few option variables too

        :count: number of tweets
        :lang: ISO 639-1 format

Full Config example

    ---
    :accounts: 
        :accountname: 
            :maildir: /path/to/maildir
    :queries:
        your query string here:
            :maildir: /path/to/another_maildir
            :count: 1
            :lang: en

EMAIL -> TWEET MAPPING
======================

The relevant parts are:

* From:
    + the account to use
    + screen_name@twitter
* Subject: 
    + the tweet
    + must lead with @screen_name for reply
    + must lead with RT for retweet
* In-reply-to: 
    + used for replies and retweets
    + statusid.statuses.twitter.com
* Message-id: 
    + used for retweets if In-reply-to is not set
    + statusid.statuses.twitter.com
* Body
    + first line is the tweet (Subject: takes precedence)
    + leftovers can be sent to pastebin
* Attachments
    + images are uploaded to yfrog and the url is appended to the tweet
