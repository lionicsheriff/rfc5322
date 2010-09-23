FIRST USE
=========

Before you do anything, you want some accounts in the config file.  Run 'fetchtweet -c -a accountname -m /path/to/maildir' and it will take you through the authentication process for the account. This only needs to be run once per account.
    
USAGE
=====
## fetchtweet [options]

    Options:
          --account, -a <s>:   Account to use
          --maildir, -m <s>:   Maildir to fetch to
       --last-tweet, -l <i>:   Id of last tweet retrieved
               --create, -c:   Add account to config
      --tweet-count, -t <i>:   Amount of tweets to retrieve
                 --help, -h:   Show this message

Fetchs tweets and stores them in maildir format. All accounts specified in ~/.rfc5322.rc are fetched.
    
## sendtweet [options] [tweet]

    Options:
      --account, -a <s>:   Account to use
           --create, -c:   Add account to config
         --pastebin, -p:   Send extra content of body to pastebin.com
      --maildir, -m <s>:   Maildir to fetch to (for account creation)
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
