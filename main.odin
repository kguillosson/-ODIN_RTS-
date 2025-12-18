#+feature global-context

package main

import rl "vendor:raylib"
import "core:fmt"
import sa "core:container/small_array"



state_sld :: enum u8{
    idle = 0,
    moving = 1,
    passenger = 2,
}

state_vic :: enum u8{
    idle = 0,
    moving = 1, 
}

unit_type ::enum u8{
    any_type = 0, 
    soldier = 1,
    vehicle = 2

}
    max_sld :u8:32
    max_vic :u8:8

    mvt_speed_sld :f32=40
    mvt_speed_vic :f32=60

    unit_set::bit_set[0..<max_sld+max_vic]
    empty_unit_set:unit_set:{}

move_task :: rl.Vector2
    
main::proc(){
    
    screen_width :i32= 1200
    screen_height :i32= 900


    nb_sld:u8=0

    nb_vic:u8=0

    fkounter :f32=0

    //common data :
    pos_array :[40]rl.Vector2
    angle_array:[40]f32
    task_array:[40]move_task

    //type specific data : 
    state_array_vic:[8] state_vic
    state_array_sld:[32] state_sld

    //init a soldier and vic
    pos_array[0] = {500, 500}
    nb_vic = 1
    pos_array[8] = {300, 300}
    pos_array[9] = {300, 400}
    nb_sld = 2
    
    selection_set :unit_set
    selection_array :[40]u8
    nb_selected :u8=0
    selection_treshold :f32=50
    


    drag_start_pos :rl.Vector2
    drag_in_progress :bool

    rl.InitWindow(screen_width, screen_height, "game")//init the window

    atlas_sld :rl.Texture2D= rl.LoadTexture("atlas fren.png")
    atlas_vic :rl.Texture2D=rl.LoadTexture("truck.png")


    

    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose(){

        //selection
        
        mouse_pos :=rl.GetMousePosition()

        if rl.IsMouseButtonPressed(.LEFT){
            drag_in_progress = true
            drag_start_pos = mouse_pos
        }
        //actions on leftclick release
        if rl.IsMouseButtonReleased(.LEFT){

            if rl.Vector2Distance(drag_start_pos, mouse_pos)<10{//this is considered a simple click on screen
                found, idx_selected := selectNearMouse(mouse_pos, .any_type, pos_array, selection_treshold, nb_sld, nb_vic)
                
                if !found {
                    /*for unit_idx in selection_array[0:nb_selected]{
                        task_array[unit_idx] = mouse_pos//give movement task

                        if unit_idx <max_vic do state_array_vic[unit_idx]=.moving
                        
                        else do state_array_sld[unit_idx-max_vic] = .moving

                        angle_array[unit_idx] = rad2deg(anglefromVect(mouse_pos-pos_array[unit_idx]))
                    }*/
                    for unit_idx in selection_set{
                        task_array[unit_idx] = mouse_pos//give movement task

                        if unit_idx <max_vic do state_array_vic[unit_idx]=.moving
                        
                        else do state_array_sld[unit_idx-max_vic] = .moving

                        angle_array[unit_idx] = rad2deg(anglefromVect(mouse_pos-pos_array[unit_idx]))
                    }


                    selection_set &=empty_unit_set
                    nb_selected = 0

                } //assign movement since you didn't click on anything
                else{
                    if rl.IsKeyDown(.LEFT_SHIFT){
                        selection_set += {idx_selected}
                        selection_array[nb_selected]=idx_selected
                        nb_selected+=1
                    }
                    else{
                        selection_set &= empty_unit_set
                        selection_set += {idx_selected}
                        selection_array[0]=idx_selected
                        nb_selected=1
                    }
                }
                
            }
            else {//here we suppose some dragging action occured
                if drag_in_progress {
                    if (card(selection_set)>1 && !rl.IsKeyDown(.LEFT_SHIFT)){//here we will task units to move towards points equidistants on the dragged line
                        drag_vctr := mouse_pos - drag_start_pos
                        length:=rl.Vector2Length(drag_vctr)
                        u_hat := rl.Vector2Normalize(drag_vctr)/*
                        for unit_idx, i in selection_array[0:nb_selected]{
                            task_array[unit_idx] = drag_start_pos + f32(i)*length/f32(i-1) * u_hat

                            if unit_idx <max_vic do state_array_vic[unit_idx]=.moving   //  \
                                                                                        //  | some work is maybe required to simplify this
                            else do state_array_sld[unit_idx-max_vic] = .moving         //  /

                            
                        }*/
                        fkounter=0
                        for unit_idx in selection_set{
                            task_array[unit_idx] = drag_start_pos + fkounter*length/f32(card(selection_set)-1) * u_hat
                            fkounter+=1
                            if unit_idx <max_vic do state_array_vic[unit_idx]=.moving   //  \
                                                                                        //  | some work is maybe required to simplify this
                            else do state_array_sld[unit_idx-max_vic] = .moving         //  /

                            angle_array[unit_idx] = rad2deg(anglefromVect(task_array[unit_idx]-pos_array[unit_idx]))
                        }
                        selection_set&={}
                        nb_selected = 0 // clear the selction array
                        fmt.printfln("nb_soldier : %d, nb_vic : %d", nb_sld, nb_vic)
                        
                    }
                    else {
                        if card(selection_set)==0 || rl.IsKeyDown(.LEFT_SHIFT) do selection_set += selectInBox(drag_start_pos, mouse_pos, pos_array)

                    }
                }
            }
        }
        if nb_selected>0 && rl.IsMouseButtonPressed(.RIGHT){
            for unit_idx in selection_set{
                angle_array[unit_idx] = rad2deg(anglefromVect(mouse_pos-pos_array[unit_idx]))
                //fmt.println(angle_array[unit_idx])
            }
        }

        drag_in_progress = drag_in_progress && rl.IsMouseButtonDown(.LEFT)
        
        //unit ticking 
        /*
        Might redo this with specific dynamic arrays for each task, allowing to iterate over the units without having to skip units with other tasks
        */
        delta_t:=rl.GetFrameTime()
        //movement
        moving_units := getMoving(state_array_vic, nb_vic, state_array_sld, nb_sld)
        
        for mover_idx in moving_units{
            //fmt.println(mover_idx)
            mvt_vctr :rl.Vector2 = task_array[mover_idx] - pos_array[mover_idx]
            remaining_dist:f32=rl.Vector2Length(mvt_vctr)
            step:f32
            if mover_idx<max_vic do step = mvt_speed_vic*delta_t
            else if mover_idx<max_vic+max_sld do step = mvt_speed_sld*delta_t

            if step<remaining_dist{
                pos_array[mover_idx]+=step*rl.Vector2Normalize(mvt_vctr)
            }
            else{
                pos_array[mover_idx]=task_array[mover_idx]
                if mover_idx<max_vic do state_array_vic[mover_idx] = .idle
                else if mover_idx<max_vic+max_sld do state_array_sld[mover_idx-max_vic] = .idle
            }
        }
        

        rl.BeginDrawing()
        rl.ClearBackground({195, 237, 181, 255})
        //draw units
        drawVics(pos_array[0:nb_vic], angle_array[0:nb_vic], atlas_vic)
        drawSlds(pos_array[max_vic:max_vic+nb_sld], angle_array[max_vic:max_vic+nb_sld], atlas_sld)
       
        //if drag_in_progress do drawSelectionBox(selection_box_start_pos, mouse_pos)
        if drag_in_progress && (card(selection_set)==0 || rl.IsKeyDown(.LEFT_SHIFT)){
            drawSelectionBox(drag_start_pos, mouse_pos)
        }

        if (drag_in_progress && card(selection_set)>1 && !rl.IsKeyDown(.LEFT_SHIFT)) do drawMoveLine(drag_start_pos, mouse_pos, card(selection_set))

        for unit_idx in selection_set{
            type:unit_type =.soldier
            if unit_idx<max_vic do type =.vehicle
            highlight(pos_array[unit_idx], type)
        }
        
        
        rl.EndDrawing()
    }
}