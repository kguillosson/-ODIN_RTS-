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

deg2rad :: proc(deg:f32)->(rad:f32){
    rad = math.PI*deg/180
    return
}

anglefromVect :: proc(vec:rl.Vector2)->f32{//gives result in rad
    return math.atan2_f32(vec.y, vec.x)

}

myVector2Rotate :: proc(vec:rl.Vector2, angle:f32)->rl.Vector2{
    length := rl.Vector2Length(vec)
    new_vec:rl.Vector2={math.cos(angle), math.sin(angle)}*length
    return new_vec
}
