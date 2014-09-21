function util()

	-- returns true if string is in the array
	local function str_in_arr(str, arr)
		for i,v in pairs(arr) do
			if v == str then
				return true
			end
		end	
		return false
	end

	-- get a tweetable line from the talk implementation
	local function get_conforming_post(impl)
		local msg = nil
		
		while msg == nil or msg:len() > 140 do
			msg = impl.talk()
		end
	
		return msg
	end
	
	-- split string by separator
	local function str_split(str, sep)
	    if str == nil then
	        return {}
	    else
	        local sep, fields = sep or " ", {}
	        local str = str.." "
	        local index = 1
	        while index <= str:len() do
	                local piece_end = str:find(sep, index)
	                if piece_end == nil then
	                        piece_end = str:len()
	                end
	                fields[#fields+1] = str:sub(index, piece_end - 1)
	                index = piece_end + 1
	        end
	        return fields
	    end
	end
	
	-- check if tweet id is new or has already been seen
	function is_new_id(i,sql)
		local s = sql.sql_query_fetch("SELECT COUNT(*) FROM `seen_tweets` WHERE `tweet_id`='"..sql.sql_escape(i).."'")
		if s[1]["COUNT(*)"] ~= "0" then
			return false
		else
			return true
		end
	end
	
	return {
	         str_in_arr          = str_in_arr,
			 get_conforming_post = get_conforming_post,
			 str_split           = str_split,
			 is_new_id           = is_new_id
		   }
	
end
