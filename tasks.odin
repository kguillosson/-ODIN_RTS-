package main

import "core:slice"
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
union_task_data :: union #no_nil{
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
union_future_task_data :: union #no_nil{
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

convertFuture2current :: proc (input : union_future_task_data, array_data:[max_units]common_data, unit_idx:u8)->(union_task_data){
    
    switch i in input {
        case empty_task_data:
            fmt.println("feur") 
        case move_future_task_data:
            out : move_task_data = {array_data[unit_idx].pos, i.wish_pos}
            return out
    }
    return empty_task_data{}
}

isActiveTask :: proc (task : container_task_data)->bool{
    #partial switch v in task.data {
         case move_task_data:
            return true
    }
    return false
}

isActiveTaskFuture :: proc (task : container_future_task_data)->bool{
    #partial switch v in task.data {
         case move_future_task_data:
            return true
    }
    return false
}


getWithTask :: proc(current_tasks :[max_units]container_task_data)->(ret_set : unit_set){
    for i:u8=0; i<max_units; i+=1{
       

        if isActiveTask(current_tasks[i]) do ret_set +={i}
    }
    return
}


/*
Here we reimplement the code to deal with array_future_tasks

updateslot is called when a task in the current array has finished
if the current task was final (ie the idx is > max_unit)
    We overwrite the task with an empty container
if the current task points to a value in the future array
    we check
*/
printFTA :: proc(future_task_array : [dynamic]container_future_task_data){
    for data, idx in future_task_array{
        fmt.printfln("container nb : %d, prev idx : %d, is prev in current : %t, next idx : %d", idx, data.prev_idx, data.prev_in_current, data.next_idx)
    }

}

updateSlot :: proc(array_current :^[max_units]container_task_data, array_future :^[dynamic]container_future_task_data, slot :u16, data:[max_units]common_data){
    if array_current[slot].idx > u16(max_units){
        array_current[slot] = container_task_data{}
        return
    }  
    else{//now we suppose that there is a future container to instanciate 
        //first we check there wasn't a problem with the pointed to future container
        next_task_idx:=array_current[slot].idx
        assert(array_future[next_task_idx].prev_idx == slot, "current and future task disagree on the chain")
        assert(array_future[next_task_idx].prev_in_current, "future task didn't know it was next in line")
        //overwrite the current task
        array_current[slot] = container_task_data{convertFuture2current(array_future[next_task_idx].data, data, u8(slot)), array_future[next_task_idx].next_idx,  array_future[next_task_idx].type}
        //check if the task we moved had a next task
        //now we need to update the pointed to task to tell it that it is next in line and its new previous location
        idx_of_last :=u16(len(array_future))-1

        if array_current[slot].idx >u16(max_units){
            //the task we moved in current was last in chain, we only need to remove the data from array future
            removeTask(array_future, array_current, next_task_idx)
        }
        else{//now we are in the bothersome situation where there was a task after the one we made current
            //update the next task in chain, tell it where it's previous is and that it's 1st in chain
            array_future[array_current[slot].idx].prev_idx = slot
            array_future[array_current[slot].idx].prev_in_current = true
            removeTask(array_future, array_current, next_task_idx)
        }

    return
        //now we need to remove the value we moved 

    }
    
}
removeTask :: proc(array_future : ^[dynamic]container_future_task_data, array_current:^[max_units]container_task_data, idx : u16){
    //this is called to remove the task in slot idx of the array future
    //it supposes that the removal of task idx in itself will not break anything
    idx_of_last :=u16(len(array_future))-1
    if idx_of_last == idx do pop(array_future) // it was last in the array, we can remove without affecting any other values
    else{ // a different future task is last in array
        prev_of_last := array_future[idx_of_last].prev_idx
        next_of_last := array_future[idx_of_last].next_idx
        //overwrite the moved data with the last in array
        array_future[idx] = array_future[idx_of_last]
        //update the 'pointers'
        if array_future[idx_of_last].prev_in_current{// if the displaced task was 1st in chain
            array_current[prev_of_last].idx = idx//tell coresp task in current that it's next task was moved
        }
        else{ //displaced wasn't 1st in chain
            array_future[prev_of_last].next_idx = idx//tell coresp task in future that it's next task was moved
        }
        if next_of_last > u16(max_units){//task was last in chain
            //do nothing
        }
        else{//last task in array has a next task
            array_future[next_of_last].prev_idx = idx
        }
        pop(array_future)
    }

}

removeChain :: proc(array_future : ^[dynamic]container_future_task_data, array_current:^[max_units]container_task_data, idx : u16){
    //here we want to remove all the tasks in the chain related to the unit idx
    next_idx := array_current[idx].idx// idx of first task in related to unit in the future
    current_idx :=idx
    for next_idx <max_tasks{
        current_idx = next_idx
        next_idx = array_future[current_idx].next_idx
        removeTask(array_future, array_current, current_idx)
    }
}





//

//New implementation
//let's do a simpler approach where we don't try to have a densly packed array and accept the presence of holes

//this finds the first free slot in the array
FindFirstFreeSlot :: proc(array_future : ^[dynamic]container_future_task_data)->(u16, bool){
    k :u16=0

    for isActiveTaskFuture(array_future[k])&&k<u16(len(array_future)){
        k+=1
    }
    if k<u16(len(array_future))-1 do return k, true
    else do return k, false
}

// we suppose that the slot in current is filled
Add2Future :: proc(array_future : ^[dynamic]container_future_task_data, array_current:^[max_units]container_task_data, data2add : union_future_task_data, idx : u16){
    assert(isActiveTask(array_current[idx]), "tried to add a future without a present")
    //find last task in chain for concerned idx
    next_slot :u16=array_current[idx].idx
    slot :u16= idx
    prev_in_current := true
    for next_slot <2*max_tasks{
        slot = next_slot
        next_slot = array_future[slot].next_idx
        prev_in_current = false
    }
    free_slot, ok := FindFirstFreeSlot(array_future)
    if !ok{
        if free_slot<max_tasks-1{
            append(array_future, container_future_task_data{data2add, 2*max_tasks, slot, prev_in_current, array_current[idx].type})
            return
        }
        else do fmt.println("failed to add task")
    }
    else{
        array_future[free_slot] = {data2add, 2*max_tasks, slot, prev_in_current, array_current[idx].type}
    }
}

clearChain :: proc(array_future : ^[dynamic]container_future_task_data, array_current:^[max_units]container_task_data, idx : u16){
    if !isActiveTask(array_current[idx]){
        fmt.println("tried to empty an empty chain")
        return
    }  
    slot :=idx
    next_slot :=array_current[idx].idx
    array_current[idx] = {}
    k:=1
    for next_slot <max_tasks{
        slot = next_slot
        next_slot = array_future[slot].next_idx
        array_future[slot] = {}
        k+=1
    }
    fmt.printfln("removed %d tasks in chain associated with slot %d", k, idx)
    return
}

updateChain :: proc(array_future : ^[dynamic]container_future_task_data, array_current:^[max_units]container_task_data, idx : u16){

}

getFutureStorageData :: proc(array_future : [dynamic]container_future_task_data, array_current : [max_units]container_task_data)->(length, used_slots , lost_tasks:u16){
    length = u16(len(array_future))
    slots_explored := make([dynamic]u16, 0, max_tasks)
    defer delete(slots_explored)
    units_with_task:=getWithTask(array_current)
    for idx in units_with_task{
        current, next :u16 = u16(idx), array_current[idx].idx
        for next <max_tasks{
            current = next
            next = array_future[current].next_idx
            append(&slots_explored, current)
        }
    }
    lost_tasks =0
    used_slots = u16(len(slots_explored))
    slice.sort(slots_explored[:])
    for k:u16=0; k<used_slots-1; k+=1{
        for j:=slots_explored[k]+1; j<slots_explored[k+1]; j+=1{
            if isActiveTaskFuture(array_future[j]) do lost_tasks+=1
        }
    }
    return
}

