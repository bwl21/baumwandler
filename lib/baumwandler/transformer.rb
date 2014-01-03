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
  # @author [beweiche]
  #
  module Predecessor


    #
    # This clones an object and maintains the
    # predecessor links
    #
    # Note that this is not a deep clone!
    #
    # @return [type] [description]
    def _bwclone
      self.clone._bwfrom(self)
    end


    #
    # Ths sets the predecessor link
    # @param  object [Object] The predecessor object
    #
    # @return [Object] The object itself to allow chaining
    def _bwfrom(object)
      @decorated = object
      return self
    end


    #
    # This yields the predecessor object
    #
    # @return [Object] The predecessor object
    def _bwp
      @decorated
    end


    #
    # This yiels a list of all predecessor objects
    #
    # @return [Array] The list of predecessor objects
    def _bwa
      p = _bwp
      a = p._bwa if p
      [p, a].flatten.compact
    end



    #
    # This yields the root of predecessor objects
    #
    # @return [Object] The root predecessor
    def _bwr
      _bwa[-1]
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
      def initialize(subjects)
        @subjects   = subjects
        @body      = nil
        @predicate = lambda{|i| true}
        @body      = lambda{|i| nil}
        @mode      = :insert
        @direction = :down
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
      r = Rule.new(subject_list)
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
      rule=_find_rule(node, :down)

      # evaluate rule
      result = [rule.get_body.call(node)].flatten

      #transform the result
      result.select{|n|n.class==node.class}.each{|node|
        transform(node)
      }

      # process the results
      case rule.get_mode
      when :insert
        node.set!(result)
      when :add
        node.setlast!(result)
      else
        raise "unsupported rule mode #{rule.get_mode}"
      end

      # find uprule
      rule = _find_rule(node, :up)

      if rule
        # evaluate rule
        result = [rule.get_body.call(node)].flatten

        # evaluate rule
        case rule.get_mode
        when :insert
          node.set!(result)
        when :add
          node.setlast!(result)
        else
          raise "unsupported rule mode #{rule.get_mode}"
        end
      end

      node

    end



    private

    def _find_rule(node, direction)
      (@rules[node.gid]||@rules[:"!default"]).select{|i|
        i.get_direction == direction
      }.select{|i|
        predicate=i.get_predicate
        result=true
        if predicate
          result=predicate.call(node)
        end
        result
      }.first
    end

  end
end


#
# We add the Baumwandler::Predecessor methods to any object
#
# @author [beweiche]
#
class Object
  include Baumwandler::Predecessor
end
