module Rfc5322
require 'tweet.rb'
require 'email.rb'

require 'grackle'
require 'htmlentities'

require 'oauth_key.rb'

    class Twitter
        attr_accessor :access_key,:access_secret,:client,:name

        def initialize access_key=nil,access_secret=nil,extra={}
            @access_key=access_key
            @access_secret=access_secret
            @name = extra[:name] ? extra[:name] : nil

            authenticate
        end

        def authenticate 

            # Account not authorised
            if @access_key == nil or @access_secret == nil
                consumer = OAuth::Consumer.new(
                    Consumer_key,
                    Consumer_secret,
                    {:site => 'http://twitter.com'} 
                )
                request_token = consumer.get_request_token(:oauth_callback => "oob")

                puts "Follow this url to authorize: " + request_token.authorize_url
                print "PIN: "
                pin = gets.strip

                access_token = request_token.get_access_token(:oauth_verifier => pin)

                @access_key = access_token.token
                @access_secret = access_token.secret
            end

            @client = Grackle::Client.new(:auth=>{
                :type=>:oauth,
                :consumer_key=>Consumer_key, :consumer_secret=>Consumer_secret,
                :token=>@access_key, :token_secret=>@access_secret,
            })
        end

        def tweet_email(email)
            email.to_tweet.tweet self
        end

        def fetch_tweets(maildir,since_id=1,count=200)
            since_id ||= 1
            count ||= 200
            timeline=client.statuses.home_timeline? :since_id => since_id,:count => count
            if timeline.length > 0 then
                    timeline.reverse.each do |tweet|
                        # plaintext email can use more chars than html
                        entities = HTMLEntities.new
                        tweet.text = entities.decode(tweet.text)

                        # fix date to be rfc 5322 valid so it can be used in mail clients
                        # we get "Wed Aug 09 19:28:25 +0000 2010"
                        # but we want "09 Aug 2010 19:28:25 +0000" 
                        timestamp = DateTime.parse(tweet.created_at)
                        tweet.created_at = timestamp.strftime("%d %b %Y %H:%M:%S %z")

                        # create email through tweet class to normalize tweet->email
                        (Tweet.new tweet.text,:id => tweet.id,
                                              :in_reply_to_status_id => tweet.in_reply_to_status_id,
                                              :created_at => tweet.created_at,
                                              :screen_name => tweet.user.screen_name).to_email.store_maildir maildir
                end
            end
            timeline.first.id
        end
    end #class Twitter
end #module Rfc5322
