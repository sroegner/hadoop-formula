describe service('hadoop-namenode') do
  it { should be_enabled }
  it { should be_running }
end

describe service('hadoop-secondarynamenode') do
  it { should be_enabled }
  it { should be_running }
end

describe service('hadoop-datanode') do
  it { should be_enabled }
  it { should be_running }
end

describe command('curl --silent --fail --head $(hostname):50070 | head -1') do
  its(:stdout) { should eql("HTTP/1.1 200 OK\r\n") }
end

describe command('curl --silent --fail --head $(hostname):50075 | head -1') do
  its(:stdout) { should eql("HTTP/1.1 200 OK\r\n") }
end
