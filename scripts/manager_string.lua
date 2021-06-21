-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- 
-- SPLIT CLAUSES
--
-- The source string is divided into substrings as defined by the delimiters parameter.  
-- Each resulting string is stored in a table along with the start and end position of
-- the result string within the original string.  The result tables are combined into
-- a single table which is then returned.
--
-- NOTE: Set trimspace flag to trim any spaces that trail delimiters before next result 
-- string
--

function split(s, delimiters, trimspace)
	local results = {};
	
  	local delim_str = "[" .. delimiters .. "]+";
  	if trimspace then
  		delim_str = delim_str .. "%s*";
  	end

  	local str = "";
  	local index = 1;
  	local delim_start, delim_end = string.find(s, delim_str, index);
  	
  	while delim_start do
  		str = string.sub(s, index, delim_start - 1);
  		if str ~= "" then
  			table.insert(results, {val = str, startpos = index, endpos = delim_start});
  		end
  		index = delim_end + 1;
  		delim_start, delim_end = string.find(s, delim_str, index);
  	end
	local str = string.sub(s, index);
	if str ~= "" then
  		table.insert(results, {val = str, startpos = index, endpos = #s + 1});
  	end
	
	return results;
end
