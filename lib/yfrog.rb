module Rfc5322

require 'roauth'
require 'mime/types'
require 'net/http'
require 'rexml/document'

require 'yfrog_key.rb'
require 'twitter_key.rb'

class Yfrog
        def initialize(access_key,access_secret)
            @oauth_url = "https://api.twitter.com/1/account/verify_credentials.xml"
            oauth = {
                :access_key => access_key,
                :access_secret => access_secret,
                :consumer_key => Twitter_key,
                :consumer_secret => Twitter_secret
            }
            @oauth_result = (::ROAuth.header(oauth,@oauth_url,{})).to_s
        end

        def upload(contents,mime,name,type=:binary)

            # change encoding type to binary
            contents = case type
            when :base64 then Base64.decode64(contents)
            else
                contents # no change
            end

            boundary = "MULTIPARTrfc5322twitterMULTIPART"
            url = URI.parse('http://yfrog.com/api/xauth_upload')
            req = Net::HTTP::Post.new(url.path)
            req.add_field("Content-Type","multipart/form-data; boundary=#{boundary}")
            req.add_field("X-Auth-Service-Provider",@oauth_url)
            req.add_field("X-Verify-Credentials-Authorization",@oauth_result)

        req.body = <<REQ
--#{boundary}
Content-Disposition: form-data; name="media"; filename="#{name}"
Content-Type: #{mime}
Content-Transfer-Encoding: binary
Content-Length: #{contents.size}

#{contents}
--#{boundary}

--#{boundary}
Content-Disposition: form-data; name=\"key\"

#{Yfrog_key}
--#{boundary}--

REQ

            res = Net::HTTP.start(url.host, url.port) do |http|
                http.request(req)
            end
            doc = REXML::Document.new(res.body)
            if doc.elements["rsp"].attributes["stat"] == "ok"
                doc.elements["rsp"].elements.each("mediaurl") do |u| return u.text end
            end

            raise "Upload failed: #{res.body}"

        end

        def upload_file(path)
            contents = open(path,"rb") do |io| io.read end
            mime = MIME::Types.type_for(path).first.content_type
            upload contents,mime,File.basename(path),:binary 
        end

    end #class
end #module
