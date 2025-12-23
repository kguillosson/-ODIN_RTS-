package main

import rl "vendor:raylib"
import "core:fmt"

//here we will define everything related to tasks, their management and their types

/*
currently, the objective is to have tasks stored in two arrays: 
1 fixed length array with one slot per unit, used to store and work on the current task
1 dynamic array to store future tasks

task data will contain the necessary data to tick the unit, and the index of the next task to accomplish, with an arbirary big number used to denote the absence of a next task
*/

//observe me recreate linked and double linked lists like it's 1955

task_type :: enum u8{
    none =0,
    move =1,

}
empty_task_data :: struct{}

move_task_data :: struct{
    current, wish :rl.Vector2
}
union_task_data :: union{
    empty_task_data,
    move_task_data,
}
container_task_data :: struct{
    data : union_task_data,
    idx : u16,//stores the postion of the next task
    type : enum_type,
}

//the datastructures used below are meant to save memory in the buffer and future array
move_future_task_data :: struct{
    wish_pos:rl.Vector2,
}
union_future_task_data :: union{
    empty_task_data,
    move_future_task_data
}
container_future_task_data :: struct{//woo double linked list
    data : union_future_task_data,
    next_idx :u16,
    prev_idx :u16,
    prev_in_current :bool, //tells if there are other task Qed in the array_future_task
    type : enum_type,
}

convertFuture2current :: proc (input : union_future_task_data, array_data:[]common_data, unit_idx:u8)->(output :union_task_data){
    
    switch i in input {
        case empty_task_data:
            fmt.println("feur") 
        case move_future_task_data:
            out : move_task_data = {array_data[unit_idx].pos, i.wish_pos}
            return out
    }
    return empty_task_data{}
}

