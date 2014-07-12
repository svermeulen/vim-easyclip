require "spec_helper"

describe "EasyClip" do

    before(:all) do
        @vim = Vimbot::Driver.new
        @vim.start

        @vim.set "visualbell"
        @vim.set "noerrorbells"

        @vim.set "runtimepath+=#{PLUGIN_ROOT}"

        @vim.command("let g:EasyClipEnableBlackHoleRedirect = 1")
        @vim.command("let g:EasyClipUseCutDefaults = 1")
        @vim.command("let g:EasyClipUseSubstituteDefaults = 1")
        @vim.command("let g:EasyClipUsePasteDefaults = 1")
        @vim.command("let g:EasyClipUsePasteToggleDefaults = 1")
        @vim.command("let g:EasyClipUseYankDefaults = 1")
        @vim.command("let g:EasyClipAutoFormat = 1")

        @vim.runtime "plugin/easyclip.vim"

        @vim.command("cmap <c-e> <plug>EasyClipCommandModeSwapPasteForward")
        @vim.command("cmap <c-y> <plug>EasyClipCommandModeSwapPasteBackward")

        @vim.command("imap <c-e> <plug>EasyClipInsertModeSwapPasteForward")
        @vim.command("imap <c-y> <plug>EasyClipInsertModeSwapPasteBackwards")

        @vim.source VIM_REPEAT_PATH
    end

    after(:all)   { @vim.stop }

    def ClearYanks
        @vim.command("ClearYanks")
    end

    before(:each) do
        @vim.clear_buffer
        ClearYanks()
    end

    def AddExampleText
        @vim.insert "first<CR>", "second<CR>", "third<CR>", "fourth"
        @vim.normal "o", "<Esc>"
    end

    def AddExampleYanks
        @vim.command("call EasyClip#Yank('one')")
        @vim.command("call EasyClip#Yank('two')")
        @vim.command("call EasyClip#Yank('three')")
        @vim.command("call EasyClip#Yank('four')")
    end

    def LinesAreUnchanged

        @vim.normal "gg"
        @vim.line.should == "first"
        @vim.normal "j"
        @vim.line.should == "second"
        @vim.normal "j"
        @vim.line.should == "third"
        @vim.normal "j"
        @vim.line.should == "fourth"
    end

    def YankExampleText
        @vim.normal "gg"
        @vim.normal 'yw', 'j', 'yw', 'j', 'yw', 'j', 'yw', 'j'
    end

    ###################
    # Black hole
    ###################
    shared_examples "black hole redirection" do

        before do
            @vim.clear_buffer
            ClearYanks()

            AddExampleText()

            @vim.insert "saved"
            @vim.normal "0mw"
            @vim.normal "gg"
        end

        def YankIsUnchanged
            yanks = GetYanks()
            yanks.length.should == 1
            yanks[0].should == "saved"
        end

        it "delete character" do
            @vim.type 'x'
            @vim.line.should == "irst"
            YankIsUnchanged()
        end

        it "delete word" do
            @vim.type 'dw'
            @vim.line.should == ""
            YankIsUnchanged()
        end

        it "delete line" do
            @vim.type 'dd'
            @vim.line.should == "second"
            YankIsUnchanged()
        end

        it "change word" do
            @vim.type 'cwnew'
            @vim.line.should == "new"
            YankIsUnchanged()
        end

        it "change line" do
            @vim.type 'ccnew'
            @vim.line.should == "new"
            YankIsUnchanged()
        end

        it "change select mode" do
            @vim.type 'venew'
            @vim.line.should == "new"
            YankIsUnchanged()
        end
    end

    ###################
    # Yanks
    ###################
    shared_examples "basic yanks" do

        before do
            AddExampleText()
            YankExampleText()
        end

        it "yanks are correct" do
            currentYanks = GetYanks()

            currentYanks[0].should == 'fourth'
            currentYanks[1].should == 'third'
            currentYanks[2].should == 'second'
            currentYanks[3].should == 'first'
        end

        it "yank rotation 1" do
            @vim.normal "p"
            @vim.normal "<c-p>"

            currentYanks = GetYanks()

            currentYanks[0].should == 'third'
            currentYanks[1].should == 'second'
            currentYanks[2].should == 'first'
            currentYanks[-1].should == 'fourth'
        end

        it "yank rotation 2" do
            @vim.normal "p"

            @vim.normal "<c-p>"
            @vim.line.should == "third"

            @vim.normal "<c-p>"
            @vim.line.should == "second"

            @vim.normal "<c-p>"
            @vim.line.should == "first"

            @vim.normal "<c-n>"
            @vim.line.should == "second"

            @vim.normal "<c-n>"
            @vim.line.should == "third"

            @vim.normal "<c-n>"
            @vim.line.should == "fourth"

            @vim.normal "<c-n>"
            @vim.line.should == "first"

            @vim.normal "<c-n>"
            @vim.line.should == "second"

            # undo should undo the original paste completely
            @vim.undo
            @vim.line.should == ""
        end

        it "yank rotation 3" do

            @vim.normal "p"
            @vim.line.should == "fourth"
            @vim.undo

            @vim.type "[yp"
            @vim.line.should == "third"
            @vim.undo

            @vim.type "[yp"
            @vim.line.should == "second"
            @vim.undo

            @vim.type "]yp"
            @vim.line.should == "third"
            @vim.undo

            @vim.type "]yp"
            @vim.line.should == "fourth"
            @vim.undo
        end
    end

    ###################
    # PASTE
    ###################
    shared_examples "basic pasting" do

        before do
            AddExampleText()
            YankExampleText()
            @vim.normal "p"
        end

        it "pastes the most recently yanked string" do
            @vim.line_number.should == 5
            @vim.line.should == "fourth"
        end

        it "pastes in visual mode" do
            @vim.type "vip"
            @vim.type "p"
            @vim.line.should == "fourth"
            @vim.line_number.should == 1
        end

        it "pressing the repeat key with '.'" do
            @vim.type "."
            @vim.line.should == "fourthfourth"
        end

        it "pressing the repeat key with '.'" do
            @vim.type "."
            @vim.line.should == "fourthfourth"
        end

        it "pressing toggle after repeat" do
            @vim.type "."
            @vim.line.should == "fourthfourth"

            @vim.type "<c-p>"
            @vim.line.should == "fourththird"

            @vim.type "<c-n>"
            @vim.line.should == "fourthfourth"
        end
    end

    ###################
    # PASTE 2
    ###################
    shared_examples "basic paste auto formatting" do

        before do
            AddExampleText()
        end

        it "auto formatting" do
            @vim.insert "          fifth"
            @vim.normal "0mm"
            @vim.line.should == "fourth"
            @vim.type "p"
            @vim.line.should == "fifth"
        end

        it "auto formatting 2" do
            @vim.insert "          fifth"
            @vim.normal "0mm"
            @vim.insert "    sixth"
            @vim.normal "p"
            @vim.line.should == "    fifth"
        end
    end

    ###################
    # COMMAND MODE PASTE
    ###################
    shared_examples "command mode paste" do

        before do
            AddExampleYanks()
        end

        it "test 1" do
            # todo
        end
    end

    ###################
    # CUT OPERATOR
    ###################
    shared_examples "basic cutting/moving" do

        before do
            AddExampleText()
        end

        it "test cut word" do
            @vim.normal "gg"

            (1..4).each do |i|
                @vim.normal "mw"
                @vim.line.should == ""
                @vim.normal "j0"
            end

            currentYanks = GetYanks()

            currentYanks[0].should == "fourth"
            currentYanks[1].should == "third"
            currentYanks[2].should == "second"
            currentYanks[3].should == "first"
        end

        it "test cut line" do

            @vim.normal "gg"

            (1..4).each do |i|
                @vim.normal "mm"
            end

            GetNumLines().should == 1

            currentYanks = GetYanks()

            currentYanks[0].should == "fourth^M"
            currentYanks[1].should == "third^M"
            currentYanks[2].should == "second^M"
            currentYanks[3].should == "first^M"
        end
    end

    ###################
    # SUBSTITUTION OPERATOR
    ###################
    shared_examples "basic substitution" do

        before do
            AddExampleText()
            YankExampleText()
        end

        it "substitute word" do
            @vim.normal "gg"
            @vim.line.should == "first"
            @vim.normal "sw"
            @vim.line.should == "fourth"
            @vim.normal "j0"
            @vim.line.should == "second"
            @vim.type "."
            @vim.line.should == "fourth"
        end

        it "substitute line" do
            @vim.normal "gg"
            @vim.line.should == "first"
            @vim.normal "ss"
            @vim.line.should == "fourth"
            @vim.normal "j0"
            @vim.line.should == "second"
            @vim.type "."
            @vim.line.should == "fourth"
        end
    end

    shared_examples "test1" do

        before do
            AddExampleText()
            YankExampleText()
        end

        it "1" do
            yanks = GetYanks()

            yanks[0].should == "first"
        end
    end

    shared_examples "all tests" do

        it_has_behavior "basic substitution"
        it_has_behavior "basic cutting/moving"
        it_has_behavior "basic pasting"
        it_has_behavior "basic paste auto formatting"
        it_has_behavior "basic yanks"
        it_has_behavior "black hole redirection"
    end

    describe "clipboard default" do

        before do
            @vim.command("set clipboard=")
        end

        it_has_behavior "all tests"
    end

    describe "clipboard unnamed" do

        before do
            @vim.command("set clipboard=unnamed")
        end

        it_has_behavior "all tests"
    end

    describe "clipboard unnamed,unnamedplus" do

        before do
            @vim.command("set clipboard=unnamed,unnamedplus")
        end

        it_has_behavior "all tests"
    end

    ###################
    # Helper functions
    ###################
    def GetNumLines
        (@vim.command "echo line('$')").to_i
    end

    def GetYanks
        yanks = @vim.command("Yanks").split("\n")[1..-1]
        yanks = yanks.map { | y | y.match(/\d*\s*(.*)$/)[1] }

        return yanks
    end
end
