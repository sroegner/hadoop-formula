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

