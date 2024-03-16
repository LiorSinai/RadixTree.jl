using Test
using RadixTree

@testset "get" verbose=true begin
    @testset "basic" begin
        label1 = RadixTreeNode("st", true)
        label2 = RadixTreeNode("am", true)
        root = RadixTreeNode{String}(
            "", false, [ 
                    RadixTreeNode("t", false, 
                    [
                        RadixTreeNode("e", false,  [label1, label2])
                    ]
                )
            ]
        )
        # in the tree
        node, num_found = get(root, "team")
        @test node == label2
        @test num_found == 4
        # in the tree but not a label
        node, num_found = get(root, "tea")
        @test node == root.children[1].children[1] 
        @test num_found == 2
        # not in the trea
        node, num_found = get(root, "hello")
        @test node == root
        @test num_found == 0
        # in
        @test "team" in root
        @test "t" in root
        @test !("tea" in root) # tea is not a label
    end

    @testset "unicode" begin
        label1 = RadixTreeNode("hello", true)
        root = RadixTreeNode{String}(
            "", false, [
                RadixTreeNode("αβ", false, 
                    [
                        RadixTreeNode("γδϵ", false,  [label1])
                    ]
                )
            ]
        )
        # note: sizeof("αβγδϵhelloω") == 17 but length("αβγδϵhelloω") == 11
        node, num_found = get(root, "αβγδϵhelloω")
        @test node == label1
        @test num_found == 10
    end
end