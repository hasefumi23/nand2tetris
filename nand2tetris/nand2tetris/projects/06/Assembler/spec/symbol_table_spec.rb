require 'minitest/autorun'
require_relative './../lib/symbol_table'

class SymbolTableTest < Minitest::Test
  def test_parser
    assert_equal SymbolTable.hello, 'hello from SymbolTable'
  end
end
