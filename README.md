# PI2GPI: from Pressure Insoles to the Gait Phases Identification

<p align="center">


Accurate detection of foot-floor contact during gait analysis is crucial for estimating spatio-temporal gait parameters. Variability in the sequence of gait phases (HFPS) is also a key factor in assessing fall risk among the elderly and pathological subjects. This repository introduces ```PI2GPI```, an approach designed for automatic and user-independent classification of gait cycle phases based on pressure insoles signals.

Although the use of force platforms and instrumented walkways is direct well-established gold standards approach in this field, it is costly, non-portable, and confined to laboratory environments. Instrumented plantar insoles (pressure insoles) including only sixteen force sensing resistor elements offer a valid alternative, overcoming these limitations.

```PI2GPI``` is a robust tool for the accurate and efficient classification of gait phases from pressure insoles data.


## What the ```PI2GPI``` algorithm does:
1.	Load data file (".mat");
2.	Detect Gait Phases from anatomic clustering of channels of PI;
3.	Visualize results in 'csv' or 'txt'.

## Files description
The following files are provided within the GitHub repository:
- PI2GPI: Main function that guides you through all the main steps of Gait Phases detection;
- data.mat: .mat file containing representative data acquired from pressure insoles and other sensors on a healthy adult during locomotion.
- HFPS_extraction: Function containing detection of gait phases from clustering of pressure insoles channels according to anatomic regions of foot. It consists of:</p>
  a. Three clusters individuation: organize the sixteen channels of PI into three clusters according to four different anatomic points of foot: Heel (blue), 5th metatarsal head (green), 1st metatrsal head (red). </p>
<img  src="https://github.com/Biolab-PoliTO/PI-GaPhI/blob/main/PI_clusters.jpg" width="75"/> </p>
  b. Individuate Activation Windows (AW) of each cluster. Signals within the same cluster were summed and smoothed and their first derivative was calculated. The resulting signal underwent an additional smoothing filter. 
For each cluster, the activation start times (maxima) and end times (subsequent minima) were identified using the MATLAB® function findpeaks, by setting these parameters minProminence = 0.15; minPeakHeight = 0.06; minPeakDistance = 20. The choice of these values helped 
  filter out peaks that are significant compared to the overall signal (minProminence), allowed to ignore peaks with very low amplitude values (minPeakHeight) and prevented the detection of local fluctuations (minPeakDistance).  In cases where two consecutive minima occurred within a 500 ms interval, the second minimum was selected as the deactivation point. </p>
  c. Identify gait phases: define correspondence between the combination of 'active' or 'not active' clusters and a specific gait phase; </p>
      (1)	'H' = 'Heel Contact':  only the heel cluster is active;</p>
      (2)	'F' = 'Flat Foot Contact': the heel cluster is active, and at least one cluster under the forefoot is also active;</p>
      (3)	'P' = 'Propulsion': the heel cluster is inactive, while at least one forefoot cluster remains active;</p>
      (4) 'S' = 'Swing': all clusters are inactive</p>
  d. Post-processing: anti-bouncing filter was applicated to remove short and spurious phases shorter or equal to 50 ms surrounded by the same phase before and after. </p>
  e. Save results: prompt the user to choose the output format 'csv' or 'txt' and the signal in 4 numeric levels ('levels') or phase labels ('phase')


## How to prepare your data
INDIP data must be in .mat format to fit the analysis framework. Data example was extracted from the open database made available by the Mobilise-D consortium [1].  What you need (see also data.mat file) is a structure containing Pressure insole data, organized in two fields: </p> 
- LeftFoot: N-by-M matrix, where N represents the time-samples and N represents the number of channels acquired from left side </p>;
- RighFoot: N-by-M matrix, where N represents the time-samples and N represents the number of channels acquired from right side </p>.
If you had a number of acquired channels or a different disposition, you should modify the organization  of the channels in the three cluster (point a.) in the function HFPS_extraction.


## How to contribute to ```PI2GPI```
Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!
1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## Disclaimer
This algorithm is provided as-is, and unfortunately, there are no guarantees that it fits your purposes or that it is bug-free.

## Reference
[1] A. Küderle, “Mobilise-D Technical Validation Study (TVS) dataset [Data set],” Zenodo. [Online]. Available: http://doi.org/10.5281/zenodo.13899385
[2] L. Palmerini et al., “Mobility recorded by wearable devices and gold standards: the Mobilise-D procedure for data standardization,” Sci Data, vol. 10, no. 1, Dec. 2023, doi: 10.1038/s41597-023-01930-9.

## Contact
Nicolas Leo, Fellow Research
nicolas.leo@polito.it
