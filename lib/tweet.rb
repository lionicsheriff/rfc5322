module Rfc5322
    require 'unicode'

    TweetLengthError = Class.new StandardError

    class Tweet 
        attr_accessor :status, :in_reply_to_status_id, :id

        def initialize status="",extra={}
            @status = status
            @in_reply_to_status_id = extra[:in_reply_to_status_id]
            @created_at = extra[:created_at]
            @screen_name = extra[:screen_name]
            @id = extra[:id]
        end

        def length
            Unicode::normalize_C(@status).length
        end

        # should this be made less grackle dependant?
        def tweet account
            if @in_reply_to_status_id then
                account.client.statuses.update! :status => @status, :in_reply_to_status_id=>@in_reply_to_status_id
            else
                account.client.statuses.update! :status => @status
            end
        end

        def retweet account
            if @status[0..1].upcase != "RT" then @status = "RT " + @status end
            if @in_reply_to_status_id then
                account.client.statuses.retweet! :id => @in_reply_to_status_id
            elsif @id
                account.client.statuses.retweet! :id => @id
            end
        end

        def post account
            if @status[0..1].upcase == "RT" then
                retweet account
            else
                shorten_urls
                attempt = 1
                begin
                    if length <= 140
                        tweet account
                    else
                        attempt += 1
                        raise TweetLengthError,"Tweet status is too long (#{length} characters)"
                    end
                rescue TweetLengthError => e
                    if attempt > 2 then
                        raise e
                    else
                        shorten_text
                        retry
                    end 
                end
            end
        end

        # go through status and shorten every long url
        def shorten_urls
            @status = (@status.split(" ").collect do |word|
                if word =~ URI::regexp and word.length > 30 then
                    # using tinyurl
                    # NOTE: look into retwt.me, they have a simple api (w/o auth) and provide analysis
                    (Net::HTTP.post_form URI.parse('http://tinyurl.com/api-create.php'),{"url" => word}).body
                else
                    word
                end
            end).join(" ")
        end

        def shorten_text
            # use tweetshrink service
            @status = (Net::HTTP.post_form URI.parse('http://tweetshrink.com/shrink'),{'format' => 'string', 'text' => @status}).body
        end



        def to_email
            long_urls,hash_tags,mentions = @status.split(" ").reduce([[],[],[]]) do |urls,word|
                case word
                when URI::regexp then
                        response = Net::HTTP.get_response URI.parse word 
                        urls[0] << response.header["location"] if response.code[0] == ?3 
                when /^#/ then urls[1] << "http://twitter.com/search/%23#{word[1..-1]}"
                when /^@/ == ?@ then urls[2] << "http://twitter.com/#{word[1..-1]}"
                end rescue urls
                urls
            end
            long_urls = long_urls.length > 0 ? long_urls.join("\n").insert(0,"\n") << "\n" : ""
            hash_tags = hash_tags.length > 0 ? hash_tags.join("\n").insert(0,"\n") << "\n" : ""
            mentions = mentions.length > 0 ? mentions.join("\n").insert(0,"\n") << "\n" : ""


            Email.new({
                :body => <<BODY + long_urls + hash_tags + mentions,
#@status
--
http://twitter.com/#@screen_name
http://twitter.com/#@screen_name/status/#@id
BODY

                :headers => { :subject => @status.lines.count > 1 ? @status.lines.first.strip : @status,
                              :from => @screen_name && "#{@screen_name}@twitter",
                              :in_reply_to => @in_reply_to_status_id && "<#{@in_reply_to_status_id}.statuses.twitter.com>",
                              :references => @in_reply_to_status_id && "<#{@in_reply_to_status_id}.statuses.twitter.com>",
                              :message_id => @id && "<#{@id}.statuses.twitter.com>",
                              :date => @created_at
                            }
            })
        end

    end
end
