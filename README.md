# ```PIN2GPI```: from Pressure INsoles to the Gait Phases Identification

<p align="center">
<img  src="https://github.com/Biolab-PoliTO/PI2GPI/blob/97f5aeefb8b41c8eab0977a60af527776efaa14d/pressure_insole_data.png" style="width:100%; height:auto;"/></p>

Accurate detection of foot-floor contact sequences during walking is a fundamental requirement for accurately estimating spatio-temporal gait parameters, which are widely used in gait analysis for clinical, rehabilitation, and research purposes. Variability in gait phase sequences is particularly important in assessing the risk of falls, especially among elderly individuals and those with pathological gait patterns. These variations may indicate underlying conditions such as neurological disorders, musculoskeletal impairments, or frailty, impacting mobility and increasing the likelihood of falls.<br>

To address these challenges, this repository introduces ```PIN2GPI```, an open-source toolbox designed for the automatic identification and classification of gait subphases using data collected from Pressure Insoles (PIs). This innovative approach leverages the temporal and spatial information provided by PIs to accurately identify both the principal gait subphases (i.e., stance and swing) and the finer sub-phases of stance (i.e., heel contact, flat-foot contact, and push-off), crucial for a comprehensive understanding of gait mechanics, as they provide deeper insights into atypical walking patterns [1].<br>

```PIN2GPI``` is versatile and can be used across a wide range of applications, from controlled laboratory environments to unsupervised real-world settings such as free daily living activities. This flexibility makes it an invaluable tool for clinicians, researchers, and healthcare providers seeking to monitor and analyze gait in both structured and dynamic conditions. Moreover, ```PIN2GPI``` can be flexibly modified at need to comply with the necessities of the user.<br>

By enabling the detection of subtle abnormalities in gait phase sequences, ```PIN2GPI``` helps uncover unique insights into an individual’s walking patterns, paving the way for more effective interventions, personalized treatment plans, and fall prevention strategies. Its open-source nature ensures accessibility for the research community and promotes further development and innovation in gait analysis.<br>


## What the ```PIN2GPI``` algorithm does:
1.	Load ``*.mat`` file containing the normalized PI data
2.	Define anatomical clusters and pre-process PI data 
3.	Identify gait subphases based on the activation status of each cluster
4.	Graphically represent results 
5. 	Export results in ```*.csv``` format


## Files description:
The following files are provided within the GitHub repository:
- ```PIN2PGI.m```: MATLAB algorithm that guides you throughout all the main steps of gait phases identification
- ```data.mat```: MATLAB file containing normalized pressure insoles data from a representative healthy adult during free daily living activities.
</p>
A detailed description of all the toolbox steps is available within the MATLAB algorithm and in [1].

## How to prepare your data:
To use this analysis framework, your data must be in ```*.mat``` format. <br>
**Example Data**<br>
The provided example dataset has been extracted and reorganized from the open database made available by the **Mobilise-D consortium** [2].<br>
**Data Structure**<br>
Your ```*.mat``` file should contain a structure with pressure insole data, normalized to the range [0, 1], and organized into two fields:
1.	```LeftFoot```: an N × M matrix, where N = Number of time samples and M = Number of channels acquired from the left foot
2.	```RightFoot```: an N × M matrix, where N = Number of time samples and M = Number of channels acquired from the right foot <br>
For a representative example of the expected input format, refer to the ```data.mat``` file.<br>

## References
If you use ```PIN2GPI``` algorithm in your work, please cite the following article:
[1] Ghislieri, M., Leo, N., Caruso, M. et al. (2025) A toolbox for the identification of foot-floor contact sequences to analyze atypical gait cycles in a real-life scenario: application on patients after proximal femur fracture and healthy elderly. J NeuroEngineering Rehabil 22, 161 (https://doi.org/10.1186/s12984-025-01683-z)

## Open-Access Data
If interested in freely available sEMG signals, please consider downloading the following dataset:
[2] Küderle, A. (2024). Mobilise-D Technical Validation Study (TVS) dataset (1.0.0) [Data set]. Zenodo.(https://doi.org/10.5281/zenodo.13899386)


##  How to contribute to ```PIN2GPI```
Contributions are the heart of the open-source community, making it a fantastic space for learning, inspiration, and innovation. While we've done our best, our code may contain inaccuracies or might not fully meet your needs. If you come across any issues—or have ideas for improvements—we encourage you to contribute! Follow the instructions below to suggest edits or enhancements. Every contribution is **greatly appreciated**!<br>

Bugs are tracked as **GitHub issues**. Whenever you report an issue, please make sure to:<br>
1.	Use a concise and descriptive title
2.	Report your MATLAB version
3.	Report whether the code ran successfully on the test data available within the repository.


## Contacts
**Nicolas Leo**, Scholarship holder - [BIOLAB@Polito](https://biolab.polito.it)<br>
[@NicolasLeo](https://www.linkedin.com/in/nicolas-leo-732aa927b/) - nicolas.leo@polito.it

**Marco Ghislieri**, Ph.D. - [BIOLAB@Polito](https://biolab.polito.it/people/marco-ghislieri/) <br>
[@MarcoGhislieri](https://twitter.com/MarcoGhislieri) - marco.ghislieri@polito.it
