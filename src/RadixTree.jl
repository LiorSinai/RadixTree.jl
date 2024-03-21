module RadixTree

import Base: eltype, get, in, insert!, show 

export RadixTreeNode, PreOrderTraversal
export get_n_larger, children, children_data, get_height, print_tree

"""
    RadixTreeNode(data="", label=false)

Create a node for a radix tree, also called a compressed trie.

Reference: https://en.wikipedia.org/wiki/Radix_tree
"""
mutable struct RadixTreeNode{T<:AbstractString}
    data::T
    is_label::Bool
    children::Vector{<:RadixTreeNode}
end

RadixTreeNode(data::T="", label::Bool=false) where T = 
    RadixTreeNode{T}(data, label, RadixTreeNode{T}[])

eltype(node::RadixTreeNode{T}) where T = T

function show(io::IO, node::RadixTreeNode)
    print(io, typeof(node))
    print(io, "(data=", node.data)
    print(io, ", is_label=", node.is_label)
    print(io, ", children=", children_data(node))
    print(io, ")")
end

is_leaf(node::RadixTreeNode) = isempty(node.children)

"""
    children(node::RadixTreeNode)

Get the `children` of `node`.
"""
children(node::RadixTreeNode) = node.children

"""
    children_data(node::RadixTreeNode)

Get the `data` of the children of `node`.
"""
children_data(node::RadixTreeNode) = [child.data for child in node.children]

"""
    get(root::RadixTreeNode, key)

Returns a tuple `(node, match_length)`
where `node` is the deepest node in `root` that contains the most characters of `key`
and `match_length` is the number of matched characters.

This functions ignores the data point at `root.`

# Examples
```jldoctest
root = RadixTreeNode("<root>")
insert!(root, "t")
insert!(root, "ten")
insert!(root, "team")
get(root, "te") 
# RadixTreeNode{String}(data=e, is_label=false, children=["am", "n"]), 2)
get(root, "team")
# (RadixTreeNode{String}(data=am, is_label=true, children=String[]), 4)
get(root, "hello")
(RadixTreeNode{String}(data=<root>, is_label=false, children=["t"]), 0)
```
"""
function get(root::RadixTreeNode, key::AbstractString)
    node = root
    num_found = 0
    suffix = key
    # skips the data in root
    while !(isnothing(node)) && !(is_leaf(node)) && (num_found < length(key))
        child = search_children(node, suffix)
        if isnothing(child)
            break
        end
        node = child
        num_found += length(node.data)
        suffix = get_suffix(suffix, length(node.data))
    end
    node, num_found
end

# Unlike chop, returns a string
function get_suffix(s::AbstractString, head::Int)
    if isempty(s)
        return s
    end
    s[nextind(s, firstindex(s), head):end]
end

"""
    get_n_larger(root::RadixTreeNode, key, n)

Find the nearest `n` larger keys than `key` in the radix tree.

## Examples
```jldoctest
root = RadixTreeNode()
for word in [
    "inside", "insight", "insist", "inspire", "install", 
    "instance", "instead", "instruct", "instrument", "insurance"
    ]
    insert!(root, word)
end
get_n_larger(tree, "insi", 5) # [inside, insight, insist] 
```
"""
function get_n_larger(root::RadixTreeNode, key::AbstractString, n::Int)
    node, num_found = get(root, key)
    out = String[]
    prefix = first(key, num_found)
    suffix = get_suffix(key, num_found)
    for child in node.children
        if startswith(child.data, suffix)
            for data in child
                push!(out, prefix * data)
                if length(out) == n
                    break
                end
            end
        end
        if length(out)  == n
            break
        end
    end
    out
end

"""
    find_n_larger(list, key, n)

This function is used for benchmarking and testing purposes.
It runs in `O(log(n))` time like `get_n_larger` and sets a competitive baseline.
"""
function find_n_larger(words::Vector{<:AbstractString}, key::AbstractString, n::Int)
    out = String[]
    idx = searchsortedfirst(words, key)
    if idx > length(words)
        return out
    end
    if words[idx] != key
        push!(out, words[idx])
    end
    idx += 1
    while length(out) < n && startswith(words[idx], key)
        push!(out, words[idx])
        idx += 1
    end
    out
end

function in(key::AbstractString, root::RadixTreeNode)
    node, num_found = get(root, key)
    num_found == length(key) # doesn't check it is a label
end

function search_children(node::RadixTreeNode, key::AbstractString)
    for child in node.children
        if startswith(key, child.data)
            return child
        end
    end
end

function search_children_with_overlap(node::RadixTreeNode, key::AbstractString)
    for len_prefix in length(key):-1:1
        for child in node.children
            data = first(child.data, len_prefix)
            if startswith(key, data)
                return child, min(len_prefix, length(data))
            end
        end
    end
    nothing, 0
end

"""
    insert!(root::RadixTreeNode, key)

Insert a `key` into a node as deep as possible in `root`.

If `key` is already a leaf of `root`, this will not add a new leaf.

# Examples
```jldoctest
root = RadixTreeNode("<root>")
insert!(root, "t")
insert!(root, "ten")
insert!(root, "team")
insert!(root, "tea")
print_tree(root)

<root>
|--t
|--|--e
|--|--|--a
|--|--|--|--m
|--|--|--n
```
"""
function insert!(root::RadixTreeNode{T}, key::AbstractString) where T
    node, match_length = get(root, key)
    if match_length == length(key) # already in tree
        node.is_label = true
        return
    end
    suffix = get_suffix(key, match_length)
    child, overlap = search_children_with_overlap(node, suffix)
    if isnothing(child)
        new_node = RadixTreeNode(T(suffix), true)
        idx = searchsortedfirst(node.children, new_node; lt=(n1, n2)->n1.data < n2.data)
        insert!(node.children, idx, new_node)
    else
        node = child
        split!(node, overlap)
        if (overlap) < length(suffix) # add remainder
            new_suffix = get_suffix(suffix, overlap)
            new_node = RadixTreeNode(T(new_suffix), true)
            idx = new_node.data < node.children[1].data ? 1 : 2
            insert!(node.children, idx, new_node)
        else
            node.is_label = true
            node
        end
    end
end

function split!(node::RadixTreeNode{T}, i::Int) where T
    suffix = get_suffix(node.data, i)
    new_node = RadixTreeNode{T}(T(suffix), node.is_label, node.children)
    node.data = first(node.data, i)
    node.children = [new_node]
    node.is_label = false
    node
end

"""
    get_height(root::RadixTreeNode, height=0)

Recursively search the tree for the maximum height.
"""
function get_height(node::RadixTreeNode, height::Int=0)
    if is_leaf(node)
        return height
    end
    next_height = height + 1
    for child in node.children
        height = max(height, get_height(child, next_height))
    end
    height
end

"""
    print_tree([io ], root; indent="--", use_data_as_seperator=false)

Print a tree line by line in a pre-order traversal.
"""
print_tree(io::IO, root::RadixTreeNode; options...) = print_tree_preorder(io, root; options...)
print_tree(root::RadixTreeNode; options...) = print_tree(stdout, root; options...)

function print_tree_preorder(io::IO, node::RadixTreeNode, level_indent=""
    ; indent::AbstractString="--", use_data_as_separator::Bool=false
    )
    println(io, level_indent * node.data)
    separator = use_data_as_separator ? node.data : "|"
    next_level = level_indent * separator * indent
    for child in node.children
        print_tree_preorder(io, child, next_level; indent=indent, use_data_as_separator=use_data_as_separator)
    end
end

Base.IteratorSize(::RadixTreeNode) = Base.SizeUnknown() 

"""
    iterate(root::RadixTreeNode)

Iterate through root using an `PreOrderTraversal` iterator by default.
Only nodes with `is_label=true` will be returned.

# Examples
```jldoctest
root = RadixTreeNode("")
insert!(root, "t")
insert!(root, "ten")
insert!(root, "team")
insert!(root, "tea")
collect(root) # [t, tea, team, ten]
```
"""
function Base.iterate(root::RadixTreeNode, state=nothing)
    iter = PreOrderTraversal(root)
    next = isnothing(state) ? iterate(iter) : iterate(iter, state)
    while next !== nothing
        ((item, is_label), state) = next
        if is_label
            return (item, state)
        end
        next = iterate(iter, state)
    end
end

"""
    PreOrderTraversal(root::RadixTreeNode)

Create an in-order iterator through root.

# Examples
```jldoctest
root = RadixTreeNode("")
insert!(root, "t")
insert!(root, "ten")
insert!(root, "team")
insert!(root, "tea")
for x in PreOrderTraversal(root)
    print(x, ", ")
end
# ("", false), ("t", true), ("te", false), ("tea", true), ("team", true), ("ten", true)
```
"""
struct PreOrderTraversal{R<:RadixTreeNode}
    root::R
end

Base.IteratorSize(::PreOrderTraversal) = Base.SizeUnknown() 

Base.iterate(iter::PreOrderTraversal) = ((iter.root.data, iter.root.is_label), [(iter.root, 1, iter.root.data)])

function Base.iterate(iter::PreOrderTraversal, stack_::Vector{Tuple{RadixTreeNode{T}, Int, T}}) where T
    if isempty(stack_)
        return nothing
    end
    #println("--", [(t[2], t[3]) for t in stack_])
    node, idx, word = last(stack_)
    if idx <= length(node.children)
        return _increment_stack!(stack_)
    else # backtrack
        pop!(stack_)
        while !(isempty(stack_))
            node, idx, word = last(stack_)
            if idx <= length(node.children)
                return _increment_stack!(stack_)
            end
            pop!(stack_)
        end
    end
    nothing
end

function _increment_stack!(stack_::Vector{<:Tuple})
    node, idx, word= last(stack_)
    stack_[end] = (node, idx + 1, word)
    child = node.children[idx]
    new_word = word * child.data
    push!(stack_, (child, 1, new_word))
    (new_word, child.is_label), stack_ 
end

end