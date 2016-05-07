# Glushkov-algorithm-in-Lua
regular expression matcher in Lua using Glushkov algorithm

- Supported regular expressions are:  
  - "c" (for a single character)  
  - "." (for any character)  
  - "[abc]" (character class)  
  - "[^abc]" (negated character class)
  - "r*" (Kleene closure)
  - "r?" (zero or one)
  - "r+" (positive closure)  
  - "pq" (concat)  
  - "p|q" (alternation)  
  - "p&q" (and)

- Does not include a parser, but a matcher only

- For example, to match "[abc]*a|." against "ccaab"  
```
-- to generate a RE manually
re1 = regex_ccl:new{ s = {a = true, b = true, c = true} }  
re2 = regex_rep:new{ r = re1 }  
re3 = regex_lit:new{ c = 'a' }  
re4 = regex_seq:new{ p = re2, q = re3 }  
re5 = regex_any:new{}  
re  = regex_alt:new{ p = re4, q = re5 }  

print( match(re, "ccaab") )
```

- Uses inheritance and derived classes written in Lua itself
