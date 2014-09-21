function sql(u, p, d)

	require "luasql.mysql"
	local sql_conn = nil

	local function sql_connect(sql_user, sql_pass, sql_db)
		env = assert (luasql.mysql())
		con = assert (env:connect(sql_db, sql_user, sql_pass))
		return con
	end

	local function sql_query(query)
		local r,e = sql_conn:execute(query)
		return r,e
	end

	local function sql_escape(string)
		return sql_conn:escape(string)
	end

	local function sql_query_fetch(query)
		local r = {}
		local t = {}
		local q,e = sql_query(query)

		if q ~= nil then
			while q:fetch(t,"a") ~= nil do
				r[#r+1] = t
				t = {}
			end
			q:close()
		else
			print(e)
		end
		return r
	end
	
	sql_conn = sql_connect(u, p, d)
	
	return {
			sql_query = sql_query,
			sql_escape = sql_escape,
			sql_query_fetch = sql_query_fetch
		   }
end
