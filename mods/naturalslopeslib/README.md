Natural slopes library
======================

* Version 1.1
* Licence LGPLv2 or, at your discretion, any later version.
* With thanks to all modders, mainly from the stairs mod for study.
* Models licensed under CC-0.

## Dependencies

None, this is a standalone library for other mods to build upon. It doesn't
have any effect by itself.

## Optional dependencies:

* poschangelib: to enable shape update when walking on nodes
* twmlib: to enable update from time to time

This mod add the ability for nodes to turn into slopes and back to full block
shape by themselves according to the surroundings and the material hardness. It creates
more natural looking landscapes and smoothes movements by removing some edges.

Slopes can be generated in various ways. Those events can be turned on or off in
settings. The shape is updated on generation, with time, by stepping on edges or
when digging and placing nodes.

As Minetest main unit is the block, having half-sized blocks can break a lot of things.
Thus half-blocks like slopes are still considered as a single block. A single slope
can turn back to a full node and vice-versa and half-blocks are not considered
buildable upon (they will transform back into full block).


How to define new slopes
------------------------

Call naturalslopeslib.register_slope to declare new slope nodes. This will also
automatically bind shape update events on the original node and the newly
created slopes. And that's it.

### naturalslopeslib.register_slope(base_node_name, def_changes, update_chance)

- base_node_name: the name of the original node
- def_changes: the node definition for the slopes is copied from the original.
    Properties that are set there are overwritten for slopes.
- update_chance: inverted chance to the node to update it's shape when an update event
    occurs on it.


How to register only the behaviour
----------------------------------

If all the slope nodes are already registered nodes, you must use an other
function to link them.

### naturalslopeslib.set_slopes(base_node_name, straight_name, inner_name, outer_name, pike_name)

- base_node_name: The full node name
- straight_name: The straight slope node name
- inner_name: The inner corner node name
- outer_name: The outer corner node name
- pike_name: The pike node name

See naturalslopeslib_api.txt for more details and other functions.
