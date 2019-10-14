RSpec.describe Hello do
  it "hello return hello world" do
    expect(Hello.new.hello).to eq "hello world"
  end
end
