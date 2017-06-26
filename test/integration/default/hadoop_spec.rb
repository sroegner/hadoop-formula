for svc in ['hadoop-namenode', 'hadoop-secondarynamenode', 'hadoop-datanode', 'hadoop-resourcemanager', 'hadoop-nodemanager', 'hadoop-historyserver'] do
  describe service(svc) do
    it { should be_enabled }
    it { should be_running }
  end
end

for _port in [8020,50070,8088,19888,50075,8042]
  describe command("ss -tlns4|grep -e #{_port} -e LISTEN") do
    its (:exit_status) {should eq 0}
  end
end

for _log in ['hdfs-namenode.log', 'hdfs-secondarynamenode.log',
             'hdfs-datanode.log', 'yarn-resourcemanager.log',
             'yarn-nodemanager.log', 'yarn-historyserver.log'] do
  describe file("/var/log/hadoop/#{_log}") do
    it { should be_file }
  end
end
