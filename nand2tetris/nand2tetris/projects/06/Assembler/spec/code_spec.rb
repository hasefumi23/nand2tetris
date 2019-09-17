require_relative './../lib/code.rb'

RSpec.describe Code do
  describe "dest" do
    it { expect(Code.dest("111")).to eq "000" }
  end

  describe "comp" do
    it { expect(Code.comp("111")).to eq "0000000" }
  end

  describe "jump" do
    it { expect(Code.jump("111")).to eq "000" }
  end
end
