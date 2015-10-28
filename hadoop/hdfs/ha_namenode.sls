{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- set username = 'hdfs' %}
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

nc:
  pkg.installed

{%- if hdfs.is_primary_namenode %}

format-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
    - user: hdfs
    - unless: test -d {{ test_folder }}

# TODO: add a zookeeper state check
format-zookeeper:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs zkfc -formatZK
    - user: hdfs

{%- elif hdfs.is_secondary_namenode %}
  # orchestration has to ensure that this part runs after the primary has successfully finished

bootstrap-secondary-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -bootstrapStandby
    - user: hdfs
    - unless: test -d {{ test_folder }}

{%- endif %}

{%- if hdfs.is_primary_namenode or hdfs.is_secondary_namenode %}

hdfs-services:
  service.running:
    - enable: True
    - names:
      - hadoop-namenode
      - hadoop-zkfc

{% endif %}
