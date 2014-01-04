module Baumwandler


  #
  # This is an example implementation of the Baumwandler node interface
  #
  # It implements the minimum set of methods required by Baumwandler::Transformer
  #
  # todo: clarify handling of non Baumwandler objects
  #
  # @author [beweiche]
  #
  class Node
    attr_accessor :gid, :key, :contents, :type, :parent, :left, :right, :attributes
    @gid = nil
    @attributes = nil
    @contents = nil
    @left = nil
    @right = nil
    @type = :node
    @p = nil
    @parent=nil


    #
    # This retrieves a particluar attribute
    # @param  key [key] The name of the attribute
    #
    # @return [Object] The value of the attribute
    def [](key)
      @attributes[key]
    end


    #
    # This creates a new node. This is basically a static factory method
    # @param  gid [Symbol] The Generic Identifier of the node
    # @param  attributes={} [Hash] The attribute list of the node
    # @param  &block [Lambda] Result of this block is used as contents of the node
    #
    # @return [Node] it returns the neew node
    def self.node(gid, attributes={}, &block)
      Node.new(gid, type=:node, attributes, &block)
    end


    #
    # This as well creates a new node. It is provided as a convenience method
    #
    # todo: do we really need this?
    #
    # @param  gid [type] [description]
    # @param  attributes={} [type] [description]
    # @param  &block [type] [description]
    #
    # @return [type] [description]
    def node(gid, attributes={}, &block)
      Node.new(gid, type=:node, attributes, &block)
    end


    #
    # This appends a list of objects to the content
    # @param  contents [Array] the content to be appended
    #
    # @return [node] The node itself to allow chaining
    def setlast!(contents)
      @contents.push *(contents)
      _treesync
      self
    end


    #
    # This prepends a list of objects to the content
    # @param  contents [Array] The content to be prepended
    #
    # @return [node] The node itself to allow chaining
    def setfirst!(contents)
      @contents.unshift *(contents)
      _treesync
      self
    end


    #
    # This insers the result of the block as content
    # @param  &block [Lambda] Result of this block is added
    #
    # @return [node] The node itself to allow chaining
    def set_block!(&block)
      set!(_prepare(block))
      self
    end


    #
    # This inserts a list of objects as content. Thereby
    # the previous content is replaced.
    #
    # @param  contents [Array] This is the list of new content
    #
    # @return [node] The node itself to allow chaining
    def set!(contents)
      @contents = contents
      _treesync
      self
    end


    #
    # This alters the entire node.
    #
    # * In order to remove an attribute, set it to nil
    #
    # @param  gid=nil [Symbol] The new generic identifier
    # @param  attributes=nil [Hash] The changed attributes
    # @param  &block [Lambda] Result of this block is inserted
    #
    # @return [node] The node itself to allow chaining
    def alter!(gid=nil, attributes=nil, &block)
      @gid=gid unless gid.nil?
      @attributes.merge!(attributes) unless attributes.nil?
      @attributes.delete_if{|k,v| !v}
      set_block!(&block) if block_given?
      _treesync
      self
    end


    #
    # queries
    # ##############
    #

    #
    # Provide the left siblings of a given node
    #
    # @return [Array] The list of left siblings
    def left
      r = nil
      r = [@left, @left.left].flatten.compact if @left
      r
    end

    #
    # [right description]
    #
    # @return [Array] The list of right siblings
    def right
      r = nil
      r = [@right, @right.right].flatten.compact if @right
      r
    end


    #
    # Yield the current node as xml.
    # This is for debugging purposes only
    #
    # @param  indent="" [String] The initial indentation used to derive indentation from recursion
    #
    # @return [String] The node as xml
    def to_xml(indent="")
      attlist=attributes.map{|k,v| "#{k}=\"#{v}\""}.unshift("").join(" ")
      [
        "\n#{indent}<#{gid}#{attlist}>",
        contents.map{|c|
          if c.respond_to? :to_xml
            c.to_xml(indent+"  ")
          else
            c
          end
        },
        ("\n#{indent}" if left || (not parent)),
        "</#{gid}>"
      ].join
    end


    private

    def _prepare(block)
      n=[block.call(self)].flatten.compact
    end

    def _treesync
      l=nil
      @contents.each{|i|
        i.left=l if i.class==self.class
        l.right=i if l.class==self.class
        i.parent=self if i.class==self.class
        l=i if i.class==self.class
      }
    end

    def initialize(gid, type=:node, attributes={}, &block)
      @gid = gid
      @attributes = attributes
      @type = type
      @parent=nil
      @contents=[]
      set_block!(&block) if block_given?
      nil
    end

  end

end
