# Cuneiform Plotting Library

This library visualizes Cuneiform history logs. These logs can be collected by connecting to a common runtime environment (CRE) via `localhost:4142/history.json`.

## Compiling the cfplot Command Line Tool

A binary can be created by entering

    raco make -j 8 *.rkt
    raco exe cfplot.rkt

The resulting file `cfplot` provides a command line interface to the plotting library. 