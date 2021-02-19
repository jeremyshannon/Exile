Changelog
=========

The semantic of version number is 'Major.minor'. Minor updates are retro-compatible, while major updates may break things.


[1.1] - 2021-02-07
------------------

### Added
- `set_manual_map_generation`.
- `get_slope_defs`.
- Chance factors for different kind of updates.
- Changelog.

### Changed
- Slope update is done last on map generation.
- `is_free*` returns nil when a neighbour node is not available.
- `is_free_for_erosion` is now deprecated, use `is_free_for_shape_update` instead.
- Edges of areas are updated progressively instead of not at all.


[1.0] - 2020-12-30
------------------

Requires Minetest 5.

### Added
- `get_regular_node_name` from a slope name.
- Ceiling slopes.
- Family group for all slopes.
- `get_all_shapes`.
- Progressive map generation method.
- `register_sloped_stomp`.
- Extensive API documentation.

### Removed
- Slope nodes for Minetest Game.

### Changed
- `get_slope_names` return each name indexed by type.
- Namespace change from `naturalslopes` to `naturalslopeslib`.
- Timed update uses `twmlib`.
- Registration is shortened by passing changes from the original definition instead of a full copy.
- Use underscore for domain name in settingstype for consistency with other mods.


[0.9] - 2017-08-30
------------------

### Added
- Backface culling for slope nodes.
- Slope node names are returned upon registration.
- `get_slope_names`.

### Changed
- `default:dirt*` are more likely to be updated.
- `natural_slope` group now indicates the type of slope.

### Fixed
- Registering slopes outside the mod.


[0.8] - 2017-08-25
------------------

### Added
- Reintroduced the smooth rendering, not enabled by default.

### Changed
- Pick a random surface node instead of an area for timed update.


[0.7] - 2017-08-15
------------------

### Added
- `skip` parameter for update_shape.
- `default:clay` and `default:snowblock` slopes.

### Removed
- Smooth rendering.

### Changed
- Updated the description of the mod.
- The ABM transformation is replaced by a random area selection from time to time.

### Fixed
- Some textures for `default` slopes.


[0.6] - 2017-08-12
------------------

### Added
- Pike shape for isolated nodes.

### Changed
- An update is forced when a node is placed above an other one.

### Fixed
- Prevent slopes to propagate with grass for `default`.


[0.5] - 2017-08-09
------------------

### Changed
- Update slope definitions for `default` to drop the full node when slopes are dug.

### Fixed
- Light for slope nodes.
- Updating a slope to an other one.


[0.4] - 2017-08-06
------------------

### Added
- Setting to enable or disable update on map generation.

### Changed
- Nodes on the edge of an area are not updated instead of being updated incorrectly

### Fixed
- Enabling slopes for `default` setting.
- Node definition being shared between slope, erasing some distinctions.


[0.3] - 2017-08-05
------------------

### Added
- Update chance argument for `register_slopes`.
- `register_slopes` uses a node definition instead of a list of definition parameters.
- Slopes for `default:dirt_with_snow`, `default:dirt_with_dry_grass`, `default:dirt_with_rainforest_litter`
- `get_replacement` and `get_replacement_id`
- Update shape on map generation.

### Changed
- `default` is now an optional dependency.
- Full grass texture for slopes.

### Fixed
- Walk advanced settings, chat command.


[0.2] - 2017-07-25
------------------

### Added
- Nodes return to their full block shape whene something is above.
- Cubic shape rendering from `stairs`.
- Update shape on walk with `poschangelib v0.1`.

### Changed
- Use settingstype for options.


[0.1] - 2017-07-21
------------------

Initial release.
