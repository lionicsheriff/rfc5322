require 'roauth'
require 'mime/types'

require 'yfrog_key.rb'

class Yfrog
    def initialize(access_key,access_secret)
        @oauth_url = "https://api.twitter.com/1/account/verify_credentials.xml"
        oauth = {
            :access_key => access_key,
            :access_secret => access_secret,
            :consumer_key => Consumer_key,
            :consumer_secret => Consumer_secret
        }
        @oauth_result = (::ROAuth.header(oauth,@oauth_url,{})).to_s
    end

    def upload_image_b64(img,mime,name)


        boundary = "MULTIPARTrfc5322twitterMULTIPART"
        url = URI.parse('http://yfrog.com/api/xauth_upload')
        req = Net::HTTP::Post.new(url.path)
        req.add_field("Content-Type","multipart/form-data; boundary=#{boundary}")
        req.add_field("X-Auth-Service-Provider",@oauth_url)
        req.add_field("X-Verify-Credentials-Authorization",@oauth_result)

        part = <<PART
Content-Disposition: form-data; name="media"; filename="#{name}"
Content-Type: #{mime}
Content-Transfer-Encoding: binary

#{Base64.decode64(img)}
PART

        req.body = <<REQ
--#{boundary}\nContent-Length: #{part.size}
Content-Disposition: form-data; name=\"media\"; filename=\"test.jpg\"
#{part}
--#{boundary}--

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
        raise "Upload failed"

    end

    def upload_image_file(path)
        url = URI.parse('http://yfrog.com/api/xauth_upload')
        image = File.open(path)
        mime = MIME::Types.type_for(path)[0].content_type
        req = Net::HTTP::Post::Multipart.new url.path,"media" => UploadIO.new(image, mime, path),"key" => Yfrog_key
        req.add_field("X-Auth-Service-Provider",@oauth_url)
        req.add_field("X-Verify-Credentials-Authorization",@oauth_result)
        res = Net::HTTP.start(url.host, url.port) do |http|
            http.request(req)
        end
        doc = REXML::Document.new(res.body)
        if doc.elements["rsp"].attributes["stat"] == "ok"
            doc.elements["rsp"].elements.each("mediaurl") do |u| return u.text end
        end
        raise "Upload failed"
    end

    def upload_video_file(path)
        upload_image_file(path)
    end

end
