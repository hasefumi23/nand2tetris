require_relative "sym"

class SymbolTable
  attr_reader :class_hash, :subroutine_hash, :past_subroutine_hashes

  def self.kind_to_seg(kind)
    case kind
    when "VAR" then "LOCAL"
    when "ARG" then "ARG"
    when "FIELD" then "THIS"
    else "NONE-KIND"
    end
  end

  # 空のシンボルテーブルを生成する
  def initialize
    @class_hash = {}
    @subroutine_hash = {}
    # デバッグ用
    @past_subroutine_hashes = []
  end

  # 新しいサブルーチンのスコープを開始する
  # （つまり、サブルーチンのシンボルテーブルをリセットする）
  def start_subroutine
    @past_subroutine_hashes << @subroutine_hash unless @subroutine_hash.empty?
    @subroutine_hash = {}
  end

  # 引数の名前、型、属性で指定された新しい識別子を定義し、それに実行インデックスを割り当てる
  # STATIC と FIELD 属性の識別子はクラスのスコープを持ち、ARGと VAR 属性の識別子はサブルーチンのスコープを持つ
  def define(name, type, kind)
    sym = Sym.new(name, type, kind, var_count(kind))
    hash = case kind
    when "STATIC", "FIELD" then @class_hash
    when "ARG", "VAR" then @subroutine_hash
    end
    # 既に定義済みの場合でも再定義しようとする場合があるので、それを防ぐ
    hash[name] = sym if hash[name].nil?
    hash[name]
  end

  # 引数で与えられた属性について、それが現在のスコープで定義されている数を返す
  def var_count(kind)
    hash = case kind
    when *%w[STATIC FIELD] then @class_hash
    when *%w[ARG VAR] then @subroutine_hash
    end
    hash.select { |_, s| s.kind == kind }.size
  end

  def sym_of(name)
    @subroutine_hash[name] || @class_hash[name]
  end

  # 引数で与えられた名前の識別子を現在のスコープで探し、その属性を返す。その識別子が現在のスコープで見つからなければ、NONE を返す
  def kind_of(name)
    (@subroutine_hash[name] || @class_hash[name])&.kind || "NONE"
  end

  # 引数で与えられた名前の識別子を現在のスコープで探し、その型を返す
  def type_of(name)
    (@subroutine_hash[name] || @class_hash[name])&.type
  end

  # 引数で与えられた名前の識別子を現在のスコープで探し、そのインデックスを返す 
  def index_of(name)
    (@subroutine_hash[name] || @class_hash[name])&.index
  end
end
