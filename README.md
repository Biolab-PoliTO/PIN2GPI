# PI2GPI: from Pressure Insoles to the Gait Phases Identification

<p align="center">
<img  src="https://github.com/NicolasLeo-hub/PI-GaPhI/blob/main/detection_example.jpg" width="2000"/>
</p>

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
- HFPS_extraction: Function containing detection of gait phases from clustering of pressure insoles channels according to anatomic regions of foot. It consists of:
  1. Three clusters individuation: organize the sixteen channels of PI into three clusters according to four different anatomic points of foot. (Figure)
     Heel: channels '12,13,14,15,16'
     5th metatarsal head: channels '5,9,10,11'
     1st metatrsal head: channels '1,2,3,4,6,7,8'
     <p align="center">
<img  src="https://github.com/Biolab-PoliTO/PI-GaPhI/blob/main/PI_clusters.jpg" width="2000"/>
</p>
     
  3. Individuate AW of each cluster: 
  4. Identify gait phases: define correspondence between the combination of 'active' or 'not active' clusters and a specific gait phase;
     (1) 'H' = 'Heel Contact':  only the heel cluster is active;
     (2) 'F' = 'Flat Foot Contact': the heel cluster is active, and at least one cluster under the forefoot is also active;
     (3) 'P' = 'Propulsion': the heel cluster is inactive, while at least one forefoot cluster remains active;
     (4) 'S' = 'Swing': all clusters are inactive
  5. Save results: prompt the user to choose the output format 'csv' or 'txt' and the signal in 4 numeric levels ('levels') or phase labels ('phase')


## How to prepare your data
INDIP data must be in .data format to fit the analysis framework.


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

## Contact
Nicolas Leo, Fellow Research
nicolas.leo@polito.it
