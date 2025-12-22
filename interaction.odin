package main

import rl "vendor:raylib"


mouseSelection :: proc(drag_start, drag_stop:rl.Vector2, pos_array : [max_sld+max_vic]rl.Vector2, selection_bitset:unit_set, nb_sld, nb_vic:u8)->(new_selection_bitset:unit_set){
    /*
    This function is called on left mouse release to update the selection bitset

    some things:
    if LSHifT is down, we consider that the user wants to keep previously selected units in their selection. (I)

    if the drag zone is small (less than 10px) the system checks if there is a unit cose to the cursor and selects it (II)

    If the drag zone is big, we select all units in it and add them to the selection set (III)
    */

                                                            
    if rl.IsKeyDown(.LEFT_SHIFT) do new_selection_bitset = selection_bitset //(I)
    else do new_selection_bitset = empty_unit_set

    
    if rl.Vector2Distance(drag_start, drag_stop)<drag_select_threshold{     //(II)
        found, idx_selected := selectNearMouse(drag_stop, .any_type, pos_array, selection_treshold, nb_sld, nb_vic)
        if found do new_selection_bitset += {idx_selected}

    }
    else{                                                                   //(III)
        new_selection_bitset = selectInBox(drag_start, drag_stop, pos_array)
    }



    return new_selection_bitset
}
