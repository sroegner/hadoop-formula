describe service('hadoop-namenode') do
  it { should be_enabled }
  it { should be_running }
end

describe command('nc -z localhost 50070') do
  its(:stdout) { should eq("imok") }
  its(:stderr) { should be_empty }
end
