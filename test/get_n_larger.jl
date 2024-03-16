using Test
using RadixTree

@testset "get_n_larger" verbose=true begin
    @testset "ins" begin
        root = RadixTreeNode{String}(
            "", false, [RadixTreeNode{String}("ins", false, [
                RadixTreeNode{String}(
                    "i", false, [
                        RadixTreeNode("de", true),
                        RadixTreeNode("ght", true),
                        RadixTreeNode("st", true),
                    ]
                ),
                RadixTreeNode("pire", true),
                RadixTreeNode{String}(
                    "t", false, [
                        RadixTreeNode{String}("a", false, [RadixTreeNode("ll", true), RadixTreeNode("nce", true)]),
                        RadixTreeNode("ead", true),
                        RadixTreeNode{String}("ru", false, [RadixTreeNode("ct", true), RadixTreeNode("ment", true)]),
                    ]
                ),
                RadixTreeNode("urance", true),
            ]
            )
        ])
        data = get_n_larger(root, "ins", 5)
        @test data == ["inside", "insight", "insist", "inspire", "install"]
        data = get_n_larger(root, "insp", 5)
        @test data == ["inspire"]
        data = get_n_larger(root, "inst", 5)
        @test data == ["install", "instance", "instead", "instruct", "instrument"]
        @test isempty(get_n_larger(root, "insure", 5))
    end
end