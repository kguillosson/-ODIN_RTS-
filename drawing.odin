package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

drawThingsFromAtlas :: proc(positions : []rl.Vector2, angles :[]f32, atlas : rl.Texture2D, texture_size:f32){
    assert(len(positions)==len(angles), "Didn't pass same length slices")
    for i:=0; i<len(positions); i+=1{
    draw_from :=rl.Rectangle{
        x =0,
        y =0,
        width = texture_size,
        height = texture_size,
    }
    draw_to := rl.Rectangle{
        x = positions[i].x,
        y=positions[i].y,
        width = texture_size,
        height = texture_size,
    }
        rl.DrawTexturePro(atlas, draw_from, draw_to, {texture_size/2,texture_size/2}, angles[i], rl.WHITE)
    }
}

drawVics :: proc(positions : []rl.Vector2, angles :[]f32, atlas : rl.Texture2D){
    assert(len(positions)==len(angles), "Didn't pass same length slices")
    drawThingsFromAtlas(positions, angles, atlas, 128)
}

drawSlds :: proc(positions : []rl.Vector2, angles :[]f32, atlas : rl.Texture2D){
    assert(len(positions)==len(angles), "Didn't pass same length slices")
    drawThingsFromAtlas(positions, angles, atlas, 64)
}


drawSelectionBox:: proc(origin, current_pos:rl.Vector2){
    WH:rl.Vector2 = origin-current_pos
    rect := rectFrom2Vector2(origin, current_pos)
    rl.DrawRectangleLinesEx(rect, 1, rl.RED)
    
}



highlight :: proc(pos2highlight : rl.Vector2, type2highlight : unit_type){
    radius_base:f32
    switch type2highlight{
        case .any_type:
            fmt.println("untyped thing to highlight, u fkd up") 
            return
        case .soldier:
            radius_base = 30
        case .vehicle:
            radius_base = 60
    }
    
    radius :f32= 3*math.sin_f32(6*f32(rl.GetTime()))+radius_base
    rl.DrawCircleLinesV(pos2highlight, radius, rl.YELLOW)
    return
}


drawMoveLine :: proc(origin, current:rl.Vector2, nb_selected:int){
    assert(nb_selected>1, "invalid number of things for draqwing a move line")
    fN:=f32(nb_selected)
    rl.DrawLineEx(origin, current, 1, rl.RED)
    drag_vctr:=current-origin
    length := rl.Vector2Length(drag_vctr)
    drag_hat:= rl.Vector2Normalize(drag_vctr)
    for i:f32=0; i<f32(fN); i+=1 {
        pos := origin + length*(i/(fN-1))*drag_hat
        rl.DrawCircleV(pos, 5, rl.RED)
    }

}



/*        if (drag_in_progress && card(selection_set)>1 && !rl.IsKeyDown(.LEFT_SHIFT)){
            drag_vctr := mouse_pos - drag_start_pos
            length:=rl.Vector2Length(drag_vctr)
            u_hat := rl.Vector2Normalize(drag_vctr)
            rl.DrawLineEx(drag_start_pos, mouse_pos, 1, rl.RED)
            for i:u8=0; i<nb_selected; i+=1{
                rl.DrawCircleV(drag_start_pos + f32(i)*length/f32(nb_selected-1) * u_hat, 5, rl.RED)
            }
        }
*/