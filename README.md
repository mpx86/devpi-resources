# devpi-resources

Documentation and other resources on installing and configuring devpi.

This documentation is based on using Ubuntu 24.04. 

## Prerequisite steps on AWS

1. Create t3.small or larger instance. t2.micro and t3.micro do not have enough CPU or memory capacity and will hang
2. Allow ports 22 and 3141 in the security group. 3141 is the default port for devpi, but this can be changed
3. SSH into instance

## Steps to run inside the EC2 instance

Install updates and reboot:

```shell
sudo apt update && sudo apt upgrade
sudo reboot
```

Create devpi user, add to sudoers, enable passwordless sudo

```shell
sudo useradd -m -s /bin/bash devpi
sudo usermod -aG sudo devpi
echo "devpi ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo /etc/sudoers.d/90-cloud-init-users
```

Log in as devpi user:

`sudo su - devpi`

Install Python, pip, and venv:

`sudo apt install python3 python3-pip python3-venv -y`

Create venv called devpi-venv and switch into that env:

```sh
python3 -m venv devpi-venv
source devpi-venv/bin/activate
```

Install devpi server, web interface, and client:

`pip install devpi-server devpi-web devpi-client`

Create directory for devpi files:

`mkdir devpi-server`

Init devpi:

`devpi-init --serverdir /home/devpi/devpi-server/data`

Generate config files for devpi:

`devpi-gen-config`

Edit the service file:

`nano gen-config/devpi.service`

Modify this line with your path:

```sh
[Service]
ExecStart=/home/devpi/devpi-venv/bin/devpi-server --serverdir /home/devpi/devpi-server/data --host 0.0.0.0 --port 3141
```

Copy the modified service to the systemd folder, then refresh service info from /etc/systemd/system:

```shell
sudo cp gen-config/devpi.service /etc/systemd/system/
sudo systemctl daemon-reload
```

Enable devpi service on startup, then start the service manually:

```shell
sudo systemctl enable devpi.service
sudo systemctl start devpi.service
```

Monitor systemctl status in realtime:

`sudo journalctl -u devpi.service -f`

## The following are devpi client commands to configure certain settings

If you want to keep your monitoring session going, launch a new ssh session before running the following tasks.

Log in as devpi, switch into your devpi venv then tell devpi to use your instance:

```shell
sudo su - devpi
source devpi-venv/bin/activate
devpi use http://localhost:3141/root/pypi
```

Configure root user password, then log in as root:

```shell
devpi-passwd root --serverdir /home/devpi/devpi-server/data
devpi login root
```

Create 'packages' user. This username will be included in the index URL (e.g.: http://localhost:3141/packages/).

You will be prompted to create a password.

`devpi user -c packages email=packager@contoso.com password=packages`

Verify new user exists. This is not needed in any automation scripts:

`devpi user -l`

Log in as packages user:

`devpi login packages`

Create new index. Volatile allows editing. Empty `bases` means
it won't cache any upstream packages from public PyPI

`devpi index -c dev bases= volatile=True`

Make default index volatile (editable), then delete default index:

```shell
devpi index root/pypi volatile=True
devpi index root/pypi --delete
```

>[!NOTE]
>You may need to reboot to stop indexing. My test server didn't stop indexing 
> PyPI packages until I rebooted. The indexing process is CPU-intensive.

## How to upload Python packages to your devpi server

Ensure you have the latest version of Twine installed:

`python3 -m pip install --upgrade twine`

From inside your package directory, run the following command:
URL Format: http://your-devpi-domain-or-ip:3141/username/indexname 

`python3 -m twine upload --repository-url http://devpi.contoso.com:3141/packages/dev dist/*`

## Useful Tips
Use this commnad to restrict admin changes such as index and user creation to only the root user:
`devpi-server --restrict-modify=root`

## Follow up tasks to be added later

- Figure out how to use an SSL cert
- Figure out how to integrate GitHub Actions
- Determine if containerization is appropriate
- Figure out how to use securely set passwords in unattended fashion
- Figure out theming
