module Rfc5322
    class Email
    require 'maildir'

        attr_accessor :headers, :body, :attachments

        def initialize options = {}
            @headers = options[:headers] ? options[:headers] : {}
            @body = options[:body] ? options[:body] : ""
            @attachments = options[:attachments] ? options[:attachments] : []
            if options[:from_string] then load_string options[:from_string] end
        end

        def load_string str
            in_part = false
            str.each_line do |line|
                if line.strip == "" then next end # ignore empty lines
                case line.downcase
                when /content-type: (.*)/ then 
                    if $1 =~ /boundary="(.*)"/ then 
                        @boundary = $1.downcase 
                        @headers[:content_type] = line.match(/.+: (.+)/)[1]
                    elsif in_part
                        @attachments.last[:headers][:content_type] = line.match(/.+: (.+)/)[1]
                    else
                        @headers[:content_type] = line.match(/.+: (.+)/)[1]
                    end
                when /--#{@boundary}/ then 
                    in_part = true
                    @attachments << {:body => "", :headers =>{}}  # add a new part
                when /--#{@boundary}--/ then in_part = false
                when /(.+): .+/ then 
                    unless in_part then
                        @headers[$1.gsub(/-/,"_").to_sym] = line.match(/.+: (.+)/)[1]
                    else
                        @attachments.last[:headers][$1.gsub(/-/,"_").to_sym] = line.match(/.+: (.+)/)[1]
                    end
                else
                    if in_part
                        @attachments.last[:body] << line
                    else
                        @body << line
                    end
                end
            end
            # move inline attachments to body
            @attachments.delete_if do |a|
                if a[:body] == "" then # no point keeping empty parts
                    true
                elsif a[:headers][:content_disposition] == "inline" then
                    # might want to deal with content-type too
                    @body << a[:body]
                    true
                else
                    false
                end
            end
        end

        def to_tweet
            # Subject: > First line of body
            tweet = Tweet.new @headers[:subject] || body.lines.first
            #NOTE: if the id is in the wrong format an error will be raised
            tweet.in_reply_to_status_id = @headers[:in_reply_to_id] && @headers[:in_reply_to_id].match(/<(\d+)\.statuses\.twitter\.com>/)[1] # id format fetched with this program
            tweet.id = @headers[:message_id] && @headers[:message_id].match(/<(\d+)\.statuses\.twitter\.com>/)[1] # id format fetched with this program
            tweet
        end

        def to_s
            def header k,v
                if v then k.to_s.capitalize.gsub(/_/,'-') + ": " + v.to_s + "\n" end
            end
<<EMAIL
#{@headers.keys.collect do |k| header k,@headers[k] end}

#{body}

#{@attachments.collect do |a| 
    "\n--#{@boundary}\n" <<
    (a[:headers].keys.collect do |k|
        header k,a[:headers][k]
    end).to_s <<
    "\n#{a[:body]}"
end}

#{@boundary && "--#{@boundary}--"}
EMAIL
        end

        def store_maildir dir
            maildir = Maildir.new(dir)
            maildir.add to_s
        end
    end #class
end #module
