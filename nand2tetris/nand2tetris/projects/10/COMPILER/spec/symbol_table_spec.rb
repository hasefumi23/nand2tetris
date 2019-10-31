RSpec.describe SymbolTable do
  let(:sym_table) { SymbolTable.new }

  before do
    sym_table.define("first_static", "int", "STATIC")
    sym_table.define("second_static", "String", "STATIC")
    sym_table.define("first_arg", "String", "ARG")
  end

  describe '#define' do
    it 'define symbol in symbol table' do
      sym = Sym.new("first_static", "int", "STATIC", 0)
      target_sym = sym_table.class_hash["first_static"]
      expect(target_sym).to eql(sym)
    end

    it 'define multi symbol in symbol table' do
      sym = Sym.new("second_static", "String", "STATIC", 1)
      target_sym = sym_table.class_hash["second_static"]
      expect(target_sym).to eql(sym)
    end
  end

  describe '#var_count' do
    it 'count of symbols of passed kind' do
      expect(sym_table.var_count("ARG")).to eq(1)
      expect(sym_table.var_count("STATIC")).to eq(2)
    end
  end

  describe '#kind_of' do
    it 'return kind of name' do
      expect(sym_table.kind_of("first_arg")).to eq("ARG")
      expect(sym_table.kind_of("first_static")).to eq("STATIC")
    end
  end

  describe '#type_of' do
    it 'return type of name' do
      expect(sym_table.type_of("first_arg")).to eq("String")
      expect(sym_table.type_of("first_static")).to eq("int")
    end
  end

  describe '#index_of' do
    it 'return index of name' do
      expect(sym_table.index_of("first_static")).to eq(0)
      expect(sym_table.index_of("second_static")).to eq(1)
    end
  end
end
