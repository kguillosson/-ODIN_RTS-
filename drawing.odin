package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

/*
This files centralises the functions used to display stuff to the screen, as well as the particle system 
*/

newDrawThingFromAtlas :: proc(data:[]common_data, atlas:rl.Texture2D){
    for i:=0; i<len(data); i+=1{
        //get the texture size we want to display
        draw_from:rl.Rectangle
        switch data[i].type{//will be replaced with a map in the future 
            case .none:
                continue
            case .sld:
                draw_from = {0,0, 64,64}
            case .vic:
                draw_from = {0,64, 128,128}
        }
        draw_to:rl.Rectangle = {data[i].x, data[i].y, draw_from.width, draw_from.height}
        rl.DrawTexturePro(atlas, draw_from, draw_to, {draw_from.width/2, draw_from.height/2}, data[i].angle ,rl.WHITE)
    }
}


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



highlight :: proc(pos2highlight : rl.Vector2, type2highlight : enum_type){
    radius_base:f32
    switch type2highlight{
        case .none:
            fmt.println("untyped thing to highlight, u fkd up") 
            return
        case .sld:
            radius_base = 30
        case .vic:
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



drawParticle :: proc (particle2draw : particle, delta_t:f32) -> (updated_particle:particle, del:bool){
    updated_particle=particle2draw
    switch &prt in updated_particle {
        case move_particle:
            rl.DrawCircleLinesV(prt.pos, 3, rl.YELLOW)
            prt.time-=delta_t
            return prt, prt.time<=0
            

    }
    return
}

initMoveParticle :: proc(pos:rl.Vector2, time: f32)->particle{
    output:particle=move_particle({pos, time})
    return output
}



drawButtont :: proc(button : button_struct){
    rl.DrawRectangleRec(button.pos, button.color) 
    textwidth := rl.MeasureText(button.label, button.fontsize)
    diff :=i32(button.width)-textwidth
    rl.DrawText(button.label, i32(button.x)+diff/2, i32(button.y)+(i32(button.height)-button.fontsize)/2, button.fontsize, rl.BLACK)
}


drawButtonHighlight :: proc(button : button_struct, highlight_color:rl.Color, highlight_width:f32){
    rl.DrawRectangleRec(button.pos, highlight_color) 
    updated_rect:rl.Rectangle={
        button.x+highlight_width,
        button.y+highlight_width,
        button.width-2*highlight_width,
        button.height-2*highlight_width,
    }
    rl.DrawRectangleRec(updated_rect, button.color) 
    textwidth := rl.MeasureText(button.label, button.fontsize)
    diff :=i32(button.width)-textwidth
    rl.DrawText(button.label, i32(button.x)+diff/2, i32(button.y)+(i32(button.height)-button.fontsize)/2, button.fontsize, rl.BLACK)
}

