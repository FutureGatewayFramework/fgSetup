# test
This subfolder contain the necessary files to test the script based installation using a Docker container.
This kind of installation can be also used to install a compact FutureGatway system for small projects or for test purposes.

# Usage
To execute the tests, it is necessary to accomplish the following steps:

1. Create the docker image
`make image`

2. Run the image
`make run`

3. Execute the tests. In order to execute the tests, it is necessary to open a shell on top of the running Docker container and execute the `do_tests.sh`script.
`docker run -ti --rm --name fgtest futuregateway/fgtest:latest /bin/bash`
`./do_tests.sh`

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
```