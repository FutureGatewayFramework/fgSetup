# Docker Installation

This repository contains necessary files to instantiate FutureGateway components using Docker containers. Each component has its own directory and each directory shares the same structure and installation procedure.
Essentially each directory contains:
 * A README file explaining the component
 * A Makefile that can be used to build the container image and run it. The Makefile contains several variables to configure properly. These variables are also used by different components' Makefiles. It is important to keep consistent these variables among different Makefiles.
 * The Dockerfile containing internally several environment variables needed to configure the component. Several variables are shared among different Dockerfiles. It is important that their value will be the same on each Dockerfile.
 
