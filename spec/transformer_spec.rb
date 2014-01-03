$:.unshift "../lib"

require 'baumwandler'

describe "Baumwandler::Transformer::Rule", exp: false do

  before(:all) do
    @e=Baumwandler::Transformer.new
  end

  it "provides the most simple form of a transformation rule" do
    @e.rule(:a).body do |i|
      "this is #{i}"
    end

    @e.get_rules[:a].first.get_body.call("foobar").should=="this is foobar"

  end

  it "it supports the most complex form of a transformation rule" do |this|
    @e.rule([:a1, :b1]).where{|this| this == "foobar"} .add .body do |this|
      [
        1,
        1
      ]
    end


    @e.get_rules[:a1].should == @e.get_rules[:b1]
    @e.get_rules[:a1].first.get_mode.should == :add
    @e.get_rules[:a1].first.get_direction.should == :down
    @e.get_rules[:a1].first.get_direction.should == :down
    @e.get_rules[:a1].first.get_predicate.call("foobar").should == true
    @e.get_rules[:a1].first.get_body.call(nil).should == [1,1]
  end


  it "can apply rules" do
    @e.rule([:a, :b]).down.add.body do |i|
      i.gid
    end

    a=Baumwandler::Node.new(:a)
    @e.transform(a)
    #@t.produce(a)
    pending("produce comes later")
  end
end

describe "Baumwandler::Tranformer.transform", exp:false do

  before :all do
    @bw=Baumwandler::Node
    @e=Baumwandler::Transformer.new

    @e.rule(:CHAPTER).body do |my_chapter|
      # chapter contents is right siblings of which first left :h1 sibling corresponds the current chapter
      # :h1 :p :p :p :h1 :p :p -> :CHAPTER(<-:h1){:P  :P :P} :CHAPTER()
      cc= my_chapter._bwp.right.select{|i|
        i.left.select{|i| i.gid == :h1 }.first == my_chapter._bwp
      }.map{|my_p| @bw.node(:P)._bwfrom(my_p)}

      a=[
        my_chapter.node(:"LONG-NAME"){|n|
          @bw.node(:"L-5", L:"DE"){
          my_chapter._bwp.contents}
        },
        cc
      ].flatten.compact
      a
    end

    @e.rule(:CHAPTER).up.insert.body{|my_chapter|
      [
        my_chapter.contents.first,
        @e.transform(@bw.node(:P){"This chapter has #{my_chapter.contents.count} children"}),
        my_chapter.contents[1..-1]
      ]
    }

    @e.rule(:P).body do |my_p|
      @bw.node(:"L-1", L:"DE"){
        (my_p._bwp || my_p).contents
      }
    end

    @e.rule(:DOCUMENT).body do |this|
      this._bwp.contents.select{|i| i.gid == :h1}
      .map{|i| @bw.node(:"CHAPTER")._bwfrom(i)}
    end

    @e.rule(:"!default").add.body do |this|
      r=this._bwp.contents if this.contents.first && this._bwp
    end

  end

  it "creates nested chapters" do
    n=Baumwandler::Node
    source=n.node(:source){|a|
      [
        n.node(:h1){"das ist überschrift 1"},
        n.node(:p){"der erste paragraph"},
        n.node(:p){"der zweite paragraph"},
        n.node(:p){"der dritte paragraph"},
        n.node(:h1){"das ist kapitel 2"},
        n.node(:p){"der vierte paragraph"},
        n.node(:p){"der fünfte paragraph"},
        n.node(:p){"der sechste paragraph"}
    ]}

    document = n.node(:DOCUMENT)._bwfrom(source) # yields {chapter:][]}
    @e.transform(document)

    document.contents.first.gid.should==:"CHAPTER"
  end

end


describe "Baumwandler::Predecessor", exp:false do

  before :all do
    class Object
      include Baumwandler::Predecessor
    end
  end

  it "can find the predecessor" do
    root    = "this is root"
    first   = "this the first derivable"._bwfrom(root)
    second  = "this is the second derivable"._bwfrom(first)
    number  = 1
    number._bwfrom(root) # it also works with fixnums


    #we clone and establish link later
    cloned_root=root.clone
    cloned_root._bwfrom(root)

    #we clone by baumwandler
    direct_clone=cloned_root._bwclone

    first._bwp.should==root
    second._bwp._bwp.should==root
    second._bwr.should==root
    direct_clone._bwa.should==[cloned_root,root]
    number._bwp.should==root

  end
end

# describe "Baumwandler::Production" do

#   before :all do
#     @e=Baumwandler::Production.new
#   end

#   it "can perform rules" do

#     @e.downrule(:a).down do |i|
#       "<#{i.gid}>"
#     end

#     @e.downrule(:a).up do|i|
#       "</#{igid}"
#     end

#     Baumwandler::Node.new(:a).produce(@e)

#     pending("Production comes later")
#   end
#end
