# PI2GPI: from Pressure Insoles to the Gait Phases Identification

<p align="center">


Accurate detection of foot-floor contact during gait analysis is essential for estimating spatio-temporal gait parameters. Variability in the sequence of gait phases is also a key factor in assessing risk of falls among elderly and pathological subjects. This repository introduces ```PI2GPI```, an approach designed for the automatic classification of gait phases based on pressure insoles (PI) signals.

While existing algorithms focus on stance and swing parameters only, there is still a lack of methods to extract the sub-phases of stance (heel contact, flat-foot contact, and push-off), specifically from PI signals. The analysys of these gait phases helps reveal hidden issues in abnormal walking patterns that can make frail patients more likely to fall. 

```PI2GPI``` is a tool for the classification of gait phases from pressure insole data, applicable both in structured laboratory tests and in unsupervised settings during free daily living activities.


## What the ```PI2GPI``` algorithm does:
1.	Load the data file (".mat");
2.	Detect the gait phases from anatomic clustering of PI channels;
3.	Display results in 'csv' or 'txt' format.

## Files description
The following files are provided within the GitHub repository:
- PI2GPI: main function that guides you through all the main steps of Gait Phases detection;
- PI.mat: .mat file containing normalized pressure insoles data from a representative healthy adult during simulated daily activities test.
- HFPS_extraction: function that contains the detection of gait phases from clustering of PI channels according to the anatomic contact points on the foot. It consists of:</p>
</p>
  a. Three clusters selection: after defining the sampling frequency (Hz), arrange the sixteen PI channels in three clusters according to three different anatomical points on the foot: Heel (blue), 5th metatarsal head (green), 1st metatarsal head (red). </p>
<img  src="https://github.com/Biolab-PoliTO/PI-GaPhI/blob/main/PI_clusters.jpg" width="75"/> </p>
If your data contains a different number of channels or follows a different channels distribution, you should modify the cluster organization within the HFPS_extraction function to match your specific dataset. </p>
  b. Pre-processing and Activation Windows detection for each cluster between the maximum and minima peaks  </p>
Sum the signals within each group, smooth them using the MATLAB function smooth setting a 11-sample span and calculate their first derivative. The resulting signals undergo an additional moving average filter with an 5-sample span. For each cluster signal, the activation start times (maxima) and end times (subsequent minima) are identified using the MATLAB function findpeaks, by empirically setting the following parameters:  minProminence = 0.15; minPeakHeight = 0.06; minPeakDistance = 20. These values allow you to filter out peaks that are significant compared to the overall signal (minProminence), ignore peaks with very low amplitude values (minPeakHeight) and prevent detection of local fluctuations (minPeakDistance).  In cases where two consecutive minima occur within a 500 ms interval, the second minimum is selected as the deactivation point. </p>
  c. Gait Phases Identification (GPI): define the correspondence between the combination of 'active' or 'not active' clusters and  specific gait phases; </p>
      (1)	'H' = 'Heel Contact': only the heel cluster is active;</p>
      (2)	'F' = 'Flat Foot Contact': the heel cluster is active, and at least one cluster under the forefoot is also active;</p>
      (3)	'P' = 'Propulsion': the heel cluster is inactive, while at least one forefoot cluster remains active;</p>
      (4) 'S' = 'Swing': all clusters are inactive</p>
  d. Post-processing: an anti-bouncing filter is applied to remove short and spurious phases (≤ 50 ms) that are surrounded by the same phase before and after them. </p>
  e. Save results: the user is invited to choose the output format (0 for 'csv' or 1 for 'txt') to save the output signal. 


## How to prepare your data
Data must be in .mat format to fit the analysis framework. Data example was extracted and reorganized from the open database made available by the Mobilise-D consortium [1].  What you need (see also PI.mat file) is a structure containing normalized pressure insoles data in the range [0 1], organized in two fields: </p> 
- LeftFoot: N-by-M matrix, where N represents the time-samples and M represents the number of channels acquired from left side;</p>
- RighFoot: N-by-M matrix, where N represents the time-samples and M represents the number of channels acquired from right side. </p>



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
