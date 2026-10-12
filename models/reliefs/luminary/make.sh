#!/bin/zsh
set -euo pipefail

NAME="luminary"
IMAGE_VERSION=120
CONFIG_VERSION="02"

BASE=1.5            # mm
RISE=2.5            # mm
SIZE_SQUARE=75      # mm
SIZE_WIDE=115       # mm

IMAGE_HEIGHT=700    # pixels
BLUR_RADIUS=1.2     # pixels

# left and right images are 1000x1000
# front, top, and back are 1527x1000

# frame generation. All values in mm.
FRAME_ABOVE_RELIEF=2
FRAME_LATERAL_THICKNESS=4
FRAME_LATERAL_PADDING=3
FRAME_WIDTH=$SIZE_WIDE
FRAME_DEPTH=$SIZE_SQUARE
FRAME_RELIEF_PEAK=$(( BASE + RISE ))
FRAME_BASE_Z=$BASE

FRAME_LATERAL_TOTALPAD=$(( (FRAME_LATERAL_PADDING + FRAME_LATERAL_THICKNESS) * 2 ))
FRAME_OUTER_HEIGHT=$((FRAME_RELIEF_PEAK + FRAME_ABOVE_RELIEF))
FRAME_OUTER_WIDTH=$((FRAME_WIDTH + FRAME_LATERAL_TOTALPAD ))
FRAME_OUTER_DEPTH=$((FRAME_DEPTH + FRAME_LATERAL_TOTALPAD ))
FRAME_CAVITY_HEIGHT=$FRAME_OUTER_HEIGHT
FRAME_CAVITY_WIDTH=$((FRAME_OUTER_WIDTH - FRAME_LATERAL_THICKNESS * 2))
FRAME_CAVITY_DEPTH=$((FRAME_OUTER_DEPTH - FRAME_LATERAL_THICKNESS * 2))
FRAME_CAVITY_OFFSET_Z=$((FRAME_BASE_Z))
FRAME_OUTER_OFFSET_Z=$((FRAME_OUTER_HEIGHT / 2))

echo $FRAME_ABOVE_RELIEF
echo $FRAME_OUTER_HEIGHT
echo $FRAME_OUTER_WIDTH
echo $FRAME_OUTER_DEPTH
echo $FRAME_CAVITY_HEIGHT
echo $FRAME_CAVITY_WIDTH
echo $FRAME_CAVITY_DEPTH
echo $FRAME_OUTER_OFFSET_Z

STL_PREFIX="_"
STL_CUBE="${STL_PREFIX}cube.stl"
STL_FRAME_OUTER="${STL_PREFIX}frame_outer.stl"
STL_FRAME_CAVITY="${STL_PREFIX}frame_cavity.stl"
STL_FRAME_1="${STL_PREFIX}frame_1.stl"
STL_FRAME="${STL_PREFIX}frame.stl"

stl_cube       -w 1 "${STL_CUBE}"

stl_transform                  \
    -sx $FRAME_OUTER_WIDTH     \
    -sy $FRAME_OUTER_DEPTH     \
    -sz $FRAME_OUTER_HEIGHT    \
    "${STL_CUBE}" "${STL_FRAME_OUTER}"

stl_transform                  \
    -sx $FRAME_CAVITY_WIDTH    \
    -sy $FRAME_CAVITY_DEPTH    \
    -sz $FRAME_CAVITY_HEIGHT   \
    -tz $FRAME_CAVITY_OFFSET_Z \
    "${STL_CUBE}" "${STL_FRAME_CAVITY}"

stl_boolean -a "${STL_FRAME_OUTER}" -b "${STL_FRAME_CAVITY}" -d "$STL_FRAME_1"

stl_transform                  \
    -tz $FRAME_OUTER_OFFSET_Z  \
    "${STL_FRAME_1}" "${STL_FRAME}"


exit


IMAGES=()
SIZES=()
FRAMES=()

IMAGES+=("frnt")
SIZES+=(SIZE_WIDE)
FRAMES+=("frame_wide.stl")

IMAGES+=("left")
SIZES+=(75)
FRAMES+=("frame_square.stl")

IMAGES+=("rght")
SIZES+=(75)
FRAMES+=("frame_square.stl")

IMAGES+=("back")
SIZES+=(SIZE_WIDE)
FRAMES+=("frame_wide.stl")

IMAGES+=("top2")
SIZES+=(SIZE_WIDE)
FRAMES+=("frame_wide.stl")


VERSION="${IMAGE_VERSION}_${CONFIG_VERSION}"
COUNT=${#IMAGES[@]}

run_stage() {
    local stage="$1"
    local n image size frame bas pxd png rlf out

    for (( n=0; n<COUNT; n++ )); do
        image="${IMAGES[n]}"
        size="${SIZES[n]}"
        frame="${FRAMES[n]}"

        bas="${NAME}_${VERSION}_${image}"
        pxd="${image}_${IMAGE_VERSION}.pxd"
        png="${bas}.png"
        rlf="${bas}_rlf.stl"
        out="${bas}.stl"

        case "$stage" in
            export)
                echo "Exporting ${pxd} -> ${png} .."
                ./pxd2png "$pxd" "$png" "$IMAGE_HEIGHT" "$BLUR_RADIUS"
                ;;

            relief)
                echo "Relief ${png} -> ${rlf} .."
                relief "$png" "$rlf" \
                    --valley "$BASE" \
                    --rise "$RISE" \
                    --size "$size" \
                    --flip
                ;;

            merge)
                echo "Framing ${rlf} -> ${out} .."
                stl_merge -o "$out" "$rlf" "$frame"
                ;;
        esac
    done
}

run_stage export
run_stage relief
run_stage merge

for image in "${IMAGES[@]}"; do
    bas="${NAME}_${VERSION}_${image}"
    echo "open \"${bas}.png\""
    echo "open \"${bas}.stl\""
done
