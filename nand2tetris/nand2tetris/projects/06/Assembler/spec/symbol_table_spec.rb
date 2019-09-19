require_relative './../lib/symbol_table'

RSpec.describe SymbolTable do
  let(:sym_table) { SymbolTable.new }
  
  describe "initialize" do
    it "initialize sym_table" do
      expect(sym_table.sym_table).not_to be nil
    end
  end

  describe "add_entry" do
    it "adds symbol and address to symbol table" do
      expect {
        sym_table.add_entry("M=D+M", 0)
        sym_table.add_entry("M=D", 1)
        sym_table.add_entry("@100", 2)
      }.to change {
        sym_table.sym_table.size
      }.by(3)
    end
  end

  describe "#contains?" do
    it "returns true when pass a symbol which symbol table already has" do
      expect {
        sym_table.add_entry("M=D", 1)
      }.to change {
        sym_table.contains?("M=D")
      }.from(false).to(true)
    end

    it "returns false when pass a symbol which symbol table does not have" do
      expect {
        sym_table.add_entry("M=D", 1)
      }.not_to change {
        sym_table.contains?("M=M+1")
      }
    end
  end

    describe "#address_by_symbol" do
      it "returns address mapped to symbol" do
        sym_table.add_entry("M=D", 1)
        expect(sym_table.address_by_symbol("M=D")).to eq 1
      end
    end
end
