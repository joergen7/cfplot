# Cuneiform Plotting Library

This library visualizes Cuneiform history logs. These logs can be collected by connecting to a common runtime environment (CRE) via `localhost:4142/history.json`.

## Usage

### Building the cfplot Command Line Tool

A binary can be created by entering

    raco make -j 8 *.rkt
    raco exe cfplot.rkt

The resulting file `cfplot` provides a command line interface to the plotting library.

### Using cfplot

    cfplot my-history-file.json

## Graph Types

### Dependency Graph

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-dep](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-dep.png)

*Complete variant call dependency graph*

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-dep-detail](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-dep-detail.png)

*Detail of the variant call dependency graph*

### Worker Allocation Graph

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-lipka](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-lipka.png)

### Staging Bandwidth over Time Scatter Plot

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-bandwidth-scatter](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-bandwidth-scatter.png)

### Staging Bandwidth Density

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-bandwidth-density](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-bandwidth-density.png)

### Stage-in Bandwidth Density per Compute Node

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-stage-in-bandwidth-density-node](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-stage-in-bandwidth-density-node.png)

### Stage-out Bandwidth Density per Compute Node

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-stage-out-bandwidth-density-node](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-stage-out-bandwidth-density-node.png)

### Processing Throughput Scatter Plot

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-scatter](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-scatter.png)

### Processing Throughput Density

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-density](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-density.png)

### Processing Throughput Density per Compute Node

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-density-node](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-throughput-density-node.png)

### Processing Selectivity Scatter Plot

![2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-selectivity](img/2019-01-17-variant-call-varscan-gruenau-4x120-2x32-2x16-gluster4-selectivity.png)

