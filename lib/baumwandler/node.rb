module Baumwandler

  #
  # This is an example implementation of the Baumwandler node interface
  #
  # It implements the minimum set of methods required by Baumwandler::Transformer
  #
  # todo: clarify handling of non Baumwandler objects
  # todo: remove attributes: left, right, this
  #
  # @author [beweiche]
  #
  #
  class Node
    #
    # This inserts a list of objects as content. Thereby
    # the previous content is replaced.
    #
    # @param  contents [Array] This is the list of new content
    #
    # @return [node] The node itself to allow chaining
    def set!(contents)
      pcontents = _prepare_content(contents)
      @contents = pcontents
      _treesync
      self
    end


    #
    # This prepends a list of objects to the content
    # @param  contents [Array] The content to be prepended
    #
    # @return [node] The node itself to allow chaining
    def setfirst!(contents)
      pcontents = _prepare_content(contents)
      @contents.unshift *(pcontents)
      _treesync
      self
    end

    #
    # This appends a list of objects to the content
    # @param  contents [Array] the content to be appended
    #
    # @return [node] The node itself to allow chaining
    def setlast!(contents)
      pcontents = _prepare_content(contents)
      @contents.push *(pcontents)
      _treesync
      self
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
    def bw_node(gid, attributes={}, &block)
      self.class.new(gid, type=:node, attributes, &block)
    end


    #
    # redefine bw_gid
    #
    # @return [String] The generic Identifier
    def bw_gid
      @gid
    end
  end


  #
  # This is the specific part of the implementation of Node
  #
  # @author [beweiche]
  #
  class Node
    attr_accessor :gid, :contents,  :attributes

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
    def self.bw_node(gid, attributes={}, &block)
      Node.new(gid, type=:node, attributes, &block)
    end




    #
    # This insers the result of the block as content
    # @param  &block [Lambda] Result of this block is added
    #
    # @return [node] The node itself to allow chaining
    def set_block!(&block)
      set!(_prepare_block(block))
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
    def previous
      r = nil
      r = bw_parent.contents[0 .. self.bw_rank - 1].reverse if bw_parent
      [r].flatten.compact
    end

    #
    # Provide the next siblings of a given node
    #
    # @return [Array] The list of right siblings
    def next
      r = nil
      r = bw_parent.contents[self.bw_rank + 1 .. -1] if bw_parent
      [r].flatten.compact
    end

    #
    # Yield the current node as xml.
    # This is for debugging purposes only
    #
    # @param  indent="" [String] The initial indentation used to derive indentation from recursion
    #
    # @return [String] The node as xml
    def to_xml(indent="", options={mode: :default})
      attlist=attributes.map{|k,v| "#{k}=\"#{v}\""}.unshift("").join(" ")
      pre = ""
      pre = "<!-- $#{object_id} (#{[bw_a].flatten.map{|i|i.object_id}.join("|")}) -->"  if options[:mode]==:debug
      [
        "\n#{indent}<#{gid}#{attlist}>#{pre}",
        contents.map{|c|
          if c.respond_to? :to_xml
            c.to_xml(indent+"  ", options)
          else
            c
          end
        },
        #("\n#{indent} #{previous.first.gid}: " if previous.first.gid),
        "</#{gid}>"
      ].join
    end


    #
    # This yields a string representation for debugging purposes
    #
    # @return [String] The string representation
    def to_s
      to_xml("", mode: :debug)
    end


    ## intended for baumwandler internal purposes

    # This clones a node. Note that it is
    # **not** a deep clone. As in the context
    # of Baumwandler, a node is cloned iteravely.
    #
    # This overrides the default definition given in
    # transformer.rb
    #
    # It takes the gid and the
    # attributes but not the content.
    #
    # It also maintains the Predecessor link
    #
    # @return [Node] The object itself
    # def _bwclone
    #   p=self._get_bwfrom || self
    #   self.node(gid, attributes)._bwfrom(p)
    # end

    private

    def _prepare_block(block)
      n=[block.call(self)].flatten.compact
    end

    def _prepare_content(contents)
      contents.map{|n|
        if n.bw_parent && n.bw_gid
          r = n.bw_copy()
        else
          r=n
        end
        r
      }
    end

    def _treesync
      @contents.each_with_index{|node, index|
        node.bw_set_rank(index)
        node.bw_set_parent(self)
      }
    end

    def initialize(gid, type=:node, attributes={}, &block)
      @gid = gid
      @attributes = attributes
      @type = type
      @parent   = nil
      @contents = []
      set_block!(&block) if block_given?
      nil
    end
  end # class
end  # module
