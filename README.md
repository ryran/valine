# valine
Easy qcow &amp; LVM snapshot management of libvirt guests with intelligent tab-completion

### What?

valine basically puts some of the most universally-useful features of virsh
into the hands of mere mortals like us. Starting, stopping, console-ing, and
completely deleting guests (along with all their storage) is of course
possible. On top of that, valine makes it ridiculously easy to create new
snapshots -- whether qcow or LVM -- and to revert/switch between snapshots.
It also provides a swanky visual overview of all of your guests and their
snapshots. All of this is tied together with automagic bash tab-completion.
For more details, see the extensive help page.

```
$ valine --help
Usage: valine
       valine DOMAIN
       valine DOMAIN new-snap [SNAP] [--off] [--size LVSIZE]
       valine DOMAIN revert-snap [SNAP] [--off]
       valine DOMAIN Delete-snap SNAP
       valine DOMAIN {start|Shutdown|Hard-reboot|hibernate|destroy|NUKE}
       valine DOMAIN {console|loop-ssh}
       valine DOMAIN Change-media [/path/to/iso]
       valine --all {new-snap|revert-snap|start|Shutdown|Hard-reboot|
                     hibernate|destroy}

Easy qcow & LVM snapshot mgmt of libvirt guests w/ intelligent tab-completion

With no subcommands:
 ┐
 │valine
 │  • Display summary of all domains & their storage (including snapshots)
 │
 │valine DOMAIN
 │  • Show virsh dominfo & domblklist along with snapshot details
 └──────────────────────────────────────────────────────────────────────────────

Snapshotting with valine:
 ┐
 │valine DOMAIN {n|new-snap} [SNAP] [--off] [--size LVSIZE]   (NO confirmation)
 │  • If provided, SNAP will be the name of the new snapshot
 │     • Otherwise, name will be auto-generated
 │  • Wait for DOMAIN to shut down
 │  • Determine storage type
 │  • If QCOW2 storage:
 │      • Create new embedded snapshot w/ virsh snapshot-create-as
 │        (Doing this more than once always leads to nested snapshots)
 │  • If LVM storage:
 │      • Check if current storage LV is thin-provisioned
 │          • If so, create a new thin LV snapshot from it (no size needed)
 │          • If not, size will be LVSIZE (default 2GiB) and
 │              • Check if current storage LV is a snapshot
 │                  • If so, create a new snapshot of its origin
 │                  • If not, create a new snapshot of it
 │      • Redfine DOMAIN xml to use the newly-created snapshot
 │      • Add new snapshot to cfgfile in /etc/valine/
 │  • If not --off:
 │      • Starts DOMAIN with new snapshot
 │
 │valine DOMAIN {r|revert-snap} [--off]                       (NO confirmation)
 │  • Wait for DOMAIN to be destroyed
 │  • If QCOW2 storage:
 │      • Revert current snapshot to original pristine state using
 │          virsh snapshot-revert DOMAIN --current
 │  • If LVM storage:
 │      • Remove current snapshot LV (lvremove) & recreate it from its origin
 │      • Update creation date/time of snapshot in cfgfile (/etc/valine/)
 │  • If not --off:
 │      • Starts DOMAIN with new snapshot
 │
 │valine DOMAIN {r|revert-snap} SNAP [--off]                  (NO confirmation)
 │  • If QCOW2 storage, SNAP should be an embedded snapshot name:
 │      • Wait for DOMAIN to be destroyed
 │      • Revert SNAP to original pristine state and set it as current, using
 │          virsh snapshot-revert DOMAIN SNAP
 │  • If LVM storage, SNAP should be the LV name [only] of an LVM logvol:
 │      • Prompt for whether to shut down or destroy DOMAIN
 │      • Find SNAP in /etc/valine/DOMAIN & confirm it's available with lvs
 │      • Edit 'source dev' definition in DOMAIN xml to point to SNAP, 
 │        whether it's a snapshot or a normal LVM logvol, using
 │            virsh dumpxml; sed; virsh undefine; virsh define
 │  • If not --off:
 │      • Starts DOMAIN with fresh snapshot or different LVM storage
 │
 │valine DOMAIN {D|Delete-snap} SNAP                         (YES confirmation)
 │  • If QCOW2 storage, SNAP should be an embedded snapshot name:
 │      • Check if SNAP is the current snapshot
 │          • If so, give warning deleting current SNAP is not recommended
 │      • Delete SNAP using: virsh snapshot-delete DOMAIN SNAP
 │  • If LVM storage, SNAP should be the LV name [only] of an LVM logvol:
 │      • Abort with warning if SNAP is the current storage
 │      • Remove current snapshot LV (lvremove) & remove it from cfgfile
 │
 │For more on managing snapshots with virsh:
 │    Virtualization Deployment & Administration Guide @ http://red.ht/1kwfbJs 
 └──────────────────────────────────────────────────────────────────────────────

Starting/stopping/saving/deleting domains with valine:
 ┐
 │valine DOMAIN {s|start}
 │
 │valine DOMAIN {S|Shutdown}
 │  • Attempt a graceful shutdown via acpi signaling
 │
 │valine DOMAIN {H|Hard-reboot}
 │  • Perform hard power reset (immediate reboot)
 │
 │valine DOMAIN {d|destroy}
 │  • Cut the power (immediate shutdown)
 │
 │valine DOMAIN {h|hibernate}
 │  • Save RAM to statefile via virsh managedsave DOMAIN
 │
 │valine DOMAIN {N|NUKE}
 │  • Completely removes a VM by executing:
 │      • virsh destroy DOMAIN
 │      • virsh undefine DOMAIN --snapshots-metadata --remove-all-storage \
 │                              --nvram --managed-save
 └──────────────────────────────────────────────────────────────────────────────

Accessing domains with valine:
 ┐
 │valine DOMAIN {c|console}
 │  • Open serial console
 │
 │valine DOMAIN {l|loop-ssh}
 │  • Keep trying to ssh to DOMAIN until success
 │    (Uses 'until ssh DOMAIN; do sleep 2; done' loop)
 │    This assumes DOMAIN is reachable via DNS or ssh-config
 └──────────────────────────────────────────────────────────────────────────────

Making changes to domains with valine:
 ┐
 │valine DOMAIN {C|Change-media} [/path/to/iso]
 │  • Insert new iso file (requires existing cdrom)
 │  • If no iso specified, eject existing
 └──────────────────────────────────────────────────────────────────────────────

Managing ALL domains at once with valine:
 ┐  
 │valine --all {n|new-snap} | {r|revert-snap} | {s|start} | {S|Shutdown} |
 │             {H|Hard-reboot} | {h|hibernate} | {d|destroy}
 │Replace DOMAIN with '--all' (or '-a') to operate on all detected domains in
 │parallel (jobs are backgrounded, verbose output is lessened, and cancelling
 │requires double Ctrl-c)
 │Note: Does not work with console or Delete-snap or NUKE commands
 │As above, the --off switch is optional with new-snap and revert-snap
 └──────────────────────────────────────────────────────────────────────────────
 
Version info: valine v0.7.1 last mod 2016/02/14
  See <http://github.com/ryran/valine> to report bugs or suggestions
```
