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
  module Object

    #
    # This clones an object and maintains the
    # node links
    #
    # Note that this is a deep clone!
    # This is likely to be redefined for
    # Impelmentation of non terminal nodes
    #
    # @return [Object] [The cloned object]
    def _bwclone
      self.clone._bwfrom(self)
    end

    # todo: handle Block
    # todo: manage conversion to a node if properties are specified
    def _bwprops(gid = nil, attributes = nil, &block)
      if self.gid
        result = self.node(gid || self.gid, attributes||self.attributes, &block)._bwfrom(self)
      else
        result=self.clone rescue self
      end
      result
    end

    #
    # Ths sets the predecessor link
    # @param  object [Object] The node linked object
    #
    # @return [Object] The object itself to allow chaining
    def _bwfrom(object)
      @_bw_link = object
      self
    end

    #
    # This yields the predecessor object
    #
    # @return [Object] The  node linked object
    def _bwp
      @_bw_link
    end

    #
    # This yiels a list of all predecessor objects
    #
    # @return [Array] The list of node linked objects
    def _bwa
      p = _bwp
      a = p._bwa if p
      [p, a].flatten.compact
    end

    #
    # This yields the root of node linked objects
    # mainly the node in the "source tree"
    #
    # @return [Object] The root node link
    def _bwr
      _bwa[-1]
    end

    #
    # This yields nil unless superseeded by a paticular implementation
    # todo: this ensures, that the the routines in transformer also work
    # for non baumwandler Nodes
    def gid
      nil
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



    # included Attributes as getter and setter

    def _bw_parent=(node)
      @_bw_parent=node
    end

    def _bw_parent
      @_bw_parent
    end

    def _bw_rank=(rank)
      @_bw_rank=rank
    end

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
      if node.gid
        rule=_find_rule(node, :down)

        #$log.debug "#{node.gid}(#{rule.get_subjects}): #{rule.get_direction}, #{rule.get_mode})"

        # evaluate downrule
        result = [rule.get_body.call(node)].flatten

        process_results.call(rule, result, node)

        #transform the result
        #node.contents.select{|n|n.class==node.class}.each{|subnode|
        node.contents.each{|subnode|
          transform(subnode)
        } if node.gid

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
