{%- set p  = salt['pillar.get']('hdfs', {}) %}
{%- set pc = p.get('config', {}) %}
{%- set g  = salt['grains.get']('hdfs', {}) %}
{%- set gc = g.get('config', {}) %}

# TODO: https://github.com/accumulo/hadoop-formula/issues/1 'Replace direct mine.get calls'
{%- set namenode_target     = g.get('namenode_target', p.get('namenode_target', 'roles:hadoop_master')) %}
{%- set datanode_target     = g.get('datanode_target', p.get('datanode_target', 'roles:hadoop_slave')) %}
{%- set journalnode_target  = g.get('journalnode_target', p.get('journalnode_target', 'roles:hdfs_journalnode')) %}
# this is a deliberate duplication as to not re-import hadoop/settings multiple times
{%- set targeting_method    = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}

# HA requires that you have exactly two NNs
{%- set namenode_host       = salt['mine.get'](namenode_target, 'network.interfaces', expr_form=targeting_method)|first %}
{%- set namenode_hosts      = salt['mine.get'](namenode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set namenode_count      = namenode_hosts|count() %}

# fix the case where someone targets 2+ nodes to be namenodes
{%- if namenode_count > 2 %}
{%- set namenode_hosts = [namenode_hosts|first, namenode_hosts|last]%}
{%- set namenode_count = namenode_hosts|count() %}
{%- elif namenode_count == 1 %}
{%- set namenode_hosts = {} %}
{%- endif %}

{%- set datanode_hosts        = salt['mine.get'](datanode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set journalnode_hosts     = salt['mine.get'](journalnode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set datanode_count        = datanode_hosts|count() %}
{%- set journalnode_count     = journalnode_hosts|count() %}
{%- set namenode_port         = gc.get('namenode_port', pc.get('namenode_port', '8020')) %}
{%- set namenode_http_port    = gc.get('namenode_http_port', pc.get('namenode_http_port', '50070')) %}
{%- set secondarynamenode_http_port  = gc.get('secondarynamenode_http_port', pc.get('secondarynamenode_http_port', '50090')) %}
{%- set local_disks           = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{%- set hdfs_repl_override    = gc.get('replication', pc.get('replication', 'x')) %}
{%- set load                  = salt['grains.get']('hdfs_load', salt['pillar.get']('hdfs_load', {})) %}
{%- set ha_cluster_id         = salt['grains.get']('ha_cluster_id', salt['pillar.get']('ha_cluster_id', 'hdfs_ha_cluster')) %}
{%- set ha_namenode_port      = gc.get('ha_namenode_port', pc.get('ha_namenode_port', namenode_port)) %}
{%- set ha_journal_port       = gc.get('ha_journal_port', pc.get('ha_journal_port', '8485')) %}
{%- set ha_namenode_http_port = gc.get('ha_namenode_http_port', pc.get('ha_namenode_http_port', namenode_http_port)) %}

{%- if journalnode_count > 0 %}
{%- set quorum_connection_string = "" %}
{%- set connection_string_list = [] %}
{%- for n in journalnode_hosts %}
{%- do connection_string_list.append( n + ':' + ha_journal_port | string() ) %}
{%- endfor %}
{%- set quorum_connection_string = connection_string_list | join(",")%}
{%- else %}
{%- set quorum_connection_string = "" %}
{%- endif %}
# Todo: this might be a candidate for pillars/grains
# {%- set tmp_root        = local_disks|first() %}
{%- set tmp_dir         = '/tmp' %}

{%- if hdfs_repl_override == 'x' %}
{%- if datanode_count >= 3 %}
{%- set replicas = '3' %}
{%- elif datanode_count == 2 %}
{%- set replicas = '2' %}
{%- else %}
{%- set replicas = '1' %}
{%- endif %}
{%- endif %}

{%- if hdfs_repl_override != 'x' %}
{%- set replicas = hdfs_repl_override %}
{%- endif %}

{%- set config_hdfs_site = gc.get('hdfs-site', pc.get('hdfs-site', {})) %}

{%- set is_namenode    = salt['match.' ~ targeting_method](namenode_target) %}
{%- set is_journalnode = salt['match.' ~ targeting_method](journalnode_target) %}
{%- set is_datanode    = salt['match.' ~ targeting_method](datanode_target) %}
{%- set hdfs = {} %}
{%- do hdfs.update({ 'local_disks'                 : local_disks,
                     'namenode_host'               : namenode_host,
                     'namenode_hosts'              : namenode_hosts,
                     'namenode_count'              : namenode_count,
                     'datanode_hosts'              : datanode_hosts,
                     'journalnode_hosts'           : journalnode_hosts,
                     'namenode_port'               : namenode_port,
                     'ha_namenode_port'            : ha_namenode_port,
                     'namenode_http_port'          : namenode_http_port,
                     'ha_namenode_http_port'       : ha_namenode_http_port,
                     'is_namenode'                 : is_namenode,
                     'is_journalnode'              : is_journalnode,
                     'is_datanode'                 : is_datanode,
                     'secondarynamenode_http_port' : secondarynamenode_http_port,
                     'replicas'                    : replicas,
                     'datanode_count'              : datanode_count,
                     'journalnode_count'           : journalnode_count,
                     'config_hdfs_site'            : config_hdfs_site,
                     'tmp_dir'                     : tmp_dir,
                     'load'                        : load,
                     'ha_cluster_id'               : ha_cluster_id,
                     'quorum_connection_string'    : quorum_connection_string,
                   }) %}
