# fgSetup
This software installs and upgrades FutureGateway components.
It provides an easy to use and very flexible solution to install different FutureGateway components on different hosts running each a different OS architecture. More components may also run on the same host.
The setup procedure can be executed more times in order to upgrade the existing system or distribuite configuration changes among components.
This software deprecates the original setup procedure [PortalSetup][PortalSetup] which provides FutureGateway installation procedure as well but limited to a single host only. 

# Components
The setup procedure supports the following FutureGateway components:

* fgdb - The FutureGateway database; available on [fgAPIServer][fgdb]
* [fgAPIServer][fgAPIServer] - The python version of APIServer (front-end)
* [APIServerDaemon][ApiServerDaemon] - The Java version of the APIServerDaemon (queue polling) and its related Executor Interfaces
* Liferay62 - A liferay portal and eventually its SDK, linked to the APIServer
* Liferay7 - A liferay portal and eventually its SDK, linked to the APIServer

# Architectures
The setup procedure supports the following OS architectures, actually differentiated only by the package manager applicaions:

* brew - MacOSx 10.x (Brew can be installed during installation)
* apt - Debian/Ubuntu(14.04)
* yum - CentOS(7)

# How it works
The installation process foresees the following steps:

1. Identify the necessary components to install and the whole FutureGateway services topology. In case more hosts are involved in the setup process, please ensure to run the setup from a host able to connect via ssh ach node passwordlessly, properly exchanging SSH keys. Early phases of the setup will try to identify any missing mandatory configuration.
2. Modify the setup\_config.sh file configuring each FutureGateway service as designed in the previous step. Each FutureGateway component contains its own specific settings inside the setup\_config.sh script. Any FG user specified in the configurion file setup\_config.sh must be already present in its host system with passwordless sudo authorization as well as SSH key exchange with the installation node.
3. From the installation host, execute the script setup\_futuregateway.sh. The first time the setup procedure will install from Git all selected components, while further executions will try to upgrade the components and update its configurations accordingly with the values placed in the file setup\_config.sh

[fgdb]: <https://github.com/indigo-dc/APIServerDaemon>
[PortalSetup]: <https://github.com/indigo-dc/PortalSetup>
[fgAPIServer]: <https://github.com/indigo-dc/fgAPIServer>
[APIServerDaemon]: <https://github.com/indigo-dc/APIServerDaemon>

