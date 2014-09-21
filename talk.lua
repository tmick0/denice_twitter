function talk(sql_impl)

	local sql = sql_impl

	-- parses incoming messages to populate dictionary
	local function talk_parse(string)
		local word1,word2
		local words = str_split(string, " ")

		for i=1,(#words+1) do
			local word = words[i]
			
			-- add to dictionary
			if word1 ~= nil then
				local temp1,temp2 = word,word2
				if temp1 == nil then
					temp1 = ""
				end
				if temp2 == nil then
					temp2 = ""
				end
				sql.sql_query(
					"INSERT INTO `dictionary` (`Word1`, `Word2`, `Word3`, `DateAdded`) " ..
					"VALUES('"..sql.sql_escape(temp2).."','"..sql.sql_escape(word1).."','"..sql.sql_escape(temp1).."','"..os.time().."')"
				)
			end
			word2 = word1		
			word1 = word

		end
	end

	-- operates on tree node and state table to help generate text
	local function extend_tree(working_node, data_table)
		local w1 = working_node.parent.value
		local w2 = working_node.value
	
		-- if we reached max entries, stop
		if #(data_table.end_nodes)+1 > data_table.max_entries then
			return
		end

		-- if we reached max depth, stop
		if working_node.depth + 1 > data_table.max_depth then
			if #(data_table.end_nodes) == 0 then
				data_table.max_nodes[#(data_table.max_nodes)+1] = working_node
			else
				data_table.max_nodes = {}
			end
			return
		end
	
		-- attempt to extend phrase
		local rows = sql.sql_query_fetch(
			"SELECT `Index`,`Word3` FROM `dictionary` WHERE `Word1` LIKE '"..sql.sql_escape(w1).."' "..
			"AND `Word2` LIKE '"..sql.sql_escape(w2).."' ORDER BY RAND() LIMIT 0,3"
		)

		-- remove nodes we already hit
		for i,v in pairs(rows) do
			if data_table.hit_nodes[v.Index] ~= nil and data_table.hit_nodes[v.Index] > data_table.max_hits then
				table.remove(rows, i)
			end
		end

		if #rows > 0 then
			for i,v in pairs(rows) do
				local new_node = {subnodes={},parent=working_node,value=v.Word3,depth=working_node.depth+1}
				working_node.subnodes[#(working_node.subnodes)+1] = new_node
				if data_table.hit_nodes[v.Index] == nil then
					data_table.hit_nodes[v.Index] = 0
				end
				data_table.hit_nodes[v.Index] = data_table.hit_nodes[v.Index] + 1
				extend_tree(new_node, data_table)
			end
		else -- perhaps should check if there are 'really' no rows or if there are no unhit rows...
			if working_node.depth > data_table.best_depth then
				data_table.best_depth = working_node.depth
			end
			data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
		end

	end

	-- collapses a run of the tree into a phrase
	local function climb_tree(leaf)
		local phrase = ""
		while leaf ~= nil do
			if leaf.value ~= nil and ((leaf.parent ~= nil and leaf.parent.parent ~= nil and #(leaf.subnodes) > 0) or leaf.value:len() > 0) then
				if phrase:len() > 0 and leaf.value:len() >0 then
					phrase = leaf.value .. " " .. phrase
				elseif leaf.value:len() > 0 then
					phrase = leaf.value
				end
			end
			leaf = leaf.parent
		end
		return phrase
	end

	-- generates text and either returns it or sends it to the channel
	local function talk()
		local phrase = ""
		local working_node
		local root_node
	
		-- parameters for building the tree
		local data_table = {
			hit_nodes={},  -- track indices already used to prevent repeats/loops
			node_count=0,  -- count nodes in tree
			end_nodes={},  -- track leaves representing complete strings
			max_nodes={},  -- track leaves representing strings of maximum length
			max_depth=30,  -- maximum word count
			best_depth=0,  -- current top word count
			max_entries=5 ,-- maximum number of leaves to complete before stopping
			max_hits=3     -- maximum number of times to hit one node
		}

		local rows = sql.sql_query_fetch("SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` WHERE `Word3` != '' ORDER BY RAND() LIMIT 0,1")

		if #rows < 1 then
			return nil
		end

		local w1 = rows[1].Word1
		local w2 = rows[1].Word2
		local w3 = rows[1].Word3
		local num_steps = 0
		local hit_end = false
		local t = NewStack()
		t:push(w3)
		t:push(w2)
		t:push(w1)
	
		-- attempt to build backward (use temporary stack)
		-- maybe we should throw out the content of the stack and attempt to build the tree from the first (last) 2 entries we find
		-- that strategy would not work if seed~=nil so maybe just build another tree backwards
		while not hit_end do
			local _w2 = t:pop()
			local _w3 = t:pop()
			t:push(_w3)
			t:push(_w2)
			local rows = sql.sql_query_fetch(
				"SELECT `Index`,`Word1` FROM `dictionary` WHERE `Word2` LIKE '"..sql.sql_escape(_w2).."' "..
				"AND `Word3` LIKE '"..sql.sql_escape(_w3).."' ORDER BY RAND()"
			)
			if #rows == 0 then
				hit_end = true
			else
				local selected_row = 1
			
				while selected_row <= #rows and not (data_table.hit_nodes[rows[selected_row].Index] == nil or data_table.hit_nodes[rows[selected_row].Index] < data_table.max_hits) do
					selected_row = selected_row + 1
				end
			
				if selected_row > #rows then
					hit_end = true
				else
					t:push(rows[1].Word1)
					if data_table.hit_nodes[rows[1].Index] == nil then
						data_table.hit_nodes[rows[1].Index] = 0
					end
					data_table.hit_nodes[rows[1].Index] = data_table.hit_nodes[rows[1].Index] + 1
				end
			end
			num_steps = num_steps + 1
		end
	
		-- add the contents of temp stack into main tree in reverse order
		root_node = {subnodes={},parent=nil,value=nil,depth=0}
		working_node = root_node

		while #t > 0 and working_node.depth < data_table.max_depth do
	                new_node = {subnodes={},parent=working_node,value=t:pop(),depth=working_node.depth+1}
	       	        working_node.subnodes[#(working_node.subnodes)+1] = new_node
	               	working_node = new_node
		end
	
		-- build tree down from end of initial run
		extend_tree(working_node, data_table)

		-- select random leaf and collapse the run into a phrase
		if #(data_table.end_nodes) > 0 then
			phrase = climb_tree(data_table.end_nodes[math.random(1,#(data_table.end_nodes))])
		else
			phrase = climb_tree(data_table.max_nodes[math.random(1,#(data_table.max_nodes))])
		end

		return phrase

	end
	
	return {talk_parse = talk_parse, talk = talk}
	
end
