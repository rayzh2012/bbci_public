BC= [];
BC.fcn= @bbci_calibrate_csp_tiny;
BC.folder= EEG_RAW_DIR;
BC.file= 'VPkg_08_08_07/imag_arrowVPkg';
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2; 'left', 'right'}};

% In demos, we just write to the temp folder. Otherwise, the default
% choice would be fine.
BC.save.folder= TMP_DIR;
BC.log.folder= TMP_DIR;

bbci= struct('calibrate', BC);

[bbci, calib]= bbci_calibrate(bbci);
%bbci_save(bbci, calib);


% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {calib.cnt, calib.mrk};

bbci.log.output= 'screen&file';
bbci.log.folder= TMP_DIR;
bbci.log.classifier= 1;

data= bbci_apply(bbci);

log_format= '%fs | [%f] | {cl_output=%f}';
[time, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'delimiter','','commentstyle','shell');

cnt_cfy= struct('fs',25, 'x',cfy, 'clab',{{'cfy'}});
epo_cfy= proc_segmentation(cnt_cfy, calib.mrk, [0 5000]);
fig_set(1, 'name','classifier output'); clf;
plot_channel(epo_cfy, 1);