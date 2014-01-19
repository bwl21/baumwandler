$:.unshift "../lib"

require 'baumwandler'

describe "Baumwandler::Transformer::Rule", exp: true do

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

describe "Baumwandler::Tranformer.transform", exp:true do

  before :all do
    @bw_factory = Baumwandler::Node # to be used as node factory
    @e          = Baumwandler::Transformer.new # the first engine
    @e2         = Baumwandler::Transformer.new # the second engine

    @e.rule(:CHAPTER).body do |my_chapter|
      cc= my_chapter.bw_p.next.take_while{|i|
      	i.gid != my_chapter.bw_p.gid
      }.map{|my_p| my_p.bw_copy(:P)}

      a=[
        @bw_factory.bw_node(:"LONG-NAME"){|n|
          @bw_factory.bw_node(:"L-5", L:"DE"){
          my_chapter.bw_p.contents #.map{|i| i.bw_copy}
         }
        },
        @bw_factory.bw_node(:"P"),

        cc
      ].flatten
      a
    end



    # this demonstrates a destrucive manipulation
    @e.rule(:CHAPTER).up.discard.body{|my_chapter|
      r=[
      	my_chapter.contents[1].contents.first.set!(["we have #{my_chapter.contents.count} children"])
      ]
    }

    @e.rule(:P).body do |this|
      a=@bw_factory.bw_node(:"L-1", L:"DE"){
        r=["(parent id #{this.bw_parent.object_id})",
           this.contents._bw? || this.bw_p && this.bw_p.contents
           ].flatten
        r
      }
      a
    end

    @e.rule(:DOCUMENT).body do |this|
      a=this.bw_p.contents.select{|i| i.gid == :h1}
      .map{|i| i.bw_copy(:CHAPTER)}
      a
    end


    @e.rule(:hugo).body do |this|
      ["{added by rule :hugo}", (this.bw_p || this).contents]
    end

    @e.rule(:"!default").add.body do |this|
      r=[]
      r=this.bw_p.contents if this.bw_p
      #.map{|i|i.bw_copy} if this.bw_p
      r
    end

    @e2.rule(:"!default").add.body do |this|
      r=[]
      r=this.bw_p.contents if this.bw_p
      #.map{|i|i.bw_copy} if this.bw_p
      r
    end

    @source=@bw_factory.bw_node(:source){|a|
      [
        @bw_factory.bw_node(:h1){["das ist überschrift 1",
        @bw_factory.bw_node(:hugo){"inhalt hugo"}]},
        @bw_factory.bw_node(:p){"der erste paragraph"},
        @bw_factory.bw_node(:p){"der zweite paragraph"},
        @bw_factory.bw_node(:p){"der dritte paragraph"},
        @bw_factory.bw_node(:h1){"das ist kapitel 2"},
        @bw_factory.bw_node(:p){"der vierte paragraph"},
        @bw_factory.bw_node(:p){"der fünfte paragraph"},
        @bw_factory.bw_node(:p){["der sechste paragraph"]},
        @bw_factory.bw_node(:h1){"das ist kapitel 3"},

    ]}

    @source_ref=@source.to_s

    @target1 = @bw_factory.bw_node(:DOCUMENT).bw_set_p(@source) # yields {chapter:][]}
      	#puts "before first transformation", @source.to_s

    @e.transform(@target1)
      	#puts "after first transformation", @source.to_s, @target1.to_s
    @target2 = @bw_factory.bw_node(:DOCUMENT).bw_set_p(@target1)
    @e2.transform(@target2)
  end

  it "performs transformation of nodes" do
    #puts @ta_factoryrget1.to_s
    #puts @source.to_s

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

  it "counts Baumwandler nodes" do
  	o = ObjectSpace.each_object(Baumwandler::Node)
  	puts o.count
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
    first   = "this the first derivable".bw_set_p(root)
    second  = "this is the second derivable".bw_set_p(first)
    number  = 1
    number.bw_set_p(root) # it also works with fixnums


    #we clone and establish link later
    cloned_root = root.clone
    cloned_root.bw_set_p(root)

    #we clone by baumwandler
    cloned_clone = cloned_root.bw_copy

    first.bw_p.should == root
    second.bw_p.bw_p.should == root
    second.bw_r.should == root
    cloned_root.bw_p.should == root
    cloned_clone.bw_a.should == [cloned_root, root]
    number.bw_p.should == root
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
