# Motion compensation

Code of the motion compensation algorithm described in the article “Imaging neural activity in the ventral nerve cord of behaving adult Drosophila” by C. L. Chen, L. Hermans, M. C. Viswanathan, D. Fortun, M. Unser, A. Cammarato, M. H. Dickinson and P. Ramdya. The code is only for scientific or personal use.

## How to install

* Install the MIJ library (http://bigwww.epfl.ch/sage/soft/mij/): copy the files “ij.jar” and “mij.jar” in the java folder of MATLAB (should be `/path/to/MATLAB/java/jar/`, e.g.: `/usr/local/MATLAB/R2018a/java/jar/`).
* Clone the repository: `git clone https://github.com/NeLy-EPFL/motion_compensation`
* Enter it: `cd motion_compensation`
* Compile the deep matching code using the following commands in directory: 
  1. `cd code/external/deepmatching_1.2.2_c++_mac/` or `cd code/external/deepmatching_1.2.2_c++_linux/` depending on your OS 
  2. `make clean all`
* Go back: `cd ../../..`
* Edit “setPath.m”: 
  * Set the paths of the MIJ library (**Note:** this might change if MATLAB version is upgraded)
  * Set the path where motion_compensation is installed (e.g.: /home/user/repos/motion_compensation)
* Launch MATLAB, and inside:
  * Run “setPath.m”: `>> setPath`
  * Compile the main file corresponding to your OS:
      ```
      >> mcc -m main_linux.m -o motion_compensation
      ```
      or
      ```
      >> mcc -m main_mac.m -o motion_compensation
      ```
* You might want to create an alias to launch the executable more easily (cf. **How to run**):  
   ```  
   alias motion_compensation="/path/to/motion_compensation/run_motion_compensation.sh /path/to/MATLAB"  
   ```  
   You can add this line to your .bashrc file to automatically have this alias when you start a terminal. 
   
## How to run

After the compilation, two new files have been created: `motion_compensation` and `run_motion_compensation.sh`. The first one is the executable, and the second one is the script to set the matlab environment variables, and then launch the executable (cf. `readme.txt` also generated).

To run the program, write in the terminal:
```
./run_motion_computation.sh /path/to/MATLAB /path/to/data [-option | -option VALUE]
```

To see the available options and optional arguments:
```
./run_motion_computation.sh /path/to/MATLAB -h
```

I recommend setting an alias to launch the motion computation without having to use the script with the MATLAB directory. E.g.:
```
alias motion_compensation="/path/to/motion_compensation/run_motion_compensation.sh /path/to/MATLAB"  
```
You can then directly write in the terminal:
```
motion_computation /path/to/data [-option | -option VALUE]
```
To unset the alias, use the `unalias motion_computation` command.

## Usage of the executable
```
Usage: motion_compensation pathToData [-option | -option VALUE]

    pathToData         - Path to the folder containing the 2 sequences:
                           1. tdTom.tif: used for computing the motion field
                           2. GC6*.tif: sequence to be warped by the motion
                                        field (capitalization does not matter)

    -h|-help           - Display this help message
    -l VALUE           - Regularization parameter lambda, default is 1000
                         Can be multiple values, e.g.: -l "[100 500 1000]"
    -g VALUE           - Strength of the feature matching constraint gamma,
                         default is 100
                         Can be multiple values, e.g.: -g "[10 50 100]"
    -N VALUE           - Number of frames to process (use -1 for all frames),
                         default is -1
    -results_dir PATH  - Path to the result folder, default is results/

Examples:
  $ motion_compensation data/experiment_1 -l 500 -g 100 -result_dir results_1
  $ motion_compensation data/experiment_2 -result_dir results_2 -g "[10 20]"
  $ motion_compensation data/experiment_3 -N 5
```
