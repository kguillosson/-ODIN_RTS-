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




