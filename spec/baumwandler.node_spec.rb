$:.unshift "../lib"

require 'baumwandler'


describe Baumwandler::Node, exp:true do

  before :all do
  end

  it "can easily be created by a global function" do
    a = Baumwandler::Node.bw_node(:hugo, franz: "josef", karl: "franz")
    a.gid.should==:hugo
    a[:franz].should=="josef"
    a[:karl].should=="franz"
  end

  it "can manipulate node properties" do
    a = Baumwandler::Node.bw_node(:hugo_old)

    a.alter!(:hugo, franz: "inhalt_franz")
    a[:franz].should=="inhalt_franz"
  end

  it "can remove attributes" do
    a=Baumwandler::Node.bw_node(:hugo, a1: 10, a2:20)
    a.alter!(nil, a2: nil)
    a[:a2].nil?.should==true
  end

  it "can build complex trees" do
    a = Baumwandler::Node.bw_node(:"AR-PACKAGE"){|n|
      [n.bw_node(:"SHORT-NAME"){|n| ["hugo", n.bw_node(:L)]},
       n.bw_node(:"LONG-NAME"){|n|
         n.bw_node(:"L-1", L:"de"){|n|
           "das ist deutsch #{n[:L]}"
         }
         n.bw_node(:"L-1", L:"en"){|n|
           "this is english #{n[:L]}"
         }

       }
       ]
    }
    a.contents.first.gid.should==:"SHORT-NAME"
  end

  it "finds all side nodes" do
    a = Baumwandler::Node.bw_node(":a"){|n|[
      n.bw_node(:b),
      "hugo",
      n.bw_node(:c),
      "hugo",
      n.bw_node(:d),
      n.bw_node(:e)
     ]
    }
    
    a.contents.first.next.map{|n|n.bw_gid}.compact.should==[:c, :d, :e]
    a.contents[-1].previous.map{|n|n.bw_gid}.compact.should==[:d, :c, :b]
  end
end
