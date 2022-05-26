# FRI-ReinforcementLearning
*Fuzzy Rule Interpolation-based Reinforcement Learning* (FRIRL) offers a way to construct sparse fuzzy rule-bases as the knowledge representation for Reinforcement Learning methods.
This has the advantage, that the knowledge base can be directly human readable, as fuzzy rules are inherently self-describing and can use natural language terms.
This framework was implemented in MATLAB and in C, and provides the well-known benchmark applications (Cart-Pole, Mountain-Car, Acrobot) in order to demonstrate the capabilities of Fuzzy Rule Interpolation-based Reinforcement Learning methods.

For example, after performing the rule-base construction and reduction steps for the Cart-Pole benchmark with FRIRL, one possible valid fuzzy rule-base consists of only 5 rules:

| Cart Position | Cart Acceleration | Pole Position | Pole Falling | Force to apply | Q |
| ----- | ------- | --------- | ----- | ---------| ------------- |
| Right | Stopped | Standing  | Right | Right 10 | Slightly good |
| Right | Stopped | Bit left  | Left  | Left 10  | Slightly good |
| Right | Stopped | Standing  | Left  | Left 8   | Slightly good |
| Right | Right   | Standing  | Left  | Left 8   | Bad           |
| Right | Stopped | Max right | Right | Right 6  | Very bad      |

The [C version](https://github.com/szaguldo-kamaz/FRI-ReinforcementLearning-C/) lacks some functions which the MATLAB version has (e.g. rule-base reduction methods), but performs much better (in some cases 400x times faster).
For details see, or if you find this method useful for your research, please cite the following paper(s):

* D. Vincze, *"Fuzzy rule interpolation and reinforcement learning,"* 2017 IEEE 15th International Symposium on Applied Machine Intelligence and Informatics (SAMI), 2017, pp. 173-178, doi: [10.1109/SAMI.2017.7880298](https://doi.org/10.1109/SAMI.2017.7880298)

* D. Vincze, A. Tóth and M. Niitsuma, *"Antecedent Redundancy Exploitation in Fuzzy Rule Interpolation-based Reinforcement Learning,"* 2020 IEEE/ASME International Conference on Advanced Intelligent Mechatronics (AIM), 2020, pp. 1316-1321, doi: [10.1109/AIM43001.2020.9158875](https://doi.org/10.1109/AIM43001.2020.9158875)

* T. Tompa and Sz. Kovács, *"Clustering-based fuzzy knowledgebase reduction in the FRIQ-learning,"* 2017 IEEE 15th International Symposium on Applied Machine Intelligence and Informatics (SAMI), 2017, pp. 000197-000200, doi: [10.1109/SAMI.2017.7880302](https://doi.org/10.1109/SAMI.2017.7880302)
