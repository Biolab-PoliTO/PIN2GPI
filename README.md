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
</p>
  a. Three clusters selection: organize the sixteen channels of PIs into three clusters according to three different anatomic points on the foot: Heel (blue), 5th metatarsal head (green), 1st metatarsal head (red). </p>
<img  src="https://github.com/Biolab-PoliTO/PI-GaPhI/blob/main/PI_clusters.jpg" width="75"/> </p>
If your data contains a different number of channels or follows a different channels distribution, you should modify the cluster organization within the HFPS_extraction function to match your specific dataset. </p>
  b. Pre-processing and Activation Windows detection for each cluster between max and min peaks
Sum the signals within each cluster, smooth them and calculate their first derivative. The resulting signals undergo an additional smoothing filter. For each cluster signal, the activation start times (maxima) and end times (subsequent minima) are identified using the MATLAB® function findpeaks, by setting these parameters:  minProminence = 0.15; minPeakHeight = 0.06; minPeakDistance = 20. The choice of these values allows to filter out peaks that are significant compared to the overall signal (minProminence), to ignore peaks with very low amplitude values (minPeakHeight) and to prevent the detection of local fluctuations (minPeakDistance).  In cases where two consecutive minima occur within a 500 ms interval, the second minimum is selected as the deactivation point. </p>
  c. Gait Phases Identification (GPI): define the correspondence between the combination of 'active' or 'not active' clusters and  specific gait phases; </p>
      (1)	'H' = 'Heel Contact': only the heel cluster is active;</p>
      (2)	'F' = 'Flat Foot Contact': the heel cluster is active, and at least one cluster under the forefoot is also active;</p>
      (3)	'P' = 'Propulsion': the heel cluster is inactive, while at least one forefoot cluster remains active;</p>
      (4) 'S' = 'Swing': all clusters are inactive</p>
  d. Post-processing: an anti-bouncing filter is applied to remove short and spurious phases (≤ 50 ms) that are surrounded by the same phase both before and after. </p>
  e. Save results: the user is prompted to choose the output format ('csv' or 'txt') and the signal representation, either in 4 numeric levels ('levels') or phase labels ('phase').


## How to prepare your data
INDIP data must be in .mat format to fit the analysis framework. Data example was extracted from the open database made available by the Mobilise-D consortium [1].  What you need (see also data.mat file) is a structure containing normalized pressure insole data in the range [0 1], organized in two fields: </p> 
- LeftFoot.NormalizedPressure: N-by-M matrix, where N represents the time-samples and N represents the number of channels acquired from left side;</p>
- RighFoot.NormalizedPressure: N-by-M matrix, where N represents the time-samples and N represents the number of channels acquired from right side. </p>



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


## Contact
Nicolas Leo, Fellow Research
nicolas.leo@polito.it
