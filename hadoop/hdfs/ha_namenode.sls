{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- set username = 'hdfs' %}
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

{% if hdfs.is_namenode %}
{% if hdfs.namenode_count == 2 %}

nc:
  pkg.installed

format-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
    - user: hdfs
    - unless: test -d {{ test_folder }}

format-zookeeper:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs zkfc -formatZK
    - user: hdfs

hdfs-services:
  service.running:
    - enable: True
    - names:
      - hadoop-namenode
      - hadoop-zkfc

# hdfs namenode –bootstrapStandby
{% endif %}
{% endif %}
