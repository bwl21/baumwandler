require 'baumwandler'

#
# This module contains all the baumwandler stuff
#
# @author [beweiche]
#
module Baumwandler


  #
  # This module contains methods which make the predecessor links
  # applicable to any object as source.
  #
  # Injected class variables
  # 
  # _bw_link - the predecessor link
  # _bw_rank - the rank
  # 
  # @author [beweiche]
  #
  module Object

    #
    # Ths sets the predecessor link
    # @param  object [Object] The node linked object
    #
    # @return [Object] The object itself to allow chaining
    def _bw_set_p(object)
      @_bw_link = object
      self
    end

    #
    # This yields the predecessor object
    #
    # @return [Object] The  node linked object
    def _bw_p
      @_bw_link
    end



    #########################
    # methods to be specialized lated




    # 
    # Set the parent of this node
    # 
    # Likely to be redefined in underlying Node implementations
    # 
    # This supports that any object can be part of a Baumwandler Tree
    # 
    # @param  node [Node] The parent of that node
    # 
    # @return [Node] The node itself
    def _bw_set_parent(node)
      @_bw_parent = node
      self
    end



    # 
    # This yields the parent of this node
    # 
    # Likely to be redefined in underlying Node implementations
    # 
    # This supports that any object can be part of a Baumwandler Tree
    # 
    # @return [Node] The parent node
    def _bw_parent
      @_bw_parent
    end

    # 
    # This yields the generic identifier of this node
    # 
    # Likely to be redefined in underlying Node implementations.
    # 
    # This supports that any object can be part of a Baumwandler Tree
    # 
    # @return [type] [description]
    def _bw_gid
      nil
    end


    ####################################################################
    # 
    # convenience Methods
    # 
    # todo: maybe place this in another module
    # 
    #
    # This yiels a list of all predecessor objects
    #
    # @return [Array] The list of node linked objects
    def _bw_a
      p = _bw_p
      a = p._bw_a if p
      [p, a].flatten.compact
    end

    #
    # This yields the root of node linked objects
    # mainly the node in the "source tree"
    #
    # @return [Object] The root node link
    def _bw_r
      _bw_a[-1]
    end

    # 
    # This indicates if the result of a query
    # is empty. This allows statements lik
    # 
    # if contents._bw? ...
    # 
    # @return [type] [description]
    def _bw?
      if respond_to? :empty?
        return self unless empty?
        return nil
      end
      return self
    end

    # set the properties of a give node. If the node has no _bw_gid
    # then it is cloned only
    # 
    # todo: handle Block
    # todo: manage conversion to a node if properties are specified
    def _bw_copy(gid = nil, attributes = nil, &block)
      if self._bw_gid
        result = self._bw_node(gid || self.gid, attributes||self.attributes, &block)._bw_set_p(self)
      else
        result = self.clone rescue self
        result._bw_set_p(self)
      end
      result
    end



    # included Attributes as getter and setter



    # 
    # Set the position in the parent object
    # 0 is the first position
    # 
    # @return [Node] The node itself
    def _bw_set_rank(rank)
      @_bw_rank = rank
      self
    end

    # 
    # Returns the position in the parent object
    # 
    # @return [Integer] The position in the parent object
    def _bw_rank
      @_bw_rank
    end

  end

  class Transformer

    @rules = {}

    #
    # This class represents one particular rule
    #
    # @author [beweiche]
    #
    class Rule
      def initialize(subjects, engine)
        @subjects   = subjects
        @body      = nil
        @predicate = lambda{|i| true}
        @body      = lambda{|i| nil}
        @mode      = :insert
        @direction = :down
        @engine    = engine
      end


      #
      # This addes the where clause to the rule
      # @param  &block [type] [description]
      #
      # @return [type] [description]
      def where(&block)
        @predicate = block
        self
      end


      #
      # this sets the node manipulation mode
      #
      def mode(mode)
        @mode = mode
        self
      end

      #
      # This sets the discard mode
      #
      # @return [type] [description]
      def discard
        @mode = :discard
        self
      end


      #
      # This sets the insert mode
      #
      # @return [type] [description]
      def insert
        @mode = :insert
        self
      end



      #
      # This sets the replace mode
      #
      # @return [type] [description]
      def replace
        @mode = :replace
        self
      end

      #
      # This sets the add mode
      #
      # @return [type] [description]
      def add
        @mode = :add
        self
      end

      #
      # This sets the setfirst mode
      #
      # @return [type] [description]
      def setfirst
        @mode = :setfirst
        self
      end
      #
      # This sets the rule body
      # @param  &block [type] [description]
      #
      # @return [type] [description]
      def body(&block)
        @body = block
        self
      end


      #
      # This makes it an up rule
      #
      # @return [type] [description]
      def up
        @direction = :up
        self
      end

      #
      # This makes it a down rule
      #
      # @return [type] [description]
      def down
        @direction = :down
        self
      end

      #
      # This retrieves the predicate
      #
      # @return [type] [description]
      def get_predicate
        @predicate
      end


      #
      # Ths retrieves the rule body
      #
      # @return [type] [description]
      def get_body
        @body
      end


      #
      # [get_direction description]
      #
      # @return [type] [description]
      def get_direction
        @direction
      end

      #
      # Ths retrieves the rule mode
      #
      # @return [type] [description]
      def get_mode
        @mode
      end

      def get_subjects
        @subjects
      end

      def get_engine
        @engine
      end

    end


    #
    # Initialize a transformation engine
    #
    # @return [type] [description]
    def initialize
      @rules=Hash.new
    end

    #
    # Ths creates a new rule and registers it
    # @param  subjects [type] [description]
    #
    # @return [type] [description]
    def rule(subjects)
      subject_list = [subjects].flatten
      r = Rule.new(subject_list, self)
      subject_list.flatten.each{|s|
        @rules[s] ||= Array.new
        @rules[s] << r
      }
      r
    end


    #
    # This yields all rules
    #
    # @return [type] [description]
    def get_rules
      @rules
    end


    #
    # This transforms a node
    # @param  node [type] [description]
    #
    # @return [type] [description]
    def transform(node)
      # find downrule
      #

      process_results=proc{|rule, result, node|
        if node.gid
          case rule.get_mode
          when :insert
            node.set!(result)
          when :add
            node.setlast!(result)
          when :setfirst
            node.setfirst!(result)
          when :discard
          else
            raise "unsupported rule mode: #{rule.get_mode}"
          end
        end
      }

      # todo: support special rules for Ruby object
      # 
      if node._bw_gid
        rule=_find_rule(node, :down)

        #$log.debug "#{node.gid}(#{rule.get_subjects}): #{rule.get_direction}, #{rule.get_mode})"

        # evaluate downrule
        result = [rule.get_body.call(node)].flatten

        process_results.call(rule, result, node)

        #transform the result
        #node.contents.select{|n|n.class==node.class}.each{|subnode|
        node.contents.each{|subnode|
          transform(subnode)
        } if node._bw_gid

        # find uprule
        rule = _find_rule(node, :up)

        if rule
          # evaluate uprule
          result = [rule.get_body.call(node)].flatten#.map{|n| n._bwclone}

          # process rule
          [process_results.call(rule, result, node)].flatten
        end
      end
      node

    end



    private

    def _find_rule(node, direction)
      r=([@rules[node.gid], @rules[:"!default"]].flatten.compact).select{|i|
        i.get_direction == direction
      }.select{|i|
        predicate=i.get_predicate
        result=true
        if predicate
          result=predicate.call(node)
        end
        result
      }
      r.first
    end

  end
end


#
# We add the Baumwandler::Predecessor methods to any object
#
# @author [beweiche]
#
class Object
  include Baumwandler::Object
end
