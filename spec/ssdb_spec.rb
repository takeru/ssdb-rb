require 'spec_helper'

describe SSDB do

  describe "class" do
    subject { described_class }

    its(:current) { should be_instance_of(described_class) }
    it { should respond_to(:current=) }
  end

  it 'should execute batches' do
    res = subject.batch do
      subject.set  "#{FPX}:key", "100"
      subject.get  "#{FPX}:key"
      subject.incr "#{FPX}:key", 10
      subject.decr "#{FPX}:key", 30
    end
    res.should == [true, "100", 110, 80]
  end

  it 'should execute batches with futures' do
    s = n = nil
    subject.batch do
      subject.set  "#{FPX}:key", "100"
      s = subject.get  "#{FPX}:key"
      n = subject.incr "#{FPX}:key", 10

      -> { s.value }.should raise_error(SSDB::FutureNotReady)
    end

    s.should be_instance_of(SSDB::Future)
    s.value.should == "100"
    n.value.should == 110
  end

  it 'should retrieve info' do
    res = subject.info
    res.should be_instance_of(Hash)
    res.should include("version")
    res.should include("cmd.get")
    res.should include("leveldb.stats")

    res["cmd.get"].should be_instance_of(Hash)
    res["cmd.get"].keys.should =~ ["calls", "time_wait", "time_proc"]

    res["leveldb.stats"].should be_instance_of(Hash)
  end
end
