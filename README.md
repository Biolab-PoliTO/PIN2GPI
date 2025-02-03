# PI2GPI: from Pressure Insoles to the Gait Phases Identification

<p align="center">


Accurate detection of foot-floor contact during gait analysis is essential for estimating spatio-temporal gait parameters. Variability in the sequence of gait phases is also a key factor in assessing risk of falls among elderly and pathological subjects. This repository introduces ```PI2GPI```, an approach designed for the automatic classification of gait phases based on pressure insoles (PI) signals.

While existing algorithms focus on stance and swing parameters only, there is still a lack of methods to extract the sub-phases of stance (heel contact, flat-foot contact, and push-off), specifically from PI signals. The analysys of these gait phases helps reveal hidden issues in abnormal walking patterns that can make frail patients more likely to fall. 

```PI2GPI``` is a tool for the classification of gait phases from pressure insole data, applicable both in structured laboratory tests and in unsupervised settings during free daily living activities.


## What the ```PI2GPI``` algorithm does:
1.	Load the data file (".mat");
2.	Detect the gait subphases from anatomic clustering of PI channels;
3.	Display results in 'csv' format.

## Files description
The following files are provided within the GitHub repository:
- PI2GPI: main function that guides you through all the main steps of Gait Phases detection;
- PI.mat: .mat file containing normalized pressure insoles data from a representative healthy adult during aa 2.5-hour recording segment of daily free activities.
- HFPS_extraction: function that contains the detection of gait phases from clustering of PI channels according to the anatomic contact points on the foot. It consists of:</p>
</p>
  a. Three clusters selection: arrange the sixteen PI channels in three clusters according to three different anatomical points on the foot: Heel (blue), 5th metatarsal head (green), 1st metatarsal head (red). </p>
<img  src="https://github.com/Biolab-PoliTO/PI-GaPhI/blob/main/PI_clusters.jpg" width="75"/> </p>
Prompt the user to modify in the command window the default channels distribution for each cluster if your data contains a different number of channels or follows a different channels distribution from the foot plot </p>
  b. Pre-processing and Activation Windows detection for each cluster between the maximum and minima peaks  </p>
  Sum PI signals within the same cluster and then normalize them respect to the channels number. Smooth the cumulative signals using an 11-sample moving average filter and compute their first derivative (ƩPI)’. Finally, apply an additional moving average filter with a 5-sample span on the resulting signals. </p>
For each cluster, the activation windows were identified using the derivative signal. Candidate start times and end times were determined by detecting maxima and minima peaks exceeding a height threshold of 0.01. Since peaks in the derivative signal correspond to the points of maximum rate of pressure change in the cumulative signals of each cluster, an activation window was defined as the time interval between the current maximum and the highest amplitude minimum before the subsequent maximum. In cases where two consecutive maxima occurred without an intermediate minimum, the maximum with the greater amplitude was selected as the activation point and the next occurring minimum was used as the deactivation point </p>
  c. Gait Phases Identification (GPI): define the correspondence between the combination of 'active' or 'not active' clusters and specific gait phases; </p>
      (1)	'H' = 'Heel Contact': only the heel cluster is active;</p>
      (2)	'F' = 'Flat Foot Contact': the heel cluster is active, and at least one cluster under the forefoot is also active;</p>
      (3)	'P' = 'Propulsion': the heel cluster is inactive, while at least one forefoot cluster remains active;</p>
      (4) 'S' = 'Swing': all clusters are inactive</p>
  d. Save results: The labeled output signals are saved in CSV format with two columns: Left and Right, respectively.


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
