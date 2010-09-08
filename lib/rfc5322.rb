module Rfc5322
    require 'rubygems'
    require 'htmlentities'
    require 'grackle'
    
    require 'oauth_key.rb'

    def login(account,config)
        if account != nil
            account = account.to_sym #this way both strings and symbols work
            account_config = config[:accounts][account]
        else
            account_config = config[:accounts][config[:accounts].keys[0]]
        end
        if account_config == nil then raise "Account not found: #{account}" end
        
        if account_config[:oauth_token] == nil or account_config[:oauth_token_secret] == nil
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

            account_config[:oauth_token] = access_token.token
            account_config[:oauth_token_secret] = access_token.secret

        end
        

        client = Grackle::Client.new(:auth=>{
            :type=>:oauth,
            :consumer_key=>Consumer_key, :consumer_secret=>Consumer_secret,
            :token=>account_config[:oauth_token], :token_secret=>account_config[:oauth_token_secret]
        })
        
        
=begin If I want to start storing the id
        if account_config[:id] == nil
            account_config[:id]=client.account.update_profile![:id]
        end
=end
        
        return client
    end

    def create_email(tweet,account)
        # I don't like empty headers lying around
        def optional_header(header,data,footer)
            if data != nil
                return "#{header}: <#{data}#{footer}>"
            else
                return "X-optional:"
            end
        end

        entities = HTMLEntities.new
        tweet.text = entities.decode(tweet.text)

        # fix date to be rfc 5322 valid so it can be used in mail clients
        # we get "Wed Aug 09 19:28:25 +0000 2010"
        # but we want "09 Aug 2010 19:28:25 +0000" 
        timestamp = DateTime.parse(tweet.created_at)
        tweet.created_at = timestamp.strftime("%d %b %Y %H:%M:%S %z")

        email = <<EMAIL
From: #{tweet.user.screen_name}@twitter
To: #{account}@twitter
Subject: #{tweet.text}
Date: #{tweet.created_at}
Message-ID: <#{tweet.id}.statuses.twitter.com>
#{optional_header "In-Reply-To",tweet.in_reply_to_status_id,".statuses.twitter.com"}
#{optional_header "References:",tweet.in_reply_to_status_id,".statuses.twitter.com"}
MIME-Version: #{"1.0"}
Content-Type: #{"text/plain; charset=UTF-8"}

#{tweet.text}
EMAIL

# doubt this is the most efficient way
return email.split("\n").delete_if{|l| l == "X-optional:"}.join("\n")
    end

    def create_tweet(email)
        tweet = {}
        email.each_line do |line|
            if line != ""
                split=line.split(" ")
                case split[0].downcase
                when "from:" then tweet[:account] = split[1].match("<?([^\\W]+)(@twitter)?")[1]
                when "to:" then tweet[:screen_name] = split[1].match("<?([^\\W]+)(@twitter)?")[1] 
                when "subject:" then tweet[:status] = split[1..-1].join(" ")
                when "message-id:" then tweet[:id] = split[1].match("<(\\d+)\.")[1]
                when "in-reply-to:" then tweet[:in_reply_to_status_id] = split[1].match("<(\\d+)\.")[1]
                else
                    unless tweet[:status] or split[0].match(':$') 
                        tweet[:status] = line
                    end
                end
            end
        end
        return tweet
    end
end
