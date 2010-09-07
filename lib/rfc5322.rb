module Rfc5322
    require 'rubygems'
    require 'htmlentities'
    require 'grackle'
    
    require 'oauth_key.rb'

    def login(account,config)
        if account != nil
            account_config = config[:accounts][account]
        else
            account_config = config[:accounts][config[:accounts].keys[0]]
        end
        if account_config == nil then raise "Account not found" end
        
        if account_config[:oauth_token] == nil or account_config[:oauth_token_secret] == nil
            consumer = OAuth::Consumer.new(
                Consumer_key,
                Consumer_secret,
                {:site => 'http://twitter.com'} 
            )
            request_token = consumer.get_request_token(:oauth_callback => "oob")

            puts "Follow this url to authorize: " + request_token.authorize_url
            `open #{request_token.authorize_url}`
            print "PIN: "
            pin = gets.strip

            access_token = request_token.get_access_token(:oauth_verifier => pin)

            account_config[:oauth_token] = access_token.token
            account_config[:oauth_token_secret] = access_token.secret

        end
        

        return Grackle::Client.new(:auth=>{
            :type=>:oauth,
            :consumer_key=>Consumer_key, :consumer_secret=>Consumer_secret,
            :token=>account_config[:oauth_token], :token_secret=>account_config[:oauth_token_secret]
        })
    end

    def create_email(tweet,account)
        # I don't like empty headers lying around
        def optional_header(header,data,footer)
            if data != nil
                return "#{header}: #{data}#{footer}"
            else
                return "X-optional:"
            end
        end

        entities = HTMLEntities.new
        tweet.text = entities.decode(tweet.text)

        # fix date to be rfc 5322 valid so it can be used in mail clients
        # we get "Wed Aug 09 19:28:25 +0000 2010"
        # but we want "09 Aug 2010 19:28:25 +0000" 
        date = Date.parse(tweet.created_at)            
        tweet.created_at = date.strftime("%d %b %Y %H:%M:%S %z")

        email = <<EMAIL
From: #{tweet.user.screen_name}
To: #{account}
Subject: #{tweet.text}
Date: #{tweet.created_at}
Message-ID: #{tweet.id}.twitter.com
#{optional_header "In-Reply-To",tweet.in_reply_to_status_id,".twitter.com"}
MIME-Version: #{"1.0"}
Content-Type: #{"text/plain; charset=UTF-8"}

#{tweet.text}
EMAIL

# doubt this is the most efficient way
return email.split("\n").delete_if{|l| l == "X-optional:"}.join("\n")
    end

    def create_tweet(email)
        tweet = {}
        email.split("\n").each do |line|
            split=line.split(" ")
            case split[0]
            when "From:" then tweet[:account] = split[1..-1].join(" ")
            when "To:" then tweet[:screen_name] = split[1..-1].join(" ")
            when "Subject:" then tweet[:status] = split[1..-1].join(" ")
            when "Message-ID:" then tweet[:id] = split[1].split(".")[0]
            when "In-Reply-To:" then tweet[:in_reply_to_status_id] =  split[1].split(".")[0]
            else
                unless tweet[:status] or line == "" or split[0].match(':$') 
                    tweet[:status] = line
                end
            end
        end
        return tweet
    end
end
