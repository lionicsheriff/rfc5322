module Rfc5322
    require 'htmlentities'
    require 'grackle'
    
    require 'oauth_key.rb'

    require 'yfrog.rb'


    # Returns a connected client
    # Outh tokens created if not authorised
    # Assumes that config file is valid
    # {:accounts => {:account: => {}}}
    # {:accounts => {:account: => {:outh_token => string, :outh_token_secret => string}}}
    def login(account,config)
        if account != nil 
            account = account.to_sym #this way both strings and symbols work
            account_config = config[:accounts][account] 
        else
            # default to first account
            account_config = config[:accounts][config[:accounts].keys[0]]
        end
        if account_config == nil then raise "Account not found: #{account}" end
        
        # Account not authorised
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

    # Turns a tweet into an email
    # account is the account name, it used in the To: header
    # account@twitter is used so the sup account selector can be used (may be needed for
    # other email clients too)
    def create_email(tweet,account)
        # email can use more chars than html
        entities = HTMLEntities.new
        tweet.text = entities.decode(tweet.text)

        # fix date to be rfc 5322 valid so it can be used in mail clients
        # we get "Wed Aug 09 19:28:25 +0000 2010"
        # but we want "09 Aug 2010 19:28:25 +0000" 
        timestamp = DateTime.parse(tweet.created_at)
        tweet.created_at = timestamp.strftime("%d %b %Y %H:%M:%S %z")

        # I don't like empty headers lying around
        def optional_header(header,data,footer)
            if data != nil
                return "#{header}: <#{data}#{footer}>"
            else
                return "X-optional:"
            end
        end

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

# doubt this is the most efficient way, but I like the semantics of the email heredoc
return email.split("\n").delete_if{|l| l == "X-optional:"}.join("\n")
    end

    # Convert an email into a tweet
    # NOTE: This will not send a tweet, it merely maps common fields between emails and tweets
    # {:account => string, :screen_name =>, :status => string, :id => string, :in_repy_to_status_id => string}

    # Common mappings
    # * Subject:, body > status = the tweet itself (Subject: has precedence)
    # * From: > account = account to send from
    # * In-Reply-To: > in_reply_to_status_id = id of tweet being responded to (you still need @screen_name at the start of the status text)

    # These will usually not be used
    # * To: > screen_name = person to send to (for direct messages, not implemented yet)
    # * Message-Id: > id = status id, this is generated at twitter. Currently only used for retweeting a tweet that has been fetched but not processed by a mua
    def create_tweet(email,account)
        def parse_attachment(attach)
                attachment = {}
                attachment[:body]=""
                attach.each_line do |line|
                    unless line == nil or line == ""
                        case line
                        when /^.+:/ then 
                                split = line.split(":")
                                attachment[split[0]] = split[1]
                        else
                                attachment[:body] << line
                        end
                    end
                end
                return attachment
        end

        tweet = {}
        parts = []
        boundary =""
        in_part = false
        email.each_line do |line|
            if line.strip != ""
                split=line.split(" ")
                case split[0].downcase
                when "from:" then tweet[:account] = split[1].match("<?([^\\W]+)(@twitter)?")[1]
                when "to:" then tweet[:screen_name] = split[1].match("<?([^\\W]+)(@twitter)?")[1] 
                when "subject:" then tweet[:status] = split[1..-1].join(" ")
                when "message-id:" then tweet[:id] = split[1].match("<(\\d+)\.")[1]
                when "in-reply-to:" then tweet[:in_reply_to_status_id] = split[1].match("<(\\d+)\.")[1]
                when "content-type:" then if split[1] == "multipart/mixed;" then 
                    boundary = split[2].split("\"")[1].downcase 
                elsif in_part
                        parts.last << line
                end
            when "--#{boundary}" then 
                    in_part = true
                    parts << ""
            when "--#{boundary}" then in_part = false
                else
                    if in_part
                        parts.last << line
                    end
                    unless tweet[:status] or split[0].match(':$') 
                        tweet[:status] = line
                    end
                end
            end
        end


        # deal with attachments
        parts.each do |p|
            part = parse_attachment(p)
            if part["Content-Type"] and part["Content-Type"].match(/image\//) then
                yf = Yfrog.new account[:oauth_token],account[:oauth_token_secret]
                filename = part["Content-Type"].match(/name=['"](.*)['"]/)[1] # this might not work for all emails. Currently just focused on rmail (used in sup)
                mime = part["Content-Type"].match(/(image\/.*);/)[1]
                tweet[:status] << " " + yf.upload_image_b64(part[:body],mime,filename)
            end
        end


        # shrink status

        # shorten urls

        # if it is too long still run through tweetshrink


        return tweet
    end

end
