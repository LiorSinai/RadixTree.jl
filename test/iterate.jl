using Test
using RadixTree

@testset "iterate" verbose=true begin
    @testset "basic" begin
        root = RadixTreeNode{String}(
            "0-", false, [
                RadixTreeNode{String}(
                    "1.1-", false, [
                        RadixTreeNode("2.1", true),
                        RadixTreeNode{String}("2.2-", false, [RadixTreeNode("3", true)])
                    ]
                ),
                RadixTreeNode("1.2", true),
            ]
        )
        data = collect(InOrderTraversal(root))
        expected = [
            ("0-", false),
            ("0-1.1-", false),
            ("0-1.1-2.1", true),
            ("0-1.1-2.2-", false),
            ("0-1.1-2.2-3", true),
            ("0-1.2", true),
        ]
        @test data == expected
        data = collect(root)
        expected = ["0-1.1-2.1", "0-1.1-2.2-3", "0-1.2"]
        @test data == expected
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
        data = collect(root)
        expected = ["slow", "slower", "team", "test", "toast", "water"]
        @test data == expected
    end

    @testset "romane" begin
        root = RadixTreeNode("")
        for key in ["romane", "romanus", "romulus", "rubens", "ruber", "rubicon", "rubicundus"]
            insert!(root, key)
        end
        data = collect(root)
        expected = ["romane", "romanus", "romulus", "rubens", "ruber", "rubicon", "rubicundus"]
        @test data == expected
    end
end