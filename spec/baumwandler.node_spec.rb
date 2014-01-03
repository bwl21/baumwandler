$:.unshift "../lib"

require 'baumwandler'


describe Baumwandler::Node, exp:true do

  before :all do
  end

  it "can easily be created by a global function" do
    a=Baumwandler::Node.node(:hugo, franz: "josef", karl: "franz")
    a.gid.should==:hugo
    a[:franz].should=="josef"
    a[:karl].should=="franz"
  end

  it "can manipulate node properties" do
    a=Baumwandler::Node.node(:hugo_old)

    a.alter!(:hugo, franz: "inhalt_franz")
    a[:franz].should=="inhalt_franz"
  end

  it "can remove attributes" do
    a=Baumwandler::Node.node(:hugo, a1: 10, a2:20)
    a.alter!(nil, a2: nil)
    a[:a2].nil?.should==true
  end

  it "can build complex trees" do
    a=Baumwandler::Node.node(:"AR-PACKAGE"){|n|
      [n.node(:"SHORT-NAME"){|n| ["hugo", n.node(:L)]},
       n.node(:"LONG-NAME"){|n|
         n.node(:"L-1", L:"de"){|n|
           "das ist deutsch #{n[:L]}"
         }
         n.node(:"L-1", L:"en"){|n|
           "this is english #{n[:L]}"
         }

       }
       ]
    }
    a.contents.first.gid.should==:"SHORT-NAME"
  end

  it "finds all side nodes" do
    a=Baumwandler::Node.node(":a"){|n|[
      n.node(:b),
      "hugo",
      n.node(:c),
      "hugo",
      n.node(:d),
      n.node(:e)
     ]
    }
    a.contents.first.right.map{|n|n.gid}.should==[:c, :d, :e]
    a.contents[-1].left.map{|n|n.gid}.should==[:d, :c, :b]
  end
end
