# i3fyra - An advanced, simple grid-based tiling layout 

### usage

```text
i3fyra --show|-s CONTAINER [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --float|-a [--array ARRAY] [--verbose] [--dryrun]
i3fyra --hide|-z CONTAINER [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --layout|-l LAYOUT [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --move|-m DIRECTION|CONTAINER [--force|-f] [--speed|-p INT] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --help|-h
i3fyra --version|-v
```

The layout consists of four containers:  

``` text
  A B
  C D
```


A container can contain one or more windows. The internal
layout of the containers doesn't matter. By default the
layout of each container is tabbed.  

A is always to the left of B and D. And always above C. B
is always to the right of A and C. And always above D.  

This means that the containers will change names if their
position changes.  

The size of the containers are defined by the three splits:
AB, AC and BD.  

Container A and C belong to one family.  
Container B and D belong to one family.  

The visibility of containers and families can be toggled.
Not visible containers are placed on the scratchpad.  

The visibility is toggled by either using *show* (`-s`) or
*hide* (`-z`). But more often by moving a container in an
*impossible* direction, (*see examples below*).  

The **i3fyra** layout is only active on one workspace. That
workspace can be set with the environment variable:
`i3FYRA_WS`, otherwise the workspace active when the layout
is created will be used.  

The benefit of using this layout is that the placement of
windows is more predictable and easier to control.
Especially when using tabbed containers, which are very
clunky to use with *default i3*.


OPTIONS
-------

`--show`|`-s` CONTAINER  
Show target container. If it doesn't exist, it will be
created and current window will be put in it. If it is
visible, nothing happens.

`--force`|`-f`  
If set virtual positions will be ignored.

`--array` ARRAY  
ARRAY should be the output of `i3list`. It is used to
improve speed when **i3fyra** is executed from a script that
already have the array, f.i. **i3run** and **i3Kornhe**.  

`--verbose`  
If set information about execution will be printed to
**stderr**.

`--dryrun`  
If set no window manipulation will be done during
execution.

`--float`|`-a`  
Autolayout. If current window is tiled: floating enabled If
window is floating, it will be put in a visible container.
If there is no visible containers. The window will be placed
in a hidden container. If no containers exist, container
'A'will be created and the window will be put there.

`--hide`|`-z` CONTAINER  
Hide target containers if visible.  

`--layout`|`-l` LAYOUT  
alter splits Changes the given splits. INT is a distance in
pixels. AB is on X axis from the left side if INT is
positive, from the right side if it is negative. AC and BD
is on Y axis from the top if INT is positive, from the
bottom if it is negative. The whole argument needs to be
quoted. Example:  
`$ i3fyra --layout 'AB=-300 BD=420'`  


`--move`|`-m` CONTAINER  
Moves current window to target container, either defined by
it's name or it's position relative to the current container
with a direction:
[`l`|`left`][`r`|`right`][`u`|`up`][`d`|`down`] If the
container doesnt exist it is created. If argument is a
direction and there is no container in that direction,
Connected container(s) visibility is toggled. If current
window is floating or not inside ABCD, normal movement is
performed. Distance for moving floating windows with this
action can be defined with the `--speed` option. Example: `$
i3fyra --speed 30 -m r` Will move current window 30 pixels
to the right, if it is floating.

`--speed`|`-p` INT  
Distance in pixels to move a floating window. Defaults to
30.

`--help`|`-h`  
Show help and exit.

`--version`|`-v`  
Show version and exit

EXAMPLES
--------
If containers **A**,**B** and **C** are visible but **D**
is hidden or none existent, the visible layout would looks
like this:  

``` text
  A B
  C B
```


If action: *move up* (`-m u`) would be called when
container **B** is active and **D** is hidden. Container
**D** would be shown. If action would have been: *move down*
(`-m d`), **D** would be shown but **B** would be placed
below **D**, this means that the containers will also swap
names. If action would have been *move left* (`-m l`) the
active window in B would be moved to container **A**. If
action was *move right* (`-m r`) **A** and **C** would be
hidden:  

``` text
  B B
  B B
```


If we now *move left* (`-m l`), **A** and **C** would be
shown again but to the right of **B**, the containers would
also change names, so **B** becomes **A**, **A** becomes
**B** and **C** becomes **D**:  

``` text
  A B
  A D
```


If this doesn't make sense, check out this demonstration on youtube: https://youtu.be/kU8gb6WLFk8
## updates

### 2020.08.08

Now keeps track of the *virtual position* of a window. What
this means is that if you have the following window rule
defined in your **i3 config file**:  

```
for_window [instance=irssi class=URxvt] focus;exec --no-startup-id i3fyra --move A
```


And spawn a window matching the criteria it will get
*moved* to the A container, which by default is the top-left
container.  

```
AAB
AAD
CCD
```


Just as before the containers can be toggled and swapped by
using `i3fyra --move DIRECTION` (where direction is
up,down,left or right). And if the A container would have
focus, and we execute `--move left` it would hide the B and
D containers:

```
AAA
AAA
CCC
```


If we in this state would execute `--move right` (while the
A container is focused), it would move the A and C container
to the right and show the B and D containers to the left,
but i3fyra will also internally rename all the containers:  

```
ABB
ABB
CDD
```


This used to mean that if we now would spawn a window
matching our previously defined window rule, it would still
get placed in the top-left container. This is where things
are different now. In **i3list** there are four new keys,
`[VPA],[VPB],[VPC] and [VPD]` which contains a number
between zero and three (0-3). If i3list would get executed
with the scenario above we would get the following results:  

```
i3list[VPA]=1
i3list[VPB]=0
i3list[VPC]=3
i3list[VPD]=2
```


the integers corresponds to the index of the hypothetical
array `a=([0]=A [1]=B [2]=C [3]=D)`, and with this
information we can see that when we want to send a window to
container A, we test the virtual position, and see that A is
positioned at 1 (*B*), be placed in **B** instead. In most
cases this is the desired result, but sometimes it isn't,
and for those cases one can use the `--force` option (which
is new) to ignore the virtual positions. But this is
probably nothing that anyone needs to worry about, and is
more or less only used internally in **i3fyra**, **i3menu**
and **i3run**. This transformation to virtual positions of
the containers also works with the `--layout` option.

A lot of performance and stability improvements has been
done in this update, and toggling layouts and containers now
works much better and predictable.  

**Removed**  `--target` option. I found myself never using
and it just created awkward cornercase issues.  

**Added** `--force`, `--array`, `--verbose` and `--dryrun`
options.




