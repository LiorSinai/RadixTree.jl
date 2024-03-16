using Test
using RadixTree

@testset "height" verbose=true begin
    @testset "empty" begin
        root = RadixTreeNode("")
        height = get_height(root)
        @test height == 0
    end

    @testset "basic" begin
        root = RadixTreeNode{String}(
            "0", false, [ 
                RadixTreeNode("1.1", false, 
                    [
                        RadixTreeNode("2.1", false,  [RadixTreeNode("3")]),
                        RadixTreeNode("2.2"),
                    ]
                ),
                RadixTreeNode("1.2") 
            ],
        )
        height = get_height(root)
        @test height == 3
    end

    @testset "wiki" begin
        root = RadixTreeNode{String}(
            "", false, [
                RadixTreeNode{String}(
                    "slow", true, [RadixTreeNode("er", true)]
                ),
                RadixTreeNode{String}("t", false, [
                    RadixTreeNode{String}("e", false, [
                        RadixTreeNode("am", true)
                        RadixTreeNode("st", true)
                        ]
                    ),
                    RadixTreeNode("oast", true),
                ]),
                RadixTreeNode("water", true),
            ]
        )
        @test get_height(root) == 3
    end
end
