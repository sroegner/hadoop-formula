for svc in ['hadoop-namenode', 'hadoop-secondarynamenode', 'hadoop-datanode', 'hadoop-resouremanager', 'hadoop-nodemanager', 'hadoop-historyserver'] do
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
