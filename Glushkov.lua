-- Class construct servicing single inheritances by using metatables and
-- a direct translation of regex.cpp in lua
-- dzchoi, Mar/22/2015

-- We wanted lua to have the responsibility for creating regex trees, hoping:
-- - lua creates, manipulates and returns regexs dynamically inside other regexs
-- - for delayed construction and lazy evaluation



-- A class is not a type but is an object of the common metatable for all its instance
-- objects or all its derived class objects that contains default shared methods(members)
-- for them. So, the relationship of "A is an instance or a derived class of B" is
-- denoted by "B is the metatable for A".

-- Is this an instance or a derived class of some (ancestor) class?
local function is_a(self, class)
    -- self may be an instance or a class
    while self do
	if self == class then return true end
	self = getmetatable(self)	-- go to its base class
    end
    return false
end

-- default construct for a new instance of a class
local function new(self, table)
    -- self is supposed to be a class and table, an instance
    if self.__index == self then
	-- new() should be called through a class only, not an instance
	return setmetatable(table or {}, self)
    end
    -- return nil otherwise
end

-- creates a (derived) class from an optional base by expanding a table
function class(base, table)	-- to be defined in the global namespace
    -- The table itself gets expanded to fit a class object and takes the responsibility
    -- of providing default members to its instances or its derived classes. These
    -- default members of a class will remain invariant through instantiations of the
    -- class.

    if base and base.__index == base then -- if base is indeed a class, derive it
	table = base:new(table or {})
	-- inherit some metamethods here, since metamethods unlike other methods are not
	-- redirected through __index
	table.__call = table.__call or base.__call
	-- base class's new() gets inherited if not provided
    else -- define a root class now
	-- if base is not an actual class, regard it as a simple table discarding the
	-- argument table
	table = base or {}		-- reuse and overwrite base
	table.new = table.new or new	-- constructor for its new instances
	table.is_a = table.is_a or is_a	-- function to tell its base class
	-- A root class has a default new() and is_a() to be inherited for needs
    end

    table.__index = table		-- to share all class members to its instances
    return table			-- return the class just created
end



-- abstract base class for regular expressions
regex = class {
    nullable = false,
    open = false,
    -- virtual: __call = function (self, c, m) ... end
}

-- "c", ".", "[abc]", "[^abc]"
regex_sym = class(regex, {
    -- virtual: match = function (self, c) ... end
    __call = function (self, c, m) -- override (will be moved into the C world)
	-- m is false(nil) by default
	return m and self:match(c)
    end
})

-- "c"
regex_lit = class(regex_sym, {
    -- c : a character
    match = function (self, c) -- override
	return c == self.c
    end
})

-- "."
regex_any = class(regex_sym, {
    match = function () return true end -- not using arguments self and c
})

-- "[abc]"
regex_ccl = class(regex_sym, {
    -- s : set of characters
    match = function (self, c) -- override
	return self.s[c] ~= nil
    end
})

-- "[^abc]"
regex_ncc = class(regex_sym, {
    -- s : set of characters
    match = function (self, c) -- override
	return self.s[c] == nil
    end
})

-- "r*"
regex_rep = class(regex, {
    -- r : inner expression
    nullable = true, -- always nullable
    r_matched = false,
    __call = function (self, c, m) -- override
	if m or self.open then
	    self.r_matched = self.r(c, m or self.r_matched)
	    self.open = self.r.open or self.r_matched
	    return self.r_matched
	end
	return false
    end
})

-- "r?" (providing the missing epsilon)
regex_opt = class(regex, {
    -- r : inner expression
    nullable = true, -- always nullable
    r_matched = false,
    __call = function (self, c, m) -- override
	if m or self.open then
	    local r_matched = self.r(c, m)
	    self.open = self.r.open
	    return r_matched
	end
	return false
    end
})

-- "r+"
regex_pcl = class(regex_rep, {
    new = function (self, table)
	-- self is supposed to be a class and table, an instance
	self.nullable = table.r.nullable
	return new(self, table)
    end
    -- nullable needs updating at run-time for zero-width assertions
})

-- "pq"
regex_seq = class(regex, {
    -- p : left part
    -- q : right part
    p_matched = false,
    new = function (self, table)
	-- self is supposed to be a class and table, an instance
	self.nullable = table.p.nullable and table.q.nullable
	return new(self, table)
    end,
    __call = function (self, c, m) -- override
	if m or self.open then
	    local q_matched = self.q(c, m and self.p.nullable or self.p_matched)
	    self.p_matched = self.p(c, m)
	    self.open = self.p.open or self.p_matched or self.q.open
	    -- nullable needs updating at run-time for zero-width assertions
	    return self.p_matched and self.q.nullable or q_matched
	end
	return false
    end
})

-- "p|q"
regex_alt = class(regex, {
    -- p : left part
    -- q : right part
    new = function (self, table)
	-- self is supposed to be a class and table, an instance
	self.nullable = table.p.nullable or table.q.nullable
	return new(self, table)
    end,
    __call = function (self, c, m) -- override
	if m or self.open then
	    local p_matched = self.p(c, m)
	    local q_matched = self.q(c, m)
	    self.open = self.p.open or self.q.open
	    -- nullable needs updating at run-time for zero-width assertions
	    return p_matched or q_matched
	end
	return false
    end
})

-- "p&q"
regex_and = class(regex, {
    -- p : left part
    -- q : right part
    new = function (self, table)
	-- self is supposed to be a class and table, an instance
	self.nullable = table.p.nullable and table.q.nullable
	return new(self, table)
    end,
    __call = function (self, c, m) -- override
	if m or self.open then
	    local p_matched = self.p(c, m)
	    local q_matched = self.q(c, m)
	    self.open = self.p.open or self.q.open
	    -- nullable needs updating at run-time for zero-width assertions
	    return p_matched and q_matched
	end
	return false
    end
})

function match(r, s)
    if s == "" then
	return r.nullable
    end

    local matched = r(s:sub(1, 1), true)
    for i = 2, #s do
	print(s:sub(i-1, i-1), ": matched=", matched, ",open=", r.open)
	if not r.open then
	    return false
	end
	matched = r(s:sub(i, i), false)
    end
    print(s:sub(#s, #s), ": matched=", matched, ",open=", r.open)

    return matched
end



-- example for "[abc]*a|."
re1 = regex_ccl:new{ s = {a = true, b = true, c = true} }
re2 = regex_rep:new{ r = re1 }
re3 = regex_lit:new{ c = 'a' }
re4 = regex_seq:new{ p = re2, q = re3 }
re5 = regex_any:new{}
re  = regex_alt:new{ p = re4, q = re5 }

print( match(re, "ccaab") )
