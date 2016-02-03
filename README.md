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
       valine DOMAIN {start|shutdown|destroy|console|NUKE}
       valine --all {new-snap|revert-snap|start|shutdown|destroy}

Easy qcow & LVM snapshot mgmt of libvirt guests w/ intelligent tab-completion

With no arguments:
 ┐
 │valine by itself displays summary of all domains & their storage
 │valine DOMAIN with no other args shows details about a particular domain
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

Starting/stopping/accessing/deleting domains with valine:
 ┐
 │valine DOMAIN {s|start} | {h|shutdown} | {d|destroy} | {c|console} | {K|NUKE}
 │
 │start, shutdown, destroy, console commands are available as a convenience due
 │to virsh's lack of intelligent BASH tab-completion
 │The NUKE command is equivalent to running:
 │  virsh destroy DOMAIN
 │  virsh undefine --snapshots-metadata --remove-all-storage DOMAIN
 └──────────────────────────────────────────────────────────────────────────────

Managing ALL domains at once with valine:
 ┐  
 │valine --all [ {n|new-snap} | {r|revert-snap} | {s|start} |
 │               {h|shutdown} | {d|destroy} ]
 │
 │Replace DOMAIN with '--all' (or '-a') to operate on all detected domains in
 │parallel (jobs are backgrounded, verbose output is lessened, and cancelling
 │requires double Ctrl-c)
 │Note: Does not work with console or Delete-snap or NUKE commands
 │As above, the --off switch is optional with new-snap and revert-snap
 └──────────────────────────────────────────────────────────────────────────────
 
Version info: valine v0.6.3 last mod 2016/02/03
  See <http://github.com/ryran/valine> to report bugs or suggestions
```
