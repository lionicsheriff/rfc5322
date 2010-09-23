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
            Email.new({
                :body => @status,
                :headers => { :subject => @status,
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
