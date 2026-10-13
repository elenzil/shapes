#!/bin/zsh
set -euo pipefail

NAME="luminary"
IMAGE_VERSION=120
CONFIG_VERSION="02"

# left and right images are 1000x1000
# front, top, and back are 1527x1000
IMAGE_HEIGHT=1000          # pixels
BLUR_RADIUS=1.2            # pixels

# Thickness of the base of the relief print. doesn't affect relief.
# You might want this thicker than seemingly necessary
# to increase the space for the clay slicer to pass over.
BASE=3.0                   # mm

# maximum variation in relief altitude.
RISE=2.5                    # mm

# specific for this project
SIZE_SQUARE=75              # mm
SIZE_WIDE=115               # mm

# minimum thickness of the porcelain.
FRAME_ABOVE_RELIEF=2.25     # mm

# width of the frame wall
FRAME_LATERAL_THICKNESS=2.5 # mm

# lateral margin between relief and wall
FRAME_LATERAL_PADDING=2     # mm

# these can be anything
STL_FRAME_WIDE="frame_wide.stl"
STL_FRAME_SQUARE="frame_square.stl"

IMAGES=()
SIZES=()
FRAMES=()

IMAGES+=("src_frnt")
SIZES+=($SIZE_WIDE)
FRAMES+=($STL_FRAME_WIDE)

IMAGES+=("src_left")
SIZES+=($SIZE_SQUARE)
FRAMES+=($STL_FRAME_SQUARE)

IMAGES+=("src_rght")
SIZES+=($SIZE_SQUARE)
FRAMES+=($STL_FRAME_SQUARE)

IMAGES+=("src_back")
SIZES+=($SIZE_WIDE)
FRAMES+=($STL_FRAME_WIDE)

IMAGES+=("src_top3")
SIZES+=($SIZE_WIDE)
FRAMES+=($STL_FRAME_WIDE)

make_frame() {
    local _FRAME_ABOVE_RELIEF="$1"
    local _FRAME_LATERAL_THICKNESS="$2"
    local _FRAME_LATERAL_PADDING="$3"
    local FRAME_WIDTH="$4"
    local FRAME_DEPTH="$5"
    local FRAME_RELIEF_PEAK="$6"
    local FRAME_BASE_Z="$7"
    local STL_FRAME="$8"

    # derived parameters
    local FRAME_LATERAL_TOTALPAD=$(( (_FRAME_LATERAL_PADDING + _FRAME_LATERAL_THICKNESS) * 2 ))
    local FRAME_OUTER_HEIGHT=$((FRAME_RELIEF_PEAK + _FRAME_ABOVE_RELIEF))
    local FRAME_OUTER_WIDTH=$((FRAME_WIDTH + FRAME_LATERAL_TOTALPAD))
    local FRAME_OUTER_DEPTH=$((FRAME_DEPTH + FRAME_LATERAL_TOTALPAD))
    local FRAME_CAVITY_HEIGHT=$FRAME_OUTER_HEIGHT
    local FRAME_CAVITY_WIDTH=$((FRAME_OUTER_WIDTH - _FRAME_LATERAL_THICKNESS * 2))
    local FRAME_CAVITY_DEPTH=$((FRAME_OUTER_DEPTH - _FRAME_LATERAL_THICKNESS * 2))
    local FRAME_CAVITY_OFFSET_Z=$FRAME_BASE_Z
    local FRAME_OUTER_OFFSET_Z=$((FRAME_OUTER_HEIGHT / 2))

    # temporary STL files
    local STL_PREFIX="_${STL_FRAME:r}"
    local STL_CUBE="${STL_PREFIX}_cube.stl"
    local STL_FRAME_OUTER="${STL_PREFIX}_outer.stl"
    local STL_FRAME_CAVITY="${STL_PREFIX}_cavity.stl"
    local STL_FRAME_1="${STL_PREFIX}_1.stl"

    stl_cube -w 1 "${STL_CUBE}"

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

    stl_boolean \
        -a "${STL_FRAME_OUTER}" \
        -b "${STL_FRAME_CAVITY}" \
        -d "${STL_FRAME_1}"

    stl_transform                 \
        -tz $FRAME_OUTER_OFFSET_Z \
        "${STL_FRAME_1}" "${STL_FRAME}"
}


# frame generation. All values in mm.
make_frame                   \
    $FRAME_ABOVE_RELIEF      \
    $FRAME_LATERAL_THICKNESS \
    $FRAME_LATERAL_PADDING   \
    $SIZE_WIDE               \
    $SIZE_SQUARE             \
    $((BASE + RISE))         \
    $BASE                    \
    "$STL_FRAME_WIDE"

make_frame                   \
    $FRAME_ABOVE_RELIEF      \
    $FRAME_LATERAL_THICKNESS \
    $FRAME_LATERAL_PADDING   \
    $SIZE_SQUARE             \
    $SIZE_SQUARE             \
    $((BASE + RISE))         \
    $BASE                    \
    "$STL_FRAME_SQUARE"


VERSION="${IMAGE_VERSION}_${CONFIG_VERSION}"
COUNT=${#IMAGES[@]}

run_stage() {
    local stage="$1"
    local n image size frame bas pxd png rlf out

    echo "Stage '${stage}'.."

    for (( n=1; n<=COUNT; n++ )); do
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
                    --rise "$RISE"   \
                    --size "$size"   \
                    --flip
                ;;

            merge)
                echo "Framing ${rlf} -> ${out} .."
                stl_merge -o "$out" "$rlf" "$frame"
                ;;
        esac
    done
}


STAGE="${1:-export}"

case "$STAGE" in
    export)
        run_stage export
        run_stage relief
        run_stage merge
        ;;

    relief)
        run_stage relief
        run_stage merge
        ;;

    merge)
        run_stage merge
        ;;

    *)
        echo "Usage: $0 [export|relief|merge]" >&2
        exit 1
        ;;
esac


for image in "${IMAGES[@]}"; do
    local bas="${NAME}_${VERSION}_${image}"
    echo "open \"${bas}.stl\""
done