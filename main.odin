//#+feature global-context

package main

import rl "vendor:raylib"
import "core:fmt"
import sa "core:container/small_array"



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

    unit_set::bit_set[0..<max_units]
    empty_unit_set:unit_set:{}


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

max_units :u8:40
max_tasks :u16:512

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
    //state_array_vic:[8] state_vic
    //state_array_sld:[32] state_sld

    //state_array:[max_sld+max_vic]state
    //vic_crew_array:[max_vic]truck_crew_struct
    

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
    array_data_common :[max_units]common_data

    array_data_common[0]={
        {700,200},
        0,
        0,
        0,
        .idle,
        .sld
    }
    array_data_common[1]={
        {600,200},
        0,
        0,
        0,
        .idle,
        .sld
    }

    is_unit, is_sld, is_vic := makeSets(array_data_common[:])

    array_current_task :[max_units]container_task_data
    array_future_task := make([dynamic]container_future_task_data, 0, max_tasks)
    defer delete(array_future_task)
    array_buffer_task :[max_units]union_future_task_data
    set_buffer :unit_set





    //this seems like a good place to do the file reading thing
    type2speed :=make(map[enum_type]f32)
    defer delete(type2speed)
    type2speed[.sld] = 40
    type2speed[.vic] = 80


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

    //atlas_sld :rl.Texture2D=rl.LoadTexture("atlas fren.png")
    //atlas_vic :rl.Texture2D=rl.LoadTexture("truck.png")
    atlas :rl.Texture2D=rl.LoadTexture("atlas.png")

    //game loop

    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose(){

        
        //get some data
        mouse_pos :=rl.GetMousePosition()
        delta_t :=rl.GetFrameTime()
        is_unit, is_sld, is_vic = makeSets(array_data_common[:])

        if rl.IsMouseButtonPressed(.LEFT){
            select_drag_in_progress = true
            select_drag_start_pos = mouse_pos
        }

        if rl.IsMouseButtonPressed(.RIGHT){
            task_drag_in_progress = true
            task_drag_start_pos = mouse_pos
        }
        //debug block
        if rl.IsKeyPressed(.SPACE){
            fmt.println(getWithTask(array_current_task))
            for task_data, k in array_current_task{
                if isActivetask(task_data) do fmt.println(task_data)
            }
        }


        //select units
        if rl.IsMouseButtonReleased(.LEFT) {
            idx, found := check_button(mouse_pos, interaction_mode_buttons_array[:])
            if found do interaction_mode_state = interaction_mode(idx)
            else do selection_set = MouseSelection(select_drag_start_pos, mouse_pos, array_data_common[:], selection_set, is_unit)
            for sld_idx:u8=0; sld_idx<nb_sld; sld_idx+=1{
                if array_data_common[sld_idx].state==.passenger do selection_set-={sld_idx+max_vic}
            }
        }
        //assign task relative to the interaction state
        /*
        NOTES:
            Next objective is to make all this into a simple function to clean up the main,
            but 4now imma make this work the ugly way to test stuff
        */
        if rl.IsMouseButtonReleased(.RIGHT) {
            switch interaction_mode_state{
                case .move:
                    fkounter = 0
                    N := f32(card(selection_set))
                    drag_vctr := mouse_pos - task_drag_start_pos
                    drag_length := rl.Vector2Length(drag_vctr)
                    drag_hat :=drag_vctr/drag_length
                    if N==1 {
                        for selected_idx in selection_set{
                            wishpos:rl.Vector2 = mouse_pos
                            array_buffer_task[selected_idx] = move_future_task_data{wishpos}
                            fmt.printfln("tried to give move task to unit %d", selected_idx)
                            fmt.print("future task created :")
                            fmt.println(array_buffer_task[selected_idx])
                            set_buffer+={selected_idx}
                        }
                    }
                    else{
                        for selected_idx in selection_set{
                            wishpos:rl.Vector2 = task_drag_start_pos + (fkounter*drag_length/(N+1)) * drag_hat
                            fkounter+=1
                            array_buffer_task[selected_idx] = move_future_task_data{wishpos}
                            fmt.printfln("tried to give move task to unit %d", selected_idx)
                            fmt.print("future task created :")
                            fmt.println(array_buffer_task[selected_idx])
                            set_buffer+={selected_idx}
                        }
                    }
                    
                    
                    
                case .crew:
                case .point: //used for debugging stuff, will be replaced with a proper overwatch system
                case .uncrew:
            }
            for selected_idx in set_buffer{
                if rl.IsKeyDown(.LEFT_CONTROL){ //check if we want to put this task after the current ones
                    if !isActivetask(array_current_task[selected_idx]){
                        array_current_task[selected_idx] = {convertFuture2current(array_buffer_task[selected_idx], array_data_common, selected_idx),  2*max_tasks, array_data_common[selected_idx].type}
                    }
                    else{//we need to find a spot to store the next task
                        nb_future_tasks := u16(len(array_future_task))
                        if array_current_task[selected_idx].idx>max_tasks{//check if the current task has no future task
                            append(&array_future_task, container_future_task_data{array_buffer_task[selected_idx],  2*max_tasks, u16(selected_idx), true, array_data_common[selected_idx].type})
                            //add the future task to the end of the array_future_tasks
                            array_current_task[selected_idx].idx = nb_future_tasks
                            //set the next task 'pointer' of the current task to the added task
                            fmt.print("current task next_task pointer set to :")
                            fmt.println(array_current_task[selected_idx].idx)

                        }
                        else if nb_future_tasks<max_tasks{
                            new_idx := array_current_task[selected_idx].idx
                            old_idx := u16(selected_idx)
                            for new_idx<=max_tasks{// here we search for the first generic_task_data that has a next task idx > max_tasks (ie last in the chain)
                                old_idx=new_idx
                                new_idx = array_future_task[old_idx].next_idx
                            }
                            append(&array_future_task, container_future_task_data{array_buffer_task[selected_idx],  2*max_tasks, old_idx, false, array_data_common[selected_idx].type})
                            //add the new task at the end of the array
                            array_future_task[old_idx].next_idx = nb_future_tasks
                            //set the oprevious last task's 'pointer' to the new last task
                            
                        }
                        else do fmt.printfln("failed to add task, future_task_array has %d of %d slots used", nb_future_tasks, max_tasks)
                        

                    }
                    
                }
                else{ //this happens if we want to replace the whole task chain 
                    //first check if there is a task to replace
                    if !isActivetask(array_current_task[selected_idx]) {
                        array_current_task[selected_idx] = {convertFuture2current(array_buffer_task[selected_idx], array_data_common, selected_idx), 2*max_tasks, array_data_common[selected_idx].type}// 2*max_tasks is used to tell the system there is no future task
                        fmt.println(array_current_task[selected_idx])
                    }
                    else{
                    new_idx := array_current_task[selected_idx].idx
                    old_idx := u16(selected_idx)
                    for new_idx<max_tasks {// here we iterate over the chain of tasks
                        old_idx=new_idx
                        new_idx = array_future_task[old_idx].next_idx

                        if old_idx == u16(len(array_future_task)-1) {//check if the task we want to delete is the last in the array
                            pop(&array_future_task)//we can simply pop it, as there is no other task chain that can be affected
                            
                        }
                        else{
                            //since we will be moving the last task in the array, we need to update the pointers of the task before and after it
                            last_task_prev_idx := array_future_task[len(array_future_task)-1].prev_idx //get the idx of the task that pointed to the last task in the array
                            array_future_task[last_task_prev_idx].next_idx = old_idx //give the new idx of the moved task
                            last_task_next_idx := array_future_task[len(array_future_task)-1].next_idx
                            if last_task_next_idx <max_tasks do array_future_task[last_task_next_idx].prev_idx = old_idx
                            //the line above checks if the displaced task had a next task
                            
                            unordered_remove(&array_future_task, old_idx)
                        }
                        
                    }
                    //overwrite the current task
                    array_current_task[selected_idx] = {convertFuture2current(array_buffer_task[selected_idx], array_data_common, selected_idx), 2*max_tasks, array_data_common[selected_idx].type}// 2*max_tasks is used to tell the system there is no future task
                }
                }
                set_buffer -={selected_idx}
            }
            assert(card(set_buffer)==0, "set buffer wasn't cleared")
        }


       

        select_drag_in_progress = select_drag_in_progress && rl.IsMouseButtonDown(.LEFT)
        task_drag_in_progress = task_drag_in_progress && rl.IsMouseButtonDown(.RIGHT)
        
        //unit ticking 
        
        /*
        Three steps:
            I   iterate over array_current_task, ticking the task_data as it comes 
            II  update the relative data in the units data (ex: update position)
            III if any task is over && it points in array_future_tasks, overwrite current task with the data pointed to and unordered remove it
             

        Ideally the code here will be remplaced with a polymorphiic function to simplyfy the code in main
        */
        
        // I
        units2tick := getWithTask(array_current_task)
        units_done :unit_set={}
        for i in units2tick{
            switch &v in array_current_task[i].data {
                case empty_task_data:
                    fmt.println("tried to tick a unit without task")
                case move_task_data:
                    //fmt.println("tried to move unit")
                    mvt_vec := v.wish-v.current
                    mvt_len := rl.Vector2Length(mvt_vec)
                    mvt_hat :=mvt_vec/mvt_len
                    step := delta_t*type2speed[array_current_task[i].type]
                    if mvt_len<step {
                         v.current = v.wish
                         units_done +={i}//tell the engine that task associated with unit i is done
                    }
                    else do v.current +=mvt_hat*step
                 
            }
        }

        // II
        for i in units2tick{
            switch &v in array_current_task[i].data {
                case empty_task_data:
                    fmt.println("tried to tick a unit without task")
                case move_task_data:
                    array_data_common[i].pos = v.current
                    //fmt.printfln("tried to assign pos (%d, %d) to unit %d", v.current.x, v.current.y, i)
            }
        }
        // III
        //this code will have my sanity I think
        //hopefully I can reduce the if/else dance to something more reasonnable in the future 
        if card(units_done)>0 do printFTA(array_future_task)
        for i in units_done{
            
            updateSlot(&array_current_task, &array_future_task, u16(i), array_data_common)
            /*
            //replace the current task
            idx := u16(array_current_task[i].idx)
            fmt.println("current task ptr")
            fmt.println(idx)
            fmt.println(array_future_task[:])/*
            
            k:=0
            for idx<max_tasks{
                fmt.printf("next task idx for task position %d in the chain and at idx %d in the array :", k, idx)
                k+=1

                idx = array_future_task[idx].next_idx
                fmt.println(idx)
            }*/



            idx2free := array_current_task[i].idx
            //assert(idx2free<u16(len(array_future_task)), "problem in defining next task from current")
            if idx2free<max_tasks{
                new_current_task_data := convertFuture2current(array_future_task[idx2free].data, array_data_common[:], i)
                array_current_task[i] = container_task_data{new_current_task_data, array_future_task[idx2free].next_idx, array_data_common[i].type }
                if !array_future_task[idx2free].prev_in_current do fmt.println("first future task in chain didn't think it was first")
            }
            
            
            //update the chain
            next_idx := array_current_task[i].idx
            if next_idx<max_tasks{  
                array_future_task[next_idx].prev_idx = u16(i)
                array_future_task[next_idx].prev_in_current = true
            }
            else {
                array_current_task[i] = container_task_data{}
                fmt.println("cleared task")
            }
            //remove the value moved in current task

            if idx2free==u16(len(array_future_task)-1){//check if the task we want to remove is the last in array future tasks
                pop(&array_future_task)
            }
            else{
                last_task_prev_idx := array_future_task[len(array_future_task)-1].prev_idx //get the idx of the task that pointed to the last task in the array
                if array_future_task[len(array_future_task)-1].prev_in_current{//last task in array points to task in current
                    
                    array_future_task[len(array_future_task)-1].prev_idx=u16(i)
                    array_current_task[i].idx = idx2free
                    fmt.printfln("next task idx given to current task : %d", idx2free)
                    
                }
                else{
                    array_future_task[last_task_prev_idx].next_idx = idx2free //give the new idx of the moved task
                }
                
                last_task_next_idx := array_future_task[len(array_future_task)-1].next_idx
                if last_task_next_idx <max_tasks do array_future_task[last_task_next_idx].prev_idx = idx2free
                unordered_remove(&array_future_task, idx2free)
            }

            
            
        */    
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
        //drawVics(pos_array[0:nb_vic], angle_array[0:nb_vic], atlas_vic)
        //drawSlds(pos_array[max_vic:max_vic+nb_sld], angle_array[max_vic:max_vic+nb_sld], atlas_sld)

        newDrawThingFromAtlas(array_data_common[:], atlas)
       
        //if select_drag_in_progress do drawSelectionBox(selection_box_start_pos, mouse_pos)
        if select_drag_in_progress {
            drawSelectionBox(select_drag_start_pos, mouse_pos)
        }

        if (task_drag_in_progress && card(selection_set)>1 && interaction_mode_state ==.move) do drawMoveLine(task_drag_start_pos, mouse_pos, card(selection_set))

        for unit_idx in selection_set{
            highlight(array_data_common[unit_idx].pos, array_data_common[unit_idx].type)
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
    //rl.UnloadTexture(atlas_sld)
    //rl.UnloadTexture(atlas_vic)
    rl.UnloadTexture(atlas)
}