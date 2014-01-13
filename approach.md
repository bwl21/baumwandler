# Objectives

*baumwandler* is intended to help to transfer the knowledge of MetaMorphosis based converters to the ruby world.

* shall be intuitive for rubyists
* do not apply MM based syntactical sugar
* prove MM- Patterns and their counterpart in ruby
* shall be agnostic to the underlying tree model (can be used with Nokogiri and others). 
* May provide node and nodeList interface for easy transfer of MM-concepts.


# Approach

### properties of a node in MetaMorphosis

* nodename
* attributes
* contents
* predecessor
* parent
* type [node, pi, string, real, integer, object]

## the general approach

### minimal node interface

Even if Baumwandler should work with any kind of object, we create an interface with minimum methods. These methods are required for

* manipulating the target tree

	set!
	:	insert new contents in a given node

	setlast!
	:	append new contents in a given node

	setfirst!
	:	prepend new contents in a given node

* inspecting node properties

	type
	:	Distinguish between node, pi, entity, object ...

	gid
	:	generic Identifier of the node used to find the right rules

	_bwparent
	:

* maintaining node properties with respect to transformation

	_bwfrom(node)
	:	maintain the node link to the previous tree

	_bw_setprops(){| |}
	:	set the Baumwandlerproperties of a node

		creates a new node with the same properties as the subject, no content, but predecessorlink
	_bw

### convenient interface

#### nodelist

a nodeliste basically boils down to an Array. So we do not introduce a particular class for that but rather use the standard Array methods of ruby.



#### creating a node

	a=BW::node("hugo") do
        [BW:node("franz),
         "string"
        ]
	end

   
# The transform Tree System

- gets rules
- controls the transformation process

~~~~(.plantuml)
@startuml

package Baumwandler_Transformer {

class Rule
Object ..|> Predecessor

Transformer *-- Rule

Rule --> "query or change" Baumwandler_interface.BwNodeInterface
Transformer --> "change" Baumwandler_interface.BwNodeInterface

}

class Object

class Predecessor <<M, Module>> {
	Predecessor @object

	Predecessor _bw_p()
	Predecessor _bw_set_p()
	__to be specialized__
	Predecessor _bw_set_parent()
	Predecessor _bw_parent()
	String _bw_gid()
	__convenience Methods__
	Predecessor _bw_clone()
	Array _bw_a()
	Predecessor _bw_r()
	Array | nil _bw?()
	Integer _bw_rank=
	Integer _bw_rank
}
class Object
class Transformer

namespace Baumwandler_interface {
	class BwNodeInterface<<M, Module>>{
    	Node _bw_set!()
    	Node _bw_setfirst!()
    	Node _bw_setlast!()
    	Node _bw_replace!()
    	Array _bw_contents()
    	__specialize Predecessor__
    	Node _bw_setprops()
    	Node _bw_parent()
    	Node _bw_gid
    	__convenience methods__
		Node _bw_node(){}
	    Predecessor _bw_set_props()
    }
}


namespace Baumwandler_nokogiri {
	class Node<extends Object>{
	}
	class Nodefactory

	Node --|> "implements" Baumwandler_interface.BwNodeInterface
}

namespace Baumwandler_native {
	class Node<extends Object>
	class Nodefactory

	Node --|> "implements" Baumwandler_interface.BwNodeInterface
}



@endum

~~~~


~~~~{.plantuml}
@startuml

participant Main
participant Transformer
participant TreeSystem

Main -> Transformer :new
activate Transformer

Main -> Transformer : add rule

Main -> TreeSystem : create root node
TreeSystem --> Main : root

Main -> Transformer : transform (root)


Transformer -> Transformer : find downrule


group transformation



Transformer -> TreeSystem : evaluate block
TreeSystem -->Transformer : result

Transformer -> TreeSystem : set! add! ... results

loop iterate each node in root

Transformer -> Transformer : transform(node)
activate Transformer

Transformer -> Transformer : find downrule

Transformer -> TreeSystem : evaluate block
TreeSystem --> Transformer : result

Transformer -> TreeSystem : set! add! ... results

ref over TreeSystem, Transformer : recursive transformation

Transformer -> Transformer : find uprule

Transformer -> TreeSystem : evaluate block
TreeSystem --> Transformer : result
deactivate Transformer


end	

Transformer -> Transformer : find applicable Uprule
Transformer -> TreeSystem : evaluate block
Transformer -> TreeSystem : set! add! ... results
end

Transformer --> Main

@enduml
~~~~

# mm expressions mapped to ruby


## chain array methods 

		a.contents.contents

	we have to write

		a.contents.map{|i| i.contents}.flatten unless a.contents.nil?

	Therefore we decided that all node queries methods (next, previous, contents etc.) always yield an Array, even an empty Array.


## specify fallbacks 
	

MM allows to specify

		*a.contents | "fallback"

Ruby has to write

		a.contents.empty ? a.contents : "fallback"

we could fix that by adding a method _bw? to Object which either delivers the object/Array or nil if object is nil or Array is empty?:

	    def _bw?
	      if respond_to? :empty?
	        return self unless empty?
	        return nil
	      end
	      return self
	    end

then we can write

		a.contents | "fallback"

# combine sets

MM allows to combine sets

	*a := (1, 2, 3)
	*b := (10, 100)

	*c=(*a * *b) yields (10, 20, 30, 100, 200, 300)

Ruby needs to use

	a = [1, 2, 3]
	b = [100, 200, 300]

	c = a.product(b).map{|a, b| a * b}




