if header["From"].match("@twitter>?$")
    if header["In-reply-to"]
        to = body[0].match("Excerpts from (.+)'s message")[1]
        header["Subject"] = "@#{to} "
    end
end
