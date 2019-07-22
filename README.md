# Linux in Unikernel Clothes (LUC)

In this project, we manually configure the Linux kernel so that it becomes
as small as 4+MB. We aim to show that it has the following unikernel properties
- no mode switching (by KML)
- specialization (by Kconfig)
- size (by evaluation)
- efficiency in terms of boot time and memory density (by evaluation)

## Contribution
- a combination of existing Linux configuration specialization and KML
  for a first-step Linux unikernel
- an evaluation of what unikernel properties are achieved
- a discussion of common unikernel tradeoffs (e.g., no smp, no fork)
  and their impact
- highlighting next steps for Linux specialization/ cross domain
  optimization

## Setup
Clone project:
`git clone https://github.ibm.com/hckuo-ibm/luc.git`

Update submodule:
`git submodule update --init`

## Files
scripts
├── firecrackerd.sh (wrapper firecracker daeomn)
├── firecracker-run.sh (wrapper of firecrakcer client)
├── image2rootfs.sh (create userspace image from docker image)
├── run-helper.sh (shared variables and helper functions)



## Takeaways:
- don't rewrite Linux unikernel people!
- know what unikernel benefits you really care about and what you give
  up to get them
- future work should be on app manifests LTO, etc.

## Going forward beyond unikernel restrictions
- smp vs. non-smp
  - smp gives speed benefits, esp when CPU bound
  - may cause size overhead (different config)?
- fork vs. non-fork
  - same as smp just may add context switches (show in microbenchmark)
- (how many applications use fork?)
- dynamic linking vs. static
- with KML unikernel properties "gracefully degrade"


