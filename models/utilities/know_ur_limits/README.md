# shapes/models/utilities/know_ur_limits


#### Images

![know_ur_limits_210](./know_ur_limits_210.png)

#### Files

* [know_ur_limits_210.jas](./know_ur_limits_210.jas)
  * The original Cheetah3D file.  Use this (with Cheetah3D) to make modifications.
* [know_ur_limits_210.usdz](./know_ur_limits_210.usdz)
* [know_ur_limits_210.stl](./know_ur_limits_210.stl)

#### About

An FDM-printable model designed to find the "limit of printability" for a given printing setup.  "Setup" includes things like printer model, filament, layer height, etc..
This visits overhang angle and bridge length, permuted with a few widths.

The photo was taken of a Bambu P1S, and even the most extreme of the tests passed.  No country for old men !

#### Printing

Units: mm  

I do not know how to construct a 3d model file so that multiple materials are respected by Bambu Studio. So if you want the cute multiple colors, you'll need to split it into multiple parts in your slicing software and then identify the one that's the base and assign it a different filament than default.