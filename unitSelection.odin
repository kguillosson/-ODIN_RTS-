package main

import "core:fmt"

import rl "vendor:raylib"


//select on map

selectNearMouse :: proc(mouse_pos:rl.Vector2, type2find :unit_type, pos_array:[40]rl.Vector2, selection_treshold :f32, nb_sld, nb_vic :u8)->(found:bool, idx :u8){
    found = false
    idx = 0
    pos_array:=pos_array
    switch type2find{
        case .any_type:
            found, idx = selectInSlice(mouse_pos, pos_array[0:nb_vic], selection_treshold, nb_vic, 0)
            if found do return
            else do found, idx = selectInSlice(mouse_pos, pos_array[max_vic:max_vic+nb_sld], selection_treshold, nb_sld, max_vic)
        case .soldier:
            found, idx = selectInSlice(mouse_pos, pos_array[max_vic:max_vic+nb_sld], selection_treshold, nb_sld, max_vic)
        case .vehicle:
            found, idx = selectInSlice(mouse_pos, pos_array[0:nb_vic], selection_treshold, nb_vic, 0)
    }
    return
}

/*
selectInBox :: proc (orig, current :rl.Vector2, pos_array:[40]rl.Vector2, nb_sld, nb_vic, nb_selected :u8, selection_array:[40]u8)->(u8, [40]u8){
    new_selection_array:=selection_array
    new_nb_selected:=nb_selected
    rect:=rectFrom2Vector2(orig, current)
    for i:u8=0; i<nb_vic; i+=1{
        
        if rl.CheckCollisionPointRec(pos_array[i], rect){
            new_selection_array[new_nb_selected]=i
            new_nb_selected+=1
            fmt.printf("found unit '%d', new nb_selected =%d", i, new_nb_selected)
        }
        
    }
    for i:u8=max_vic; i<nb_sld+max_vic; i+=1{

        if rl.CheckCollisionPointRec(pos_array[i], rect){
            new_selection_array[new_nb_selected]=i
            new_nb_selected+=1
            fmt.printf("found unit '%d', new nb_selected =%d", i, new_nb_selected)
        }
        
    }
    fmt.print("\n")
    fmt.println(new_selection_array[0:nb_selected])
    return new_nb_selected, new_selection_array
}*/
selectInBox ::proc(orig, current:rl.Vector2, pos_array:[40]rl.Vector2,)->(unit_set){
    ret_set:unit_set
    rect:=rectFrom2Vector2(orig, current)
    for i:u8=0; i<max_sld+max_vic; i+=1{
        if rl.CheckCollisionPointRec(pos_array[i], rect) do ret_set+={i}
    }
    return ret_set
}

selectInSlice :: proc(mouse_pos :rl.Vector2, pos_slice :[]rl.Vector2, selection_treshold :f32, nb_thing, first_valid_idx :u8)->(found:bool, idx :u8){
    for i:u8=0; i<nb_thing; i+=1{
        if rl.Vector2Distance(mouse_pos, pos_slice[i])<selection_treshold{
            return true, first_valid_idx+i
        }
    }
    return false, 0
}

//select from state

getMoving :: proc (vic_state_array :[max_vic]state_vic, nb_vic:u8, sld_state_array :[max_sld]state_sld, nb_sld:u8)->(unit_set){
    return_set:unit_set
    for i:u8=0; i<nb_vic; i+=1{
        if vic_state_array[i] ==.moving{
            return_set +={i}
        }
    }
    for i:u8=0; i<nb_sld; i+=1{
        if sld_state_array[i] ==.moving{
            return_set += {i+max_vic}
        }
    }
    return return_set
}





