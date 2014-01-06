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
    @bw=Baumwandler::Node # to be used as node factory
    @e=Baumwandler::Transformer.new # the first engine
    @e2=Baumwandler::Transformer.new # the second engine

    @e.rule(:CHAPTER).body do |my_chapter|
      cc= my_chapter._bwp.next.take_while{|i|
      	i.gid != my_chapter._bwp.gid
      }.map{|my_p| my_p._bwprops(:P)}

      a=[
        @bw.node(:"LONG-NAME"){|n|
          @bw.node(:"L-5", L:"DE"){
          my_chapter._bwp.contents.map{|i| i._bwprops}}
        },
        cc
      ].flatten
      a
    end


#todo: make this a !setfirst rule
    @e.rule(:CHAPTER).up.insert.body{|my_chapter|
      r=[
        my_chapter.contents.first,
        @e.transform(@bw.node(:P){"This chapter has #{my_chapter.contents.count} children"}),
        my_chapter.contents[1..-1]
      ]
    }

    @e.rule(:P).body do |this|
      a=@bw.node(:"L-1", L:"DE"){
        r=["(parent id #{this.parent.object_id})",
           this.contents._bw? || this._bwp.contents.map{|i|i._bwprops}
           ].flatten
        r
      }
      a
    end

    @e.rule(:DOCUMENT).body do |this|
      a=this._bwp.contents.select{|i| i.gid == :h1}
      .map{|i| i._bwprops(:CHAPTER)}
      a
    end


    @e.rule(:hugo).body do |this|
      ["{added by rule :hugo}", (this._bwp || this).contents]
    end

    @e.rule(:"!default").add.body do |this|
      r=[]
      r=this._bwp.contents.map{|i|i._bwprops} if this._bwp
      r
    end

    @e2.rule(:"!default").add.body do |this|
      r=[]
      r=this._bwp.contents.map{|i|i._bwprops} if this._bwp
      r
    end

    @source=@bw.node(:source){|a|
      [
        @bw.node(:h1){["das ist überschrift 1",@bw.node(:hugo){"inhalt hugo"}]},
        @bw.node(:p){"der erste paragraph"},
        @bw.node(:p){"der zweite paragraph"},
        @bw.node(:p){"der dritte paragraph"},
        @bw.node(:h1){"das ist kapitel 2"},
        @bw.node(:p){"der vierte paragraph"},
        @bw.node(:p){"der fünfte paragraph"},
        @bw.node(:p){["der sechste paragraph"]},
        @bw.node(:h1){"das ist kapitel 3"},

    ]}

    @source_ref=@source.to_s

    @target1 = @bw.node(:DOCUMENT)._bwfrom(@source) # yields {chapter:][]}
    @e.transform(@target1)
    @target2 = @bw.node(:DOCUMENT)._bwfrom(@target1)
    @e2.transform(@target2)
  end

  it "performs transformation of nodes" do
  	puts @source.to_s
    puts @target1.to_s
    @target1.contents.first.gid.should==:"CHAPTER"
    expected=@source.contents[3].contents.first
    @target1.contents.first.contents[-1].contents.first.contents[-1].should==expected
  end

  it "can wrap elements around text" do
    expected=@source.contents[3].contents.first
    @target1.contents.first.contents[-1].contents.first.contents[-1].should==expected
  end

  it "does not touch the source " do
    @source.to_s.should == @source_ref
  end

  it "duplicates a tree by default" do
  	puts @target2.to_s
  	@target2.to_xml.should == @target1.to_xml
  end


end


describe "Baumwandler::Object", exp:false do

  before :all do
    class Object
      include Baumwandler::Object
    end
  end

  it "can find the predecessor" do
    root    = "this is root"
    first   = "this the first derivable"._bwfrom(root)
    second  = "this is the second derivable"._bwfrom(first)
    number  = 1
    number._bwfrom(root) # it also works with fixnums


    #we clone and establish link later
    cloned_root = root.clone
    cloned_root._bwfrom(root)

    #we clone by baumwandler
    cloned_clone = cloned_root._bwclone

    first._bwp.should == root
    second._bwp._bwp.should == root
    second._bwr.should == root
    cloned_root._bwp.should == root

    cloned_clone._bwa.should == [cloned_root, root]
    number._bwp.should == root
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
