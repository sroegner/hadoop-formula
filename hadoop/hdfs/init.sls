{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}

{%- set username = 'hdfs' %}
{%- set uid = hadoop.users[username] %}

{{ hadoop_user(username, uid) }}

# every node can advertise any JBOD drives to the framework by setting the hdfs_data_disk grain
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}
{%- set systemd_servicegroup_env = hadoop.sysconfigdir + '/hadoop-hdfs' %}

{% for disk in hdfs_disks %}
{{ disk }}/hdfs:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{% if hdfs.is_namenode %}
{{ disk }}/hdfs/nn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{{ disk }}/hdfs/snn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

{%- if hdfs.tmp_dir != '/tmp' %}
{{ hdfs.tmp_dir }}:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
    - mode: '1775'
{% endif %}


{%- if hdfs.is_datanode %}
{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{%- if hdfs.is_journalnode %}
{{ disk }}/hdfs/journal:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{% endfor %}

{%- if grains['systemd'] %}
{{ systemd_servicegroup_env }}:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs.sysconfig
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      log_dir: {{ hadoop.log_root }}
      log_level: {{ hdfs.log_level }}

{{ hadoop.sysconfigdir }}/hadoop-namenode:
  file.managed:
    - source: salt://hadoop/conf/hdfs/namenode.sysconfig
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop.sysconfigdir }}/hadoop-secondarynamenode:
  file.managed:
    - source: salt://hadoop/conf/hdfs/secondarynamenode.sysconfig
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop.sysconfigdir }}/hadoop-datanode:
  file.managed:
    - source: salt://hadoop/conf/hdfs/datanode.sysconfig
    - template: jinja
    - mode: 644
    - user: root
    - group: root
{%- endif %}

{{ hadoop.alt_config }}/core-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/core-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/hdfs-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/masters:
  file.managed:
    - mode: 644
    - contents: {{ hdfs.namenode_host }}

{{ hadoop.alt_config }}/slaves:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts.exclude:
  file.managed

{% if hdfs.is_namenode %}

{%- if hdfs.namenode_count == 1 %}
format-namenode:
  cmd.run:
{%- if hadoop.major_version|string() == '1' %}
    - name: {{ hadoop.alt_home }}/bin/hadoop namenode -format -force
{%- else %}
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
{% endif %}
    - user: hdfs
    - unless: test -d {{ test_folder }}
{%- endif %}

{{ hadoop.initscript_targetdir }}/hadoop-namenode{{ hadoop.initscript_extension }}:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: namenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      systemd_group_env: {{ systemd_servicegroup_env }}
      systemd_service_env: '{{ hadoop.sysconfigdir }}/hadoop-namenode'
      systemd_cmd: '{{ hadoop.alt_home}}/bin/hdfs --config {{ hadoop.alt_config }} namenode'
{%- if hdfs.namenode_count == 1 %}
{{ hadoop.initscript_targetdir }}/hadoop-secondarynamenode{{ hadoop.initscript_extension }}:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: secondarynamenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      systemd_group_env: {{ systemd_servicegroup_env }}
      systemd_service_env: '{{ hadoop.sysconfigdir }}/hadoop-secondarynamenode'
      systemd_cmd: '{{ hadoop.alt_home}}/bin/hdfs --config {{ hadoop.alt_config }} secondarynamenode'
{%- else %}
{{ hadoop.initscript_targetdir }}/hadoop-zkfc{{ hadoop.initscript_extension }}:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: zkfc
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      systemd_group_env: {{ systemd_servicegroup_env }}
      systemd_service_env: '{{ hadoop.sysconfigdir }}/hadoop-zkfc'
      systemd_cmd: '{{ hadoop.alt_home}}/bin/hdfs --config {{ hadoop.alt_config }} zkfc'
{% endif %}
{% endif %}

{% if hdfs.is_datanode %}
{{ hadoop.initscript_targetdir }}/hadoop-datanode{{ hadoop.initscript_extension }}:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: datanode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      systemd_group_env: {{ systemd_servicegroup_env }}
      systemd_service_env: '{{ hadoop.sysconfigdir }}/hadoop-datanode'
      systemd_cmd: '{{ hadoop.alt_home}}/bin/hdfs --config {{ hadoop.alt_config }} datanode'
{% endif %}

{% if hdfs.is_journalnode %}
{{ hadoop.initscript_targetdir }}/hadoop-journalnode{{ hadoop.initscript_extension }}:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: journalnode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      systemd_group_env: {{ systemd_servicegroup_env }}
      systemd_service_env: '{{ hadoop.sysconfigdir }}/hadoop-journalnode'
      systemd_cmd: '{{ hadoop.alt_home}}/bin/hdfs --config {{ hadoop.alt_config }} journalnamenode'
{% endif %}

{% if hdfs.is_namenode and hdfs.namenode_count == 1 %}
hdfs-nn-services:
  service.running:
    - enable: True
    - names:
      - hadoop-secondarynamenode
      - hadoop-namenode
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}

{% if hdfs.is_datanode or hdfs.is_journalnode %}
hdfs-services:
  service.running:
    - enable: True
    - names:
{%- if hdfs.is_datanode %}
      - hadoop-datanode
{%- endif %}
{%- if hdfs.is_journalnode %}
      - hadoop-journalnode
{%- endif %}
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}
