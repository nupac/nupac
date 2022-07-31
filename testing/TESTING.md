## __Testing__

### __Manual testing__
To simplify creation of reproducible test environments, a Vagrantfile is included in `vagrant` directory that will set up an Ubuntu 22.04 VM with nushell preinstalled and project directory mounted under `/vagrant`. Uses VirtualBox provider by default unless ran on MacOS ARM in which case it defaults to Parallels

#### __Quickstart__
* Make sure you have Vagrant installed
* Make sure you have Parallels (MacOS ARM64) or Virtualbox (other platforms) installed
* Run `vagrant up` to set up the test VM
* Run `vagrant ssh` to connect to the VM

#### __Caveats__
By default Vagrant will install the latest available version of nushell. If you need to install an older version instead pass its version tag as an argument to vagrant when running `vagrant up` or `vagrant provision` like this: `vagrant --version=0.63.0 up`

### __Automated testing__
Automated tests are written using Ansible and Molecule framework. Ansible was chosen because of its system-level automation capabilities as well as ease of use and readability of the resulting playbooks.

#### __Quickstart__
* Make sure you have following packages installed: python3 docker pip
* Make sure your user is able to run Docker containers without a password (i.e by adding your used to the `docker` group)
* Install python dependencies by running 'pip install -r requirements.txt'
* Run `molecule test` to run the default test case using the default distro

#### __Framework design__
Because our use case differs greatly from what is usually achieved using either of these tools we utilize them in a slightly non-standard way. Instead of per-scenario subdirectories nested within `molecule` directory (as is customary in Molecule) we use a single `default` scenario with each test case being a separate Converge stage playbook. This allows us to maintain only a single test configuration in `molecule.yml` instead of using a separate one for every single test case. Additionally, we utilize a shared Prepare stage playbook that we use both for initial config as well as as a smoke test. Think of it as an equivalent of `beforeEach` stage in JUnit/Mocha.

Test case to run is selected by setting `TEST` environment variable corresponding to the name of the playbook containing our test. This allows us to easily parallelize test runs on CI

Distro to run tests on is selected by setting `DISTRO` environment variable corresponding to the name and tag of a base Docker container we want to use. Just like with test case selection the purpose of this decision is ease of parallelization

Each test runs in a Docker container built from a Jinja template. We decided not to use pre-built containers due to our need to cover both glibc and musl based distros (Most Ansible Docker maintainers such as Jeff Geerling only provide glibc based containers since that's what's being commonly used for servers). This might change in the future if we decide that the effort necessary to maintain this design outwieghs the benefits of covering Alpine Linux.

Windows and MacOS systems are not currently tested but we hope to change that in the future

#### __Test design__
Each test case sets necessary state (if applicable) and performs assertions using native Ansible modules. Only command currently under test is executed using Nushell itself (by utilizing Ansible `raw` module). The reason for that is Nushell is a part of System-Under-Test and as such should not be trusted by the tests. We violate this principle a bit by piping output of some commands into `to json` but without that asserting on command output would be nigh impossible

#### __Local development__
In order to run any of the tests locally set the environment variable `TEST` to the name of the test and then run `molecule test`. In nushell this can be easily achieved using `with-env` command, i.e: `with-env [TEST refresh-cache.yml] {molecule test}`

### __Scripts__
Purpose of scripts included in this directory is as follows:
* get-testcases.nu - This script is used by CI to generate list of test cases to execute on Pull Request
* linter.nu - This script runs linter on all .nu files in repository
* run-all-tests.nu - This script is used to run all tests in the repository sequentially
* shell.nu - This script is used to connect to Docker container created by Molecule for debugging. Run this after running either create or converge stages (but not full test as full tests destroy the test container afterwards)
* template.nu - This script is used to render the Dockerfile using jinja cli. Run this when making changes to Dockerfile.j2 to check rendered file for syntax issues