function twitter(ak, as, ct, cs)

	local api_key = ak
	local api_sec = as
	local acc_tok = ct
	local acc_sec = cs


	local req_url = "https://api.twitter.com/oauth/request_token"
	local acc_url = "https://api.twitter.com/oauth/access_token"
	local aut_url = "https://api.twitter.com/oauth/authorize"


	local OAuth = require("OAuth")
	local client = OAuth.new(api_key, api_sec, {
		RequestToken     = req_url,
		AccessToken      = acc_url,
		AuthorizeUser    = {aut_url, method="GET"}
	},{
		OAuthToken       = acc_tok,
		OAuthTokenSecret = acc_sec
	})

	local function fetch_tweets(last_tweet)
		local settings = {
			trim_user = true,
			include_entities = false,
			contributor_details = false,
			count = 200
		}
		if last_tweet ~= nil then
			settings.since_id = last_tweet
		end

		local c, h, s, r = client:PerformRequest("GET", "https://api.twitter.com/1.1/statuses/home_timeline.json", settings)

		if c ~= 200 then
			print('failed to fetch tweets: ' .. c .. ' / ' ..s)
			print(r)
			return nil
		end

		local json = require('json')
		return json.decode(r)
	end

	local function post_tweet(tweet)
		local settings = {
			status = tweet
		}

		local c,h,s,r = client:PerformRequest("POST", "https://api.twitter.com/1.1/statuses/update.json", settings)

		if c ~= 200 then
			print('failed to post tweet: ' .. c .. ' / ' ..s)
			print(r)
			return nil
		end
	end
	
	return { fetch_tweets = fetch_tweets,
	         post_tweet   = post_tweet    }

end


