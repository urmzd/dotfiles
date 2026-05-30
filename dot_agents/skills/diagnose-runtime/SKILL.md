---
name: diagnose-runtime
description: >
  Triage LOCAL runtime failures on your own machine: crashes and errors, hangs and
  deadlocks, slowness and high CPU/memory, and hardware/serial/USB issues. Method:
  reproduce, isolate (bisect, log, strace/dtruss, sample), form a hypothesis,
  verify the fix holds. Read-mostly: it inspects processes and logs, it does not
  commit, push, or edit source. Use when the user asks "why does this error", "why
  does the system hang after generating the PDF", "why is the computer running
  hot", "why is image loading slow", or "this process is stuck". Do NOT use for
  CI/pipeline failures (use diagnose-ci) or for applying and re-shipping a fix (use
  fix-and-retry) -- this skill investigates and recommends only.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(ps *), Bash(lsof *)
user-invocable: true
arguments:
  - name: symptom
    description: Optional short description of the symptom (error text, "hang", "slow", "hot", "device not found"). If omitted, ask the user to reproduce.
    required: false
metadata:
  title: Diagnose Runtime
  category: development
  order: 0
---

# Diagnose Runtime

Triage a local runtime problem on this machine. The remote counterpart for red
pipelines is [[diagnose-ci]]; once the cause is known and you want to apply and
re-ship the fix, hand off to [[fix-and-retry]]. This skill stops at a verified
diagnosis and a recommended fix.

## Method

Work the loop in order. Skipping reproduction is the most common way a "fix"
fails to hold.

1. **Reproduce.** Get a deterministic trigger before changing anything. Capture
   the exact command, inputs, and environment. If it is intermittent, note the
   frequency (1-in-N) and any correlation (load, time, specific input file). An
   unreproducible bug cannot be verified fixed.
2. **Isolate.** Shrink the surface until the failing component is unambiguous:
   bisect inputs (halve the data, the config, the call graph), bisect history
   (`git bisect`), and attach an observer (logs, a tracer, a sampler). Change one
   variable at a time.
3. **Hypothesize.** State the suspected cause as a falsifiable sentence: "the
   process blocks on a fsync to a full disk", not "I/O is slow". A hypothesis you
   cannot test is a guess.
4. **Verify.** Apply the smallest change that should fix the hypothesized cause,
   then re-run the reproduction. The bug must disappear when the change is in and
   return when it is reverted. If it does not, the hypothesis was wrong: go back
   to step 2 with what you learned.

## Pick the tool by symptom

| Symptom | First reach for | What it tells you |
| --- | --- | --- |
| Crash / error / panic | the error text + `Console.app` (or `log show --last 10m`) | the actual exception, signal, and stack |
| Hang / deadlock / spinner | `sample <pid> 5` then `spindump` | where every thread is stuck right now |
| High CPU / running hot | `ps -Ao pid,pcpu,comm -r \| head -20` then Activity Monitor (Energy/CPU tab) | which process is burning cycles |
| High memory / swap | `ps -Ao pid,rss,comm -m \| head -20`, Activity Monitor (Memory tab) | the leaker; watch RSS climb over time |
| Slow operation | `sample` during the slow window, or `time <cmd>` | CPU-bound vs blocked-on-I/O |
| Stuck on a file / port | `lsof -p <pid>`, `lsof <path>`, `lsof -i :<port>` | open handles, who holds the lock/port |
| Disk / "no space" | `df -h`, `du -sh *` | full volume or inode exhaustion |
| Serial / USB / device | `ls /dev/tty.* /dev/cu.*`, `ioreg -p IOUSB`, `system_profiler SPUSBDataType` | whether the OS even sees the device |
| Syscall-level mystery | `sudo dtruss -p <pid>` (macOS) / `strace -p <pid>` (Linux) | every syscall and where it blocks |

## Gotchas

- **`sample <pid> 5` over `spindump` first.** `sample` runs without sudo, profiles
  one process for N seconds, and prints the hot call stack -- usually enough to
  see a busy-wait or a blocking call. Reach for `spindump` (needs sudo) when the
  whole system stalls or you need every process's state, including the kernel.
- **macOS has no `strace`.** Use `sudo dtruss -p <pid>` or `dtruss -f <cmd>`. It
  needs sudo and, for some targets, SIP relaxed. On Linux, `strace -f -p <pid>`.
  `dtrace`/`dtruss` will silently produce nothing if the process is sandboxed.
- **"Running hot" is usually one runaway process, not the hardware.** Sort by CPU
  (`ps -Ao pid,pcpu,comm -r`) before blaming the fan or thermal paste. A
  `WindowServer`, `mds`/`mdworker` (Spotlight indexing), or `kernel_task` (thermal
  throttling) at the top each point to a different root cause. `kernel_task` high
  often means the OS is throttling to cool down, not that it is the culprit.
- **A hang "after generating the PDF" is usually a not-yet-closed resource.** A
  child process that never exits, a pipe whose reader is gone, an unflushed/never
  closed file handle, or a `wait()` on a process that already died. `lsof -p <pid>`
  shows the dangling handles; `sample` shows the thread parked in `read`/`wait`.
  Check for a subprocess (e.g. a renderer) the parent is blocking on.
- **Slow image loading: separate decode from I/O from network.** `sample` during
  the load: a stack deep in image-decode is CPU-bound (wrong format/size, no
  thumbnail cache); a stack in `read`/`recv` is I/O- or network-bound (cold disk,
  remote fetch, no caching). Do not optimize the decoder if the time is in the
  socket.
- **Intermittent under load points at a resource limit, not logic.** File
  descriptors (`ulimit -n`, `lsof -p <pid> \| wc -l`), thread/connection pools, or
  memory pressure. The code is correct; it is starved.
- **Verify against the reproduction, not against vibes.** "It seems faster" is not
  a fix. Re-run the captured trigger with and without the change and compare the
  same measurement.

## Report

Present a concise summary:

```text
## Runtime issue: <one-line symptom>
- Reproduction: <exact trigger>
- Isolated to: <component / file / process>
- Root cause: <falsifiable explanation>
- Evidence: <the sample/lsof/log line that proves it>
- Fix: <smallest change>, verified by <re-running the trigger>
```

If the fix involves a code change you want applied, committed, and re-tested in
one shot, hand off to [[fix-and-retry]] (CI) or apply locally and re-run the
reproduction. For suspicious processes, unknown listeners, or possible
compromise rather than a performance/correctness bug, route to [[audit-security]].
