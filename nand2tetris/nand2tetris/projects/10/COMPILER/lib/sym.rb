class Sym
  attr_accessor :name, :type, :kind, :index

  def initialize(name, type, kind, index)
    @name = name
    @type = type
    @kind = kind
    @index = index
  end

  def eql?(other)
    @name == other.name &&
      @type == other.type &&
      @kind == other.kind &&
      @index == other.index
  end

  def hash
    [@name, @type, @kind, @index].hash
  end
end
