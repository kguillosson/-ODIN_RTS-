package main

import rl "vendor:raylib"
import "core:math"


rectFrom2Vector2 :: proc(v1, v2 :rl.Vector2)->rl.Rectangle{
    WH:rl.Vector2 = v1-v2
    rect : rl.Rectangle = {
        x = math.min(v1.x, v2.x),
        y = math.min(v1.y, v2.y),
        width = math.abs(WH.x),
        height = math.abs(WH.y)
    }
    return rect
}

rad2deg :: proc(rad:f32)->(deg:f32){
    deg = 180*rad/math.PI
    return
}

anglefromVect :: proc(vec:rl.Vector2)->f32{//gives result in rad
    return math.atan2_f32(vec.y, vec.x)

}
