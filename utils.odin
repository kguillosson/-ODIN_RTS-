package main

makeSets :: proc(array_data:[]common_data)->(unit_set, sld_set, vic_set :unit_set){
    /*
    This function is used to make sets informing us on the type of the datapoints in array data for easy acces
    */
    for data, idx in array_data{
        if data.type!=.none {
            unit_set+={u8(idx)}
            #partial switch data.type{
                case .sld:
                    sld_set+={u8(idx)}
                case .vic:
                    vic_set+={u8(idx)}
            }
        }
    }
    return
}


getWithTask :: proc(current_tasks :[max_units]container_task_data)->(ret_set : unit_set){
    for i:u8=0; i<max_units; i+=1{
        if type_of(current_tasks[i].data) != empty_task_data do ret_set+={i}
    }
    return
}

