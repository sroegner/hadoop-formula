========================
hadoop high availability
========================

Description of additional steps for provisioning highly available services.

Preface:
========

Please consider this feature experimental, in particular do not attempt to use it in any kind of production
environment. Also note that at this point there is no (and probably never will be) support for migration
from singlenode into HA mode.

This extension can be mainly be useful in quickly setting up a functioning Hadoop HA environment for testing purposes.

New states:
===========

.. contents::
    :local:

``hadoop``
----------

Downloads the hadoop tarball from the hadoop:source_url, installs the package, creates the hadoop group for all other components to share.

``hadoop.hdfs.ha_namenode``
---------------

::

    roles:
      - hadoop_slave

Additional Formula Dependencies:
================================

* ``zookeeper``

Salt Minion Configuration
=========================

As mentioned above, all installation and configuration is assinged via roles.
Mounted disks (or just directories) can be configured for use with hdfs and mapreduce via grains.

Example ``/etc/salt/grains`` for the "primary" namenode:

::

    hdfs_data_disks:
      - /data1
      - /data2
      - /data3
      - /data4

    roles:
      - hadoop_master
      - hdfs_namenode1

Example ``/etc/salt/grains`` for the "secondary" namenode:

::

    hdfs_data_disks:
      - /data1
      - /data2
      - /data3
      - /data4

    roles:
      - hadoop_master
      - hdfs_namenode2

Example ``/etc/salt/grains`` for a journalnode:

::

    hdfs_data_disks:
      - /data1

    roles:
      - hdfs_journalnode

Orchestration Example:
======================

Since this feature is more complex than the already distributed Hadoop architecture normally is, here is a short listing of service components and their place in the order of setup - as should be mandated by a salt orchestration script.

# Prerequisites as usual (name resolution, NTP, JDK installation)
# Install Hadoop binaries and configuration on all targeted Hadoop cluster members
# Install Zookeeper binaries and configuration on all targeted Zookeeper cluster members
# Start all service members of the Zookeeper cluster
# Start all HDFS datanodes
# Start all HDFS journalnodes
# On the designated "first" namenode (to become the active member):
  # Initialize HDFS namenode metadata as usual (hdfs namenode -format)
  # Initialize Zookeeper for namenode HA (hdfs zkfc -formatZK)
  # Start namenode service as usual (service hadoop-namenode start)
  # Start the zookeeper fencing service (service hadoop-zkfc start)
# On the designated "second" namenode (to become the standby member):
  # Prepare HDFS namenode metadata (hdfs namenode -prepareStandby)
  # Start namenode service as usual (service hadoop-namenode start)
  # Start the zookeeper fencing service (service hadoop-zkfc start)

Below is an example orchestration script to illustrate what the listed actions might look like in Salt

::

    prep:
      salt.state:
        - tgt: '*'
        - sls:
          - hostsfile
          - hostsfile.hostname
          - ntp.server

    hnode_prep:
      salt.state:
        - tgt: 'G@roles:hadoop_master or G@roles:hadoop_slave or G@roles:zookeeper'
        - tgt_type: compound
        - require:
          - salt: prep
        - sls:
          - sun-java
          - sun-java.env

    zookeeper_service:
      salt.state:
        - tgt: 'G@roles:zookeeper'
        - tgt_type: compound
        - require:
            - salt: hnode_prep
        - sls:
            - zookeeper
            - zookeeper.server

    hadoop_hdfs:
      salt.state:
        - tgt: 'G@roles:hadoop_master or G@roles:hadoop_slave'
        - tgt_type: compound
        - require:
          - salt: zookeeper_service
        - sls:
          - hadoop
          - hadoop.hdfs

    hadoop_hdfs_ha_init:
      salt.state:
        - tgt: 'G@roles:hdfs_namenode1'
        - tgt_type: compound
        - require:
          - salt: hadoop_hdfs
        - sls:
          - hadoop.hdfs.ha_namenode

    hadoop_hdfs_ha_bootstrap_secondary:
      salt.state:
        - tgt: 'G@roles:hdfs_namenode2'
        - tgt_type: compound
        - require:
          - salt: hadoop_hdfs_ha_init
        - sls:
          - hadoop.hdfs.ha_namenode
