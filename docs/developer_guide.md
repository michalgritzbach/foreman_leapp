# Developer guide
The `foreman_leapp` plugin enables the consumer to use a job template to upgrade Red Hat Enterprise Linux hosts.

**Example usage**

* In the Foreman web UI, navigate to Hosts > All Hosts.
* Select the hosts that you want to upgrade to Red Hat Enterprise Linux 8.
* In the upper right of the Hosts window, from the Select Action list, select Preupgrade check with Leapp.
* Click Submit to start the pre-upgrade check.
* When the check is finished, click the Leapp preupgrade report tab to continue
* Fix the found remediation(s) and run the upgrade job
* For further information see the documentation links bellow

## Spin up virtual machines
Easiest way to spin up virtual machines is with the [Vagrant](https://www.vagrantup.com)  & Libvirt.

**Installation (Fedora)**
```shell
sudo dnf install vagrant-libvirt
sudo dnf install @vagrant
```

**Sample Vagrant file** (with [RHEL 7 box](https://app.vagrantup.com/generic/boxes/rhel7))
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "generic/rhel7"
end
```

**Spin up the RHEL 7 machine**
```shell
vagrant up rhel7
```

## Leapp tool
### Installing on RHEL 7

**Register & subscribe**
```shell
subscription-manager register
subscription-manager list --available --match-installed
subscription-manager attach --pool POOL_ID
```

**Enable repositories**
```shell
subscription-manager repos --enable rhel-7-server-rpms
subscription-manager repos --enable rhel-7-server-extras-rpms
```

**Update to the latest `7.x` version**
```shell
yum clean all
yum update
reboot

cat /etc/os-release
# => Check that RHEL is on the latest version
```

**Install Leapp tool**
```shell
yum install -y leapp
```

## Leapp commands

**Pre-upgrade check**
```shell
leapp preupgrade

# => /var/log/leapp/leapp-report.json (This one is parsed by foreman-leapp)
# => /var/log/leapp/leapp-report.txt
# => /var/log/leapp/leapp-preupgrade.log

leapp preupgrade --verbose  # Enable verbose logging
leapp preupgrade --debug    # Enable debug mode
```
For the report sample see the files in the `report_samples` folder. `leapp-report.json`
comes from leapp 0.21, `leapp-report-0.22.json` from leapp 0.22.

Starting with leapp 0.22 the arguments of the `command` remediations are reported
verbatim, while older leapp quoted them itself
([leapp-repository#1520](https://github.com/oamg/leapp-repository/pull/1520)).
The remediation plan is therefore assembled based on the version of the `leapp`
package the report was collected with, which is stored in
`preupgrade_report_entries.leapp_version`.

**Upgrade**

```shell
leapp upgrade
```

## Resources and documentation

* [RHEL - Upgrading from RHEL 7 to RHEL 8](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/upgrading_from_rhel_7_to_rhel_8)
* [Satellite - Upgrading from RHEL 7 to RHEL 8](https://access.redhat.com/documentation/en-us/red_hat_satellite/6.10/html/managing_hosts/upgrading-hosts-from-rhel7-to-rhel8_managing-hosts)
* [Developer documentation for Leapp tool](https://leapp.readthedocs.io/en/latest/index.html)
* ~~[leapp-to.github.io/gettingstarted](https://leapp-to.github.io/gettingstarted)~~ is outdated, do not use!
