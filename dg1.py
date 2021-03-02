import pandas as pd
import xarray as xr

from allensdk.core.brain_observatory_cache import BrainObservatoryCache
import allensdk.brain_observatory.stimulus_info as stim_info
from allensdk.brain_observatory.drifting_gratings import DriftingGratings

# This class uses a 'manifest' to keep track of downloaded data and metadata.  
# All downloaded files will be stored relative to the directory holding the manifest
# file.  If 'manifest_file' is a relative path (as it is below), it will be 
# saved relative to your working directory.  It can also be an absolute path.
boc = BrainObservatoryCache()

# Download a list of all targeted areas
targeted_structures = boc.get_all_targeted_structures()

# Download cells for a set of experiments and convert to DataFrame
cells = boc.get_cell_specimens()
cells = pd.DataFrame.from_records(cells)

dsi_cells = cells.query('area == "VISp" & g_dsi_dg >= .2 & g_dsi_dg < .9')

# find experiment containers for those cells
dsi_ec_ids = dsi_cells['experiment_container_id'].unique()

# Download the ophys experiments containing the static gratings stimulus for VISp experiment containers
dsi_exps = boc.get_ophys_experiments(experiment_container_ids=dsi_ec_ids, stimuli=[stim_info.DRIFTING_GRATINGS])

exp_id = dsi_exps[1]['id']
data_set = boc.get_ophys_experiment_data(exp_id)

dg = DriftingGratings(data_set)
mean_sweeps = dg.mean_sweep_response.values

d = xr.DataArray(
    mean_sweeps, 
    dims=("stim", "cell"),
    coords = {'cell' : [str(x) for x in dg.cell_id] + ['dx']})
d.to_dataframe(name='value').reset_index().to_feather('cells_dg1.feather')

dg.stim_table.to_feather('stim_table_dg1.feather')
