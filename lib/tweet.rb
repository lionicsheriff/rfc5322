module Rfc5322
    class Tweet 
        attr_accessor :status, :in_reply_to_status_id, :id

        def initialize status,extra={}
            @status = status
            @in_reply_to_status_id = extra[:in_reply_to_status_id]
            @created_at = extra[:created_at]
            @screen_name = extra[:screen_name]
            @id = extra[:id]

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
                account.client.statuses.update! :id => @in_reply_to_status_id
            elsif @id
                account.client.statuses.update! :id => @id
            end
        end

        def to_email
            Email.new({
                :body => @status,
                :headers => { :subject => @status,
                              :from => @screen_name && "#{@screen_name}@twitter",
                              :in_reply_to => @in_reply_to_status_id && "<#{@in_reply_to_status_id}.statuses.twitter.com",
                              :references => @in_reply_to_status_id && "<#{@in_reply_to_status_id}.statuses.twitter.com",
                              :message_id => @id && "<#{@id}.statuses.twitter.com>",
                              :date => @created_at
                            }
            })
        end

    end
end
