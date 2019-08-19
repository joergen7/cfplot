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

## History JSON format

Below is an example for a history file with one entry. The ellipses at the end of the history list represent the following entries. Each entry is an object with two fields: `app` and `delta`.

    {
      "history": [
        {
          "app": {
            "app_id": "042913bc99e7464b8ab377a36bbe17cda963445664cf5f3d1b70e74f",
            "arg_bind_lst": [
              {
                "arg_name": "idx",
                "value": "8d851bb_idx.tar"
              },
              {
                "arg_name": "fastq",
                "value": "558b7dd_SRR576938.sra.fastq"
              }
            ],
            "lambda": {
              "arg_type_lst": [
                {
                  "arg_name": "idx",
                  "arg_type": "File",
                  "is_list": false
                },
                {
                  "arg_name": "fastq",
                  "arg_type": "File",
                  "is_list": false
                }
              ],
              "lambda_name": "bowtie-align",
              "lang": "Bash",
              "ret_type_lst": [
                {
                  "arg_name": "bam",
                  "arg_type": "File",
                  "is_list": false
                }
              ],
              "script": "\n  bam=$fastq.bam\n  tar xf $idx\n  bowtie -S idx $fastq | samtools view -b - > $bam\n"
            }
          },
          "delta": {
            "app_id": "042913bc99e7464b8ab377a36bbe17cda963445664cf5f3d1b70e74f",
            "result": {
              "node": "cf_worker@default-ubuntu-1804",
              "ret_bind_lst": [
                {
                  "arg_name": "bam",
                  "value": "b70e74f_558b7dd_SRR576938.sra.fastq.bam"
                }
              ],
              "stat": {
                "run": {
                  "duration": "178156775904",
                  "t_start": "1545049650778968246"
                },
                "sched": {
                  "duration": "178197792686",
                  "t_start": "1545049650753821561"
                },
                "stage_in_lst": [
                  {
                    "duration": "13259112",
                    "filename": "8d851bb_idx.tar",
                    "size": "13373440",
                    "t_start": "1545049650755376933"
                  },
                  {
                    "duration": "9195502",
                    "filename": "558b7dd_SRR576938.sra.fastq",
                    "size": "1355957118",
                    "t_start": "1545049650769217200"
                  }
                ],
                "stage_out_lst": [
                  {
                    "duration": "10451127",
                    "filename": "b70e74f_558b7dd_SRR576938.sra.fastq.bam",
                    "size": "272845997",
                    "t_start": "1545049828936511802"
                  }
                ]
              },
              "status": "ok"
            }
          }
        },
        ...
      ]
    }

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

## System Requirements

- [Racket](https://www.racket-lang.org) 7.0 or higher

## Resources

- [cuneiform-lang.org](https://www.cuneiform-lang.org/). Official website of the Cuneiform programming language.

## Authors

- Jörgen Brandt ([@joergen7](https://github.com/joergen7/)) [joergen@cuneiform-lang.org](mailto:joergen@cuneiform-lang.org)

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)