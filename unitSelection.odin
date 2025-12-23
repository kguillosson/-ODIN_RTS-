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

newSelectNearMouse :: proc(mouse_pos: rl.Vector2, type2find :enum_type, array_data:[]common_data, selection_treshold:f32)->(bool, u8){
    /*
    the type2find parameter can restrict to a single type if we pass said type, if we pass none then it will look for any type
    */

    switch type2find{
        case .none:
            for data, idx in array_data{
                if data.type!=.none && rl.Vector2Distance(mouse_pos, data.pos)<selection_treshold do return true, u8(idx) 
            }
        case .sld:
            for data, idx in array_data{
                if data.type==.sld && rl.Vector2Distance(mouse_pos, data.pos)<selection_treshold do return true, u8(idx) 
            }
        case .vic:
            for data, idx in array_data{
                if data.type==.vic && rl.Vector2Distance(mouse_pos, data.pos)<selection_treshold do return true, u8(idx) 
            }
    }
    return false, 0

    
}

SelectNearMouse :: proc(mouse_pos :rl.Vector2, array_data :[]common_data, selection_treshold :f32, set:unit_set)->(bool, u8){
    //finds a unit that is near the mouse and in set
    for idx in set{
        if rl.Vector2Distance(array_data[idx].pos, mouse_pos)<selection_treshold do return true, idx
    }
    return false, 0
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

newSelectInBox :: proc(start, end :rl.Vector2, array_data:[]common_data)->(return_set:unit_set){
    rect:=rectFrom2Vector2(start, end)
    for data, idx in array_data{
        if rl.CheckCollisionPointRec(data.pos, rect) do return_set+={u8(idx)}
    }
    return
}

SelectInBox :: proc(start, end :rl.Vector2, array_data:[]common_data, set :unit_set)->(return_set:unit_set){
    /*
    selects units that are in the selection box and in 'set'
    */
    rect:=rectFrom2Vector2(start, end)
    for idx in set{
        if rl.CheckCollisionPointRec(array_data[idx].pos, rect) do return_set +={idx}
    }
    return
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
/* 
//ain't at the point where I'll need that
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
getPassenger :: proc(sld_state_array: [max_sld]state_sld, nb_sld:u8)->unit_set{
    return_set : unit_set
    for i:u8=0; i<nb_sld; i+=1{
        if sld_state_array[i]==.passenger do return_set += {i+max_vic}
    }
    return return_set
}
*/




