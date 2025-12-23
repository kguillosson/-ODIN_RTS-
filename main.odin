//#+feature global-context

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
    vic_set :unit_set:{0, 1, 2, 3, 4, 5, 6, 7}

move_task :: rl.Vector2
crew_task :: struct{
    vic2crew:u8,
    slot:u8,
}

task :: struct #raw_union{
    move : move_task,
    crew : crew_task
}

particle :: union{
    move_particle
}

move_particle :: struct{
    pos : rl.Vector2,
    time : f32,

}


button_struct :: struct{
    using pos:rl.Rectangle, 
    color:rl.Color,
    fontsize:i32, 
    label:cstring, 
    }

interaction_mode::enum u8{
    move=0,
    crew=1,
    point=2,
    uncrew=3,
}


truck_crew_struct::struct{
    passenger:[5]u8,
    driver:u8,
    occupancy : bit_set[0..<6;u8],
}

@(rodata)
truck_displacement_array :=[6]rl.Vector2{
    // the -64 is to recenter the unit relative to the center of the vic
    {85-64, 46-64},
    {85-64, 80-64},
    {54-64, 40-64},
    {20-64, 40-64},
    {54-64, 91-64},
    {20-64, 91-64},
}
@(rodata)
truck_angle_array :=[6]f32{
    0,
    0,
    90,
    90,
    -90,
    -90
}

//New data structure: we wil use a common data struct for shared things, and specialised data containers for the diverse types (ie. slds, vics...)

enum_state :: enum u8{
    /*
    This enum is meant to inform us about what a unit is doing
    */
    inactive = 0,   //used for vics w/out a driver, or for unused slds slots
    idle = 1,       //tells us there is no current task
    moving = 2,
    crewing = 3,    //only for slds
    passenger = 4,  //same


}

enum_type :: enum u8{
    none =0,
    sld = 1,
    vic = 2,
}

common_data :: struct{
    using pos :rl.Vector2,  // in px
    angle :f32,             // in degrees
    task_ptr :u8,           // points to the current task in the array_task_current
    type_ptr :u8,           // points to the unit data in it's type specific array
    state :enum_state,      // what the unit is doing
    type :enum_type,        // what the unit is
}




main::proc(){

    //data initialisation
    
    screen_width :i32= 1200
    screen_height :i32= 900


    nb_sld:u8=0

    nb_vic:u8=0

    fkounter :f32=0

    //common data :
    pos_array :[max_sld+max_vic]rl.Vector2
    angle_array:[max_sld+max_vic]f32
    task_array:[max_sld+max_vic]task

    //type specific data : 
    state_array_vic:[8] state_vic
    state_array_sld:[32] state_sld

    state_array:[max_sld+max_vic]state
    vic_crew_array:[max_vic]truck_crew_struct
    

    //init a soldier and vic
    pos_array[0] = {500, 500}
    nb_vic = 1
    pos_array[8] = {300, 300}
    pos_array[9] = {300, 400}
    pos_array[10] = {300, 500}
    pos_array[11] = {400, 300}
    pos_array[12] = {400, 400}
    pos_array[13] = {400, 500}
    nb_sld = 6
    
    selection_set :unit_set
    

  
    
    move_particle_lifetime:f32=1


    select_drag_start_pos :rl.Vector2
    select_drag_in_progress :bool

    task_drag_in_progress :bool
    task_drag_start_pos :rl.Vector2


    //new data structure definition
    array_data_common :[40]common_data

    array_data_common[0]={
        {700,200},
        0,
        0,
        0,
        .idle,
        .vic
    }

    //buttons definition
    //interaction_mode_buttons
    interaction_mode_state : interaction_mode = .move
    crew_mode_button : button_struct ={
        {100, 0, 100, 30},
        rl.YELLOW,
        20,
        "CREW"
    }
    move_mode_button : button_struct={
        {0,0,100,30},
        rl.YELLOW,
        20,
        "MOVE",
    }
    point_mode_button :button_struct={
        {200, 0, 100, 30},
        rl.YELLOW,
        20,
        "POINT",
    }
    uncrew_mode_button : button_struct={
        {300, 0, 100 ,30},
        rl.YELLOW,
        20,
        "UNCREW"
    }
    interaction_mode_buttons_array :[4]button_struct={move_mode_button, crew_mode_button, point_mode_button, uncrew_mode_button}


    //particle dynamic array creation

    prt_array := make([dynamic]particle, 0, 64)

    rl.InitWindow(screen_width, screen_height, "game")//init the window

    atlas_sld :rl.Texture2D=rl.LoadTexture("atlas fren.png")
    atlas_vic :rl.Texture2D=rl.LoadTexture("truck.png")
    atlas :rl.Texture2D=rl.LoadTexture("atlas.png")

    //game loop

    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose(){

        //selection 
        //get the mouse data
        mouse_pos :=rl.GetMousePosition()

        if rl.IsMouseButtonPressed(.LEFT){
            select_drag_in_progress = true
            select_drag_start_pos = mouse_pos
        }

        if rl.IsMouseButtonPressed(.RIGHT){
            task_drag_in_progress = true
            task_drag_start_pos = mouse_pos
        }

        //select units
        if rl.IsMouseButtonReleased(.LEFT) {
            idx, found := check_button(mouse_pos, interaction_mode_buttons_array[:])
            if found do interaction_mode_state = interaction_mode(idx)
            else do selection_set = mouseSelection(select_drag_start_pos, mouse_pos, pos_array, selection_set, nb_sld, nb_vic)
            for sld_idx:u8=0; sld_idx<nb_sld; sld_idx+=1{
                if state_array_sld[sld_idx]==.passenger do selection_set-={sld_idx+max_vic}
            }
        }
        //assign task relative to the interaction state
    if rl.IsMouseButtonReleased(.RIGHT){
        switch interaction_mode_state{
            case .move:
                if card(selection_set)==1{
                    for unit_idx in selection_set{
                        task_array[unit_idx].move=mouse_pos
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
                        
                        task_array[unit_idx].move = task_drag_start_pos + fkounter*length/f32(card(selection_set)-1) * u_hat
                        append(&prt_array, initMoveParticle(task_array[unit_idx].move, move_particle_lifetime))
                        fkounter+=1
                        if unit_idx <max_vic do state_array_vic[unit_idx]=.moving   //  \
                                                                                    //  | some work is maybe required to simplify this
                        else do state_array_sld[unit_idx-max_vic] = .moving         //  /

                        angle_array[unit_idx] = rad2deg(anglefromVect(task_array[unit_idx].move-pos_array[unit_idx]))
                    }
                    selection_set&={}
                }
                
            case .crew:
                found, idx := selectNearMouse(mouse_pos, .vehicle, pos_array, selection_treshold, nb_sld, nb_vic)
                if found{
                    selection_set -= vic_set

                    if card(selection_set)<=6-card(vic_crew_array[idx].occupancy){
                        for sld_idx in selection_set{

                            state_array_sld[sld_idx-max_vic]=.passenger
                            if 0 not_in vic_crew_array[idx].occupancy{
                                vic_crew_array[idx].driver=sld_idx
                                vic_crew_array[idx].occupancy+={0}
                                task_array[sld_idx].crew.vic2crew=idx
                                task_array[sld_idx].crew.slot=0
                            }
                            else{
                                for i:=1; i<6; i+=1{
                                    if (i not_in vic_crew_array[idx].occupancy){
                                        vic_crew_array[idx].passenger[i-1]=sld_idx
                                        vic_crew_array[idx].occupancy+={i}
                                        task_array[sld_idx].crew.vic2crew=idx
                                        task_array[sld_idx].crew.slot=u8(i)
                                        break
                                    }
                                }
                            }
                        }
                        selection_set&={}
                    }
                }
            case .point:
                for unit_idx in selection_set{
                    angle_array[unit_idx]=rad2deg(anglefromVect(mouse_pos-pos_array[unit_idx]))
                }
            case .uncrew:
                found, idx := selectNearMouse(mouse_pos, .vehicle, pos_array, selection_treshold, nb_sld, nb_vic)
                if found {
                    if  (0 in (vic_crew_array[idx].occupancy)){
                        state_array_sld[vic_crew_array[idx].driver-max_vic]=.idle
                        vic_crew_array[idx].occupancy -= {0}
                    }
                    for i in vic_crew_array[idx].occupancy{
                        state_array_sld[vic_crew_array[idx].passenger[i-1]-max_vic]=.idle
                        vic_crew_array[idx].occupancy -= {i}
                    }
                }
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
            mvt_vctr :rl.Vector2 = task_array[mover_idx].move - pos_array[mover_idx]
            remaining_dist:f32=rl.Vector2Length(mvt_vctr)
            step:f32
            if mover_idx<max_vic do step = mvt_speed_vic*delta_t
            else if mover_idx<max_vic+max_sld do step = mvt_speed_sld*delta_t

            if step<remaining_dist{
                pos_array[mover_idx]+=step*rl.Vector2Normalize(mvt_vctr)
            }
            else{
                pos_array[mover_idx]=task_array[mover_idx].move
                if mover_idx<max_vic do state_array_vic[mover_idx] = .idle
                else if mover_idx<max_vic+max_sld do state_array_sld[mover_idx-max_vic] = .idle
            }
        }
        passengers :=getPassenger(state_array_sld, nb_sld)

        for passenger_idx in passengers{
            vic_idx := task_array[passenger_idx].crew.vic2crew
            vic_pos := pos_array[vic_idx]
            displaced_pos := rl.Vector2Rotate(truck_displacement_array[task_array[passenger_idx].crew.slot], deg2rad(angle_array[vic_idx]))+vic_pos
            pos_array[passenger_idx]=displaced_pos
            angle_array[passenger_idx]=angle_array[vic_idx]+truck_angle_array[task_array[passenger_idx].crew.slot]
        }
        

        rl.BeginDrawing()
        rl.ClearBackground({195, 237, 181, 255})
        //particle drawing
        for i :=0; i<len(prt_array); i+=1{
            del_prt:bool
            prt_array[i], del_prt = drawParticle(prt_array[i], delta_t)
            if del_prt{
                unordered_remove(&prt_array, i)
                i-=1
            }
        }


        //draw units
        drawVics(pos_array[0:nb_vic], angle_array[0:nb_vic], atlas_vic)
        drawSlds(pos_array[max_vic:max_vic+nb_sld], angle_array[max_vic:max_vic+nb_sld], atlas_sld)

        newDrawThingFromAtlas(array_data_common[:], atlas)
       
        //if select_drag_in_progress do drawSelectionBox(selection_box_start_pos, mouse_pos)
        if select_drag_in_progress {
            drawSelectionBox(select_drag_start_pos, mouse_pos)
        }

        if (task_drag_in_progress && card(selection_set)>1 && interaction_mode_state ==.move) do drawMoveLine(task_drag_start_pos, mouse_pos, card(selection_set))

        for unit_idx in selection_set{
            type:unit_type =.soldier
            if unit_idx<max_vic do type =.vehicle
            highlight(pos_array[unit_idx], type)
        }
        

        //button drawing
        for button, i in interaction_mode_buttons_array{
            if interaction_mode(i) == interaction_mode_state{
                drawButtonHighlight(button, rl.BLACK, 3)
            }
            else do drawButtont(button)
        }

        rl.EndDrawing()
    }
    rl.UnloadTexture(atlas_sld)
    rl.UnloadTexture(atlas_vic)

}