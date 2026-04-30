# Workshop Test Data

## What's here

`samplesheet.csv` — sample metadata used by the exercises.

The `.fastq.gz` data files are **not stored in this repository** due to their size. Download them before the workshop using the instructions below.

## Downloading the data (do this before class)

Run the following command from inside the `exercises/data/` directory. Replace `cid` with your Chalmers CID.

```bash
scp -r cid@remote12.chalmers.se:~/My_Areas/Linux/bioresourcelabs/Bioinformatics_course/Data_for_nextflow_tutorial/*.fastq.gz .
```

You will be prompted for your Chalmers password. Once complete, the `data/` folder should contain six `.fastq.gz` files (three samples, paired-end).
