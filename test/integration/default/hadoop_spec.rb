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

for _port in [8020,50070,50075] do
  describe command("ss -tlns4|grep -e #{_port} -e LISTEN") do
    its(:exit_status) { should eq(0)  }
  end
end

#describe file('/var/log/hadoop/hdfs-namenode.log') do
#  it { should be_file }
#  it { should be_owned_by 'hdfs' }
#  it { should be_grouped_into 'hdfs' }
#end
