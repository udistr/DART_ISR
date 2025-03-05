import netCDF4 as nc
import numpy as np
import time
import os
import sys
import random

def add_perts(mem_num, perts_dir):
    wall_clock = int(time.time_ns()) % 32766
    np.random.seed(wall_clock)
    
    scale = {
        'T': 1.3,
        'U': 1.3,
        'V': 1.3,
        'Q': 1.3,
        'M': 0.6
    }
    
    bank_size = 100
    ens_mem_num = random.randint(1, bank_size)
    pert_bank_file = "pert_bank_mem_{}.nc".format(ens_mem_num)
    wrf_file = "wrfvar_output"
    
    with open("mem{}_pert_bank_num".format(mem_num), "w") as f:
        f.write(str(ens_mem_num))
    
    print("bank member number {}".format(ens_mem_num))
    
    pert_fields = ["U", "V", "T", "QVAPOR", "MU"]
    wrf_fields = ["U", "V", "THM", "QVAPOR", "MU"]
    pert_scale = [scale['U'], scale['V'], scale['T'], scale['Q'], scale['M']]
    
    pert_path = os.path.join(perts_dir, pert_bank_file)
    
    # Try opening with different modes and options
    try:
        with nc.Dataset(pert_path, "r") as pert_in:
            # First read all the data we need
            pert_data = {}
            for field in pert_fields:
                pert_data[field] = pert_in.variables[field][:]

        for wrf_filename in [wrf_file, wrf_file + ".nc"]:
            try:
                with nc.Dataset(wrf_filename, "r+", format="NETCDF3_64BIT") as wrf_in:
                    for wrf_field, pert_field, scale_factor in zip(wrf_fields, pert_fields, pert_scale):
                        temp_w = wrf_in.variables[wrf_field][:]
                        temp_p = pert_data[pert_field]
                        temp_c = temp_w + (temp_p * scale_factor)
                        wrf_in.variables[wrf_field][:] = temp_c
                    break  # Exit the loop if successful
            except:
                if wrf_filename.endswith(".nc"):  # If both attempts failed, raise the error
                    raise
                continue

    except Exception as e:
        print("Error occurred: {}".format(str(e)))
        raise
    
    print("perts added")

if __name__ == "__main__":
    import sys
    error_file = open('add_perts.err', 'w')
    sys.stderr = error_file
    MEM_NUM = sys.argv[1] if len(sys.argv) > 1 else "1"
    PERTS_DIR = sys.argv[2] if len(sys.argv) > 2 else "."
    
    add_perts(MEM_NUM, PERTS_DIR)
    error_file.close()
