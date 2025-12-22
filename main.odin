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

state_common :: enum u8{
    idle = 0,
    moving = 1,
}

state :: struct #raw_union {
    sld:state_sld,
    vic:state_vic,
    comm:state_common
}

unit_type ::enum u8{
    any_type = 0, 
    soldier = 1,
    vehicle = 2

}

    drag_select_threshold :f32:10
    selection_treshold :f32:50

    max_sld :u8:32
    max_vic :u8:8

    mvt_speed_sld :f32=40
    mvt_speed_vic :f32=60

    unit_set::bit_set[0..<max_sld+max_vic]
    empty_unit_set:unit_set:{}

move_task :: rl.Vector2


particle :: union{
    move_particle
}

move_particle :: struct{
    pos : rl.Vector2,
    time : f32,

}

mouse_interaction_enum :: enum{
    lmb_held,
    lmb_release,
    shift_held,
    rmb,
}

mouse_interaction_set :: bit_set[mouse_interaction_enum]


main::proc(){
    
    screen_width :i32= 1200
    screen_height :i32= 900


    nb_sld:u8=0

    nb_vic:u8=0

    fkounter :f32=0

    //common data :
    pos_array :[max_sld+max_vic]rl.Vector2
    angle_array:[max_sld+max_vic]f32
    task_array:[max_sld+max_vic]move_task

    //type specific data : 
    state_array_vic:[8] state_vic
    state_array_sld:[32] state_sld

    state_array:[max_sld+max_vic]state

    //init a soldier and vic
    pos_array[0] = {500, 500}
    nb_vic = 1
    pos_array[8] = {300, 300}
    pos_array[9] = {300, 400}
    nb_sld = 2
    
    selection_set :unit_set
    interaction_set :mouse_interaction_set

    nb_selected :u8=0
    
    move_particle_lifetime:f32=1


    select_drag_start_pos :rl.Vector2
    select_drag_in_progress :bool

    task_drag_in_progress :bool
    task_drag_start_pos :rl.Vector2

    //particle dynamic array creation

    prt_array := make([dynamic]particle, 0, 64)

    rl.InitWindow(screen_width, screen_height, "game")//init the window

    atlas_sld :rl.Texture2D= rl.LoadTexture("atlas fren.png")
    atlas_vic :rl.Texture2D=rl.LoadTexture("truck.png")


    

    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose(){

        //selection
        
        mouse_pos :=rl.GetMousePosition()

        if rl.IsMouseButtonPressed(.LEFT){//get the point where we started to drag an set the flag
            select_drag_in_progress = true
            select_drag_start_pos = mouse_pos
        }

        if rl.IsMouseButtonPressed(.RIGHT){
            task_drag_in_progress = true
            task_drag_start_pos = mouse_pos
        }


        if rl.IsMouseButtonReleased(.LEFT) do selection_set = mouseSelection(select_drag_start_pos, mouse_pos, pos_array, selection_set, nb_sld, nb_vic)

        if rl.IsMouseButtonReleased(.RIGHT){
            if card(selection_set)==1{
                for unit_idx in selection_set{
                    task_array[unit_idx]=mouse_pos
                    append(&prt_array, initMoveParticle(mouse_pos, move_particle_lifetime))

                    if unit_idx <max_vic do state_array_vic[unit_idx]=.moving
                    else do state_array_sld[unit_idx-max_vic] = .moving

                    angle_array[unit_idx] = rad2deg(anglefromVect(mouse_pos-pos_array[unit_idx]))
                }
                selection_set&={}
            }
            else if card(selection_set)>1{
                drag_vctr := mouse_pos - task_drag_start_pos
                length:=rl.Vector2Length(drag_vctr)
                u_hat := rl.Vector2Normalize(drag_vctr)
                fkounter=0
                for unit_idx in selection_set{
                    
                    task_array[unit_idx] = task_drag_start_pos + fkounter*length/f32(card(selection_set)-1) * u_hat
                    append(&prt_array, initMoveParticle(task_array[unit_idx], move_particle_lifetime))
                    fkounter+=1
                    if unit_idx <max_vic do state_array_vic[unit_idx]=.moving   //  \
                                                                                //  | some work is maybe required to simplify this
                    else do state_array_sld[unit_idx-max_vic] = .moving         //  /

                    angle_array[unit_idx] = rad2deg(anglefromVect(task_array[unit_idx]-pos_array[unit_idx]))
                }
                selection_set&={}
            }
        }


       

        select_drag_in_progress = select_drag_in_progress && rl.IsMouseButtonDown(.LEFT)
        task_drag_in_progress = task_drag_in_progress && rl.IsMouseButtonDown(.RIGHT)
        
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
       
        //if select_drag_in_progress do drawSelectionBox(selection_box_start_pos, mouse_pos)
        if select_drag_in_progress && (card(selection_set)==0 || rl.IsKeyDown(.LEFT_SHIFT)){
            drawSelectionBox(select_drag_start_pos, mouse_pos)
        }

        if (task_drag_in_progress && card(selection_set)>1 ) do drawMoveLine(task_drag_start_pos, mouse_pos, card(selection_set))

        for unit_idx in selection_set{
            type:unit_type =.soldier
            if unit_idx<max_vic do type =.vehicle
            highlight(pos_array[unit_idx], type)
        }
        
        //particle drawing
        for i :=0; i<len(prt_array); i+=1{
            del_prt:bool
            prt_array[i], del_prt = drawParticle(prt_array[i], delta_t)
            if del_prt{
                unordered_remove(&prt_array, i)
                i-=1
            }
        }
        
        rl.EndDrawing()
    }
    rl.UnloadTexture(atlas_sld)
    rl.UnloadTexture(atlas_vic)

}