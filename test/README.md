# test
This subfolder contain the necessary files to test the script based installation using a Docker container.
This kind of installation can be also used to install a compact FutureGatway system for small projects or for test purposes.

# Usage
To execute the tests, it is necessary to accomplish the following steps:

1. Create the docker image

`make image`

2. Run the image

`make run`

3. Execute the tests. In order to execute the tests, it is necessary to open a shell on top of the running Docker container and execute the `do_tests.sh` script with:

* Start the container: `docker run -d --rm --name fgtest futuregateway/fgtest:latest`
* Enter the container: `docker exec -ti fgtest /bin/bash`
* Install and execute tests: `./do_tests.sh`

The test has two different phases. At the beginning it installs the Futuregateway components using the script based installation (apt based installation). In the second phase it runs a set of tests checking FutureGateway APIs.

# Other tests
Whith this test environment it is also possible to enable SSH and perform a small task execution test.
Instructions to accomplish this kind of tests are available below:

```bash
sudo su - futuregateway
cd $HOME/fgAPIServer
cp /home/fgtest/fgSetup/docker/test_futuregateway.sh ./test_futuregateway.sh
ESC_FGHOST=$(echo "localhost/fgapiserver/$FGAPISERVER_APIVER" | sed s/\\//\\\\\\//g)
sed -i "s/^FGHOST.*/FGHOST=$ESC_FGHOST/" test_futuregateway.sh
sed -i "s/  fgapisrv_lnkptvflag.*/  fgapisrv_lnkptvflag: False/" fgapiserver.yaml
sudo su - -c "echo \"127.0.0.1    sshnode\" >> /etc/hosts"
sudo su - -c "echo \"127.0.0.1    fgdb\" >> /etc/hosts"
sudo useradd -m -p $(echo "test" |openssl passwd -1 -stdin)  -s /bin/bash test
# Now you can execute tests with:
./test_futuregateway.sh
```

# Code changes
The following commands are useful to apply APIServerDaemon code changes.

```bash
rm -rf ~/APIServerDaemon/web/WEB-INF/lib
mkdir -p ~/APIServerDaemon/web/WEB-INF/lib
cp ~/grid-and-cloud-engine/grid-and-cloud-engine-threadpool/target/lib/*.jar ~/APIServerDaemon/web/WEB-INF/lib/
cp ~/grid-and-cloud-engine/grid-and-cloud-engine-threadpool/target/*.jar ~/APIServerDaemon/web/WEB-INF/lib/
cp ~/grid-and-cloud-engine/grid-and-cloud-engine_M/target/lib/*.jar ~/APIServerDaemon/web/WEB-INF/lib/
cp ~/grid-and-cloud-engine/grid-and-cloud-engine_M/target/*.jar ~/APIServerDaemon/web/WEB-INF/lib/
cp ~/jsaga-adaptor-rocci/dist/jsaga-adaptor-rocci.jar ~/APIServerDaemon/web/WEB-INF/lib
cd ~/APIServerDaemon
mvn clean; mvn install
sudo cp target/APIServerDaemon.war $CATALINA_HOME/webapps/
```

To monitor the reloading phase of the APIServerDaemon web application, use:

```bash
tail -f $CATALINA_HOME/logs/catalina.out
```

# Execution control
Use the following commands to monitor APIServerDaemon activities:

* Tomcat log: `tail -f $CATALINA_HOME/logs/catalina.out`
* APIServerDaemon log: `tail -f $CATALINA_HOME/webapps/APIServerDaemon/WEB-INF/logs/APIServerDaemon.log`
* GridEngine log: `tail -f $CATALINA_HOME/webapps/APIServerDaemon/WEB-INF/logs/GridEngineLog.log`

Use the following commands to manage FutureGateway services:

* **fgdb** - `sudo service mysql [start|stop|restart]`
* **fgAPIServer** - `sudo service [start|stop|restart]`
* **APIServerDaemon** - `sudo -u futuregateway $CATALINA_HOME/bin/catalina.sh [start|stop] &&`

Please be sure to run Tomcat as futuregateway user.

# Known issues

* APIServerDemon don't start. This problem seems related to slower systems. The `catalina.out` file reports `null` as FutureGateway DB version. In this case just restart Tomcat.
* Script `do_tests.sh` hangs during the installation (apt installations). It may happen the apt-get command requires user prompt durign the installation. In such a case, it is recommended to verify first what is causing this problem looking in the log file: `/var/log/apt/term.log`. To avoid this problem, there are two possibilities: the first, installing manually the package and then re-executing the script. In the second case try the command `apt-get upgrade -y` and then retry the script execution.
