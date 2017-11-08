# nidmresults-spmhtml

Read and display NIDM-Results packs in the SPM environment.

##### Usage

To view NIDM results using the NIDM results viewer run the following

1. Open SPM fMRI from the Matlab command line.
1. Click on Batch.
<img src="Doc/examplemenu1.png" width="300">  
 **Fig. 1.** The SPM menu.
1. Click on SPM -> Tools -> NIDM-Results Display
<img src="Doc/examplemenu2.png" width="300">  
 **Fig. 1.** The SPM option in the batch window.
1. Enter the NIDM-Results file you wish to view and where you wish the output html to be stored.
<img src="Doc/example_batch.png" width="300">  
 **Fig. 1.** The NIDM-Results batch window.
1. If there are multiple excursion sets stored in the NIDM-Results file the contrast window will open. Select the contrasts you wish to view and click done.
<img src="Doc/example_conMan.png" width="300">  
 **Fig. 1.** The contrast manager window.
1. This should create output like the below.

<img src="Doc/example1.png" width="300">            |  <img src="Doc/example2.png" width="300">
:-------------------------:|:-------------------------:
 **Fig. 1.** Table data and images  |  **Fig. 2.** Summary statistics

##### Requirements

- [SPM12](http://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

##### Installation

1. Add the filepath to SPM in Matlab;

 ```
 addpath(<full path to SPM>)
 ```
1. Clone this repository into the SPM toolboxes folder (into the below folder).
 ```
 <full path to SPM>/toolbox
 ``` 

##### Testing

1. Add the filepath to the 'tests' folder;

 ```
addpath(fullfile(fileparts(which('nidm_results_display')), 'test'))
 ```
1. Run runTest;

 ```
 runTest();
 ```


##### Notes for future development

1. Currently (as of 19/03/2017), there is a bug in the NIDM-export for SPM which means that attributes with the prefix `nidm_` inside the jsonld have an additional `:` character appended on the end. This has been fixed and should be updated in the next SPM update. However, until then, in the viewer there is some additional code removing these colons. This code can be found in the `nidm_results_display` code specifically in lines 26 and 124 onwards.

1. Presently (as of 19/03/2017), both FSL and SPM export NIDM-Results in the prov jsonld format. However, although both of these follow the same guidelines, the export for these packs is very different. The viewer currently supports NIDM-Results packs generated by the FSL-format that contain either a single excursion set or multiple excursion sets. 
However, the viewer only supports SPM-formatted NIDM-Results packs containing a SINGLE excursion set. This is simply as SPM only exports single contrast NIDM-Results packs currently. However, if in the future another software supports NIDM-Results export and follows the SPM NIDM export format and exports multiple contrasts, the viewer will not be able to display the export. Currently, this is not an issue but it is something to be aware of, should more softwares adopt NIDM-Results. 
