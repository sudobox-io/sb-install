SudoBox

You will need to install as the root user.

### Minimum Specs and Requirements

<ol>
<li>A VPS/VM or dedicated server supporting the following:</li>
<li>Ubuntu 18/20/21</li>
<li>2 CPU Cores or 2 VCPU Cores</li>
<li>2GB Ram</li>
<li>40GB Disk Space</li>
<li>An existing domain or buy a new one from namecheap</li>
<li>Cloudflare account free tier <a href=https://www.cloudflare.com/en-gb/plans/free/>Sign Up</a></li>
</ol>

### INSTALLATION

We recommend you have the following information to hand to help speed up your installation:

<ol>
<li>You will need your CloudFlare email address</li>
<li>Copy your Cloudflare Global API --> Find it here. <a href=https://developers.cloudflare.com/api/keys/#view-your-api-key/>Global API</a></li>
</ol>

To begin your journey with Sudobox, you can execute the installation process by typing or pasting the command below:

```
sudo apt update
sudo apt install curl
curl -fsSl https://raw.githubusercontent.com/sudobox-io/sb-install/master/install.sh | sudo bash && sb
```

have the following information handy to speed up your installation:

<ol>
<li>Cloudflare Email</li>
<li>Cloudflare API Token --> learn to make one here. <a href=https://developers.cloudflare.com/api/tokens/create//>API Tokens</a></li>
<li>Cloudflare Global API --> Find it here. <a href=https://developers.cloudflare.com/api/keys/#view-your-api-key/>Global API</a></li>
</ol>

![SudoBox Preinstaller!](./sb-installer.png "SB-preinstaller")

### NOTICE

Sudobox is underway with features to be added on a weekly basis therefore all documentation, container images and code are subject to change.

### Support

For more indepth guides please visit our documentation <a href="https://docs.sudobox.io">https://docs.sudobox.io</a>

If you are looking for help our discord and Forum members are ready to lend a hand.. <a href="https://sudobox.io">Sudobox</a>
