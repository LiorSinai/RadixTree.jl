module RadixTree

import Base: eltype, get, in, insert!, show 

export RadixTreeNode, InOrderTraversal
export get_n_larger, children, children_data, get_height, print_tree

"""
    RadixTreeNode(data="", label=false)

Create a node for a radix tree, also called a compressed trie.
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
    idx = 0 
    # skips the data in root
    while !(isnothing(node)) && !(is_leaf(node)) && (num_found < length(key))
        suffix = chop(key; head=num_found, tail=0)
        idx = search_children(node, suffix)
        if isnothing(idx)
            break
        end
        node = node.children[idx]
        num_found += length(node.data)
    end
    node, num_found
end

function get_n_larger(root::RadixTreeNode, key::AbstractString, n::Int)
    node, num_found = get(root, key)
    out = String[]
    prefix = first(key, num_found)
    suffix = chop(key; head=num_found, tail=0)
    i = 0
    for child in node.children
        if has_starting_overlap(suffix, child.data)
            for data in child
                i += 1
                push!(out, prefix * data)
                if i == n
                    break
                end
            end
        end
        if i == n
            break
        end
    end
    out
end

function has_starting_overlap(s1::AbstractString, s2::AbstractString)
    for (c1, c2) in zip(s1, s2)
        if c1 != c2
            return false
        end
    end
    true
end

function in(key::AbstractString, root::RadixTreeNode)
    node, num_found = get(root, key)
    num_found == length(key) # doesn't check it is a label
end

function search_children(node::RadixTreeNode, key::AbstractString)
    for (idx, edge) in enumerate(node.children)
        if startswith(key, edge.data)
            return idx
        end
    end
end

function search_children_with_overlap(node::RadixTreeNode, key::AbstractString)
    for len_prefix in length(key):-1:1
        prefix = first(key, len_prefix)
        for (idx, edge) in enumerate(node.children)
            data = first(edge.data, len_prefix)
            if startswith(key, data)
                return idx, min(len_prefix, length(data))
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
    suffix = chop(key; head=match_length, tail=0)
    idx, overlap = search_children_with_overlap(node, suffix)
    if isnothing(idx)
        new_node = RadixTreeNode(T(suffix), true)
        return insert_child_in_order!(node, new_node)
    else
        node = node.children[idx]
        split!(node, overlap)
        if (overlap) < length(suffix) # add remainder
            new_suffix = chop(suffix; head=overlap, tail=0)
            new_node = RadixTreeNode(T(new_suffix), true)
            insert_child_in_order!(node, new_node)
        else
            node.is_label = true
            node
        end
    end
end

function insert_child_in_order!(node::RadixTreeNode, child::RadixTreeNode)
    idx = 1
    while idx <= length(node.children) && (child.data > node.children[idx].data)
        idx += 1
    end
    insert!(node.children, idx, child)
    node
end

function split!(node::RadixTreeNode{T}, i::Int) where T
    suffix = chop(node.data; head=i, tail=0)
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

Iterate through root using an `InOrderTraversal` iterator by default.
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
    iter =  InOrderTraversal(root)
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
    InOrderTraversal(root::RadixTreeNode)

Create an in-order iterator through root.

# Examples
```jldoctest
root = RadixTreeNode("")
insert!(root, "t")
insert!(root, "ten")
insert!(root, "team")
insert!(root, "tea")
for x in InOrderTraversal(root)
    print(x, ", ")
end
# ("", false), ("t", true), ("te", false), ("tea", true), ("team", true), ("ten", true)
```
"""
struct InOrderTraversal{R<:RadixTreeNode}
    root::R
end

Base.IteratorSize(::InOrderTraversal) = Base.SizeUnknown() 

Base.iterate(iter::InOrderTraversal) = ((iter.root.data, iter.root.is_label), [(iter.root, iter.root.data, 1)])

function Base.iterate(iter::InOrderTraversal, stack_::Vector{Tuple{RadixTreeNode{T}, T, Int}}) where T
    if isempty(stack_)
        return nothing
    end
    #println("--", [(t[2], t[3]) for t in stack_])
    node, word, idx = last(stack_)
    if idx <= length(node.children)
        return _update_stack!(node, idx, word, stack_)
    else # backtrack
        pop!(stack_)
        while !(isempty(stack_))
            node, word, idx = last(stack_)
            if idx <= length(node.children)
                return _update_stack!(node, idx, word, stack_)
            end
            pop!(stack_)
        end
    end
    nothing
end

function _update_stack!(node::RadixTreeNode{T}, idx::Int, word::T, stack_::Vector) where T
    child = node.children[idx]
    stack_[end] = (node, word, idx + 1)
    new_word = word * child.data
    push!(stack_, (child, new_word, 1))
    (new_word, child.is_label), stack_ 
end

end