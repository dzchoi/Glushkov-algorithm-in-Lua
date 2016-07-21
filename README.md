# Glushkov's algorithm in Lua

In computer science theory - particularly formal language theory - the Glushkov Construction Algorithm (GCA) transforms a given regular expression into an equivalent nondeterministic finite automaton (NFA). Thus, it forms a bridge between regular expressions and nondeterministic finite automata: two abstract representations of formal languages.

The NFA format is better suited for execution on a computer when regular expressions are used. These expressions may be used to describe advanced search patterns in "find and replace" like operations of text processing utilities. This algorithm can be considered a compiler from a regular expression to an NFA, which is why this algorithm is of practical interest. Furthermore, the automaton is small by nature as the number of states is equal to the number of letters of the regular expression, plus one.

## This program does:
- implement the Glushkov's algorithm in Lua,
- use OOP technique of the inheritance and the derivation written in Lua for defining a Glushkov NFA internally, and
- include a regular expression engine only (does not include a text parser for regular expressions.)

## Supported regular expressions are:  
- `"c"` (for a single character)  
- `"."` (for any character)  
- `"[abc]"` (character class)  
- `"[^abc]"` (negated character class)
- `"r*"` (Kleene closure)
- `"r?"` (zero or one)
- `"r+"` (positive closure)  
- `"pq"` (concat)  
- `"p|q"` (alternation)  
- `"p&q"` (and)

## Quick example
- For example, to match `"[abc]*a|."` against `"ccaab"`  
```
-- generate a RE for "[abc]*a|."
re1 = regex_ccl:new{ s = {a = true, b = true, c = true} }  
re2 = regex_rep:new{ r = re1 }  
re3 = regex_lit:new{ c = 'a' }  
re4 = regex_seq:new{ p = re2, q = re3 }  
re5 = regex_any:new{}  
re  = regex_alt:new{ p = re4, q = re5 }  

-- match the RE against "ccaab"
print( match(re, "ccaab") )
```
