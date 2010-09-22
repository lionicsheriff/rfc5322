USAGE
=====
## fetchtweet [--add-account string] 

Fetchs tweets and stores them in maildir format. All accounts specified in ~/.rfc5322.yaml are fetched.

--add-account creates an account in ~/.rfc5322.yaml before fetching
    
## sendtweet [--account string] [tweet]

Sends a tweet using specified account (defaults to first in config file).
It also accepts an email piped into it (see EMAIL)

Attached images are uploaded to yfrog and the url is appended to the tweet

EXAMPLES
========

Tweet from the commandline

    sendtweet Hey

Tweet with a specific account

    sendtweet --account lionicsheriff Hey! Listen!

Retweet a tweet that has already been fetched

    cat email | sendtweet RT

Tweet using email format

    echo From: lionicsheriff \\n Subject: Over here! | sendtweet

Use email format with specific account

    cat email | sendtweet --account lionicsheriff

CONFIG
======

## ~/.rfc5322.yaml
    
Simplest config file is:
    
    ---
    :accounts: 
        :accountname: 
            :maildir: /path/to/maildir
    
AUTHENTICATION
==============

Run fetchtweet (or fetchtweet --add-account) and it will take you through the authentication process for each account in the config file. This only needs to be run once per account.
    
EMAIL
=====

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
* Attachments
    + images are uploaded to yfrog and the url is appended to the tweet
