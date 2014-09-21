-- [[ config ]] --

-- sql stuff
local sql_user = ""
local sql_pass = ""
local sql_db   = "denice_twitter"

-- twitter api key and secret
local api_key = ""
local api_sec = ""

-- twitter access token and secret
local acc_tok = ""
local acc_sec = ""


-- [[ load libraries ]] --

dofile("stack.lua")
dofile("util.lua")
dofile("sql.lua")
dofile("twitter.lua")
dofile("talk.lua")

-- [[ create singletons ]] --

local twitter_api = twitter(api_key, api_sec, acc_tok, acc_sec)
local sql_impl    = sql(sql_user, sql_pass, sql_db)
local talk_impl   = talk(sql_impl)
local utils       = util()

-- [[ perform action ]] --

function main()

	if #arg ~= 1 or not utils.str_in_arr(arg[1], {"fetch", "post", "test", "stats"}) then
		print("usage: lua " .. arg[0] .. " (fetch|post|test|stats)")
		return
	end
	
	if arg[1] == "fetch" then
	
		local q = sql_impl.sql_query_fetch("SELECT `tweet_id` FROM `seen_tweets` ORDER BY `tweet_id` DESC LIMIT 0,1")
		local last_tweet = nil
	
		if q[1] ~= nil then
			last_tweet = q[1].tweet_id
		end

		local t = twitter_api.fetch_tweets(last_tweet)

		for i,v in ipairs(t) do
			if utils.is_new_id(v.id_str, sql_impl) then
				talk_impl.talk_parse(v.text)
				sql_impl.sql_query("INSERT INTO `seen_tweets` VALUES ('"..sql_escape(v.id_str).."', '"..os.time().."')")
			end
		end
		
	elseif arg[1] == "post" then
	
		twitter_api.post_tweet(utils.get_conforming_post(talk_impl))
		
	elseif arg[1] == "test" then
	
		print(utils.get_conforming_post(talk_impl))
		
	elseif arg[1] == "stats" then
		
		local q1 = sql_impl.sql_query_fetch("SELECT COUNT(*) FROM `dictionary`")
		local q2 = sql_impl.sql_query_fetch("SELECT COUNT(*) FROM `seen_tweets`")

		print("seen "..q2[1]["COUNT(*)"].." tweets, have "..q1[1]["COUNT(*)"].." dictionary rows")
	
	end

end

main()
