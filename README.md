# Process Modeling in Decentralized Organizations

Prototype for process modeling in decentralized organizations. A first version for process modeling and instance tracking is extended in the current version of this prototype. In addition to securing the integrity of models on the Ethereum blockchain and model versioning through the Git DVCS, the modeling of organizations with decentralized agreement is implemented.

Please note that is an alpha version for demonstration purposes.

Copyright: (c) 2020 Felix Härer


## Contents

This repository contains two versions of the software:

- Prototype_v2 is the current version developed in 2019 and 2020 as a proof-of-concept for:<br>
  Härer, Felix (2020): Process Modeling in Decentralized Organizations Utilizing Blockchain Consensus. Accepted for publication in: Enterprise Modelling and Information Systems Architectures (EMISAJ) – International Journal of Conceptual Modeling.<br>
 Härer, Felix (2019): Integrierte Entwicklung und Ausführung von Prozessen in dezentralen Organisationen. Ein Vorschlag auf Basis der Blockchain, Dissertation, University of Bamberg Press, Germany. DOI: 10.20378/irbo-55721.
 

- Prototype_v1 is the first version developed in 2018 as a proof-of-concept for:
 Härer, Felix (2018): Decentralized Process Modeling and Instance Tracking Secured By a Blockchain. In: Proceedings of the 26th European Conference on Information Systems (ECIS). Portsmouth, UK, June 23-28, 2018. https://aisel.aisnet.org/ecis2018_rp/55/.


## Requirements

The current version of the prototype requires the following software:

- Java SE 11 with JavaFX.
- The Ethereum node software parity in a fully validating configuration, synchronized and connected to the public ethereum network. 
- A Git repository for loading and saving models accessible over https.


The first version of the prototype includes Java and the Ethereum node software geth. Note that this version is only available for Windows. If Java SE 9 and JavaFX are not installed on the system, the included jre.zip must be extracted within the directory of the prototype.
It requires:

- Java SE 9 with JavaFX.
- A Git repository for loading and saving models accessible over https.


### Setup

When the program is started, a new ethereum wallet can be created and registered with the program's smart contract. Alternatively, an existing wallet might be chosen. A Git repository then needs to be specified in order to load and save models.


### Smart Contracts

Two smart contracts for the current version of the prototype are deployed on Ethereum. 

- A global smart contract handles the registration of peers with their addresses, the storage of integrity data for global commits, and for voting processes in the form of the two-phase commits. It is deployed at 0xD38CF1FDAB83DAE505224A1F8DC264E3FB85C24E, see e.g. https://etherscan.io/address/0xD38CF1FDAB83DAE505224A1F8DC264E3FB85C24E.

- An object-specific smart contract handles the model versioning and execution for individual peers. For the case study discussed in the publication, the contract for the object 'Manufacturer' is deployed at 0x6c249d8c7a3a75419d1fe2dcfb0644fb5ea9a60a. See e.g. https://etherscan.io/address/0x6c249d8c7a3a75419d1fe2dcfb0644fb5ea9a60a.


The smart contract for the first version is deployed on an Ethereum testnet at address 0x44838c369f4c7f781bb6b14df3c45f5b4797af0d. See e.g. https://ropsten.etherscan.io/address/0x44838c369f4c7f781bb6b14df3c45f5b4797af0d.
