# Exercise 01 — Hello World

**Time:** ~5 minutes
**Goal:** Run your first Nextflow pipeline and understand processes, channels, and the workflow block.

## Run it

```bash
cd exercises/01_hello_world
nextflow run hello_world.nf
```

## What you should see

```
N E X T F L O W  ~  version 24.04.2
Launching `hello_world.nf` [some_name] DSL2 - revision: ...
executor >  local (5)
[xx/yyyyyy] process > SHOUT (5) [100%] 5 of 5 ✔
Wrote: shouted_Hello.txt
Wrote: shouted_Hej.txt
Wrote: shouted_Ciao.txt
Wrote: shouted_Bonjour.txt
Wrote: shouted_Hola.txt
```

The order may be different each time — that's parallelism at work.

## Try this

1. Run again. Notice the `[cached]` markers — Nextflow remembers what it already did.
2. Look inside `results/` — five `.txt` files with uppercase greetings.
3. Override the greetings:
   ```bash
   nextflow run hello_world.nf --greetings '["Tjenare","Hejsan","Tjabba"]'
   ```
4. Look at `work/` — every run is sandboxed in its own subdirectory.

## What you learned

- A **process** is a unit of work; a **channel** is the data flow between processes
- `publishDir` exports results out of the temporary `work/` directory
- Nextflow caches every step — re-runs are fast unless inputs change
- `nextflow.enable.dsl = 2` enables the modern syntax (always use this)
