# Semaphore Image

This directory contains files to create a Semaphore packer image

## Build Image

Packer managed image stored in resource group

```powershell
./build.ps1 -WorkingDirectory "./" -File "build.json" -VariablesFile "variables.json"
```

## Notes from HashiCorp (Email)

You should take a look at this [document](https://www.terraform.io/docs/enterprise/private/centos-install-guide.html) about deploying PTFE to CentOS. Note the following key things:

1. You need to pre-install a suitable version of Docker prior to deploying PTFE itself.

2. Despite that doc saying "Docker CE 17.06 or later", PTFE cannot run with Docker CE 18.x. In fact, this [doc](https://www.terraform.io/docs/enterprise/private/preflight-installer.html#software-requirements) makes it explicit that you should not use Docker CE above 17.12.

3. ou need to configure a suitable docker storage backend, prior to installing Docker. The first link I gave gives links for using the devicemapper and overlay2 options.

4. Additionally, there is an issue with many Linux-based Azure VMs which cause the Linux OS to only see 30GB of storage even through the volume selected for the VM is given more. The [PTFE Azure Guide](https://www.terraform.io/docs/enterprise/private/azure-setup-guide.html) has a [link](https://blogs.msdn.microsoft.com/linuxonazure/2017/04/03/how-to-resize-linux-osdisk-partition-on-azure/) to a document that gives a procedure for resizing the Linux disk partition. This needs to be 50GB to pass the PTFE pre-flight checks.

Also, if you are trying to do the [automated installation](https://www.terraform.io/docs/enterprise/private/automating-the-installer.html) using the replicated.conf and application-settings.json files, be sure to put a copy of replicated.conf readable by all users (with chmod 644) in the /etc directory since that is where the replicated installer looks for it. As long as the replicated.conf file uses fully qualified paths to other files like the json file and the license file, you can put those files wherever you want.
