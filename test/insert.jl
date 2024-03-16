using Test
using RadixTree

@testset "insert" verbose=true begin
    @testset "insert in order" begin
        root = RadixTreeNode("")
        insert!(root, "t")
        insert!(root, "z")
        insert!(root, "a")
        @test root.children[1].data == "a"
        @test root.children[2].data == "t"
        @test root.children[3].data == "z"
    end

    @testset "extend" begin
        root = RadixTreeNode("")
        insert!(root, "s")
        insert!(root, "slow")
        insert!(root, "slow") # should ignore
        insert!(root, "slower")
        insert!(root, "slowing")
        @test root.children[1].data == "s"
        @test root.children[1].children[1].data == "low"
        @test root.children[1].children[1].children[1].data == "er"
        @test root.children[1].children[1].children[2].data == "ing"
    end

    @testset "extend and split" begin
        root = RadixTreeNode("")
        insert!(root, "t")
        @test root.children[1].data == "t"
        insert!(root, "ten")
        @test root.children[1].children[1].data == "en"
        insert!(root, "team") # trigger split
        @test root.children[1].children[1].data == "e"
        @test root.children[1].children[1].children[1].data == "am"
        @test root.children[1].children[1].children[2].data == "n"
    end

    @testset "split no add" begin
        root = RadixTreeNode("")
        insert!(root, "t")
        insert!(root, "team")
        @test root.children[1].data == "t"
        @test root.children[1].children[1].data == "eam"
        insert!(root, "tea") # trigger split
        @test root.children[1].children[1].data == "ea"
        @test root.children[1].children[1].is_label
        node = root.children[1].children[1]
        @test length(node.children) == 1
        @test node.children[1].data == "m"
    end

    @testset "nothing" begin
        root = RadixTreeNode{String}("<root>", false, [RadixTreeNode("a")])
        insert!(root, "")
        @test root.is_label
    end

    @testset "unicode" begin
        root = RadixTreeNode("")
        insert!(root, "αβγδ")
        insert!(root, "αβ")
        insert!(root, "αβγδhϵllo")
        @test root.children[1].data == "αβ"
        @test root.children[1].children[1].data == "γδ"
        @test root.children[1].children[1].children[1].data == "hϵllo"
    end

    @testset "wiki" begin
        # example from Wikipedia
        root = RadixTreeNode("<root>")
        insert!(root, "test")
        insert!(root, "slow")
        insert!(root, "water")
        @test root.children[1].data == "slow"
        @test root.children[2].data == "test"
        @test root.children[3].data == "water"
        insert!(root, "slower") # extend
        insert!(root, "tester") # extend
        @test root.children[1].children[1].data == "er"
        @test root.children[2].children[1].data == "er"
        insert!(root, "team") # split
        @test root.children[2].data == "te"
        @test root.children[2].children[1].data == "am"
        @test root.children[2].children[2].data == "st"
        @test root.children[2].children[2].children[1].data == "er"
        insert!(root, "toast") 
        @test root.children[2].data == "t"
        @test root.children[2].children[1].data == "e"
        @test root.children[2].children[2].data == "oast"
    end

    @testset "romane" begin
        # also from Wikipedia
        root = RadixTreeNode("<root>")
        for key in ["romane", "romanus", "romulus", "rubens", "ruber", "rubicon", "rubicundus"]
            insert!(root, key)
        end
        @test root.children[1].data == "r"
        @test children_data(root.children[1]) == ["om", "ub"]
        @test children_data(root.children[1].children[1]) == ["an", "ulus"]
        @test children_data(root.children[1].children[1].children[1]) == ["e", "us"]
        @test children_data(root.children[1].children[2]) == ["e", "ic"]
        @test children_data(root.children[1].children[2].children[1]) == ["ns", "r"]
        @test children_data(root.children[1].children[2].children[2]) == ["on", "undus"]
    end

    @testset "numbers" begin
        root = RadixTreeNode("")
        for key in ["1901", "11", "1993", "1900", "100", "2", "2024", "2010"]
            insert!(root, key)
        end
        @test children_data(root) == ["1", "2"]
        @test children_data(root.children[1]) == ["00", "1", "9"]
        @test children_data(root.children[1].children[3]) == ["0", "93"]
        @test children_data(root.children[1].children[3].children[1]) == ["0", "1"]
        @test children_data(root.children[2]) == ["0"]
        @test children_data(root.children[2].children[1]) == ["10", "24"]
    end

end